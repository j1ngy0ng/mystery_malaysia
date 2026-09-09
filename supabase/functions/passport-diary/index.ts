import { withSupabase } from "npm:@supabase/server@1.4.1";
import { countExploredStates } from "./states.ts";

type Input = {
  action?:
    | "dashboard"
    | "group_diary_status"
    | "save_reflection"
    | "generate_diary"
    | "generate_group_diary"
    | "save_diary";
  session_id?: string;
  reflection?: string;
  title?: string;
  content?: string;
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
      if (input.action === "dashboard") {
        const [
          { data: stampRows, error: stampError },
          { data: visits, error: visitsError },
          { data: participants, error: participantsError },
          { data: diaries, error: diariesError },
        ] = await Promise.all([
          admin.from("user_stamps").select(
            "earned_at,session_id,mission_sessions!inner(title)," +
              "stamp_definitions!inner(name,rarity,destinations!inner(name,state))",
          ).eq("user_id", userId).order("earned_at", { ascending: false }),
          admin.from("verified_visits").select("stage_id").eq("user_id", userId),
          admin.from("mission_participants").select(
            "session_id,mission_sessions!inner(title,status,mode,completed_at)",
          ).eq("user_id", userId).neq("status", "left"),
          admin.from("diary_entries").select(
            "id,session_id,title,content,updated_at,diary_type",
          )
            .eq("owner_user_id", userId).order("updated_at", { ascending: false }),
        ]);
        if (stampError || visitsError || participantsError || diariesError) {
          throw stampError ?? visitsError ?? participantsError ??
            diariesError;
        }
        const completed = (participants ?? []).filter((row: any) =>
          row.mission_sessions?.status === "completed"
        );
        const sharedCompleted = completed.filter((row: any) =>
          row.mission_sessions?.mode === "collaborative"
        ).length;
        const participantSessionIds = (participants ?? []).map((row: any) =>
          row.session_id
        );
        const { data: sharedDiaries, error: sharedDiaryError } =
          participantSessionIds.length
            ? await admin.from("diary_entries")
              .select("id,session_id,title,content,updated_at,diary_type")
              .eq("diary_type", "shared")
              .in("session_id", participantSessionIds)
              .order("updated_at", { ascending: false })
            : { data: [], error: null };
        if (sharedDiaryError) throw sharedDiaryError;
        const ownDiarySessionIds = new Set(
          (diaries ?? []).map((row: any) => row.session_id),
        );
        const sharedDiarySessionIds = new Set(
          (sharedDiaries ?? []).map((row: any) => row.session_id),
        );
        const stamps = (stampRows ?? []).map((row: any) => {
          const definition = row.stamp_definitions;
          const destination = definition.destinations;
          const mission = row.mission_sessions;
          return {
            place: destination.name,
            state: destination.state,
            name: definition.name,
            rarity: definition.rarity,
            earned_at: row.earned_at,
            session_id: row.session_id,
            mission_title: mission?.title,
          };
        });
        const states = countExploredStates(stamps);
        const criteria = {
          completed_missions: completed.length,
          verified_destinations: visits?.length ?? 0,
          explored_states: states,
          shared_missions: sharedCompleted,
        };
        const newBadges = await awardBadges(admin, userId, criteria);
        const [
          { data: userBadges, error: badgesError },
          { data: badgeDefinitions, error: definitionsError },
        ] = await Promise.all([
          admin.from("user_badges").select("badge_id,earned_at")
            .eq("user_id", userId),
          admin.from("badge_definitions")
            .select("id,name,description,artwork_path,criteria")
            .eq("active", true).order("name"),
        ]);
        if (badgesError || definitionsError) {
          throw badgesError ?? definitionsError;
        }
        const earnedBadges = new Map(
          (userBadges ?? []).map((badge: any) => [
            badge.badge_id,
            badge.earned_at,
          ]),
        );
        return Response.json({
          stats: {
            completed_missions: completed.length,
            visited_destinations: visits?.length ?? 0,
            explored_states: states,
            collected_stamps: stamps.length,
          },
          stamps,
          badges: (badgeDefinitions ?? []).map((badge: any) => ({
            name: badge.name,
            description: badge.description,
            artwork_path: badge.artwork_path,
            criteria: badge.criteria,
            earned: earnedBadges.has(badge.id),
            earned_at: earnedBadges.get(badge.id) ?? null,
          })),
          diaries: [...(sharedDiaries ?? []), ...(diaries ?? [])].map((row: any) => ({
            id: row.id,
            session_id: row.session_id,
            title: row.title,
            summary: row.content?.text ?? "",
            updated_at: row.updated_at,
            diary_type: row.diary_type ?? "individual",
          })),
          eligible_diary_missions: completed
            .filter((row: any) =>
              row.mission_sessions.mode === "collaborative"
                ? !sharedDiarySessionIds.has(row.session_id)
                : !ownDiarySessionIds.has(row.session_id)
            )
            .map((row: any) => ({
              session_id: row.session_id,
              title: row.mission_sessions.title,
              mode: row.mission_sessions.mode,
              completed_at: row.mission_sessions.completed_at,
            })),
          newly_unlocked_badges: newBadges,
        });
      }

      if (!input.session_id) {
        return Response.json({ message: "Choose a completed mission." }, {
          status: 400,
        });
      }
      const { data: participant, error: participantError } = await admin
        .from("mission_participants")
        .select("role,status,mission_sessions!inner(title,status,mode,completed_at)")
        .eq("session_id", input.session_id)
        .eq("user_id", userId)
        .neq("status", "left")
        .maybeSingle();
      if (participantError) throw participantError;
      if (!participant || participant.mission_sessions.status !== "completed") {
        return Response.json({
          message: "Only a verified member of a completed mission can create this diary.",
        }, { status: 403 });
      }

      if (input.action === "group_diary_status") {
        if (participant.mission_sessions.mode !== "collaborative") {
          return Response.json({ message: "A collaborative mission is required." }, {
            status: 400,
          });
        }
        return Response.json(
          await loadGroupDiaryState(
            admin,
            input.session_id,
            userId,
            participant.role,
          ),
        );
      }

      if (input.action === "save_reflection") {
        const reflection = input.reflection?.trim() ?? "";
        if (reflection.length < 10) {
          return Response.json({
            message: "Please provide more details about your travel experience.",
          }, { status: 400 });
        }
        const { error } = await admin.from("reflections").upsert({
          user_id: userId,
          session_id: input.session_id,
          private_notes: reflection,
        }, { onConflict: "user_id,session_id" });
        if (error) throw error;
        return Response.json({
          saved: true,
          message: "Your reflection has been submitted successfully.",
        });
      }

      if (input.action === "generate_diary") {
        if (participant.mission_sessions.mode === "collaborative") {
          return Response.json({
            message: "Collaborative missions use one shared group diary.",
          }, { status: 409 });
        }
        const reflection = input.reflection?.trim() ?? "";
        if (reflection.length < 10) {
          return Response.json({
            message: "Please provide more details about your travel experience before generating the diary.",
          }, { status: 400 });
        }
        const { error: reflectionError } = await admin.from("reflections")
          .upsert({
            user_id: userId,
            session_id: input.session_id,
            private_notes: reflection,
          }, { onConflict: "user_id,session_id" });
        if (reflectionError) throw reflectionError;
        const verified = await verifiedJourney(
          admin,
          userId,
          input.session_id,
        );
        if (verified.destinations.length === 0) {
          return Response.json({
            message: "This mission has no verified destination visits.",
          }, { status: 409 });
        }
        const title = `My ${participant.mission_sessions.title} Journey`;
        const generated = await generateDiary({
          missionTitle: participant.mission_sessions.title,
          completedAt: participant.mission_sessions.completed_at,
          destinations: verified.destinations,
          reflection,
        });
        if (!generated) {
          return Response.json({
            generated: false,
            draft_saved: true,
            title,
            content: verifiedDraft(verified.destinations, reflection),
            message:
              "Gemini is temporarily unavailable. A verified editable draft was prepared from your reflection and confirmed visits.",
          });
        }
        return Response.json({
          generated: true,
          title,
          content: generated,
          message: "Your AI travel diary has been generated successfully.",
        });
      }

      if (input.action === "save_diary") {
        if (participant.mission_sessions.mode === "collaborative") {
          return Response.json({
            message: "Collaborative missions use one shared group diary.",
          }, { status: 409 });
        }
        const title = input.title?.trim() ?? "";
        const content = input.content?.trim() ?? "";
        if (title.length === 0 || content.length === 0) {
          return Response.json({ message: "Diary title and content are required." }, {
            status: 400,
          });
        }
        const { data: existing } = await admin.from("diary_entries")
          .select("id").eq("session_id", input.session_id)
          .eq("owner_user_id", userId).eq("diary_type", "individual")
          .maybeSingle();
        const values = {
          session_id: input.session_id,
          owner_user_id: userId,
          diary_type: "individual",
          title,
          content: { text: content },
          visibility: "private",
          ai_model: Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash",
          prompt_version: "verified-diary-v1",
        };
        const result = existing
          ? await admin.from("diary_entries").update(values).eq("id", existing.id)
          : await admin.from("diary_entries").insert(values);
        if (result.error) throw result.error;
        return Response.json({
          saved: true,
          message: "Your travel diary has been saved successfully.",
        });
      }

      if (input.action === "generate_group_diary") {
        if (
          participant.mission_sessions.mode !== "collaborative" ||
          participant.role !== "host"
        ) {
          return Response.json({
            message: "Only the host can generate the shared group diary.",
          }, { status: 403 });
        }
        const state = await loadGroupDiaryState(
          admin,
          input.session_id,
          userId,
          participant.role,
        );
        if (state.diary) return Response.json({ diary: state.diary });
        if (!state.all_submitted) {
          return Response.json({
            message: "Every current member must submit a reflection first.",
          }, { status: 409 });
        }
        const journey = await verifiedJourney(admin, userId, input.session_id);
        if (journey.destinations.length === 0) {
          return Response.json({
            message: "This mission has no verified destination visits.",
          }, { status: 409 });
        }
        const combinedReflection = state.members.map((member: any) =>
          `${member.name}: ${member.reflection}`
        ).join("\n\n");
        const title = `Our ${participant.mission_sessions.title} Journey`;
        const generated = await generateDiary({
          missionTitle: participant.mission_sessions.title,
          completedAt: participant.mission_sessions.completed_at,
          destinations: journey.destinations,
          reflection: combinedReflection,
          group: true,
        });
        const content = generated ?? verifiedDraft(
          journey.destinations,
          combinedReflection,
          true,
        );
        const { data: saved, error: saveError } = await admin
          .from("diary_entries")
          .insert({
            session_id: input.session_id,
            owner_user_id: null,
            diary_type: "shared",
            title,
            content: { text: content },
            visibility: "participants",
            ai_model: Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash",
            prompt_version: "verified-group-diary-v1",
          })
          .select("id,session_id,title,content,updated_at")
          .single();
        if (saveError) throw saveError;
        await admin.from("notifications").insert(
          state.members.map((member: any) => ({
            user_id: member.user_id,
            notification_type: "group_diary_ready",
            title: "Your shared travel diary is ready",
            body: `${title} is ready to read and share.`,
            data: { session_id: input.session_id, diary_id: saved.id },
          })),
        );
        return Response.json({
          diary: {
            id: saved.id,
            session_id: saved.session_id,
            title: saved.title,
            summary: saved.content?.text ?? "",
            updated_at: saved.updated_at,
            diary_type: "shared",
          },
          generated: Boolean(generated),
          message: generated
            ? "The shared AI travel diary is ready for every member."
            : "Gemini was unavailable, so a verified shared draft was created for every member.",
        });
      }

      return Response.json({ message: "Unknown passport action." }, {
        status: 400,
      });
    } catch (error) {
      console.error("Passport and diary failed:", safeMessage(error));
      return Response.json({
        message: "Unable to retrieve your passport information. Please try again.",
      }, { status: 500 });
    }
  }),
};

