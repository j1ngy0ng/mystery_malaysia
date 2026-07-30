import { withSupabase } from "npm:@supabase/server@1.4.1";

type ArrivalInput = {
  session_id?: string;
  latitude?: number;
  longitude?: number;
  accuracy_metres?: number;
};

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const userId = context.userClaims?.id;
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }

    let input: ArrivalInput;
    try {
      input = await request.json();
      validateInput(input);
    } catch (error) {
      return Response.json({ message: safeMessage(error) }, { status: 400 });
    }

    const admin = context.supabaseAdmin;
    const sessionId = input.session_id!;
    try {
      const { data: participant, error: participantError } = await admin
        .from("mission_participants")
        .select("status")
        .eq("session_id", sessionId)
        .eq("user_id", userId)
        .neq("status", "left")
        .maybeSingle();
      if (participantError) throw participantError;
      if (!participant) {
        return Response.json({ message: "You are not in this mission." }, {
          status: 403,
        });
      }

      const { data: session, error: sessionError } = await admin
        .from("mission_sessions")
        .select("id,title,status,current_stage,recommendation_id,mode")
        .eq("id", sessionId)
        .single();
      if (sessionError) throw sessionError;
      if (session.status !== "active") {
        return Response.json({ message: "This mission is not active." }, {
          status: 409,
        });
      }

      const { data: stage, error: stageError } = await admin
        .from("mission_stages")
        .select("id,stage_number")
        .eq("session_id", sessionId)
        .eq("stage_number", session.current_stage)
        .eq("status", "active")
        .single();
      if (stageError) throw stageError;

      const { data: secret, error: secretError } = await admin
        .from("mission_stage_secrets")
        .select(
          "destination_id,arrival_latitude,arrival_longitude,arrival_radius_metres",
        )
        .eq("stage_id", stage.id)
        .single();
      if (secretError) throw secretError;

      if ((input.accuracy_metres ?? 999) > 50) {
        return Response.json({
          arrived: false,
          code: "poor_gps_accuracy",
          message:
            "Your current GPS signal is not accurate enough to verify your location. Please wait or move to an open area and try again.",
        });
      }

      const distanceMetres = distanceBetween(
        input.latitude!,
        input.longitude!,
        secret.arrival_latitude,
        secret.arrival_longitude,
      );
      if (distanceMetres > secret.arrival_radius_metres) {
        return Response.json({
          arrived: false,
          message:
            "You are not at the hidden destination yet. Use the clue and keep exploring.",
        });
      }

      const { data: destination, error: destinationError } = await admin
        .from("destinations")
        .select(
          "id,name,state,city,categories,opening_hours,accessibility," +
            "visitor_information,facts,formatted_address,primary_type," +
            "google_rating,google_user_rating_count,google_maps_uri,safety_score",
        )
        .eq("id", secret.destination_id)
        .single();
      if (destinationError) throw destinationError;

      let educationalFacts = Array.isArray(destination.facts)
        ? destination.facts.filter((fact: unknown): fact is string =>
          typeof fact === "string" && fact.trim().length > 0
        )
        : [];
      let visitorInformation = destination.visitor_information &&
          typeof destination.visitor_information === "object"
        ? { ...destination.visitor_information }
        : {};
      if (educationalFacts.length === 0) {
        const grounded = await groundedTeachingGuide(destination);
        if (grounded.facts.length > 0) {
          educationalFacts = grounded.facts;
          visitorInformation = {
            ...visitorInformation,
            educational_source: "Gemini grounded with Google Search",
            educational_sources: grounded.sources,
            summary_disclosure:
              "Historical and cultural notes are grounded with Google Search. Open the listed sources to verify details.",
          };
          const { error: cacheGuideError } = await admin
            .from("destinations")
            .update({
              facts: educationalFacts,
              visitor_information: visitorInformation,
            })
            .eq("id", destination.id);
          if (cacheGuideError) throw cacheGuideError;
        }
      }
      if (educationalFacts.length === 0) {
        educationalFacts = verifiedPlaceFacts(destination);
        visitorInformation = {
          ...visitorInformation,
          educational_source: "Verified Google Places attributes",
          summary_disclosure:
            "A reliable destination-specific historical source was not available, so this guide shows only verified place information.",
        };
      }
      visitorInformation = withVisitorGuidance(
        visitorInformation,
        destination.primary_type,
      );
      const photoUri = await placePhotoUri(
        typeof visitorInformation.photo_name === "string"
          ? visitorInformation.photo_name
          : null,
      );
      if (photoUri) {
        visitorInformation = { ...visitorInformation, image_url: photoUri };
      }
      const revealedDestination = {
        name: destination.name,
        state: destination.state,
        city: destination.city,
        categories: destination.categories,
        opening_hours: destination.opening_hours,
        accessibility: destination.accessibility,
        visitor_information: visitorInformation,
        facts: educationalFacts,
        formatted_address: destination.formatted_address,
        primary_type: destination.primary_type,
        google_rating: destination.google_rating,
        google_user_rating_count: destination.google_user_rating_count,
        google_maps_uri: destination.google_maps_uri,
        safety_score: destination.safety_score,
      };

      const { data: clue, error: clueError } = await admin
        .from("destination_clues")
        .select("clue_xp_reward")
        .eq("destination_id", destination.id)
        .single();
      if (clueError) throw clueError;

      const now = new Date().toISOString();
      const { error: visitError } = await admin
        .from("verified_visits")
        .insert({
          stage_id: stage.id,
          session_id: sessionId,
          user_id: userId,
          verified_latitude: input.latitude,
          verified_longitude: input.longitude,
          gps_accuracy_metres: input.accuracy_metres ?? 0,
          distance_to_target_metres: Math.round(distanceMetres * 100) / 100,
        });
      if (visitError && visitError.code !== "23505") throw visitError;

      let { data: stamp, error: stampError } = await admin
        .from("stamp_definitions")
        .select("id")
        .eq("destination_id", destination.id)
        .maybeSingle();
      if (stampError) throw stampError;
      if (!stamp) {
        const created = await admin
          .from("stamp_definitions")
          .insert({
            destination_id: destination.id,
            name: `${destination.name} Explorer`,
            artwork_path: "generated/default-destination-stamp",
            rarity: "common",
          })
          .select("id")
          .single();
        if (created.error) throw created.error;
        stamp = created.data;
      }

      const { error: userStampError } = await admin
        .from("user_stamps")
        .upsert({
          user_id: userId,
          stamp_id: stamp.id,
          destination_id: destination.id,
          session_id: sessionId,
          stage_id: stage.id,
        }, {
          onConflict: "user_id,stamp_id",
          ignoreDuplicates: true,
        });
      if (userStampError) throw userStampError;

      const xpReward = Number(clue.clue_xp_reward ?? 0);
      const { data: existingXp, error: existingXpError } = await admin
        .from("xp_ledger")
        .select("id")
        .eq("user_id", userId)
        .eq("stage_id", stage.id)
        .eq("reason", "destination_arrival")
        .maybeSingle();
      if (existingXpError) throw existingXpError;
      if (!existingXp && xpReward > 0) {
        const { error: xpError } = await admin.from("xp_ledger").insert({
          user_id: userId,
          session_id: sessionId,
          stage_id: stage.id,
          amount: xpReward,
          reason: "destination_arrival",
        });
        if (xpError) throw xpError;
      }

      if (session.mode === "collaborative") {
        await admin.from("mission_participants").update({
          status: "arrived",
        }).eq("session_id", sessionId).eq("user_id", userId);
        const [{ count: memberCount, error: memberCountError }, {
          count: arrivedCount,
          error: arrivedCountError,
        }] = await Promise.all([
          admin.from("mission_participants")
            .select("user_id", { count: "exact", head: true })
            .eq("session_id", sessionId).neq("status", "left"),
          admin.from("verified_visits")
            .select("user_id", { count: "exact", head: true })
            .eq("stage_id", stage.id),
        ]);
        if (memberCountError) throw memberCountError;
        if (arrivedCountError) throw arrivedCountError;
        if ((arrivedCount ?? 0) < (memberCount ?? 1)) {
          return Response.json({
            arrived: true,
            waiting_for_members: true,
            mission_completed: false,
            completed_stage: null,
            next_stage: stage.stage_number,
            total_stages: 3,
            xp_awarded: xpReward,
            stamp_awarded: true,
            message:
              "Your arrival is verified. This shared stage advances after every joined member verifies arrival.",
            destination: revealedDestination,
          });
        }
      }

      const { error: completeStageError } = await admin
        .from("mission_stages")
        .update({ status: "completed", completed_at: now })
        .eq("id", stage.id);
      if (completeStageError) throw completeStageError;

      const { count: totalStages, error: countError } = await admin
        .from("mission_stages")
        .select("id", { count: "exact", head: true })
        .eq("session_id", sessionId);
      if (countError) throw countError;
      const missionCompleted = stage.stage_number >= (totalStages ?? 3);
      let nextClue: Record<string, unknown> | null = null;

      if (missionCompleted) {
        const { error: sessionCompleteError } = await admin
          .from("mission_sessions")
          .update({ status: "completed", completed_at: now })
          .eq("id", sessionId);
        if (sessionCompleteError) throw sessionCompleteError;
        await admin
          .from("mission_participants")
          .update({ status: "completed", completed_at: now })
          .eq("session_id", sessionId)
          .neq("status", "left");
        await admin
          .from("user_current_missions")
          .delete()
          .eq("user_id", userId);
        await admin
          .from("destination_allocations")
          .update({ status: "completed" })
          .eq("recommendation_id", session.recommendation_id)
          .eq("user_id", userId)
          .eq("status", "active");
      } else {
        const nextStageNumber = stage.stage_number + 1;
        const { data: nextStage, error: nextStageError } = await admin
          .from("mission_stages")
          .update({ status: "active", unlocked_at: now })
          .eq("session_id", sessionId)
          .eq("stage_number", nextStageNumber)
          .select("id")
          .single();
        if (nextStageError) throw nextStageError;
        const { error: sessionAdvanceError } = await admin
          .from("mission_sessions")
          .update({ current_stage: nextStageNumber })
          .eq("id", sessionId);
        if (sessionAdvanceError) throw sessionAdvanceError;
        if (session.mode === "collaborative") {
          await admin.from("mission_participants").update({
            status: "navigating",
          }).eq("session_id", sessionId).neq("status", "left");
        }

        const [{ data: reveal, error: revealError }, {
          data: nextSecret,
          error: nextSecretError,
        }] = await Promise.all([
          admin
            .from("mission_clue_reveals")
            .select("title,prompt")
            .eq("stage_id", nextStage.id)
            .single(),
          admin
            .from("mission_stage_secrets")
            .select("destination_id")
            .eq("stage_id", nextStage.id)
            .single(),
        ]);
        if (revealError) throw revealError;
        if (nextSecretError) throw nextSecretError;
        const { data: nextDestinationClue, error: nextClueError } = await admin
          .from("destination_clues")
          .select("hint_text")
          .eq("destination_id", nextSecret.destination_id)
          .single();
        if (nextClueError) throw nextClueError;
        nextClue = {
          number: nextStageNumber,
          title: reveal.title,
          text: reveal.prompt,
          hint: "",
        };
      }

      await admin.from("mission_session_events").insert({
        session_id: sessionId,
        actor_id: userId,
        event_type: missionCompleted
          ? "mission_completed"
          : "destination_verified",
        payload: {
          stage_number: stage.stage_number,
          destination_id: destination.id,
        },
      });

      return Response.json({
        arrived: true,
        mission_completed: missionCompleted,
        completed_stage: stage.stage_number,
        next_stage: missionCompleted ? null : stage.stage_number + 1,
        total_stages: totalStages ?? 3,
        xp_awarded: xpReward,
        stamp_awarded: true,
        next_clue: nextClue,
        destination: revealedDestination,
      });
    } catch (error) {
      console.error("Confirm arrival failed:", safeMessage(error));
      return Response.json(
        { message: "Arrival verification could not be completed." },
        { status: 500 },
      );
    }
  }),
};

