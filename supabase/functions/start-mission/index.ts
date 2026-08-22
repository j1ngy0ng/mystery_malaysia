import { withSupabase } from "npm:@supabase/server@1.4.1";
import { pauseCurrentMission } from "../_shared/mission-lifecycle.ts";

type StartMissionInput = {
  action?: "select" | "start";
  recommendation_id?: string;
  session_id?: string;
  mode?: "solo" | "collaborative";
};

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const userId = context.userClaims?.id;
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }

    let input: StartMissionInput;
    try {
      input = await request.json();
    } catch {
      return Response.json({ message: "A mission choice is required." }, {
        status: 400,
      });
    }
    const admin = context.supabaseAdmin;
    let sessionId: string | null = null;
    let selectedRecommendationId: string | null = null;
    try {
      if (input.action === "start") {
        return await startSelectedMission(admin, userId, input.session_id);
      }

      const recommendationId = input.recommendation_id?.trim();
      if (!recommendationId || !isUuid(recommendationId)) {
        return Response.json({ message: "The mission choice is invalid." }, {
          status: 400,
        });
      }
      selectedRecommendationId = recommendationId;
      const { data: recommendation, error: recommendationError } = await admin
        .from("mission_recommendations")
        .select("id,request_id,title")
        .eq("id", recommendationId)
        .single();
      if (recommendationError) throw recommendationError;

      const { data: missionRequest, error: requestError } = await admin
        .from("mission_requests")
        .select("user_id,status,group_type")
        .eq("id", recommendation.request_id)
        .single();
      if (requestError) throw requestError;
      if (missionRequest.user_id !== userId) {
        return Response.json({ message: "This mission is not yours." }, {
          status: 403,
        });
      }
      if (missionRequest.status !== "ready") {
        return Response.json(
          { message: "This mission choice is no longer available." },
          { status: 409 },
        );
      }

      const { data: stops, error: stopsError } = await admin
        .from("mission_recommendation_stops")
        .select("stop_number,destination_id")
        .eq("recommendation_id", recommendationId)
        .order("stop_number");
      if (stopsError) throw stopsError;
      if (stops?.length !== 3) {
        return Response.json(
          { message: "A mission must contain exactly three destinations." },
          { status: 409 },
        );
      }

      const destinationIds = stops.map((stop) => stop.destination_id);
      const reserved = await reserveSelectedDestinations({
        admin,
        destinationIds,
        userId,
        requestId: recommendation.request_id,
        recommendationId,
      });
      if (!reserved) {
        return Response.json(
          {
            message:
              "One of these destinations has just reached its visitor capacity. Choose another mission or generate again.",
          },
          { status: 409 },
        );
      }
      const [{ data: destinations, error: destinationsError }, {
        data: clues,
        error: cluesError,
      }] = await Promise.all([
        admin
          .from("destinations")
          .select(
            "id,name,state,city,latitude,longitude,categories,primary_type,facts",
          )
          .in("id", destinationIds),
        admin
          .from("destination_clues")
          .select(
            "destination_id,clue_type,title,prompt,hint_text,validation_rules",
          )
          .in("destination_id", destinationIds),
      ]);
      if (destinationsError) throw destinationsError;
      if (cluesError) throw cluesError;
      if (destinations?.length !== 3 || clues?.length !== 3) {
        throw new Error("The mission destination data is incomplete.");
      }

      const now = new Date().toISOString();
      const collaborative = input.mode === "collaborative";
      const selectedOnly = !collaborative && input.action === "select";
      const status = collaborative
        ? "waiting"
        : selectedOnly
        ? "ready"
        : "active";
      const { data: session, error: sessionError } = await admin
        .from("mission_sessions")
        .insert({
          recommendation_id: recommendationId,
          title: recommendation.title,
          mode: collaborative ? "collaborative" : "solo",
          travel_type: collaborative ? "friends" : "solo",
          status,
          current_stage: 1,
          started_at: status === "active" ? now : null,
        })
        .select("id,title,current_stage")
        .single();
      if (sessionError) throw sessionError;
      sessionId = session.id;

      const { error: participantError } = await admin
        .from("mission_participants")
        .insert({
          session_id: sessionId,
          user_id: userId,
          role: "host",
          ready: status === "active",
          status: status === "active" ? "navigating" : "joined",
        });
      if (participantError) throw participantError;

      const { data: stages, error: stagesError } = await admin
        .from("mission_stages")
        .insert(
          stops.map((stop) => ({
            session_id: sessionId,
            stage_number: stop.stop_number,
            status: status === "active" && stop.stop_number === 1
              ? "active"
              : "locked",
            unlocked_at: status === "active" && stop.stop_number === 1
              ? now
              : null,
          })),
        )
        .select("id,stage_number");
      if (stagesError) throw stagesError;

      const destinationById = new Map(
        destinations.map((destination) => [destination.id, destination]),
      );
      const clueByDestinationId = new Map(
        clues.map((clue) => [clue.destination_id, clue]),
      );
      const stopByNumber = new Map(
        stops.map((stop) => [stop.stop_number, stop]),
      );

      const { error: secretError } = await admin
        .from("mission_stage_secrets")
        .insert(
          stages.map((stage) => {
            const stop = stopByNumber.get(stage.stage_number)!;
            const destination = destinationById.get(stop.destination_id)!;
            const clue = clueByDestinationId.get(stop.destination_id)!;
            const radius = Number(clue.validation_rules?.radius_metres ?? 120);
            return {
              stage_id: stage.id,
              session_id: sessionId,
              destination_id: stop.destination_id,
              arrival_latitude: destination.latitude,
              arrival_longitude: destination.longitude,
              arrival_radius_metres: Math.min(Math.max(radius, 20), 500),
            };
          }),
        );
      if (secretError) throw secretError;

      const { error: revealError } = await admin
        .from("mission_clue_reveals")
        .insert(
          stages.map((stage) => {
            const stop = stopByNumber.get(stage.stage_number)!;
            const clue = clueByDestinationId.get(stop.destination_id)!;
            return {
              stage_id: stage.id,
              clue_type: clue.clue_type,
              title: clue.title,
              prompt: clue.prompt,
            };
          }),
        );
      if (revealError) throw revealError;

      await pauseCurrentMission(admin, userId, sessionId);
      const { error: currentMissionError } = await admin
        .from("user_current_missions")
        .upsert({ user_id: userId, session_id: sessionId }, {
          onConflict: "user_id",
        });
      if (currentMissionError) throw currentMissionError;

      const { error: activateError } = await admin
        .from("destination_allocations")
        .update({ status: "active" })
        .eq("recommendation_id", recommendationId)
        .eq("user_id", userId)
        .eq("status", "reserved");
      if (activateError) throw activateError;

      const { error: releaseError } = await admin
        .from("destination_allocations")
        .update({ status: "released", released_at: now })
        .eq("request_id", recommendation.request_id)
        .eq("user_id", userId)
        .eq("status", "reserved")
        .neq("recommendation_id", recommendationId);
      if (releaseError) throw releaseError;

      await admin.from("mission_session_events").insert({
        session_id: sessionId,
        actor_id: userId,
        event_type: collaborative
          ? "shared_created"
          : selectedOnly
          ? "selected"
          : "started",
        payload: { recommendation_id: recommendationId },
      });

      if (collaborative) {
        return Response.json({
          session_id: sessionId,
          title: session.title,
          status: "waiting",
        });
      }

      const firstStage = stages.find((stage) => stage.stage_number === 1)!;
      const firstStop = stopByNumber.get(1)!;
      const firstClue = clueByDestinationId.get(firstStop.destination_id)!;
      return Response.json({
        session_id: sessionId,
        title: session.title,
        region: destinationById.get(firstStop.destination_id)!.state,
        current_stage: 1,
        total_stages: 3,
        status,
        stage_id: firstStage.id,
        clue: {
          number: 1,
          title: firstClue.title,
          text: firstClue.prompt,
          hint: "",
        },
      });
    } catch (error) {
      if (sessionId) {
        await admin.from("mission_sessions").delete().eq("id", sessionId);
      }
      if (selectedRecommendationId) {
        await releaseReservedDestinations(admin, selectedRecommendationId);
      }
      console.error("Start mission failed:", safeMessage(error));
      return Response.json({ message: "The mission could not be started." }, {
        status: 500,
      });
    }
  }),
};

