import { withSupabase } from "npm:@supabase/server@1.4.1";

type MissionInput = {
  origin_latitude: number;
  origin_longitude: number;
  available_minutes: number;
  budget_myr: number;
  maximum_distance_km?: number;
  categories?: string[];
  group_type?: "solo" | "couple" | "family" | "friends";
};

type DestinationCandidate = {
  id: string;
  external_place_id: string | null;
  name: string;
  state: string;
  city: string;
  latitude: number;
  longitude: number;
  categories: string[];
  estimated_budget_myr: number | null;
  estimated_duration_minutes: number | null;
  google_maps_uri: string | null;
  google_rating: number | null;
  google_user_rating_count: number | null;
  safety_score: number | null;
  discovery_score: number | null;
  selection_score: number;
  distance_km: number;
};

type GroundedPlace = {
  placeId: string;
  title: string;
  uri: string;
};

type PlaceDetails = {
  id: string;
  displayName?: { text?: string };
  formattedAddress?: string;
  addressComponents?: Array<{
    longText?: string;
    types?: string[];
  }>;
  location?: { latitude?: number; longitude?: number };
  types?: string[];
  primaryType?: string;
  businessStatus?: string;
  rating?: number;
  userRatingCount?: number;
  currentOpeningHours?: { openNow?: boolean };
  accessibilityOptions?: Record<string, boolean>;
  googleMapsUri?: string;
};

type DiscoveryResult = {
  candidates: DestinationCandidate[];
  mode: "maps_grounded" | "curated_fallback";
  warning?: string;
};

type GeneratedRecommendation = {
  title: string;
  story_hook: string;
  explanation: string;
  estimated_duration_minutes: number;
  estimated_budget_myr: number;
  total_distance_km: number;
  difficulty: "easy" | "moderate" | "hard";
  xp_reward: number;
  tags: string[];
  destination_ids: string[];
};

type GeminiResult = {
  model: string;
  recommendations: GeneratedRecommendation[];
};

const responseSchema = {
  type: "OBJECT",
  required: ["recommendations"],
  properties: {
    recommendations: {
      type: "ARRAY",
      minItems: 1,
      maxItems: 3,
      items: {
        type: "OBJECT",
        required: [
          "title",
          "story_hook",
          "explanation",
          "estimated_duration_minutes",
          "estimated_budget_myr",
          "total_distance_km",
          "difficulty",
          "xp_reward",
          "tags",
          "destination_ids",
        ],
        properties: {
          title: { type: "STRING" },
          story_hook: { type: "STRING" },
          explanation: { type: "STRING" },
          estimated_duration_minutes: { type: "INTEGER" },
          estimated_budget_myr: { type: "NUMBER" },
          total_distance_km: { type: "NUMBER" },
          difficulty: {
            type: "STRING",
            enum: ["easy", "moderate", "hard"],
          },
          xp_reward: { type: "INTEGER" },
          tags: { type: "ARRAY", items: { type: "STRING" } },
          destination_ids: {
            type: "ARRAY",
            minItems: 1,
            maxItems: 4,
            items: { type: "STRING" },
          },
        },
      },
    },
  },
};

