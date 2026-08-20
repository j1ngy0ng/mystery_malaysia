import { withSupabase } from "npm:@supabase/server@1.4.1";
import { pauseCurrentMission } from "../_shared/mission-lifecycle.ts";

type Input = {
  action?: "history" | "current" | "pause" | "resume" | "abandon" | "proximity" | "hint" | "clue_viewed";
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

    const input = await request.json().catch(() => ({})) as Input;
    const admin = context.supabaseAdmin;
    try {
      if (input.action === "history") {
        const { data: participants, error } = await admin
          .from("mission_participants")
          .select("session_id")
          .eq("user_id", userId)
          .neq("status", "left");
        if (error) throw error;
        const ids = participants?.map((row) => row.session_id) ?? [];
        if (ids.length === 0) return Response.json({ missions: [] });
        const { data: sessions, error: sessionsError } = await admin
          .from("mission_sessions")
          .select("id,title,status,current_stage,mode,created_at,started_at,paused_at,completed_at,abandoned_at")
          .in("id", ids)
          .order("created_at", { ascending: false });
        if (sessionsError) throw sessionsError;
        const missions = await Promise.all(
          (sessions ?? []).map((session) =>
            missionSummary(admin, session, userId)
          ),
        );
        return Response.json({ missions });
      }

      if (input.action === "current") {
        const { data: current, error } = await admin
          .from("user_current_missions")
          .select("session_id")
          .eq("user_id", userId)
          .maybeSingle();
        if (error) throw error;
        if (!current) return Response.json({ mission: null });
        const { data: session, error: sessionError } = await admin
          .from("mission_sessions")
          .select("*")
          .eq("id", current.session_id)
          .single();
        if (sessionError) throw sessionError;
        return Response.json({
          mission: await missionSummary(admin, session, userId),
        });
      }

      if (!input.session_id) {
        return Response.json({ message: "A mission session is required." }, {
          status: 400,
        });
      }
      const { data: participant, error: participantError } = await admin
        .from("mission_participants")
        .select("role,status")
        .eq("session_id", input.session_id)
        .eq("user_id", userId)
        .neq("status", "left")
        .maybeSingle();
      if (participantError) throw participantError;
      if (!participant) {
        return Response.json({ message: "You cannot access this mission." }, {
          status: 403,
        });
      }
      const { data: session, error: sessionError } = await admin
        .from("mission_sessions")
        .select("*")
        .eq("id", input.session_id)
        .single();
      if (sessionError) throw sessionError;

      if (input.action === "pause" || input.action === "resume" || input.action === "abandon") {
        if (session.mode === "collaborative" && participant.role !== "host") {
          return Response.json({
            message: "Only the mission host can change the shared mission status.",
          }, { status: 403 });
        }
        const allowed = input.action === "pause"
          ? session.status === "active"
          : input.action === "resume"
          ? session.status === "paused"
          : ["ready", "active", "paused", "waiting"].includes(session.status);
        if (!allowed) {
          return Response.json({
            message: `This mission cannot be ${input.action}d from its current state.`,
          }, { status: 409 });
        }
        const now = new Date().toISOString();
        if (input.action === "resume") {
          await pauseCurrentMission(admin, userId, session.id);
        }
        const status = input.action === "pause"
          ? "paused"
          : input.action === "resume"
          ? "active"
          : "abandoned";
        const update: Record<string, unknown> = { status };
        if (status === "paused") update.paused_at = now;
        if (status === "active") update.paused_at = null;
        if (status === "abandoned") update.abandoned_at = now;
        const { error } = await admin.from("mission_sessions")
          .update(update).eq("id", session.id);
        if (error) throw error;
        if (status === "active") {
          const { error: currentMissionError } = await admin
            .from("user_current_missions")
            .upsert({ user_id: userId, session_id: session.id }, {
              onConflict: "user_id",
            });
          if (currentMissionError) throw currentMissionError;
        }
        await admin.from("mission_session_events").insert({
          session_id: session.id,
          actor_id: userId,
          event_type: `mission_${status}`,
        });
        return Response.json({ status });
      }

      const { data: stage, error: stageError } = await admin
        .from("mission_stages")
        .select("id,stage_number,status")
        .eq("session_id", session.id)
        .eq("stage_number", session.current_stage)
        .single();
      if (stageError) throw stageError;

      if (input.action === "clue_viewed") {
        await admin.from("clue_progress").upsert({
          stage_id: stage.id,
          user_id: userId,
          status: "viewed",
        }, { onConflict: "stage_id,user_id" });
        return Response.json({ recorded: true });
      }

      if (input.action === "hint") {
        if (session.status !== "active" || stage.status !== "active") {
          return Response.json({
            message: "Hints are available only during an active mission.",
          }, { status: 409 });
        }
        const { data: existing, error: existingError } = await admin
          .from("clue_hint_reveals")
          .select("revealed_text")
          .eq("stage_id", stage.id)
          .eq("user_id", userId)
          .maybeSingle();
        if (existingError) throw existingError;
        if (existing) {
          return Response.json({
            hint: existing.revealed_text,
            already_used: true,
          });
        }
        const { data: secret, error: secretError } = await admin
          .from("mission_stage_secrets")
          .select("destination_id")
          .eq("stage_id", stage.id)
          .single();
        if (secretError) throw secretError;
        const { data: clue, error: clueError } = await admin
          .from("destination_clues")
          .select("hint_text,hint_xp_cost")
          .eq("destination_id", secret.destination_id)
          .single();
        if (clueError) throw clueError;
        if (!clue.hint_text) {
          return Response.json({
            message: "Unable to generate the AI hint at the moment. Please try again later.",
          }, { status: 503 });
        }
        const { error: insertError } = await admin.from("clue_hint_reveals")
          .insert({
            stage_id: stage.id,
            user_id: userId,
            revealed_text: clue.hint_text,
            xp_cost: clue.hint_xp_cost ?? 0,
          });
        if (insertError) throw insertError;
        await admin.from("clue_progress").upsert({
          stage_id: stage.id,
          user_id: userId,
          status: "viewed",
          hint_used: true,
        }, { onConflict: "stage_id,user_id" });
        return Response.json({ hint: clue.hint_text, already_used: false });
      }

      if (input.action === "proximity") {
        if (session.status !== "active") {
          return Response.json({ message: "The mission is not active." }, {
            status: 409,
          });
        }
        if (
          typeof input.latitude !== "number" ||
          typeof input.longitude !== "number"
        ) {
          return Response.json({ message: "A GPS location is required." }, {
            status: 400,
          });
        }
        if ((input.accuracy_metres ?? 999) > 50) {
          return Response.json({
            level: "poor_accuracy",
            message:
              "Your current GPS signal is not accurate enough. Move to an open area and try again.",
          });
        }
        const { data: secret, error: secretError } = await admin
          .from("mission_stage_secrets")
          .select("arrival_latitude,arrival_longitude,arrival_radius_metres")
          .eq("stage_id", stage.id)
          .single();
        if (secretError) throw secretError;
        const distance = distanceBetween(
          input.latitude,
          input.longitude,
          secret.arrival_latitude,
          secret.arrival_longitude,
        );
        const level = distance <= secret.arrival_radius_metres
          ? "reached"
          : distance <= 250
          ? "hot"
          : distance <= 750
          ? "warm"
          : distance <= 2000
          ? "cold"
          : "freezing";
        return Response.json({ level });
      }

      return Response.json({ message: "Unknown mission action." }, {
        status: 400,
      });
    } catch (error) {
      console.error("Mission control failed:", safeMessage(error));
      return Response.json({
        message: "Unable to update the mission. Please try again.",
      }, { status: 500 });
    }
  }),
};