function validateInput(input: ArrivalInput): void {
  if (!input || typeof input !== "object") {
    throw new Error("Arrival details are required.");
  }
  if (!input.session_id || !isUuid(input.session_id)) {
    throw new Error("The mission session is invalid.");
  }
  assertNumber(input.latitude, -90, 90, "latitude");
  assertNumber(input.longitude, -180, 180, "longitude");
  if (input.accuracy_metres !== undefined) {
    assertNumber(input.accuracy_metres, 0, 200, "accuracy_metres");
  }
}

function assertNumber(
  value: unknown,
  minimum: number,
  maximum: number,
  field: string,
): void {
  if (
    typeof value !== "number" ||
    !Number.isFinite(value) ||
    value < minimum ||
    value > maximum
  ) {
    throw new Error(`${field} is invalid.`);
  }
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
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

async function placePhotoUri(photoName: string | null): Promise<string | null> {
  const key = Deno.env.get("GOOGLE_PLACES_API_KEY")?.trim();
  if (!key || !photoName) return null;
  try {
    const response = await fetch(
      `https://places.googleapis.com/v1/${photoName}/media?maxWidthPx=1200&maxHeightPx=800&skipHttpRedirect=true`,
      { headers: { "X-Goog-Api-Key": key } },
    );
    if (!response.ok) return null;
    const payload = await response.json();
    return typeof payload.photoUri === "string" ? payload.photoUri : null;
  } catch {
    return null;
  }
}

async function groundedTeachingGuide(
  destination: Record<string, unknown>,
): Promise<{
  facts: string[];
  sources: Array<{ title: string; uri: string }>;
}> {
  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!apiKey) return { facts: [], sources: [] };
  const configuredModel = Deno.env.get("GEMINI_MODEL")?.trim();
  const models = [
    configuredModel,
    "gemini-3.6-flash",
    "gemini-flash-latest",
    "gemini-2.5-flash",
  ].filter((model, index, values): model is string =>
    Boolean(model) && values.indexOf(model) === index
  );
  const prompt = [
    "Use Google Search to verify two or three concise historical or cultural facts about this Malaysian destination.",
    "Use authoritative tourism, government, heritage, museum, university, or official venue sources where available.",
    "Do not infer facts from ratings. Do not invent dates, events, architecture, religious practices, or superlatives.",
    "Return each verified fact on its own line beginning exactly with FACT: and no other prose.",
    "If no reliable destination-specific fact can be verified, return exactly NO_VERIFIED_FACTS.",
    `Destination: ${JSON.stringify({
      name: destination.name,
      city: destination.city,
      state: destination.state,
      address: destination.formatted_address,
      type: destination.primary_type,
    })}`,
  ].join("\n");

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
            tools: [{ google_search: {} }],
            generationConfig: { temperature: 0.1 },
          }),
        },
      );
      if (!response.ok) continue;
      const payload = await response.json();
      const candidate = payload?.candidates?.[0];
      const text = candidate?.content?.parts
        ?.map((part: { text?: string }) => part.text ?? "")
        .join("\n");
      const sources = (candidate?.groundingMetadata?.groundingChunks ?? [])
        .flatMap((chunk: {
          web?: { title?: string; uri?: string };
        }) =>
          chunk.web?.uri
            ? [{
              title: chunk.web.title?.trim() || "Source",
              uri: chunk.web.uri,
            }]
            : []
        )
        .filter(
          (
            source: { title: string; uri: string },
            index: number,
            all: Array<{ title: string; uri: string }>,
          ) => all.findIndex((item) => item.uri === source.uri) === index,
        )
        .slice(0, 5);
      if (typeof text !== "string" || sources.length === 0) continue;
      const facts = text
        .split(/\r?\n/)
        .map((line: string) => line.trim())
        .filter((line: string) => line.startsWith("FACT:"))
        .map((line: string) => line.slice(5).trim())
        .filter((fact: string) => fact.length >= 20 && fact.length <= 600)
        .slice(0, 3);
      if (facts.length > 0) return { facts, sources };
    } catch {
      // The verified Place guide still works when grounded teaching is absent.
    }
  }
  return { facts: [], sources: [] };
}