export default {
  fetch: withSupabase({ auth: "user" }, async (request, context) => {
    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return Response.json(
        { message: "Gemini is not configured on the server." },
        { status: 500 },
      );
    }

    const userId = context.userClaims?.id;
    if (!userId) {
      return Response.json({ message: "Authentication required." }, {
        status: 401,
      });
    }

    let input: MissionInput;
    try {
      input = await request.json();
      validateInput(input);
    } catch (error) {
      return Response.json(
        {
          message: error instanceof Error
            ? error.message
            : "Invalid mission request.",
        },
        { status: 400 },
      );
    }

    const maximumDistanceKm = clamp(
      input.maximum_distance_km ?? 20,
      1,
      100,
    );
    const rawCategories = Array.isArray(input.categories)
      ? input.categories
      : [];
    const categories = rawCategories
      .filter((category): category is string => typeof category === "string")
      .map((category) => category.trim())
      .filter(Boolean)
      .slice(0, 5);
    const groupType = input.group_type ?? "solo";
    const admin = context.supabaseAdmin;
    let requestId: string | null = null;

    try {
      const { data: missionRequest, error: requestError } = await admin
        .from("mission_requests")
        .insert({
          user_id: userId,
          origin_latitude: input.origin_latitude,
          origin_longitude: input.origin_longitude,
          available_minutes: input.available_minutes,
          budget_myr: input.budget_myr,
          maximum_distance_km: maximumDistanceKm,
          categories,
          group_type: groupType,
          status: "generating",
        })
        .select("id")
        .single();
      if (requestError) throw requestError;
      requestId = missionRequest.id;

      await expireOldReservations(admin);
      const [historyIds, liveAllocationIds] = await Promise.all([
        loadUserDestinationHistory(admin, userId),
        loadLiveAllocationDestinationIds(admin),
      ]);
      const excludedIds = new Set([...historyIds, ...liveAllocationIds]);

      const discovery = await discoverCandidates({
        admin,
        apiKey: geminiKey,
        input,
        categories,
        maximumDistanceKm,
        excludedIds,
        requestId,
        userId,
      });
      const candidates = discovery.candidates;

      if (candidates.length === 0) {
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          discovery_mode: discovery.mode,
          message:
            "No new tourist-suitable destinations were found nearby. Try another area or a larger distance.",
        });
      }

      const geminiResult = await callGemini({
        apiKey: geminiKey,
        input,
        categories,
        maximumDistanceKm,
        candidates,
      });
      const validated = validateRecommendations(
        geminiResult.recommendations,
        candidates,
        input,
      );

      if (validated.length === 0) {
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          message: "Gemini could not form a valid route from nearby places.",
        });
      }

      const savedRecommendations = [];
      for (const [index, recommendation] of validated.entries()) {
        const { destination_ids, ...publicRecommendation } = recommendation;
        const { data: saved, error: recommendationError } = await admin
          .from("mission_recommendations")
          .insert({
            request_id: requestId,
            ...publicRecommendation,
            partially_satisfied_constraints: [],
            recommendation_rank: index + 1,
          })
          .select()
          .single();
        if (recommendationError) throw recommendationError;

        const stopRows = destination_ids.map((destinationId, stopIndex) => {
          const destination = candidates.find(
            (candidate) => candidate.id === destinationId,
          )!;
          return {
            recommendation_id: saved.id,
            stop_number: stopIndex + 1,
            destination_id: destinationId,
            travel_distance_km: destination.distance_km,
          };
        });
        const { error: stopError } = await admin
          .from("mission_recommendation_stops")
          .insert(stopRows);
        if (stopError) throw stopError;

        const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
        const { error: allocationError } = await admin
          .from("destination_allocations")
          .insert(
            destination_ids.map((destinationId) => ({
              destination_id: destinationId,
              user_id: userId,
              request_id: requestId,
              recommendation_id: saved.id,
              status: "reserved",
              expires_at: expiresAt,
            })),
          );
        if (allocationError) {
          // Another request won the reservation race. Remove this route and
          // continue with another recommendation rather than overcrowding it.
          await admin
            .from("destination_allocations")
            .delete()
            .eq("recommendation_id", saved.id);
          await admin
            .from("mission_recommendations")
            .delete()
            .eq("id", saved.id);
          continue;
        }

        await admin.from("recommendation_events").insert({
          request_id: requestId,
          recommendation_id: saved.id,
          event_type: "generated",
          ai_model: geminiResult.model,
          prompt_version: "mission-v2-maps-grounded",
          payload: {
            candidate_count: candidates.length,
            discovery_mode: discovery.mode,
            reservation_expires_at: expiresAt,
          },
        });

        savedRecommendations.push({
          id: saved.id,
          title: saved.title,
          story_hook: saved.story_hook,
          explanation: saved.explanation,
          estimated_duration_minutes: saved.estimated_duration_minutes,
          estimated_budget_myr: saved.estimated_budget_myr,
          total_distance_km: saved.total_distance_km,
          difficulty: saved.difficulty,
          xp_reward: saved.xp_reward,
          tags: saved.tags,
          recommendation_rank: saved.recommendation_rank,
          stops: destination_ids.length,
        });
      }

      if (savedRecommendations.length === 0) {
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          discovery_mode: discovery.mode,
          message:
            "Those destinations were just assigned to other explorers. Generate again for a fresh route.",
        });
      }

      await admin
        .from("mission_requests")
        .update({ status: "ready" })
        .eq("id", requestId);

      return Response.json({
        request_id: requestId,
        recommendations: savedRecommendations,
        discovery_mode: discovery.mode,
        warning: discovery.warning,
      });
    } catch (error) {
      const reason = safeErrorMessage(error);
      console.error("Mission generation failed:", reason);
      if (requestId) {
        await admin
          .from("mission_recommendations")
          .delete()
          .eq("request_id", requestId);
        await admin
          .from("mission_requests")
          .update({ status: "failed" })
          .eq("id", requestId);
        await admin.from("recommendation_events").insert({
          request_id: requestId,
          event_type: "failed",
          ai_model: Deno.env.get("GEMINI_MODEL") ?? "automatic-fallback",
          prompt_version: "mission-v2-maps-grounded",
          payload: { reason },
        });
      }
      return Response.json(
        { message: publicGenerationError(error) },
        { status: 500 },
      );
    }
  }),
};

async function expireOldReservations(admin: any): Promise<void> {
  const { error } = await admin
    .from("destination_allocations")
    .update({
      status: "expired",
      released_at: new Date().toISOString(),
    })
    .eq("status", "reserved")
    .lt("expires_at", new Date().toISOString());
  if (error) throw error;
}

