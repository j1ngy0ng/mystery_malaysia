import assert from "node:assert/strict";

import {
  additionalDestinationHint,
  isWithinMalaysiaBounds,
  surroundingsDestinationClue,
  validateRecommendations,
} from "./index.ts";

const input = {
  origin_latitude: 3.1424,
  origin_longitude: 101.7168,
  available_minutes: 240,
  budget_myr: 100,
};

function candidates(count: number) {
  return Array.from({ length: count }, (_, index) => ({ id: `d${index}` }));
}

function generated() {
  return Array.from({ length: 3 }, (_, index) => ({
    title: `Mission ${index + 1}`,
    story_hook: "A mystery awaits.",
    explanation: "Follow the clues.",
    estimated_duration_minutes: 120,
    estimated_budget_myr: 30,
    total_distance_km: 5,
    difficulty: "easy" as const,
    tags: ["mystery"],
    destination_ids: ["d0", "d1", "d2"],
  }));
}

Deno.test("mission options reuse stops only when the candidate pool requires it", () => {
  for (const candidateCount of [3, 8, 9]) {
    const result = validateRecommendations(
      generated(),
      candidates(candidateCount) as never,
      input,
    );
    assert.equal(result.length, 3);
    for (const mission of result) {
      assert.equal(mission.destination_ids.length, 3);
      assert.equal(new Set(mission.destination_ids).size, 3);
    }
    assert.equal(
      new Set(result.flatMap((mission) => mission.destination_ids)).size,
      Math.min(candidateCount, 9),
    );
  }
});

Deno.test("rejects coordinates outside Malaysia's geographic regions", () => {
  assert.equal(isWithinMalaysiaBounds(3.139, 101.6869), true);
  assert.equal(isWithinMalaysiaBounds(5.9804, 116.0735), true);
  assert.equal(isWithinMalaysiaBounds(51.5072, -0.1276), false);
});

Deno.test("stages destination identity after the surroundings clue", () => {
  const clue = surroundingsDestinationClue({
    city: "Melaka",
    primary_type: "historical_landmark",
  });
  assert.match(clue, /heritage details/i);
  assert.doesNotMatch(clue, /M\s*[•.]\s*S/i);

  assert.equal(
    additionalDestinationHint({ name: "Melaka Sultanate Palace Museum" }),
    "The destination name has 4 words. Its initials are “M • S • P • M”, and its final word is “Museum”.",
  );
  assert.equal(
    additionalDestinationHint({ name: "Saloma" }),
    "The destination name has 6 characters and starts with “S”. Look for its official visitor sign nearby.",
  );
});
