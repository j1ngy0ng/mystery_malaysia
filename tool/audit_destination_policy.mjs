import assert from "node:assert/strict";
import {
  isLogicalTouristDestination,
} from "../supabase/functions/_shared/destination-policy.ts";

assert.equal(
  isLogicalTouristDestination({
    types: ["mosque", "place_of_worship"],
    primaryType: "mosque",
    userRatingCount: 300,
  }),
  false,
);
assert.equal(
  isLogicalTouristDestination({
    types: ["mosque", "historical_landmark", "tourist_attraction"],
    primaryType: "mosque",
    userRatingCount: 300,
  }),
  true,
);
assert.equal(
  isLogicalTouristDestination({
    types: ["fast_food_restaurant", "restaurant"],
    primaryType: "fast_food_restaurant",
    userRatingCount: 5000,
  }),
  false,
);
assert.equal(
  isLogicalTouristDestination({
    types: ["museum", "tourist_attraction"],
    primaryType: "museum",
    userRatingCount: 25,
  }),
  true,
);

console.log("Destination policy audit passed.");