async function loadUserDestinationHistory(
  admin: any,
  userId: string,
): Promise<Set<string>> {
  const { data: requests, error: requestError } = await admin
    .from("mission_requests")
    .select("id")
    .eq("user_id", userId);
  if (requestError) throw requestError;

  const requestIds = (requests ?? []).map((item: { id: string }) => item.id);
  if (requestIds.length === 0) return new Set();

  const { data: recommendations, error: recommendationError } = await admin
    .from("mission_recommendations")
    .select("id")
    .in("request_id", requestIds);
  if (recommendationError) throw recommendationError;

  const recommendationIds = (recommendations ?? []).map(
    (item: { id: string }) => item.id,
  );
  if (recommendationIds.length === 0) return new Set();

  const { data: stops, error: stopError } = await admin
    .from("mission_recommendation_stops")
    .select("destination_id")
    .in("recommendation_id", recommendationIds);
  if (stopError) throw stopError;

  return new Set(
    (stops ?? []).map(
      (item: { destination_id: string }) => item.destination_id,
    ),
  );
}

async function loadLiveAllocationDestinationIds(
  admin: any,
): Promise<Set<string>> {
  const { data, error } = await admin
    .from("destination_allocations")
    .select("destination_id")
    .in("status", ["reserved", "active"]);
  if (error) throw error;
  return new Set(
    (data ?? []).map(
      (item: { destination_id: string }) => item.destination_id,
    ),
  );
}

async function discoverCandidates({
  admin,
  apiKey,
  input,
  categories,
  maximumDistanceKm,
  excludedIds,
  requestId,
  userId,
}: {
  admin: any;
  apiKey: string;
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
  excludedIds: Set<string>;
  requestId: string;
  userId: string;
}): Promise<DiscoveryResult> {
  try {
    let groundedPlaces: GroundedPlace[];
    try {
      groundedPlaces = await discoverGroundedPlaces({
        apiKey,
        input,
        categories,
        maximumDistanceKm,
      });
    } catch (error) {
      throw new Error(`maps_grounding: ${safeErrorMessage(error)}`);
    }

    let details: PlaceDetails[];
    try {
      details = await loadPlaceDetails(
        groundedPlaces,
        Deno.env.get("GOOGLE_PLACES_API_KEY")?.trim() || apiKey,
      );
    } catch (error) {
      throw new Error(`place_details: ${safeErrorMessage(error)}`);
    }

    let dynamicCandidates: DestinationCandidate[];
    try {
      dynamicCandidates = await cacheEligiblePlaces({
        admin,
        groundedPlaces,
        details,
        input,
        categories,
        maximumDistanceKm,
        excludedIds,
        requestId,
        userId,
      });
    } catch (error) {
      throw new Error(`supabase_cache: ${safeErrorMessage(error)}`);
    }
    if (dynamicCandidates.length > 0) {
      return {
        candidates: dynamicCandidates,
        mode: "maps_grounded",
      };
    }
    throw new Error(
      "Maps grounding returned no places that passed tourist-suitability checks.",
    );
  } catch (error) {
    const warning = safeErrorMessage(error);
    console.warn("Maps-grounded discovery unavailable; using curated cache:", warning);
    return {
      candidates: await loadCuratedCandidates({
        admin,
        input,
        maximumDistanceKm,
        excludedIds,
        requestId,
        userId,
      }),
      mode: "curated_fallback",
      warning: discoveryFallbackWarning(warning),
    };
  }
}

async function discoverGroundedPlaces({
  apiKey,
  input,
  categories,
  maximumDistanceKm,
}: {
  apiKey: string;
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
}): Promise<GroundedPlace[]> {
  const configuredModel = Deno.env.get("GEMINI_MAPS_MODEL")?.trim();
  const models = configuredModel
    ? [configuredModel]
    : ["gemini-3.5-flash", "gemini-2.5-flash", "gemini-3.6-flash"];
  const prompt = [
    "Find 12 to 18 real, lesser-known Malaysian places suitable for a playful mystery tourism mission.",
    "You must use the Google Maps grounding tool to find and verify the places.",
    `Search within ${maximumDistanceKm} km of latitude ${input.origin_latitude}, longitude ${input.origin_longitude}.`,
    categories.length > 0
      ? `Prefer these interests when possible: ${categories.join(", ")}.`
      : "Balance culture, local food, history, nature, arts and hidden public attractions.",
    "Prioritise places with enough trustworthy public information but lower visitor exposure than famous landmarks.",
    "Only include publicly accessible, tourist-appropriate places. Exclude private homes, schools, hospitals, bars, nightclubs, accommodation, dangerous or remote wilderness, and places that appear closed.",
    "Do not create an itinerary or reveal clues. Briefly explain the variety of the real places you found.",
  ].join("\n");

  let lastError: Error | null = null;
  for (const model of models) {
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
          tools: [{ googleMaps: {} }],
          toolConfig: {
            retrievalConfig: {
              latLng: {
                latitude: input.origin_latitude,
                longitude: input.origin_longitude,
              },
            },
          },
        }),
      },
    );

    if (!response.ok) {
      const error = new Error(
        `Gemini Maps model ${model} failed (${response.status}): ${
          await googleErrorDetail(response)
        }`,
      );
      if ([404, 429].includes(response.status) && !configuredModel) {
        lastError = error;
        continue;
      }
      throw error;
    }

    const payload = await response.json();
    const chunks = payload?.candidates?.[0]?.groundingMetadata
      ?.groundingChunks;
    const unique = new Map<string, GroundedPlace>();
    if (Array.isArray(chunks)) {
      for (const chunk of chunks) {
        const maps = chunk?.maps;
        const placeId = normalizePlaceId(maps?.placeId);
        if (!placeId || unique.has(placeId)) continue;
        unique.set(placeId, {
          placeId,
          title: cleanText(maps?.title, 180, "Malaysian hidden gem"),
          uri: typeof maps?.uri === "string" ? maps.uri : "",
        });
      }
    }
    if (unique.size > 0) return [...unique.values()].slice(0, 18);
    lastError = new Error(
      `Gemini Maps model ${model} returned no grounded place IDs.`,
    );
  }
  throw lastError ?? new Error("No Maps-grounded Gemini model was available.");
}

