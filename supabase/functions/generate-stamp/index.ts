import { withSupabase } from "npm:@supabase/server@1.4.1";
import {
  generateMissionStamp,
  signedMissionStampUrl,
} from "../_shared/mission-stamp.ts";

type Input = { session_id?: string };

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const userId = context.userClaims?.id;
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }
    const input = await request.json().catch(() => ({})) as Input;
    const sessionId = input.session_id?.trim();
    if (!sessionId || !isUuid(sessionId)) {
      return Response.json({ message: "The mission session is invalid." }, {
        status: 400,
      });
    }

    const admin = context.supabaseAdmin;
    try {
      const [{ data: participant, error: participantError }, {
        data: session,
        error: sessionError,
      }] = await Promise.all([
        admin.from("mission_participants").select("user_id")
          .eq("session_id", sessionId).eq("user_id", userId)
          .neq("status", "left").maybeSingle(),
        admin.from("mission_sessions").select(
          "id,title,recommendation_id,stamp_artwork_path",
        ).eq("id", sessionId).maybeSingle(),
      ]);
      if (participantError) throw participantError;
      if (sessionError) throw sessionError;
      if (!participant || !session) {
        return Response.json({ message: "You cannot access this mission." }, {
          status: 403,
        });
      }
      if (session.stamp_artwork_path) {
        return Response.json({
          generated: false,
          artwork_url: await signedMissionStampUrl(
            admin,
            session.stamp_artwork_path,
          ),
        });
      }

      const destinations = await loadDestinations(
        admin,
        session.recommendation_id,
      );
      const generated = await generateMissionStamp({
        admin,
        sessionId,
        title: session.title,
        destinations,
      });
      return Response.json({
        generated: true,
        artwork_url: await signedMissionStampUrl(admin, generated.path),
      });
    } catch (error) {
      console.error("Mission stamp generation failed:", safeMessage(error));
      return Response.json({
        message:
          "AI stamp artwork is temporarily unavailable. Your collectible fallback remains available.",
      }, { status: 503 });
    }
  }),
};

async function loadDestinations(admin: any, recommendationId: string) {
  const { data: stops, error: stopsError } = await admin
    .from("mission_recommendation_stops")
    .select("stop_number,destination_id")
    .eq("recommendation_id", recommendationId)
    .order("stop_number");
  if (stopsError) throw stopsError;
  const ids = (stops ?? []).map((stop: any) => stop.destination_id);
  const { data, error } = await admin.from("destinations").select(
    "id,name,state,city,categories,primary_type,facts",
  ).in("id", ids);
  if (error) throw error;
  const byId = new Map((data ?? []).map((item: any) => [item.id, item]));
  const ordered = ids.map((id: string) => byId.get(id)).filter(Boolean);
  if (ordered.length !== 3) throw new Error("Mission destinations are incomplete.");
  return ordered;
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(value);
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
