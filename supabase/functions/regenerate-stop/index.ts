import { withSupabase } from "npm:@supabase/server@1.4.1";

type Input = { recommendation_id?: string; stop_number?: number };

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const userId = context.userClaims?.id;
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }
    const input = await request.json().catch(() => ({})) as Input;
    if (
      !input.recommendation_id ||
      !Number.isInteger(input.stop_number) ||
      input.stop_number! < 1 ||
      input.stop_number! > 3
    ) {
      return Response.json({ message: "Choose a valid mystery stop." }, {
        status: 400,
      });
    }

    const admin = context.supabaseAdmin;
    try {
      const { data: recommendation, error: recommendationError } = await admin
        .from("mission_recommendations")
        .select("*,mission_requests!inner(*)")
        .eq("id", input.recommendation_id)
        .single();
      if (recommendationError) throw recommendationError;
      const missionRequest = recommendation.mission_requests;
      if (missionRequest.user_id !== userId || missionRequest.status !== "ready") {
        return Response.json({ message: "This mission cannot be changed." }, {
          status: 403,
        });
      }
      const { data: stops, error: stopsError } = await admin
        .from("mission_recommendation_stops")
        .select("stop_number,destination_id")
        .eq("recommendation_id", recommendation.id)
        .order("stop_number");
      if (stopsError) throw stopsError;
      const excluded = new Set(stops.map((row) => row.destination_id));
      const { data: previousVisits, error: visitsError } = await admin
        .from("verified_visits")
        .select("stage_id")
        .eq("user_id", userId);
      if (visitsError) throw visitsError;
      if (previousVisits?.length) {
        const { data: secrets } = await admin.from("mission_stage_secrets")
          .select("destination_id").in(
            "stage_id",
            previousVisits.map((row) => row.stage_id),
          );
        for (const row of secrets ?? []) excluded.add(row.destination_id);
      }

      const { data: destinations, error: destinationsError } = await admin
        .from("destinations")
        .select(
          "id,latitude,longitude,categories,estimated_budget_myr," +
            "estimated_duration_minutes,discovery_score,safety_score,capacity_per_slot",
        )
        .eq("active", true)
        .in("safety_status", ["automated_review", "curated"])
        .gte("safety_score", 0.6);
      if (destinationsError) throw destinationsError;
      const categorySet = new Set(missionRequest.categories ?? []);
      const eligible = (destinations ?? [])
        .filter((destination) => !excluded.has(destination.id))
        .filter((destination) =>
          categorySet.size === 0 ||
          destination.categories.some((category: string) =>
            categorySet.has(category)
          )
        )
        .map((destination) => ({
          ...destination,
          distance: distanceBetween(
            missionRequest.origin_latitude,
            missionRequest.origin_longitude,
            destination.latitude,
            destination.longitude,
          ) / 1000,
        }))
        .filter((destination) =>
          destination.distance <= missionRequest.maximum_distance_km
        )
        .sort((a, b) =>
          Number(b.discovery_score ?? 0) - Number(a.discovery_score ?? 0)
        );

      let replacement: any = null;
      for (const candidate of eligible) {
        const { data: clue } = await admin.from("destination_clues")
          .select("destination_id").eq("destination_id", candidate.id)
          .maybeSingle();
        if (!clue) continue;
        const { data: allocation } = await admin.rpc(
          "reserve_destination_capacity",
          {
            p_destination_id: candidate.id,
            p_user_id: userId,
            p_request_id: missionRequest.id,
            p_recommendation_id: recommendation.id,
            p_expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
          },
        );
        if (allocation) {
          replacement = candidate;
          break;
        }
      }
      if (!replacement) {
        return Response.json({
          message: "No different safe destination is available right now.",
        }, { status: 409 });
      }

      const oldStop = stops.find((row) =>
        row.stop_number === input.stop_number
      )!;
      const { error: updateStopError } = await admin
        .from("mission_recommendation_stops")
        .update({
          destination_id: replacement.id,
          travel_distance_km: replacement.distance,
        })
        .eq("recommendation_id", recommendation.id)
        .eq("stop_number", input.stop_number);
      if (updateStopError) throw updateStopError;
      await admin.from("destination_allocations").update({
        status: "released",
        released_at: new Date().toISOString(),
      }).eq("recommendation_id", recommendation.id)
        .eq("destination_id", oldStop.destination_id)
        .eq("status", "reserved");

      const allIds = stops.map((row) =>
        row.stop_number === input.stop_number
          ? replacement.id
          : row.destination_id
      );
      const { data: route } = await admin.from("destinations")
        .select("categories,estimated_budget_myr,estimated_duration_minutes")
        .in("id", allIds);
      const duration = (route ?? []).reduce(
        (total, row) => total + Number(row.estimated_duration_minutes ?? 60),
        0,
      );
      const budget = (route ?? []).reduce(
        (total, row) => total + Number(row.estimated_budget_myr ?? 0),
        0,
      );
      const aiCopy = await regenerateMissionCopy({
        originalTitle: recommendation.title,
        categories: (route ?? []).flatMap((row) => row.categories ?? []),
        duration,
        budget,
      });
      const updated = {
        title: aiCopy?.title ??
          `${recommendation.title.replace(/ Remix$/, "")} Remix`,
        story_hook: aiCopy?.story_hook ??
          "A freshly remixed three-stop mystery trail with one new hidden gem.",
        explanation: aiCopy?.explanation ??
          "One stop was replaced while your budget, time, safety and exploration constraints were preserved.",
        difficulty: aiCopy?.difficulty ?? recommendation.difficulty,
        estimated_duration_minutes: duration,
        estimated_budget_myr: budget,
      };
      const { data: saved, error: saveError } = await admin
        .from("mission_recommendations")
        .update(updated)
        .eq("id", recommendation.id)
        .select()
        .single();
      if (saveError) throw saveError;
      await admin.from("recommendation_events").insert({
        request_id: missionRequest.id,
        recommendation_id: recommendation.id,
        event_type: "stop_regenerated",
        prompt_version: "mission-v4-three-stops",
        payload: { stop_number: input.stop_number },
      });
      return Response.json({
        recommendation: {
          id: saved.id,
          title: saved.title,
          story_hook: saved.story_hook,
          explanation: saved.explanation,
          estimated_duration_minutes: saved.estimated_duration_minutes,
          estimated_budget_myr: saved.estimated_budget_myr,
          difficulty: saved.difficulty,
          recommendation_rank: saved.recommendation_rank,
          stops: 3,
        },
      });
    } catch (error) {
      console.error("Stop regeneration failed:", safeMessage(error));
      return Response.json({
        message: "The mystery stop could not be regenerated.",
      }, { status: 500 });
    }
  }),
};