async function loadPlaceDetails(
  groundedPlaces: GroundedPlace[],
  apiKey: string,
): Promise<PlaceDetails[]> {
  const fieldMask = [
    "id",
    "displayName",
    "formattedAddress",
    "addressComponents",
    "location",
    "types",
    "primaryType",
    "businessStatus",
    "rating",
    "userRatingCount",
    "currentOpeningHours",
    "accessibilityOptions",
    "googleMapsUri",
  ].join(",");
  const results = await Promise.allSettled(
    groundedPlaces.slice(0, 15).map(async (place) => {
      const response = await fetch(
        `https://places.googleapis.com/v1/places/${
          encodeURIComponent(place.placeId)
        }`,
        {
          headers: {
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask": fieldMask,
          },
        },
      );
      if (!response.ok) {
        throw new Error(
          `Google Places details failed (${response.status}): ${
            await googleErrorDetail(response)
          }`,
        );
      }
      return await response.json() as PlaceDetails;
    }),
  );

  const details = results
    .filter(
      (result): result is PromiseFulfilledResult<PlaceDetails> =>
        result.status === "fulfilled",
    )
    .map((result) => result.value);
  if (details.length === 0) {
    const firstFailure = results.find(
      (result): result is PromiseRejectedResult =>
        result.status === "rejected",
    );
    throw firstFailure?.reason ??
      new Error("Google Places returned no usable place details.");
  }
  return details;
}

