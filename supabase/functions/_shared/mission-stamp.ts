type StampDestination = {
  name: string;
  state?: string | null;
  city?: string | null;
  categories?: string[] | null;
  primary_type?: string | null;
  facts?: unknown;
};

export async function generateMissionStamp({
  admin,
  sessionId,
  title,
  destinations,
}: {
  admin: any;
  sessionId: string;
  title: string;
  destinations: StampDestination[];
}): Promise<{ path: string; model: string }> {
  const apiKey = Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!apiKey) throw new Error("GEMINI_API_KEY is not configured.");
  if (destinations.length !== 3) {
    throw new Error("A mission stamp requires exactly three destinations.");
  }

  const configuredModel = Deno.env.get("GEMINI_IMAGE_MODEL")?.trim();
  const models = configuredModel
    ? [configuredModel]
    : [
      "gemini-3.1-flash-lite-image",
      "gemini-3.1-flash-image",
      "gemini-2.5-flash-image",
    ];
  const prompt = [
    "Create one square collectible postage-stamp illustration for a Malaysian tourism mystery mission.",
    `Mission: ${title}.`,
    `Its three real destinations are: ${JSON.stringify(destinations.map((item) => ({
      name: item.name,
      state: item.state,
      city: item.city,
      type: item.primary_type,
      categories: item.categories ?? [],
      verified_facts: Array.isArray(item.facts)
        ? item.facts.filter((fact) => typeof fact === "string").slice(0, 2)
        : [],
    })))}`,
    "Blend recognizable visual motifs from all three destinations into one cohesive emblem, so this mission has its own unmistakable artwork.",
    "Bright, playful flat-vector travel-poster style; bold clean outlines; hibiscus pink, mango yellow, tropical teal and deep blue; decorative perforated postage edge; balanced 1:1 composition.",
    "No words, letters, numbers, logos, flags, government emblems, official seals, signatures or blank mockup frame.",
  ].join("\n");

  let generated: { bytes: Uint8Array; mimeType: string; model: string } | null =
    null;
  let lastError: Error | null = null;
  for (const model of models) {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: { responseModalities: ["IMAGE"] },
        }),
      },
    );
    if (!response.ok) {
      const detail = await response.text();
      lastError = new Error(
        `Gemini stamp model ${model} failed (${response.status}): ${detail.slice(0, 300)}`,
      );
      if (!configuredModel && [404, 429, 503].includes(response.status)) {
        continue;
      }
      throw lastError;
    }

    const payload = await response.json();
    const parts = payload?.candidates?.[0]?.content?.parts;
    const image = Array.isArray(parts)
      ? parts.find((part: any) =>
        part?.inlineData?.data || part?.inline_data?.data
      )
      : null;
    const inlineData = image?.inlineData ?? image?.inline_data;
    const encoded = inlineData?.data;
    const mimeType = String(
      inlineData?.mimeType ?? inlineData?.mime_type ?? "image/png",
    ).toLowerCase();
    if (typeof encoded !== "string" || !mimeType.startsWith("image/")) {
      lastError = new Error(`Gemini stamp model ${model} returned no image.`);
      continue;
    }
    const bytes = Uint8Array.from(atob(encoded), (character) =>
      character.charCodeAt(0)
    );
    if (bytes.length === 0 || bytes.length > 10 * 1024 * 1024) {
      lastError = new Error(`Gemini stamp model ${model} returned invalid data.`);
      continue;
    }
    generated = { bytes, mimeType, model };
    break;
  }
  if (!generated) {
    throw lastError ?? new Error("No Gemini image model was available.");
  }
  const { bytes, mimeType, model } = generated;
  const extension = mimeType.includes("jpeg") || mimeType.includes("jpg")
    ? "jpg"
    : mimeType.includes("webp")
    ? "webp"
    : "png";
  const path = `${sessionId}/stamp.${extension}`;
  const { error: uploadError } = await admin.storage
    .from("mission-stamps")
    .upload(path, bytes, { contentType: mimeType, upsert: true });
  if (uploadError) throw uploadError;

  const { error: sessionError } = await admin.from("mission_sessions").update({
    stamp_artwork_path: path,
    stamp_ai_model: model,
    stamp_prompt_version: "mission-destinations-v1",
  }).eq("id", sessionId);
  if (sessionError) throw sessionError;
  return { path, model };
}

export async function signedMissionStampUrl(
  admin: any,
  path: string | null | undefined,
): Promise<string | null> {
  if (!path) return null;
  const { data, error } = await admin.storage.from("mission-stamps")
    .createSignedUrl(path, 60 * 60);
  if (error) throw error;
  return data?.signedUrl ?? null;
}
