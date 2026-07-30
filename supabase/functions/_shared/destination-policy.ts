export type PlaceForPolicy = {
  types?: string[];
  primaryType?: string;
  userRatingCount?: number;
  editorialSummary?: { text?: string };
  generativeSummary?: { overview?: { text?: string } };
};

const routineTypes = new Set([
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
  "apartment_complex",
  "condominium_complex",
  "housing_complex",
  "shopping_mall",
  "supermarket",
  "convenience_store",
  "food_court",
  "fast_food_restaurant",
  "restaurant",
  "cafe",
  "coffee_shop",
  "meal_takeaway",
  "meal_delivery",
]);

const worshipTypes = new Set([
  "place_of_worship",
  "mosque",
  "church",
  "hindu_temple",
  "buddhist_temple",
  "synagogue",
  "shinto_shrine",
]);

const heritageSignals = new Set([
  "tourist_attraction",
  "cultural_landmark",
  "historical_landmark",
  "historical_place",
  "monument",
  "museum",
]);

const tourismTypes = new Set([
  ...heritageSignals,
  "art_gallery",
  "art_museum",
  "history_museum",
  "castle",
  "performing_arts_theater",
  "cultural_center",
  "amphitheatre",
  "aquarium",
  "botanical_garden",
  "hiking_area",
  "national_park",
  "observation_deck",
  "planetarium",
  "plaza",
  "state_park",
  "visitor_center",
  "wildlife_park",
  "wildlife_refuge",
  "zoo",
  "beach",
  "island",
  "mountain_peak",
  "nature_preserve",
  "scenic_spot",
]);

export function hasExcludedPlaceType(types: string[]): boolean {
  return types.some((type) =>
    routineTypes.has(type) ||
    type.endsWith("_restaurant") ||
    type.endsWith("_cafe")
  );
}

export function isLogicalTouristDestination(
  place: PlaceForPolicy,
): boolean {
  const types = new Set(place.types ?? []);
  if (place.primaryType) types.add(place.primaryType);
  if (hasExcludedPlaceType([...types])) return false;

  const isWorship = [...types].some((type) => worshipTypes.has(type));
  const hasHeritageSignal = [...types].some((type) =>
    heritageSignals.has(type)
  );
  if (isWorship) return hasHeritageSignal;

  if ([...types].some((type) => tourismTypes.has(type))) return true;

  const hasSummary = Boolean(
    place.editorialSummary?.text?.trim() ||
      place.generativeSummary?.overview?.text?.trim(),
  );
  const ratingCount = place.userRatingCount ?? 0;
  if (types.has("park")) return hasSummary && ratingCount >= 100;
  if (types.has("farmers_market") || types.has("flea_market")) {
    return hasSummary && ratingCount >= 50;
  }
  return false;
}
