import { withSupabase } from "npm:@supabase/server@1.4.1";
import {
  isLogicalTouristDestination,
} from "../_shared/destination-policy.ts";
import {
  openingTimeWarning,
  stopPreview,
} from "../_shared/stop-preview.ts";

const STOPS_PER_MISSION = 3;
const MISSION_OPTIONS = 3;

type MissionInput = {
  origin_latitude: number;
  origin_longitude: number;
  available_minutes: number;
  budget_myr: number;
  maximum_distance_km?: number;
  intended_start_at?: string;
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
  primary_type: string | null;
  opening_hours: Record<string, unknown>;
  facts: unknown;
  daylight_only: boolean;
  capacity_per_slot: number;
  selection_score: number;
  distance_km: number;
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
  currentOpeningHours?: {
    openNow?: boolean;
    weekdayDescriptions?: string[];
  };
  regularOpeningHours?: {
    weekdayDescriptions?: string[];
  };
  accessibilityOptions?: Record<string, boolean>;
  googleMapsUri?: string;
  editorialSummary?: { text?: string };
  generativeSummary?: {
    overview?: { text?: string };
    disclosureText?: { text?: string };
  };
  photos?: Array<{
    name?: string;
    authorAttributions?: Array<{
      displayName?: string;
      uri?: string;
      photoUri?: string;
    }>;
  }>;
};

