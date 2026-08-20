import { Webhook } from "npm:standardwebhooks@1.0.0";

type EmailData = {
  token?: string;
  token_hash?: string;
  token_new?: string;
  token_hash_new?: string;
  redirect_to?: string;
  email_action_type: string;
};

type HookPayload = {
  user: { email: string; new_email?: string };
  email_data: EmailData;
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const resendApiKey = Deno.env.get("RESEND_API_KEY") ?? "";
const from = Deno.env.get("AUTH_EMAIL_FROM") ??
  "Mystery Malaysia <onboarding@resend.dev>";
const hookSecret = (Deno.env.get("SEND_EMAIL_HOOK_SECRET") ?? "").replace(
  "v1,whsec_",
  "",
);

const copy: Record<string, [string, string, string, string]> = {
  signup: [
    "Confirm your Mystery Malaysia adventure",
    "🌺",
    "Your first adventure is almost ready!",
    "Confirm your email to unlock mystery missions, Malaysian hidden gems, clues, passport stamps and shared adventures.",
  ],
  recovery: [
    "Reset your Mystery Malaysia password",
    "🔐",
    "Choose a new password",
    "We received a request to reset your password. Continue to the app to create a new one.",
  ],
  invite: [
    "You are invited to a Mystery Malaysia mission",
    "🧭",
    "A shared adventure is waiting!",
    "Join your travel crew to solve clues and discover hidden Malaysian gems together.",
  ],
  magiclink: [
    "Your Mystery Malaysia sign-in link",
    "✨",
    "Continue your adventure",
    "Use this secure link to sign in to Mystery Malaysia.",
  ],
  email_change: [
    "Confirm your Mystery Malaysia email change",
    "📮",
    "Confirm your new email",
    "Use this secure link to confirm the change to your account email.",
  ],
  reauthentication: [
    "Confirm your Mystery Malaysia identity",
    "🛡️",
    "Confirm it is you",
    "Use this secure link to continue your account change.",
  ],
};

function actionUrl(data: EmailData, tokenHash: string) {
  const query = new URLSearchParams({
    token: tokenHash,
    type: data.email_action_type,
    redirect_to: data.redirect_to || "com.mysterymalaysia://login-callback/",
  });
  return `${supabaseUrl}/auth/v1/verify?${query}`;
}

function emailHtml(data: EmailData, tokenHash: string) {
  const [, emoji, heading, description] = copy[data.email_action_type] ?? [
    "Mystery Malaysia account action",
    "🧭",
    "Continue to Mystery Malaysia",
    "Use this secure link to continue.",
  ];
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;background:#fffaf0;font-family:Arial,sans-serif;color:#10233f"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#fffaf0;padding:32px 16px"><tr><td align="center"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#fff;border:1px solid #dbe7e4;border-radius:28px;overflow:hidden"><tr><td style="background:#08769a;padding:34px 32px;text-align:center;color:#fff"><div style="font-size:48px">${emoji}</div><h1 style="margin:12px 0 4px;font-size:30px">Mystery Malaysia</h1><p style="margin:0;font-size:16px">Malaysia is full of secrets. Let’s find yours.</p></td></tr><tr><td style="padding:34px 32px"><h2 style="margin:0 0 14px;font-size:24px">${heading}</h2><p style="margin:0 0 24px;line-height:1.6;color:#52627a">${description}</p><p style="margin:0 0 26px;text-align:center"><a href="${actionUrl(data, tokenHash)}" style="display:inline-block;background:#ff5a75;color:#fff;text-decoration:none;font-weight:bold;font-size:16px;padding:15px 26px;border-radius:999px">Continue in the app</a></p><p style="margin:0;font-size:13px;line-height:1.5;color:#7b8798">If you did not request this action, you can safely ignore this email.</p></td></tr><tr><td style="background:#fff0bd;padding:18px 32px;text-align:center;font-size:13px;color:#52627a">Made for curious explorers across Malaysia 🇲🇾</td></tr></table></td></tr></table></body></html>`;
}

async function send(to: string, data: EmailData, tokenHash: string) {
  const [subject] = copy[data.email_action_type] ?? [
    "Mystery Malaysia account action",
  ];
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to: [to],
      subject,
      html: emailHtml(data, tokenHash),
    }),
  });
  if (!response.ok) throw new Error(`Email provider returned ${response.status}`);
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }
  if (!resendApiKey || !hookSecret || !supabaseUrl) {
    return Response.json({ error: "Email hook is not configured" }, {
      status: 503,
    });
  }

  try {
    const body = await request.text();
    const payload = new Webhook(hookSecret).verify(
      body,
      Object.fromEntries(request.headers),
    ) as HookPayload;
    const { user, email_data: data } = payload;

    if (data.email_action_type === "email_change" && user.new_email) {
      if (data.token_hash_new) {
        await send(user.email, data, data.token_hash_new);
      }
      if (data.token_hash) {
        await send(user.new_email, data, data.token_hash);
      }
    } else {
      const tokenHash = data.token_hash || data.token_hash_new;
      if (!tokenHash) throw new Error("Auth email token is missing");
      await send(user.email, data, tokenHash);
    }

    return Response.json({});
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    return Response.json({ error: "Unable to send authentication email" }, {
      status: 401,
    });
  }
});