async function cacheEligiblePlaces({
  admin,
  groundedPlaces,
  details,
  input,
  categories,
  maximumDistanceKm,
  excludedIds,
  requestId,
  userId,
}: {
  admin: any;
  groundedPlaces: GroundedPlace[];
  details: PlaceDetails[];
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
  excludedIds: Set<string>;
  requestId: string;
  userId: string;
}): Promise<DestinationCandidate[]> {
  const groundedById = new Map(
    groundedPlaces.map((place) => [place.placeId, place]),
  );
  const eligibleRows = details.flatMap((place) => {
    const latitude = place.location?.latitude;
    const longitude = place.location?.longitude;
    const placeId = normalizePlaceId(place.id);
    if (
      !placeId ||
      typeof latitude !== "number" ||
      typeof longitude !== "number" ||
      place.businessStatus !== "OPERATIONAL" ||
      hasExcludedPlaceType(place.types ?? [])
    ) {
      return [];
    }
    const distance = distanceKm(
      input.origin_latitude,
      input.origin_longitude,
      latitude,
      longitude,
    );
    const rating = place.rating ?? 0;
    const ratingCount = place.userRatingCount ?? 0;
    const safetyScore = touristSuitabilityScore(rating, ratingCount);
    if (
      distance > maximumDistanceKm ||
      rating < 3.8 ||
      ratingCount < 5 ||
      safetyScore < 0.65
    ) {
      return [];
    }

    const mappedCategories = categoriesForPlace(place.types ?? []);
    const discoveryScore = hiddenGemScore(ratingCount);
    const categoryMatch = categories.length === 0
      ? 0.5
      : mappedCategories.some((item) =>
          categories.some((requested) =>
            item.toLowerCase().includes(requested.toLowerCase()) ||
            requested.toLowerCase().includes(item.toLowerCase())
          )
        )
      ? 1
      : 0;
    const distanceFit = 1 - clamp(distance / maximumDistanceKm, 0, 1);
    const selectionScore = 0.45 * discoveryScore +
      0.30 * safetyScore +
      0.15 * distanceFit +
      0.10 * categoryMatch;
    const grounded = groundedById.get(placeId);
    const state = addressPart(
      place,
      "administrative_area_level_1",
      "Malaysia",
    );
    const city = addressPart(
      place,
      "locality",
      addressPart(place, "administrative_area_level_2", state),
    );
    const daylightOnly = isDaylightOnly(place.types ?? []);

    return [{
      external_place_id: `google:${placeId}`,
      name: cleanText(
        place.displayName?.text ?? grounded?.title,
        180,
        "Malaysian hidden gem",
      ),
      state,
      city,
      latitude,
      longitude,
      categories: mappedCategories,
      estimated_budget_myr: estimatedBudget(place.types ?? []),
      estimated_duration_minutes: estimatedDuration(place.types ?? []),
      opening_hours: place.currentOpeningHours ?? {},
      accessibility: place.accessibilityOptions ?? {},
      visitor_information: {
        formatted_address: place.formattedAddress,
        verification: "Google Places",
      },
      facts: [],
      popularity_score: popularityIndex(ratingCount),
      active: true,
      google_maps_uri: place.googleMapsUri || grounded?.uri || null,
      formatted_address: place.formattedAddress ?? null,
      primary_type: place.primaryType ?? null,
      google_rating: rating,
      google_user_rating_count: ratingCount,
      business_status: place.businessStatus,
      safety_status: "automated_review",
      safety_score: roundScore(safetyScore),
      discovery_score: roundScore(discoveryScore),
      capacity_per_slot: 1,
      daylight_only: daylightOnly,
      source_metadata: {
        source: "google_maps_grounding_and_places",
        discovered_by: "gemini",
        google_place_id: placeId,
        suitability_note:
          "Automated tourist-suitability signal; not a guarantee of personal safety.",
        request_id: requestId,
        requested_by_user_id: userId,
      },
      source_updated_at: new Date().toISOString(),
      last_place_sync_at: new Date().toISOString(),
      _distance_km: distance,
      _selection_score: selectionScore,
    }];
  });

  if (eligibleRows.length === 0) return [];
  const rowsForUpsert = eligibleRows.map((row) => {
    const { _distance_km, _selection_score, ...databaseRow } = row;
    return databaseRow;
  });
  const { data: savedRows, error: upsertError } = await admin
    .from("destinations")
    .upsert(rowsForUpsert, { onConflict: "external_place_id" })
    .select(
      "id,external_place_id,name,state,city,latitude,longitude,categories," +
        "estimated_budget_myr,estimated_duration_minutes,google_maps_uri," +
        "google_rating,google_user_rating_count,safety_score,discovery_score",
    );
  if (upsertError) throw upsertError;

  const sourceByExternalId = new Map(
    eligibleRows.map((row) => [row.external_place_id, row]),
  );
  const clueRows = (savedRows ?? []).map((row: {
    id: string;
    external_place_id: string;
  }) => {
    const source = sourceByExternalId.get(row.external_place_id);
    const typeHint = friendlyPlaceType(source?.primary_type);
    return {
      destination_id: row.id,
      clue_type: "observation",
      title: "A hidden corner is calling",
      prompt:
        "Follow the mystery zone on the map. Your live location will verify the destination when you arrive.",
      accepted_answers: [],
      validation_rules: {
        verification: "location",
        radius_metres: 120,
      },
      hint_text:
        `Look for a ${typeHint} around ${source?.city ?? "your nearby area"}.`,
      clue_xp_reward: 100,
      hint_xp_cost: 20,
      ai_model: "gemini-maps-grounded",
      prompt_version: "dynamic-location-v1",
    };
  });
  const { error: clueError } = await admin
    .from("destination_clues")
    .upsert(clueRows, { onConflict: "destination_id" });
  if (clueError) throw clueError;

  return (savedRows ?? [])
    .filter((row: { id: string }) => !excludedIds.has(row.id))
    .map((row: any) => {
      const source = sourceByExternalId.get(row.external_place_id)!;
      return {
        ...row,
        distance_km: source._distance_km,
        selection_score: source._selection_score,
      } as DestinationCandidate;
    })
    .sort((left: DestinationCandidate, right: DestinationCandidate) =>
      candidateOrder(left, right, requestId, userId)
    )
    .slice(0, 18);
}