async function missionSummary(
  admin: any,
  session: Record<string, any>,
  userId: string,
) {
  const { data: stages, error: stagesError } = await admin
    .from("mission_stages")
    .select("id,stage_number,status")
    .eq("session_id", session.id)
    .order("stage_number");
  if (stagesError) throw stagesError;
  const stage = stages?.find((row: any) =>
    row.stage_number === session.current_stage
  );
  let region = "Malaysia";
  let clue = null;
  if (stage) {
    const [{ data: reveal }, { data: secret }, { data: hint }] = await Promise.all([
      admin.from("mission_clue_reveals").select("title,prompt")
        .eq("stage_id", stage.id).maybeSingle(),
      admin.from("mission_stage_secrets").select("destination_id")
        .eq("stage_id", stage.id).maybeSingle(),
      admin.from("clue_hint_reveals").select("revealed_text")
        .eq("stage_id", stage.id).eq("user_id", userId).maybeSingle(),
    ]);
    if (secret) {
      const { data: destination } = await admin.from("destinations")
        .select("state").eq("id", secret.destination_id).maybeSingle();
      region = destination?.state ?? region;
    }
    if (
      reveal &&
      (stage.status !== "locked" || session.status === "ready")
    ) {
      clue = {
        number: stage.stage_number,
        title: reveal.title,
        text: reveal.prompt,
        hint: hint?.revealed_text ?? "",
        hint_revealed: Boolean(hint),
      };
    }
  }
  const date = session.completed_at ?? session.paused_at ??
    session.abandoned_at ?? session.started_at ?? session.created_at;
  return {
    session_id: session.id,
    title: session.title,
    region,
    status: session.status,
    mode: session.mode,
    current_stage: session.current_stage,
    total_stages: stages?.length ?? 3,
    date,
    clue,
  };
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
