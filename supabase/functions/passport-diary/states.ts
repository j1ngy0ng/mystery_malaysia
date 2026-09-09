const stateNames = [
  "johor", "kedah", "kelantan", "melaka", "negeri sembilan", "pahang",
  "penang", "perak", "perlis", "sabah", "sarawak", "selangor",
  "terengganu", "kuala lumpur", "putrajaya", "labuan",
];

export function countExploredStates(stamps: { state?: string | null }[]): number {
  const states = stamps.map(({ state }) => {
    const name = (state ?? "").toLowerCase()
      .replace("malacca", "melaka").replace("pulau pinang", "penang");
    return stateNames.find((candidate) => name.includes(candidate));
  });
  return new Set(states.filter((state) => state !== undefined)).size;
}