async function loadCuratedCandidates({
  admin,
  input,
  maximumDistanceKm,
  excludedIds,
  requestId,
  userId,
}: {
  admin: any;
  input: MissionInput;
  maximumDistanceKm: number;
  excludedIds: Set<string>;
  requestId: string;
  userId: string;
}): Promise<DestinationCandidate[]> {
  const { data: rows, error } = await admin
    .from("destinations")
    .select(
      "id,external_place_id,name,state,city,latitude,longitude,categories," +
        "estimated_budget_myr,estimated_duration_minutes,google_maps_uri," +
        "google_rating,google_user_rating_count,safety_score,discovery_score," +
        "destination_clues!inner(destination_id)",
    )
    .eq("active", true)
    .in("safety_status", ["automated_review", "curated"]);
  if (error) throw error;

  return (rows ?? [])
    .filter((row: { id: string }) => !excludedIds.has(row.id))
    .map((row: any) => {
      const distance = distanceKm(
        input.origin_latitude,
        input.origin_longitude,
        row.latitude,
        row.longitude,
      );
      const safetyScore = Number(row.safety_score ?? 0.75);
      const discoveryScore = Number(row.discovery_score ?? 0.5);
      return {
        ...row,
        distance_km: distance,
        selection_score: 0.45 * discoveryScore +
          0.30 * safetyScore +
          0.25 * (1 - clamp(distance / maximumDistanceKm, 0, 1)),
      } as DestinationCandidate;
    })
    .filter((row: DestinationCandidate) =>
      row.distance_km <= maximumDistanceKm
    )
    .sort((left: DestinationCandidate, right: DestinationCandidate) =>
      candidateOrder(left, right, requestId, userId)
    )
    .slice(0, 18);
}

async function callGemini({
  apiKey,
  input,
  categories,
  maximumDistanceKm,
  candidates,
}: {
  apiKey: string;
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
  candidates: DestinationCandidate[];
}): Promise<GeminiResult> {
  const configuredModel = Deno.env.get("GEMINI_MODEL")?.trim();
  const models = configuredModel
    ? [configuredModel]
    : [
      "gemini-3.6-flash",
      "gemini-flash-latest",
      "gemini-3.5-flash-lite",
      "gemini-2.5-flash",
    ];
  const prompt = [
    "You design bright, playful mystery tourism missions in Malaysia.",
    "Choose only destination IDs from the supplied candidate list.",
    "Never invent an ID. Do not reveal destination names in titles, hooks, or explanations.",
    "Create one to three varied recommendations with one to four unique stops each.",
    `User constraints: ${JSON.stringify({
      available_minutes: input.available_minutes,
      budget_myr: input.budget_myr,
      maximum_distance_km: maximumDistanceKm,
      categories,
      group_type: input.group_type ?? "solo",
    })}`,
    `Hidden server candidates: ${JSON.stringify(candidates)}`,
  ].join("\n\n");

  let lastNotFoundError: Error | null = null;
  for (const model of models) {
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
          generationConfig: {
            responseMimeType: "application/json",
            responseSchema,
          },
        }),
      },
    );

    if (!response.ok) {
      const detail = await googleErrorDetail(response);
      const error = new Error(
        `Gemini model ${model} failed (${response.status}): ${detail}`,
      );
      if (response.status === 404 && !configuredModel) {
        lastNotFoundError = error;
        continue;
      }
      throw error;
    }

    const payload = await response.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string") {
      throw new Error(`Gemini model ${model} returned no structured content.`);
    }
    const parsed = JSON.parse(text);
    return {
      model,
      recommendations: Array.isArray(parsed.recommendations)
        ? parsed.recommendations
        : [],
    };
  }

  throw lastNotFoundError ??
    new Error("No supported Gemini model was available.");
}

async function googleErrorDetail(response: Response): Promise<string> {
  try {
    const payload = await response.json();
    const message = payload?.error?.message;
    if (typeof message === "string" && message.trim()) {
      return message.trim().replace(/\s+/g, " ").slice(0, 300);
    }
  } catch {
    // Fall back to the status text when Google did not return JSON.
  }
  return response.statusText || "Unknown Google API error";
}