async function verifiedJourney(admin: any, userId: string, sessionId: string) {
  const { data: visits, error } = await admin.from("verified_visits")
    .select("stage_id,verified_at").eq("user_id", userId)
    .eq("session_id", sessionId).order("verified_at");
  if (error) throw error;
  if (!visits?.length) return { destinations: [] };
  const { data: secrets, error: secretsError } = await admin
    .from("mission_stage_secrets").select("stage_id,destination_id")
    .in("stage_id", visits.map((row: any) => row.stage_id));
  if (secretsError) throw secretsError;
  const { data: destinations, error: destinationError } = await admin
    .from("destinations").select("id,name,state,city,categories,facts")
    .in("id", secrets.map((row: any) => row.destination_id));
  if (destinationError) throw destinationError;
  return { destinations: destinations ?? [] };
}

async function loadGroupDiaryState(
  admin: any,
  sessionId: string,
  viewerId: string,
  viewerRole: string,
) {
  const [
    { data: members, error: memberError },
    { data: reflections, error: reflectionError },
    { data: diary, error: diaryError },
  ] = await Promise.all([
    admin.from("mission_participants").select("user_id,role,status")
      .eq("session_id", sessionId).neq("status", "left"),
    admin.from("reflections").select("user_id,private_notes,updated_at")
      .eq("session_id", sessionId),
    admin.from("diary_entries")
      .select("id,session_id,title,content,updated_at")
      .eq("session_id", sessionId).eq("diary_type", "shared")
      .maybeSingle(),
  ]);
  if (memberError || reflectionError || diaryError) {
    throw memberError ?? reflectionError ?? diaryError;
  }
  const memberIds = (members ?? []).map((member: any) => member.user_id);
  const { data: profiles, error: profileError } = memberIds.length
    ? await admin.from("profiles").select("id,display_name,username")
      .in("id", memberIds)
    : { data: [], error: null };
  if (profileError) throw profileError;
  const profileById = new Map(
    (profiles ?? []).map((profile: any) => [profile.id, profile]),
  );
  const reflectionByUser = new Map(
    (reflections ?? []).map((reflection: any) => [
      reflection.user_id,
      reflection,
    ]),
  );
  const groupMembers = (members ?? []).map((member: any) => {
    const reflection = reflectionByUser.get(member.user_id);
    const profile = profileById.get(member.user_id);
    return {
      user_id: member.user_id,
      name: profile?.display_name ?? profile?.username ?? "Explorer",
      role: member.role,
      is_viewer: member.user_id === viewerId,
      reflection: reflection?.private_notes ?? null,
      submitted_at: reflection?.updated_at ?? null,
    };
  });
  return {
    is_host: viewerRole === "host",
    all_submitted: groupMembers.length > 0 &&
      groupMembers.every((member: any) =>
        typeof member.reflection === "string" && member.reflection.trim()
      ),
    members: groupMembers,
    diary: diary
      ? {
        id: diary.id,
        session_id: diary.session_id,
        title: diary.title,
        summary: diary.content?.text ?? "",
        updated_at: diary.updated_at,
        diary_type: "shared",
      }
      : null,
  };
}