async function reserveSelectedDestinations({
  admin,
  destinationIds,
  userId,
  requestId,
  recommendationId,
}: {
  admin: any;
  destinationIds: string[];
  userId: string;
  requestId: string;
  recommendationId: string;
}): Promise<boolean> {
  const { data: existing, error: existingError } = await admin
    .from("destination_allocations")
    .select("destination_id")
    .eq("recommendation_id", recommendationId)
    .eq("user_id", userId)
    .in("status", ["reserved", "active"]);
  if (existingError) throw existingError;
  const alreadyReserved = new Set(
    (existing ?? []).map((row: { destination_id: string }) =>
      row.destination_id
    ),
  );
  const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

  for (const destinationId of destinationIds) {
    if (alreadyReserved.has(destinationId)) continue;
    const { data, error } = await admin.rpc("reserve_destination_capacity", {
      p_destination_id: destinationId,
      p_user_id: userId,
      p_request_id: requestId,
      p_recommendation_id: recommendationId,
      p_expires_at: expiresAt,
    });
    if (error) throw error;
    if (!data) {
      await releaseReservedDestinations(admin, recommendationId);
      return false;
    }
  }
  return true;
}

async function releaseReservedDestinations(
  admin: any,
  recommendationId: string,
): Promise<void> {
  const { error } = await admin
    .from("destination_allocations")
    .update({ status: "released", released_at: new Date().toISOString() })
    .eq("recommendation_id", recommendationId)
    .eq("status", "reserved");
  if (error) throw error;
}