function verifiedPlaceFacts(
  destination: Record<string, unknown>,
): string[] {
  const type = typeof destination.primary_type === "string"
    ? destination.primary_type.replaceAll("_", " ")
    : "visitor destination";
  const location = [destination.city, destination.state]
    .filter((value): value is string =>
      typeof value === "string" && value.trim().length > 0
    )
    .join(", ");
  const facts = [
    `${destination.name} is verified by Google Places as an operational ${type}${
      location ? ` in ${location}` : " in Malaysia"
    }.`,
  ];
  const rating = Number(destination.google_rating);
  const ratingCount = Number(destination.google_user_rating_count);
  if (Number.isFinite(rating) && Number.isFinite(ratingCount) && ratingCount > 0) {
    facts.push(
      `Its live Google Places record has a ${rating.toFixed(1)} rating from ${Math.round(ratingCount)} reviews; this is a popularity signal, not a guarantee of safety or quality.`,
    );
  }
  return facts;
}

function withVisitorGuidance(
  information: Record<string, unknown>,
  primaryType: unknown,
): Record<string, unknown> {
  const type = typeof primaryType === "string" ? primaryType : "";
  const existingEtiquette = Array.isArray(information.cultural_etiquette)
    ? information.cultural_etiquette.filter((item) =>
      typeof item === "string" && item.trim().length > 0
    )
    : [];
  const existingSafety = Array.isArray(information.safety_notes)
    ? information.safety_notes.filter((item) =>
      typeof item === "string" && item.trim().length > 0
    )
    : [];
  const etiquette = existingEtiquette.length > 0
    ? existingEtiquette
    : [
      type.includes("place_of_worship")
        ? "Dress respectfully, keep voices low, and follow all posted worship-space rules."
        : "Follow posted rules and ask before photographing people.",
      "Respect staff, residents, worshippers and other visitors.",
    ];
  const safety = existingSafety.length > 0
    ? existingSafety
    : [
      "Visit during published hours and follow current venue or authority notices.",
      "Keep valuables secure, remain in public visitor areas, and leave if conditions feel unsafe.",
      "Automated tourist-suitability checks do not guarantee personal safety.",
    ];
  return {
    ...information,
    cultural_etiquette: etiquette,
    safety_notes: safety,
  };
}