async function generateDiary(input: {
  missionTitle: string;
  completedAt: string;
  destinations: any[];
  reflection: string;
  group?: boolean;
}): Promise<string | null> {
  const key = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!key) return null;
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
    input.group
      ? "Write a warm first-person plural group travel diary of 180-280 words using we/our."
      : "Write a warm first-person travel diary of 180-280 words.",
    "Use only the verified journey data and traveller reflection below.",
    "Do not add destinations, activities, people, facts or events not present in the input.",
    "Return only the diary prose.",
    JSON.stringify(input),
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
            "x-goog-api-key": key,
          },
          body: JSON.stringify({
            contents: [{ role: "user", parts: [{ text: prompt }] }],
            generationConfig: { temperature: 0.5 },
          }),
        },
      );
      if (!response.ok) {
        const detail = await response.text();
        console.error(
          `Diary model ${model} failed (${response.status}): ${
            detail.slice(0, 240)
          }`,
        );
        continue;
      }
      const payload = await response.json();
      const text = payload?.candidates?.[0]?.content?.parts
        ?.map((part: { text?: string }) => part.text ?? "").join("\n").trim();
      if (typeof text === "string" && text.length >= 100) return text;
    } catch (error) {
      console.error(`Diary model ${model} failed: ${safeMessage(error)}`);
    }
  }
  return null;
}