function normalizePlaceId(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim().replace(/^places\//, "");
}

function addressPart(
  place: PlaceDetails,
  type: string,
  fallback: string,
): string {
  const component = place.addressComponents?.find((item) =>
    item.types?.includes(type)
  );
  return cleanText(component?.longText, 100, fallback);
}

function hasExcludedPlaceType(types: string[]): boolean {
  const excluded = new Set([
    "bar",
    "night_club",
    "liquor_store",
    "lodging",
    "hotel",
    "motel",
    "hostel",
    "school",
    "primary_school",
    "secondary_school",
    "university",
    "hospital",
    "medical_center",
    "doctor",
    "police",
    "funeral_home",
    "cemetery",
    "private_guest_room",
    "apartment_building",
  ]);
  return types.some((type) => excluded.has(type));
}

function categoriesForPlace(types: string[]): string[] {
  const categories = new Set<string>();
  for (const type of types) {
    if (
      [
        "museum",
        "art_gallery",
        "cultural_landmark",
        "historical_landmark",
        "place_of_worship",
      ].includes(type)
    ) {
      categories.add("Culture");
    }
    if (["historical_landmark", "monument"].includes(type)) {
      categories.add("History");
    }
    if (
      [
        "park",
        "botanical_garden",
        "hiking_area",
        "nature_preserve",
        "scenic_spot",
      ].includes(type)
    ) {
      categories.add("Nature");
    }
    if (
      [
        "restaurant",
        "cafe",
        "food_court",
        "market",
        "bakery",
      ].includes(type)
    ) {
      categories.add("Food");
    }
    if (
      [
        "tourist_attraction",
        "cultural_landmark",
        "historical_landmark",
        "scenic_spot",
      ].includes(type)
    ) {
      categories.add("Hidden gems");
    }
  }
  if (categories.size === 0) categories.add("Hidden gems");
  return [...categories].slice(0, 5);
}

function estimatedBudget(types: string[]): number {
  if (types.some((type) => ["restaurant", "food_court"].includes(type))) {
    return 35;
  }
  if (types.some((type) => ["cafe", "bakery"].includes(type))) return 22;
  if (
    types.some((type) =>
      ["museum", "tourist_attraction", "amusement_center"].includes(type)
    )
  ) {
    return 20;
  }
  return 5;
}

function estimatedDuration(types: string[]): number {
  if (
    types.some((type) =>
      ["park", "botanical_garden", "hiking_area", "nature_preserve"].includes(
        type,
      )
    )
  ) {
    return 90;
  }
  if (types.some((type) => ["restaurant", "food_court"].includes(type))) {
    return 75;
  }
  return 60;
}

function isDaylightOnly(types: string[]): boolean {
  return types.some((type) =>
    [
      "park",
      "botanical_garden",
      "hiking_area",
      "nature_preserve",
      "scenic_spot",
    ].includes(type)
  );
}

function touristSuitabilityScore(
  rating: number,
  ratingCount: number,
): number {
  const priorRating = 4;
  const priorWeight = 30;
  const bayesianRating = (
    ratingCount * rating + priorWeight * priorRating
  ) / (ratingCount + priorWeight);
  const quality = clamp(bayesianRating / 5, 0, 1);
  const evidence = clamp(
    Math.log1p(ratingCount) / Math.log1p(500),
    0,
    1,
  );
  return clamp(0.72 * quality + 0.28 * evidence, 0, 1);
}

function hiddenGemScore(ratingCount: number): number {
  return clamp(
    1 - Math.log1p(ratingCount) / Math.log1p(3000),
    0,
    1,
  );
}

function popularityIndex(ratingCount: number): number {
  return Math.round(
    clamp(Math.log1p(ratingCount) / Math.log1p(3000), 0, 1) * 1000,
  ) / 100;
}

function friendlyPlaceType(value: unknown): string {
  if (typeof value !== "string" || !value.trim()) {
    return "public local attraction";
  }
  return value.replaceAll("_", " ");
}

function roundScore(value: number): number {
  return Math.round(value * 1000) / 1000;
}

function candidateOrder(
  left: DestinationCandidate,
  right: DestinationCandidate,
  requestId: string,
  userId: string,
): number {
  const leftScore = left.selection_score +
    deterministicJitter(`${requestId}:${userId}:${left.id}`);
  const rightScore = right.selection_score +
    deterministicJitter(`${requestId}:${userId}:${right.id}`);
  return rightScore - leftScore;
}

function deterministicJitter(value: string): number {
  let hash = 2166136261;
  for (let index = 0; index < value.length; index++) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return ((hash >>> 0) / 4294967295) * 0.12;
}

function validateRecommendations(
  generated: GeneratedRecommendation[],
  candidates: DestinationCandidate[],
  input: MissionInput,
): GeneratedRecommendation[] {
  const allowedIds = new Set(candidates.map((candidate) => candidate.id));
  const globallyUsedIds = new Set<string>();
  const results: GeneratedRecommendation[] = [];

  for (const item of generated.slice(0, 3)) {
    if (!item || typeof item !== "object") continue;
    const destinationIds = [...new Set(item.destination_ids ?? [])]
      .filter((id) => allowedIds.has(id))
      .filter((id) => !globallyUsedIds.has(id))
      .slice(0, 4);
    if (destinationIds.length === 0) continue;
    destinationIds.forEach((id) => globallyUsedIds.add(id));

    results.push({
      title: cleanText(item.title, 80, "Mystery Malaysia Trail"),
      story_hook: cleanText(
        item.story_hook,
        400,
        "Follow the clues to uncover a Malaysian hidden gem.",
      ),
      explanation: cleanText(
        item.explanation,
        500,
        "Designed around your current location, time and budget.",
      ),
      estimated_duration_minutes: Math.round(
        clamp(item.estimated_duration_minutes, 30, input.available_minutes),
      ),
      estimated_budget_myr: roundMoney(
        clamp(item.estimated_budget_myr, 0, input.budget_myr),
      ),
      total_distance_km: roundDistance(
        Math.max(0, item.total_distance_km ?? 0),
      ),
      difficulty: ["easy", "moderate", "hard"].includes(item.difficulty)
        ? item.difficulty
        : "easy",
      xp_reward: Math.round(clamp(item.xp_reward ?? 0, 0, 5000)),
      tags: (item.tags ?? [])
        .map((tag) => cleanText(tag, 30, ""))
        .filter(Boolean)
        .slice(0, 8),
      destination_ids: destinationIds,
    });
  }
  return results;
}

function validateInput(input: MissionInput): void {
  if (!input || typeof input !== "object") {
    throw new Error("A mission request body is required.");
  }
  assertNumber(input.origin_latitude, -90, 90, "origin_latitude");
  assertNumber(input.origin_longitude, -180, 180, "origin_longitude");
  assertNumber(input.available_minutes, 30, 1440, "available_minutes");
  assertNumber(input.budget_myr, 0, 10000, "budget_myr");
  if (
    input.group_type !== undefined &&
    !["solo", "couple", "family", "friends"].includes(input.group_type)
  ) {
    throw new Error("group_type is invalid.");
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

function clamp(value: number, minimum: number, maximum: number): number {
  const safeValue = Number.isFinite(value) ? value : minimum;
  return Math.min(Math.max(safeValue, minimum), maximum);
}

function cleanText(value: unknown, maximum: number, fallback: string): string {
  if (typeof value !== "string") return fallback;
  const cleaned = value.trim().replace(/\s+/g, " ");
  return cleaned ? cleaned.slice(0, maximum) : fallback;
}

function roundMoney(value: number): number {
  return Math.round(value * 100) / 100;
}

function roundDistance(value: number): number {
  return Math.round(value * 100) / 100;
}

function distanceKm(
  fromLatitude: number,
  fromLongitude: number,
  toLatitude: number,
  toLongitude: number,
): number {
  const radians = (degrees: number) => degrees * Math.PI / 180;
  const earthRadiusKm = 6371;
  const latitudeDelta = radians(toLatitude - fromLatitude);
  const longitudeDelta = radians(toLongitude - fromLongitude);
  const startLatitude = radians(fromLatitude);
  const endLatitude = radians(toLatitude);
  const a = Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(startLatitude) * Math.cos(endLatitude) *
      Math.sin(longitudeDelta / 2) ** 2;
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function safeErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message.slice(0, 300);
  if (
    error &&
    typeof error === "object" &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    return error.message.slice(0, 300);
  }
  return "Unknown generation error";
}

function discoveryFallbackWarning(reason: string): string {
  if (reason.startsWith("place_details:")) {
    return "Gemini found real places, but Google Places Details could not verify them. Add a server-side GOOGLE_PLACES_API_KEY with Places API (New) and billing enabled. This request used the curated safety catalogue.";
  }
  if (reason.startsWith("supabase_cache:")) {
    return "Live places were verified but could not be cached in Supabase. This request used the curated safety catalogue.";
  }
  if (reason.startsWith("maps_grounding:")) {
    if (reason.includes("(429)")) {
      return "Gemini Maps grounding is temporarily over its quota. This request used the curated safety catalogue.";
    }
    if (reason.includes("(404)")) {
      return "The configured Gemini project has no available Maps-grounding model. This request used the curated safety catalogue.";
    }
    if (reason.includes("returned no grounded place IDs")) {
      return "Gemini did not return Maps-grounded place IDs for this search. This request used the curated safety catalogue.";
    }
    return "The current Gemini server key or model could not use Google Maps grounding. This request used the curated safety catalogue.";
  }
  if (reason.includes("Google Places details failed (403)")) {
    return "Live discovery needs a server-side Google Places API key with Places API (New) and billing enabled. This request used the curated safety catalogue.";
  }
  if (reason.includes("Google Places details failed")) {
    return "Google Places Details could not verify the grounded places. Check the server Places API key, Places API (New), and billing. This request used the curated safety catalogue.";
  }
  if (reason.includes("Gemini Maps model") && reason.includes("(403)")) {
    return "Gemini Maps grounding is not allowed by the current server key. This request used the curated safety catalogue.";
  }
  if (reason.includes("Gemini Maps model") && reason.includes("(400)")) {
    return "The current Gemini model or project does not support Google Maps grounding. This request used the curated safety catalogue.";
  }
  if (reason.includes("returned no grounded place IDs")) {
    return "Gemini found no Maps-grounded places for this location. This request used the curated safety catalogue.";
  }
  if (reason.includes("tourist-suitability checks")) {
    return "No live places passed the tourist-suitability checks. This request used the curated safety catalogue.";
  }
  if (
    reason.includes("destinations") ||
    reason.includes("destination_clues") ||
    reason.includes("schema cache")
  ) {
    return "Live places were found but could not be cached in Supabase. This request used the curated safety catalogue.";
  }
  return "Live Maps discovery was temporarily unavailable, so this request used the curated safety catalogue.";
}

function publicGenerationError(error: unknown): string {
  const reason = safeErrorMessage(error);
  if (reason.includes("(403)")) {
    return "Gemini rejected the server API key. Check its API restrictions.";
  }
  if (reason.includes("(429)")) {
    return "Gemini is temporarily over its request limit. Try again shortly.";
  }
  if (reason.includes("(404)")) {
    return "No compatible Gemini model is available for this API key.";
  }
  return "Mission generation failed. Please try again.";
}
