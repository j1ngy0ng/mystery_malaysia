import assert from "node:assert/strict";
import { countExploredStates } from "./states.ts";

assert.equal(countExploredStates([
  { state: "Kuala Lumpur" },
  { state: "Wilayah Persekutuan Kuala Lumpur" },
  { state: " Federal Territory of KUALA LUMPUR " },
]), 1);
assert.equal(countExploredStates([
  { state: "Kuala Lumpur" },
  { state: "Penang" },
  { state: "Pulau Pinang" },
  { state: "Malacca" },
  { state: "Melaka" },
  { state: "Malaysia" },
  { state: null },
  {},
]), 3);
assert.equal(countExploredStates([]), 0);