async function regenerateMissionCopy(input: {
  originalTitle: string;
  categories: string[];
  duration: number;
  budget: number;
}): Promise<{
  title: string;
  story_hook: string;
  explanation: string;
  difficulty: string;
} | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!apiKey) return null;
  const configuredModel = Deno.env.get("GEMINI_MODEL")?.trim();
  const models = configuredModel
    ? [configuredModel]
    : ["gemini-3.6-flash", "gemini-flash-latest", "gemini-2.5-flash"];
  const prompt = [
    "Refresh the public copy for a bright Malaysian mystery-tourism mission after one hidden stop changed.",
    "Never reveal or imply a destination name, address, landmark, route or exact location.",
    "Return a short playful title, a one-sentence story hook, a one-sentence explanation, and difficulty: easy, moderate, or challenging.",
    JSON.stringify({
      previous_title: input.originalTitle,
      activity_categories: [...new Set(input.categories)].slice(0, 8),
      estimated_duration_minutes: input.duration,
      estimated_budget_myr: input.budget,
    }),
  ].join("\n");
  const responseSchema = {
    type: "OBJECT",
    required: ["title", "story_hook", "explanation", "difficulty"],
    properties: {
      title: { type: "STRING" },
      story_hook: { type: "STRING" },
      explanation: { type: "STRING" },
      difficulty: {
        type: "STRING",
        enum: ["easy", "moderate", "challenging"],
      },
    },
  };

  for (const model of models) {
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${
          encodeURIComponent(model)
        }:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": apiKey,
          },
          body: JSON.stringify({
            contents: [{ role: "user", parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.7,
              responseMimeType: "application/json",
              responseSchema,
            },
          }),
        },
      );
      if (!response.ok) {
        if (response.status === 404 && !configuredModel) continue;
        return null;
      }
      const payload = await response.json();
      const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== "string") return null;
      const copy = JSON.parse(text);
      if (
        typeof copy.title !== "string" ||
        typeof copy.story_hook !== "string" ||
        typeof copy.explanation !== "string" ||
        !["easy", "moderate", "challenging"].includes(copy.difficulty)
      ) return null;
      return copy;
    } catch {
      return null;
    }
  }
  return null;
}

function distanceBetween(
  fromLatitude: number,
  fromLongitude: number,
  toLatitude: number,
  toLongitude: number,
): number {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const latitudeDelta = radians(toLatitude - fromLatitude);
  const longitudeDelta = radians(toLongitude - fromLongitude);
  const startLatitude = radians(fromLatitude);
  const endLatitude = radians(toLatitude);
  const a = Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(startLatitude) * Math.cos(endLatitude) *
      Math.sin(longitudeDelta / 2) ** 2;
  return 6371000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 300) : String(error);
}
