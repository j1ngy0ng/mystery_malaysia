export async function pauseCurrentMission(
  admin: any,
  userId: string,
  nextSessionId: string,
) {
  const { data: current, error: currentError } = await admin
    .from("user_current_missions")
    .select("session_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (currentError) throw currentError;
  if (!current || current.session_id === nextSessionId) return;

  const { data: session, error: sessionError } = await admin
    .from("mission_sessions")
    .select("id,status")
    .eq("id", current.session_id)
    .maybeSingle();
  if (sessionError) throw sessionError;
  if (session?.status !== "active") return;

  const pausedAt = new Date().toISOString();
  const { error: pauseError } = await admin.from("mission_sessions")
    .update({ status: "paused", paused_at: pausedAt })
    .eq("id", session.id)
    .eq("status", "active");
  if (pauseError) throw pauseError;
  await admin.from("mission_session_events").insert({
    session_id: session.id,
    actor_id: userId,
    event_type: "mission_auto_paused",
    payload: { next_session_id: nextSessionId },
  });
}
