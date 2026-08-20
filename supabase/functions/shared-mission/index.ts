import { withSupabase } from "npm:@supabase/server@1.4.1";

type Input = {
  action?: "overview" | "lobby" | "invite" | "respond" | "remove" | "leave" | "ready" | "start" | "reflection";
  session_id?: string;
  invitation_id?: string;
  email?: string;
  response?: "accepted" | "declined";
  member_id?: string;
  ready?: boolean;
  reflection?: string;
};

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const userId = context.userClaims?.id;
    const userEmail = String(context.userClaims?.email ?? "").toLowerCase();
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }
    const input = await request.json().catch(() => ({})) as Input;
    const admin = context.supabaseAdmin;
    try {
      if (input.action === "overview") {
        const { data: memberships, error: membershipsError } = await admin
          .from("mission_participants")
          .select("session_id")
          .eq("user_id", userId)
          .neq("status", "left");
        if (membershipsError) throw membershipsError;
        const sessionIds = memberships?.map((row) => row.session_id) ?? [];
        const { data: sessions, error: sessionsError } = sessionIds.length
          ? await admin.from("mission_sessions")
            .select("id,title,status,current_stage,mode")
            .in("id", sessionIds).eq("mode", "collaborative")
            .order("created_at", { ascending: false })
          : { data: [], error: null };
        if (sessionsError) throw sessionsError;
        const { data: invitations, error: invitationError } = await admin
          .from("invitations")
          .select("id,session_id,inviter_id,status,expires_at,mission_sessions!inner(title)")
          .eq("status", "pending")
          .or(`invitee_id.eq.${userId},invitee_email.eq.${userEmail}`);
        if (invitationError) throw invitationError;
        return Response.json({
          sessions,
          invitations: (invitations ?? []).map((row: any) => ({
            id: row.id,
            session_id: row.session_id,
            title: row.mission_sessions.title,
            expires_at: row.expires_at,
          })),
        });
      }

      if (input.action === "respond") {
        if (!input.invitation_id || !input.response) {
          return Response.json({ message: "Choose an invitation response." }, {
            status: 400,
          });
        }
        const { data: invitation, error } = await admin.from("invitations")
          .select("*").eq("id", input.invitation_id).eq("status", "pending")
          .single();
        if (error) throw error;
        if (
          invitation.invitee_id !== userId &&
          invitation.invitee_email?.toLowerCase() !== userEmail
        ) {
          return Response.json({ message: "This invitation is not yours." }, {
            status: 403,
          });
        }
        if (new Date(invitation.expires_at) <= new Date()) {
          await admin.from("invitations").update({ status: "expired" })
            .eq("id", invitation.id);
          return Response.json({ message: "This invitation has expired." }, {
            status: 410,
          });
        }
        if (input.response === "declined") {
          await admin.from("invitations").update({
            status: "declined",
            invitee_id: userId,
            responded_at: new Date().toISOString(),
          }).eq("id", invitation.id);
          return Response.json({ status: "declined" });
        }
        const { data: current } = await admin.from("user_current_missions")
          .select("session_id").eq("user_id", userId).maybeSingle();
        if (current && current.session_id !== invitation.session_id) {
          return Response.json({
            message: "Finish or abandon your current mission before joining another.",
          }, { status: 409 });
        }
        const { data: session, error: sessionError } = await admin
          .from("mission_sessions").select("status").eq("id", invitation.session_id)
          .single();
        if (sessionError) throw sessionError;
        if (session.status !== "waiting") {
          return Response.json({ message: "This shared mission already started." }, {
            status: 409,
          });
        }
        const { error: participantError } = await admin.from("mission_participants")
          .upsert({
            session_id: invitation.session_id,
            user_id: userId,
            role: "member",
            ready: false,
            status: "joined",
          }, { onConflict: "session_id,user_id" });
        if (participantError) throw participantError;
        await admin.from("user_current_missions").upsert({
          user_id: userId,
          session_id: invitation.session_id,
        });
        await admin.from("invitations").update({
          status: "accepted",
          invitee_id: userId,
          responded_at: new Date().toISOString(),
        }).eq("id", invitation.id);
        return Response.json({
          status: "accepted",
          session_id: invitation.session_id,
        });
      }

      if (!input.session_id) {
        return Response.json({ message: "A shared mission is required." }, {
          status: 400,
        });
      }
      const { data: participant, error: participantError } = await admin
        .from("mission_participants").select("role,status,ready")
        .eq("session_id", input.session_id).eq("user_id", userId)
        .neq("status", "left").maybeSingle();
      if (participantError) throw participantError;
      if (!participant) {
        return Response.json({ message: "You cannot access this shared mission." }, {
          status: 403,
        });
      }
      const { data: session, error: sessionError } = await admin
        .from("mission_sessions").select("*").eq("id", input.session_id)
        .eq("mode", "collaborative").single();
      if (sessionError) throw sessionError;

      if (input.action === "lobby") {
        const { data: members, error } = await admin.from("mission_participants")
          .select("user_id,role,status,ready")
          .eq("session_id", session.id).neq("status", "left");
        if (error) throw error;
        const { data: profiles, error: profilesError } = await admin
          .from("profiles").select("id,display_name,username,avatar_path")
          .in("id", (members ?? []).map((row: any) => row.user_id));
        if (profilesError) throw profilesError;
        const profileById = new Map(
          (profiles ?? []).map((profile: any) => [profile.id, profile]),
        );
        const { data: pending } = await admin.from("invitations")
          .select("id,invitee_email,status,expires_at")
          .eq("session_id", session.id).eq("status", "pending");
        return Response.json({
          session: {
            id: session.id,
            title: session.title,
            status: session.status,
            current_stage: session.current_stage,
          },
          viewer: { user_id: userId, role: participant.role },
          members: (members ?? []).map((row: any) => ({
            user_id: row.user_id,
            name: profileById.get(row.user_id)?.display_name ?? "Explorer",
            username: profileById.get(row.user_id)?.username,
            role: row.role,
            status: row.status,
            ready: row.ready,
          })),
          pending_invitations: pending ?? [],
        });
      }

      if (input.action === "invite") {
        if (participant.role !== "host" || session.status !== "waiting") {
          return Response.json({
            message: "Only the host can invite members before the mission starts.",
          }, { status: 403 });
        }
        const email = input.email?.trim().toLowerCase() ?? "";
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
          return Response.json({ message: "Please enter a valid email address." }, {
            status: 400,
          });
        }
        if (email === userEmail) {
          return Response.json({ message: "You cannot invite yourself." }, {
            status: 400,
          });
        }
        const { data: existing } = await admin.from("invitations").select("id")
          .eq("session_id", session.id).eq("invitee_email", email)
          .eq("status", "pending").maybeSingle();
        if (existing) {
          return Response.json({
            message: "This tourist has already been invited.",
          }, { status: 409 });
        }
        let inviteeId: string | null = null;
        for (let page = 1; page <= 5 && !inviteeId; page++) {
          const { data } = await admin.auth.admin.listUsers({
            page,
            perPage: 200,
          });
          inviteeId = data.users.find((user: any) =>
            user.email?.toLowerCase() === email
          )?.id ?? null;
          if (data.users.length < 200) break;
        }
        const registered = Boolean(inviteeId);
        let emailSent = false;
        if (!inviteeId) {
          const { data: invitedUser, error: emailError } = await admin.auth.admin
            .inviteUserByEmail(email, {
              redirectTo: "com.mysterymalaysia://login-callback/",
              data: {
                display_name: "Explorer",
                mission_invitation_session_id: session.id,
              },
            });
          if (emailError || !invitedUser.user) {
            return Response.json({
              message: Number(emailError?.status) === 429
                ? "Email sending is temporarily limited. Please try again later."
                : "The invitation email could not be sent. Please try again.",
            }, { status: Number(emailError?.status) === 429 ? 429 : 502 });
          }
          inviteeId = invitedUser.user.id;
          emailSent = true;
        }
        const { data: invitation, error: inviteError } = await admin
          .from("invitations").insert({
            session_id: session.id,
            inviter_id: userId,
            invitee_id: inviteeId,
            invitee_email: email,
            expires_at: new Date(Date.now() + 7 * 86400000).toISOString(),
          }).select("id,invitation_token").single();
        if (inviteError) throw inviteError;
        await admin.from("notifications").insert({
          user_id: inviteeId,
          notification_type: "mission_invitation",
          title: "Shared mission invitation",
          body: `You were invited to ${session.title}.`,
          data: { invitation_id: invitation.id, session_id: session.id },
        });
        return Response.json({
          registered,
          email_sent: emailSent,
          invitation_id: invitation.id,
          message: registered
            ? "The registered traveller received an in-app invitation."
            : "The traveller is not registered, so an account invitation email was sent.",
        });
      }

      if (input.action === "remove") {
        if (
          participant.role !== "host" ||
          !["waiting", "active", "paused"].includes(session.status) ||
          !input.member_id ||
          input.member_id === userId
        ) {
          return Response.json({
            message: "Only the host can remove another member from a current mission.",
          }, { status: 403 });
        }
        await admin.from("mission_participants").update({
          status: "left",
          ready: false,
        }).eq("session_id", session.id).eq("user_id", input.member_id);
        await admin.from("user_current_missions").delete()
          .eq("session_id", session.id).eq("user_id", input.member_id);
        await admin.from("notifications").insert({
          user_id: input.member_id,
          notification_type: "mission_member_removed",
          title: "Removed from shared mission",
          body: "You have been removed from the shared mission.",
          data: { session_id: session.id },
        });
        return Response.json({ removed: true });
      }

      if (input.action === "leave") {
        if (participant.role === "host") {
          return Response.json({
            message: "The host cannot quit the crew. Abandon the shared mission instead.",
          }, { status: 409 });
        }
        if (!["waiting", "active", "paused"].includes(session.status)) {
          return Response.json({
            message: "This shared mission can no longer be left.",
          }, { status: 409 });
        }
        const { error: leaveError } = await admin.from("mission_participants")
          .update({ status: "left", ready: false })
          .eq("session_id", session.id)
          .eq("user_id", userId);
        if (leaveError) throw leaveError;
        await admin.from("user_current_missions").delete()
          .eq("session_id", session.id).eq("user_id", userId);
        const { data: host } = await admin.from("mission_participants")
          .select("user_id").eq("session_id", session.id).eq("role", "host")
          .neq("status", "left").maybeSingle();
        if (host) {
          await admin.from("notifications").insert({
            user_id: host.user_id,
            notification_type: "mission_member_left",
            title: "A teammate left the mission",
            body: "A traveller has left your shared mission crew.",
            data: { session_id: session.id, member_id: userId },
          });
        }
        return Response.json({
          left: true,
          message: "You left the shared mission.",
        });
      }

      if (input.action === "ready") {
        if (session.status !== "waiting") {
          return Response.json({ message: "This mission already started." }, {
            status: 409,
          });
        }
        const ready = input.ready ?? true;
        await admin.from("mission_participants").update({
          ready,
          status: ready ? "ready" : "joined",
        }).eq("session_id", session.id).eq("user_id", userId);
        return Response.json({ ready });
      }

      if (input.action === "start") {
        if (participant.role !== "host" || session.status !== "waiting") {
          return Response.json({
            message: "Only the host can start a waiting shared mission.",
          }, { status: 403 });
        }
        const { data: members } = await admin.from("mission_participants")
          .select("ready").eq("session_id", session.id).neq("status", "left");
        if (!members?.length || members.some((member: any) => !member.ready)) {
          return Response.json({
            message: "Every joined member must be ready before starting.",
          }, { status: 409 });
        }
        const now = new Date().toISOString();
        await admin.from("mission_sessions").update({
          status: "active",
          started_at: now,
        }).eq("id", session.id);
        await admin.from("mission_stages").update({
          status: "active",
          unlocked_at: now,
        }).eq("session_id", session.id).eq("stage_number", 1);
        await admin.from("mission_participants").update({
          status: "navigating",
        }).eq("session_id", session.id).neq("status", "left");
        return Response.json({ started: true });
      }

      if (input.action === "reflection") {
        if (session.status !== "completed") {
          return Response.json({
            message: "Reflections are available after the shared mission is completed.",
          }, { status: 409 });
        }
        const reflection = input.reflection?.trim() ?? "";
        if (!reflection) {
          return Response.json({
            message: "Please enter your travel reflection before submitting.",
          }, { status: 400 });
        }
        const { data: existing } = await admin.from("reflections").select("id")
          .eq("session_id", session.id).eq("user_id", userId).maybeSingle();
        await admin.from("reflections").upsert({
          session_id: session.id,
          user_id: userId,
          private_notes: reflection,
        }, { onConflict: "user_id,session_id" });
        await admin.from("mission_participants").update({
          status: "reflection_submitted",
        }).eq("session_id", session.id).eq("user_id", userId);
        return Response.json({
          updated: Boolean(existing),
          message: existing
            ? "Your travel reflection has been updated successfully."
            : "Your travel reflection has been submitted successfully.",
        });
      }

      return Response.json({ message: "Unknown shared mission action." }, {
        status: 400,
      });
    } catch (error) {
      console.error("Shared mission failed:", safeMessage(error));
      return Response.json({
        message: "The shared mission could not be updated.",
      }, { status: 500 });
    }
  }),
};

function safeMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 300) : String(error);
}