type DiscoveryResult = {
  candidates: DestinationCandidate[];
  mode: "places_nearby" | "curated_fallback";
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
      minItems: MISSION_OPTIONS,
      maxItems: MISSION_OPTIONS,
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
          tags: { type: "ARRAY", items: { type: "STRING" } },
          destination_ids: {
            type: "ARRAY",
            minItems: STOPS_PER_MISSION,
            maxItems: STOPS_PER_MISSION,
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
          intended_start_at: input.intended_start_at ?? null,
          categories,
          group_type: groupType,
          status: "generating",
        })
        .select("id")
        .single();
      if (requestError) throw requestError;
      requestId = missionRequest.id;

      await expireOldReservations(admin);
      const [historyIds, fullDestinationIds] = await Promise.all([
        loadUserDestinationHistory(admin, userId),
        loadFullDestinationIds(admin),
      ]);
      const excludedIds = new Set([...historyIds, ...fullDestinationIds]);

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

      if (candidates.length < STOPS_PER_MISSION) {
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          discovery_mode: discovery.mode,
          message:
            "Fewer than three new tourist-suitable destinations were found nearby. Try another area or a larger distance.",
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

      if (validated.length !== MISSION_OPTIONS) {
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          message:
            "Gemini could not form three valid mission choices from nearby places.",
        });
      }
      const routeOptimized = await Promise.all(
        validated.map((recommendation) =>
          optimizeRoute(
            recommendation,
            candidates,
            input,
            Deno.env.get("GOOGLE_ROUTES_API_KEY")?.trim() ||
              Deno.env.get("GOOGLE_PLACES_API_KEY")?.trim(),
          )
        ),
      );

      const savedRecommendations = [];
      for (const [index, recommendation] of routeOptimized.entries()) {
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

        await admin.from("recommendation_events").insert({
          request_id: requestId,
          recommendation_id: saved.id,
          event_type: "generated",
          ai_model: geminiResult.model,
          prompt_version: "mission-v5-reusable-preview-stops",
          payload: {
            candidate_count: candidates.length,
            discovery_mode: discovery.mode,
            reused_between_options: candidates.length <
              STOPS_PER_MISSION * MISSION_OPTIONS,
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
          tags: saved.tags,
          recommendation_rank: saved.recommendation_rank,
          stops: destination_ids.length,
          stop_previews: destination_ids.map((id, stopIndex) =>
            stopPreview(
              candidates.find((candidate) => candidate.id === id),
              stopIndex,
            )
          ),
          stop_opening_warnings: destination_ids.map((id) =>
            openingTimeWarning(
              candidates.find((candidate) => candidate.id === id),
              input.intended_start_at,
            )
          ),
        });
      }

      if (savedRecommendations.length !== MISSION_OPTIONS) {
        await admin
          .from("mission_recommendations")
          .delete()
          .eq("request_id", requestId);
        await admin
          .from("mission_requests")
          .update({ status: "no_match" })
          .eq("id", requestId);
        return Response.json({
          request_id: requestId,
          recommendations: [],
          discovery_mode: discovery.mode,
          message: "Three complete mission choices could not be prepared.",
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
          prompt_version: "mission-v5-reusable-preview-stops",
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

async function loadFullDestinationIds(
  admin: any,
): Promise<Set<string>> {
  const [{ data: allocations, error: allocationError }, {
    data: destinations,
    error: destinationError,
  }] = await Promise.all([
    admin
      .from("destination_allocations")
      .select("destination_id")
      .in("status", ["reserved", "active"]),
    admin
      .from("destinations")
      .select("id,capacity_per_slot")
      .eq("active", true),
  ]);
  if (allocationError) throw allocationError;
  if (destinationError) throw destinationError;

  const counts = new Map<string, number>();
  for (const item of allocations ?? []) {
    counts.set(
      item.destination_id,
      (counts.get(item.destination_id) ?? 0) + 1,
    );
  }
  return new Set(
    (destinations ?? [])
      .filter((item: { id: string; capacity_per_slot: number }) =>
        (counts.get(item.id) ?? 0) >= item.capacity_per_slot
      )
      .map((item: { id: string }) => item.id),
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
    let details: PlaceDetails[];
    try {
      details = await searchNearbyPlaces({
        apiKey: Deno.env.get("GOOGLE_PLACES_API_KEY")?.trim() || apiKey,
        input,
        categories,
        maximumDistanceKm,
      });
    } catch (error) {
      throw new Error(`places_nearby: ${safeErrorMessage(error)}`);
    }

    let dynamicCandidates: DestinationCandidate[];
    try {
      dynamicCandidates = await cacheEligiblePlaces({
        admin,
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
        mode: "places_nearby",
      };
    }
    throw new Error(
      "Nearby Search returned no places that passed tourist-suitability checks.",
    );
  } catch (error) {
    const warning = safeErrorMessage(error);
    console.warn("Places discovery unavailable; using curated cache:", warning);
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

async function searchNearbyPlaces({
  apiKey,
  input,
  categories,
  maximumDistanceKm,
}: {
  apiKey: string;
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
}): Promise<PlaceDetails[]> {
  const categoryTypes: Record<string, string[]> = {
    Culture: [
      "museum",
      "art_gallery",
      "cultural_landmark",
    ],
    Food: ["farmers_market", "flea_market", "market"],
    Nature: [
      "park",
      "botanical_garden",
      "hiking_area",
      "nature_preserve",
      "scenic_spot",
    ],
    History: [
      "historical_landmark",
      "historical_place",
      "museum",
      "monument",
    ],
    "Hidden gems": [
      "tourist_attraction",
      "scenic_spot",
      "cultural_landmark",
    ],
  };
  const broadTypes = [
    "museum",
    "art_gallery",
    "park",
    "tourist_attraction",
    "historical_landmark",
    "historical_place",
    "cultural_landmark",
    "botanical_garden",
    "hiking_area",
    "nature_preserve",
    "scenic_spot",
  ];
  const requestedTypes = [...new Set(
    categories.flatMap((category) => categoryTypes[category] ?? []),
  )];
  const searchGroups = requestedTypes.length > 0
    ? [requestedTypes, broadTypes]
    : [broadTypes];
  const fieldMask = [
    "places.id",
    "places.displayName",
    "places.formattedAddress",
    "places.addressComponents",
    "places.location",
    "places.types",
    "places.primaryType",
    "places.businessStatus",
    "places.rating",
    "places.userRatingCount",
    "places.currentOpeningHours",
    "places.regularOpeningHours",
    "places.accessibilityOptions",
    "places.googleMapsUri",
    "places.editorialSummary",
    "places.generativeSummary",
    "places.photos",
  ].join(",");
  const radiusMetres = Math.min(maximumDistanceKm * 1000, 50000);

  const searches = await Promise.allSettled(
    searchGroups.map(async (types) => {
      const response = await fetch(
        "https://places.googleapis.com/v1/places:searchNearby",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask": fieldMask,
          },
          body: JSON.stringify({
            includedTypes: types,
            excludedTypes: [
              "bar",
              "night_club",
              "lodging",
              "hospital",
              "school",
              "restaurant",
              "fast_food_restaurant",
              "cafe",
              "coffee_shop",
              "food_court",
              "meal_takeaway",
              "meal_delivery",
              "shopping_mall",
              "supermarket",
              "convenience_store",
              "apartment_building",
              "apartment_complex",
              "condominium_complex",
              "housing_complex",
            ],
            maxResultCount: 20,
            rankPreference: "DISTANCE",
            locationRestriction: {
              circle: {
                center: {
                  latitude: input.origin_latitude,
                  longitude: input.origin_longitude,
                },
                radius: radiusMetres,
              },
            },
            languageCode: "en",
            regionCode: "MY",
          }),
        },
      );
      if (!response.ok) {
        throw new Error(
          `Google Places Nearby Search failed (${response.status}): ${
            await googleErrorDetail(response)
          }`,
        );
      }
      const payload = await response.json();
      return Array.isArray(payload?.places)
        ? payload.places as PlaceDetails[]
        : [];
    }),
  );

  const unique = new Map<string, PlaceDetails>();
  for (const result of searches) {
    if (result.status !== "fulfilled") continue;
    for (const place of result.value) {
      const placeId = normalizePlaceId(place.id);
      if (placeId && !unique.has(placeId)) unique.set(placeId, place);
    }
  }
  if (unique.size === 0) {
    const failure = searches.find(
      (result): result is PromiseRejectedResult =>
        result.status === "rejected",
    );
    throw failure?.reason ?? new Error("Nearby Search returned no places.");
  }
  return [...unique.values()];
}

async function cacheEligiblePlaces({
  admin,
  details,
  input,
  categories,
  maximumDistanceKm,
  excludedIds,
  requestId,
  userId,
}: {
  admin: any;
  details: PlaceDetails[];
  input: MissionInput;
  categories: string[];
  maximumDistanceKm: number;
  excludedIds: Set<string>;
  requestId: string;
  userId: string;
}): Promise<DestinationCandidate[]> {
  const eligibleRows = details.flatMap((place) => {
    const latitude = place.location?.latitude;
    const longitude = place.location?.longitude;
    const placeId = normalizePlaceId(place.id);
    if (
      !placeId ||
      typeof latitude !== "number" ||
      typeof longitude !== "number" ||
      place.businessStatus !== "OPERATIONAL" ||
      !isLogicalTouristDestination(place)
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
      0.10 * categoryMatch -
      (place.currentOpeningHours?.openNow === false ? 0.15 : 0);
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
    const educationalFacts = [
      place.editorialSummary?.text,
      place.generativeSummary?.overview?.text,
    ]
      .filter((fact): fact is string => Boolean(fact?.trim()));
    const openingHours = {
      openNow: place.currentOpeningHours?.openNow,
      weekdayDescriptions:
        place.regularOpeningHours?.weekdayDescriptions ??
          place.currentOpeningHours?.weekdayDescriptions ??
          [],
      source: "Google Places",
    };

    return [{
      external_place_id: `google:${placeId}`,
      name: cleanText(
        place.displayName?.text,
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
      opening_hours: openingHours,
      accessibility: place.accessibilityOptions ?? {},
      visitor_information: {
        formatted_address: place.formattedAddress,
        verification: "Google Places",
        cultural_etiquette: culturalEtiquette(place.types ?? []),
        safety_notes: safetyGuidance(place.types ?? [], daylightOnly),
        educational_source: educationalFacts.length > 0
          ? "Google Places summary"
          : "Verified Google Places attributes",
        summary_disclosure: place.generativeSummary?.disclosureText?.text,
        photo_name: place.photos?.[0]?.name,
        photo_attributions: place.photos?.[0]?.authorAttributions ?? [],
      },
      facts: educationalFacts,
      popularity_score: popularityIndex(ratingCount),
      active: true,
      google_maps_uri: place.googleMapsUri ?? null,
      formatted_address: place.formattedAddress ?? null,
      primary_type: place.primaryType ?? null,
      google_rating: rating,
      google_user_rating_count: ratingCount,
      business_status: place.businessStatus,
      safety_status: "automated_review",
      safety_score: roundScore(safetyScore),
      discovery_score: roundScore(discoveryScore),
      capacity_per_slot: destinationCapacity(
        place.types ?? [],
        ratingCount,
      ),
      daylight_only: daylightOnly,
      source_metadata: {
        source: "google_places_nearby",
        discovered_by: "google_places",
        google_place_id: placeId,
        suitability_note:
          "Automated tourist-suitability signal; not a guarantee of personal safety.",
        request_id: requestId,
        requested_by_user_id: userId,
        google_types: place.types ?? [],
        primary_type: place.primaryType ?? null,
        has_place_summary: educationalFacts.length > 0,
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
        "google_rating,google_user_rating_count,safety_score,discovery_score," +
        "capacity_per_slot,primary_type,opening_hours,facts,daylight_only",
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
    return {
      destination_id: row.id,
      clue_type: "observation",
      title: "Find this exact hidden stop",
      prompt: obviousDestinationClue(source),
      accepted_answers: [],
      validation_rules: {
        verification: "location",
        radius_metres: 120,
      },
      hint_text: additionalDestinationHint(source),
      clue_xp_reward: 0,
      hint_xp_cost: 0,
      ai_model: null,
      prompt_version: "places-specific-no-address-v3",
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
        "capacity_per_slot,safety_status,primary_type,source_metadata," +
        "opening_hours,facts,daylight_only," +
        "destination_clues!inner(destination_id)",
    )
    .eq("active", true)
    .in("safety_status", ["automated_review", "curated"]);
  if (error) throw error;

  return (rows ?? [])
    .filter((row: { id: string }) => !excludedIds.has(row.id))
    .filter(isStoredLogicalDestination)
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
    `Create exactly ${MISSION_OPTIONS} varied recommendations with exactly ${STOPS_PER_MISSION} unique stops each.`,
    candidates.length >= STOPS_PER_MISSION * MISSION_OPTIONS
      ? "Use nine different destination IDs across the full recommendation list; do not reuse a destination between mission choices."
      : `Only ${candidates.length} valid destinations are available. Reuse destination IDs between mission choices only as needed, maximize variety, and never repeat a destination inside the same mission.`,
    `User constraints: ${JSON.stringify({
      available_minutes: input.available_minutes,
      budget_myr: input.budget_myr,
      maximum_distance_km: maximumDistanceKm,
      intended_start_at: input.intended_start_at,
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

function categoriesForPlace(types: string[]): string[] {
  const categories = new Set<string>();
  for (const type of types) {
    if (
      [
        "museum",
        "art_gallery",
        "cultural_landmark",
        "historical_landmark",
        "historical_place",
        "place_of_worship",
        "mosque",
        "church",
        "hindu_temple",
        "buddhist_temple",
        "synagogue",
      ].includes(type)
    ) {
      categories.add("Culture");
    }
    if (["historical_landmark", "historical_place", "monument"].includes(type)) {
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
        "farmers_market",
        "flea_market",
        "market",
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

function isStoredLogicalDestination(row: any): boolean {
  if (row.safety_status === "curated") return true;
  const metadata = row.source_metadata ?? {};
  const googleTypes = Array.isArray(metadata.google_types)
    ? metadata.google_types.filter((type: unknown): type is string =>
      typeof type === "string"
    )
    : [];
  if (googleTypes.length === 0) {
    googleTypes.push(row.primary_type ?? "");
  }
  return isLogicalTouristDestination({
    types: googleTypes,
    primaryType: row.primary_type ?? undefined,
    userRatingCount: row.google_user_rating_count ?? undefined,
    editorialSummary: metadata.has_place_summary
      ? { text: "Available" }
      : undefined,
  });
}

function estimatedBudget(types: string[]): number {
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
  return 60;
}

function destinationCapacity(types: string[], ratingCount: number): number {
  let capacity = 3;
  if (
    types.some((type) =>
      [
        "park",
        "botanical_garden",
        "nature_preserve",
        "hiking_area",
        "scenic_spot",
      ].includes(type)
    )
  ) {
    capacity = 7;
  } else if (
    types.some((type) =>
      ["museum", "market", "tourist_attraction"].includes(type)
    )
  ) {
    capacity = 5;
  }

  // A small evidence footprint may also indicate a small venue.
  if (ratingCount < 20) capacity = Math.min(capacity, 3);
  if (ratingCount >= 1000) capacity += 1;
  return Math.round(clamp(capacity, 2, 8));
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

function culturalEtiquette(types: string[]): string[] {
  if (
    types.some((type) =>
      [
        "place_of_worship",
        "mosque",
        "church",
        "hindu_temple",
        "buddhist_temple",
        "synagogue",
      ].includes(type)
    )
  ) {
    return [
      "Dress modestly and follow the venue's posted visitor rules.",
      "Remove footwear where requested and avoid interrupting worship.",
      "Ask before photographing people, ceremonies or restricted interiors.",
    ];
  }
  if (
    types.some((type) =>
      ["museum", "art_gallery", "cultural_landmark"].includes(type)
    )
  ) {
    return [
      "Follow photography signs and do not touch exhibits unless invited.",
      "Keep voices low around guided visits, ceremonies and learning spaces.",
    ];
  }
  if (types.some((type) => ["market", "neighborhood"].includes(type))) {
    return [
      "Respect residents, vendors and private property.",
      "Ask permission before photographing people or stalls at close range.",
    ];
  }
  if (
    types.some((type) =>
      ["park", "hiking_area", "nature_preserve"].includes(type)
    )
  ) {
    return [
      "Stay on marked paths, carry out litter and do not feed wildlife.",
      "Give other visitors space and keep noise low in natural areas.",
    ];
  }
  return [
    "Follow posted rules and ask permission before photographing people.",
    "Treat staff, residents, worshippers and other visitors respectfully.",
  ];
}

function safetyGuidance(
  types: string[],
  daylightOnly: boolean,
): string[] {
  const notes = [
    "Visit during published operating hours and follow current staff or site notices.",
    "Keep valuables secure and use marked pedestrian crossings near traffic.",
    "Public ratings and automated suitability checks do not guarantee personal safety.",
  ];
  if (daylightOnly) {
    notes.unshift(
      "Plan this outdoor stop for daylight and check weather conditions before entering.",
      "Carry water, use suitable footwear and remain on public or marked paths.",
    );
  }
  if (
    types.some((type) =>
      ["market", "tourist_attraction", "place_of_worship"].includes(type)
    )
  ) {
    notes.push(
      "Expect busy periods; keep your group together and use designated entrances.",
    );
  }
  return notes;
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

function obviousDestinationClue(
  destination?: {
    name?: string;
    city?: string;
    state?: string;
    primary_type?: string;
  },
): string {
  const name = destination?.name?.trim() || "this destination";
  const type = friendlyPlaceType(destination?.primary_type);
  const area = destination?.city?.trim() || destination?.state?.trim() ||
    "your nearby area";
  const words = destinationNameWords(name);
  const initials = words.map((word) => word[0].toUpperCase()).join(" • ");
  const namePattern = words.length > 1
    ? `Its ${words.length}-word official name has the initials “${initials}”.`
    : `Its official name has ${[...name].length} characters, starts with “${
      name[0].toUpperCase()
    }” and ends with “${name.at(-1)?.toUpperCase()}”.`;
  return `Seek a ${type} in ${area}. ${namePattern} ` +
    "Follow the Hot & Cold signal and look for matching visitor signage.";
}

function additionalDestinationHint(
  destination?: { name?: string },
): string {
  const name = destination?.name?.trim() || "";
  const words = destinationNameWords(name);
  if (words.length > 1) {
    return `The destination name has ${words.length} words and ends with “${
      words.at(-1)
    }”.`;
  }
  return name
    ? `The destination name has ${[...name].length} characters and starts with “${
      name[0].toUpperCase()
    }”. Look for its official visitor sign nearby.`
    : "Look for the official visitor entrance as the Hot & Cold signal strengthens.";
}

function destinationNameWords(name: string): string[] {
  return name
    .split(/\s+/)
    .map((word) => word.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, ""))
    .filter(Boolean);
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

export function validateRecommendations(
  generated: GeneratedRecommendation[],
  candidates: DestinationCandidate[],
  input: MissionInput,
): GeneratedRecommendation[] {
  const allowedIds = new Set(candidates.map((candidate) => candidate.id));
  const candidateOrder = new Map(
    candidates.map((candidate, index) => [candidate.id, index]),
  );
  const usageCounts = new Map<string, number>();
  const results: GeneratedRecommendation[] = [];

  for (const item of generated.slice(0, MISSION_OPTIONS)) {
    if (!item || typeof item !== "object") continue;
    const requestedIds = [...new Set(item.destination_ids ?? [])]
      .filter((id) => allowedIds.has(id));
    const requestedOrder = new Map(
      requestedIds.map((id, index) => [id, index]),
    );
    const destinationIds = candidates
      .map((candidate) => candidate.id)
      .sort((left, right) =>
        (usageCounts.get(left) ?? 0) - (usageCounts.get(right) ?? 0) ||
        Number(!requestedOrder.has(left)) - Number(!requestedOrder.has(right)) ||
        (requestedOrder.get(left) ?? Number.MAX_SAFE_INTEGER) -
          (requestedOrder.get(right) ?? Number.MAX_SAFE_INTEGER) ||
        (candidateOrder.get(left) ?? 0) - (candidateOrder.get(right) ?? 0)
      )
      .slice(0, STOPS_PER_MISSION);
    if (destinationIds.length !== STOPS_PER_MISSION) continue;
    destinationIds.forEach((id) =>
      usageCounts.set(id, (usageCounts.get(id) ?? 0) + 1)
    );

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
    input.intended_start_at !== undefined &&
    Number.isNaN(Date.parse(input.intended_start_at))
  ) {
    throw new Error("intended_start_at is invalid.");
  }
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

async function optimizeRoute(
  recommendation: GeneratedRecommendation,
  candidates: DestinationCandidate[],
  input: MissionInput,
  apiKey?: string,
): Promise<GeneratedRecommendation> {
  if (!apiKey || recommendation.destination_ids.length !== 3) {
    return recommendation;
  }
  const stops = recommendation.destination_ids.map((id) =>
    candidates.find((candidate) => candidate.id === id)
  );
  if (stops.some((stop) => !stop)) return recommendation;
  const waypoint = (latitude: number, longitude: number) => ({
    waypoint: { location: { latLng: { latitude, longitude } } },
  });
  try {
    const response = await fetch(
      "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask":
            "originIndex,destinationIndex,status,condition,distanceMeters,duration",
        },
        body: JSON.stringify({
          origins: [
            waypoint(input.origin_latitude, input.origin_longitude),
            ...stops.map((stop) => waypoint(stop!.latitude, stop!.longitude)),
          ],
          destinations: stops.map((stop) =>
            waypoint(stop!.latitude, stop!.longitude)
          ),
          travelMode: "DRIVE",
          routingPreference: "TRAFFIC_AWARE",
        }),
      },
    );
    if (!response.ok) return recommendation;
    const elements = await response.json();
    if (!Array.isArray(elements)) return recommendation;
    const metres = new Map<string, number>();
    for (const element of elements) {
      if (
        element.condition === "ROUTE_EXISTS" &&
        typeof element.distanceMeters === "number"
      ) {
        metres.set(
          `${element.originIndex}:${element.destinationIndex}`,
          element.distanceMeters,
        );
      }
    }
    const permutations = [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ];
    let best = permutations[0];
    let bestMetres = Number.POSITIVE_INFINITY;
    for (const order of permutations) {
      const total = (metres.get(`0:${order[0]}`) ?? Infinity) +
        (metres.get(`${order[0] + 1}:${order[1]}`) ?? Infinity) +
        (metres.get(`${order[1] + 1}:${order[2]}`) ?? Infinity);
      if (total < bestMetres) {
        bestMetres = total;
        best = order;
      }
    }
    if (!Number.isFinite(bestMetres)) return recommendation;
    return {
      ...recommendation,
      destination_ids: best.map((index) =>
        recommendation.destination_ids[index]
      ),
      total_distance_km: Math.round(bestMetres / 10) / 100,
    };
  } catch {
    return recommendation;
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
  if (reason.startsWith("supabase_cache:")) {
    return "Live places were verified but could not be cached in Supabase. This request used the curated safety catalogue.";
  }
  if (reason.startsWith("places_nearby:")) {
    if (reason.includes("(403)")) {
      return "Live discovery needs a server-side GOOGLE_PLACES_API_KEY with Places API (New) and billing enabled. This request used the curated safety catalogue.";
    }
    if (reason.includes("(429)")) {
      return "Google Places is temporarily over its request quota. This request used the curated safety catalogue.";
    }
    return "Google Places Nearby Search was unavailable. Check the server Places key and API restrictions. This request used the curated safety catalogue.";
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
  return "Live Places discovery was temporarily unavailable, so this request used the curated safety catalogue.";
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
