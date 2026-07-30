import { withSupabase } from "npm:@supabase/server@1.4.1";

type StartMissionInput = {
  recommendation_id?: string;
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
    const recommendationId = input.recommendation_id?.trim();
    if (!recommendationId || !isUuid(recommendationId)) {
      return Response.json({ message: "The mission choice is invalid." }, {
        status: 400,
      });
    }

    const admin = context.supabaseAdmin;
    let sessionId: string | null = null;
    try {
      const { data: current, error: currentError } = await admin
        .from("user_current_missions")
        .select("session_id")
        .eq("user_id", userId)
        .maybeSingle();
      if (currentError) throw currentError;
      if (current) {
        return Response.json(
          {
            message:
              "Finish, pause or abandon your current mission before starting another.",
          },
          { status: 409 },
        );
      }

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
      const [{ data: destinations, error: destinationsError }, {
        data: clues,
        error: cluesError,
      }] = await Promise.all([
        admin
          .from("destinations")
          .select("id,state,latitude,longitude")
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
      const { data: session, error: sessionError } = await admin
        .from("mission_sessions")
        .insert({
          recommendation_id: recommendationId,
          title: recommendation.title,
          mode: collaborative ? "collaborative" : "solo",
          travel_type: collaborative ? "friends" : "solo",
          status: collaborative ? "waiting" : "active",
          current_stage: 1,
          started_at: collaborative ? null : now,
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
          ready: !collaborative,
          status: collaborative ? "joined" : "navigating",
        });
      if (participantError) throw participantError;

      const { data: stages, error: stagesError } = await admin
        .from("mission_stages")
        .insert(
          stops.map((stop) => ({
            session_id: sessionId,
            stage_number: stop.stop_number,
            status: !collaborative && stop.stop_number === 1
              ? "active"
              : "locked",
            unlocked_at: !collaborative && stop.stop_number === 1 ? now : null,
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

      const { error: currentMissionError } = await admin
        .from("user_current_missions")
        .insert({ user_id: userId, session_id: sessionId });
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
        event_type: collaborative ? "shared_created" : "started",
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
      console.error("Start mission failed:", safeMessage(error));
      return Response.json({ message: "The mission could not be started." }, {
        status: 500,
      });
    }
  }),
};

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 300) : String(error);
}