function verifiedDraft(
  destinations: any[],
  reflection: string,
  group = false,
): string {
  const stops = destinations.map((destination, index) => {
    const facts = Array.isArray(destination.facts)
      ? destination.facts.filter((fact: unknown) => typeof fact === "string")
      : [];
    const location = [destination.city, destination.state]
      .filter((value) => typeof value === "string" && value.trim())
      .join(", ");
    return [
      `Stop ${index + 1}: ${destination.name}${
        location ? ` — ${location}` : ""
      }`,
      facts[0] ? `What I learned: ${facts[0]}` : null,
    ].filter(Boolean).join("\n");
  });
  return [
    reflection.trim(),
    "",
    group
      ? "Our verified Mystery Malaysia journey:"
      : "My verified Mystery Malaysia journey:",
    ...stops,
  ].join("\n");
}

async function awardBadges(
  admin: any,
  userId: string,
  progress: Record<string, number>,
): Promise<string[]> {
  const { data: definitions, error } = await admin.from("badge_definitions")
    .select("id,name,criteria").eq("active", true);
  if (error) throw error;
  const unlocked = [];
  for (const badge of definitions ?? []) {
    const eligible = Object.entries(badge.criteria ?? {}).every(
      ([key, target]) => (progress[key] ?? 0) >= Number(target),
    );
    if (!eligible) continue;
    const { data, error: awardError } = await admin.from("user_badges")
      .upsert({ user_id: userId, badge_id: badge.id }, {
        onConflict: "user_id,badge_id",
        ignoreDuplicates: true,
      }).select("badge_id");
    if (awardError) throw awardError;
    if (data?.length) unlocked.push(badge.name);
  }
  return unlocked;
}

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 300) : String(error);
}