async function startSelectedMission(
  admin: any,
  userId: string,
  rawSessionId?: string,
): Promise<Response> {
  const sessionId = rawSessionId?.trim();
  if (!sessionId || !isUuid(sessionId)) {
    return Response.json({ message: "The saved mission is invalid." }, {
      status: 400,
    });
  }

  const [{ data: session, error: sessionError }, {
    data: participant,
    error: participantError,
  }] = await Promise.all([
    admin.from("mission_sessions").select("id,mode,status")
      .eq("id", sessionId).maybeSingle(),
    admin.from("mission_participants").select("role,status")
      .eq("session_id", sessionId).eq("user_id", userId)
      .neq("status", "left").maybeSingle(),
  ]);
  if (sessionError) throw sessionError;
  if (participantError) throw participantError;
  if (!session || !participant) {
    return Response.json({ message: "You cannot start this mission." }, {
      status: 403,
    });
  }
  if (session.mode !== "solo") {
    return Response.json({
      message: "Shared missions must be started from their lobby.",
    }, { status: 409 });
  }
  await pauseCurrentMission(admin, userId, sessionId);
  const { error: currentMissionError } = await admin
    .from("user_current_missions")
    .upsert({ user_id: userId, session_id: sessionId }, {
      onConflict: "user_id",
    });
  if (currentMissionError) throw currentMissionError;
  if (session.status === "active") {
    return Response.json({ session_id: sessionId, status: "active" });
  }
  if (session.status !== "ready") {
    return Response.json({
      message: "This mission is not waiting to be started.",
    }, { status: 409 });
  }

  const now = new Date().toISOString();
  const { data: started, error: startError } = await admin
    .from("mission_sessions")
    .update({ status: "active", started_at: now })
    .eq("id", sessionId)
    .eq("status", "ready")
    .select("id")
    .maybeSingle();
  if (startError) throw startError;
  if (!started) {
    return Response.json({
      message: "The mission status changed. Refresh and try again.",
    }, { status: 409 });
  }

  const { error: stageError } = await admin.from("mission_stages")
    .update({ status: "active", unlocked_at: now })
    .eq("session_id", sessionId)
    .eq("stage_number", 1)
    .eq("status", "locked");
  if (stageError) throw stageError;

  const { error: participantUpdateError } = await admin
    .from("mission_participants")
    .update({ ready: true, status: "navigating" })
    .eq("session_id", sessionId)
    .eq("user_id", userId);
  if (participantUpdateError) throw participantUpdateError;

  await admin.from("mission_session_events").insert({
    session_id: sessionId,
    actor_id: userId,
    event_type: "started",
  });
  return Response.json({ session_id: sessionId, status: "active" });
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 300) : String(error);
}
