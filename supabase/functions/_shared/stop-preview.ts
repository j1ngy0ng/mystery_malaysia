export type PreviewDestination = {
  id: string;
  name?: string | null;
  city?: string | null;
  state?: string | null;
  primary_type?: string | null;
  categories?: string[] | null;
  facts?: unknown;
  estimated_duration_minutes?: number | null;
  opening_hours?: unknown;
  daylight_only?: boolean | null;
};

export function stopPreview(
  destination: PreviewDestination | undefined,
  variantIndex?: number,
): string {
  if (!destination) {
    return "A distinctive Malaysian experience with its own story and atmosphere.";
  }

  const fact = Array.isArray(destination.facts)
    ? destination.facts.find((item): item is string =>
      typeof item === "string" && item.trim().length >= 35
    )
    : null;
  if (fact) {
    const redacted = redactIdentity(fact, destination);
    if (redacted.length >= 35) {
      const minutes = Math.max(
        30,
        Number(destination.estimated_duration_minutes ?? 60),
      );
      const variants = [
        `${redacted} Set aside about ${minutes} minutes to explore its defining details.`,
        `Look beyond the obvious here: ${lowerFirst(redacted)} A ${minutes}-minute visit should leave room for discovery.`,
        `What gives this stop its character? ${redacted} Plan roughly ${minutes} minutes on site.`,
        `The atmosphere is part of the puzzle: ${lowerFirst(redacted)} Explore at an unhurried pace for about ${minutes} minutes.`,
      ];
      return limit(
        variants[(variantIndex ?? hash(destination.id)) % variants.length],
        320,
      );
    }
  }

  const themes = (destination.categories ?? [])
    .map((item) => item.replaceAll("_", " ").trim().toLowerCase())
    .filter(Boolean)
    .slice(0, 3);
  const focus = themes.length > 0
    ? naturalList(themes)
    : (destination.primary_type ?? "local discovery").replaceAll("_", " ");
  const minutes = Math.max(
    30,
    Number(destination.estimated_duration_minutes ?? 60),
  );
  const variants = [
    `Trace the character of this hidden stop through ${focus}; allow about ${minutes} minutes to notice its defining details.`,
    `This ${focus} experience rewards careful observation and a slower pace, with roughly ${minutes} minutes suggested for exploring.`,
    `Expect a distinctly Malaysian encounter shaped by ${focus}. Its atmosphere is best absorbed over about ${minutes} minutes.`,
    `Your next clue leads to an experience centred on ${focus}, where the surroundings matter as much as the discovery. Plan ${minutes} minutes.`,
  ];
  return variants[(variantIndex ?? hash(destination.id)) % variants.length];
}

export function openingTimeWarning(
  destination: PreviewDestination | undefined,
  intendedStartAt?: string | null,
): string {
  const hours = asRecord(destination?.opening_hours);
  const descriptions = (
    hours?.weekdayDescriptions ?? hours?.weekday_descriptions
  );
  const weekly = Array.isArray(descriptions)
    ? descriptions.filter((item): item is string =>
      typeof item === "string" && item.trim().length > 0
    )
    : [];
  const day = intendedStartAt ? malaysiaWeekday(intendedStartAt) : null;
  const matching = day
    ? weekly.find((item) => item.toLowerCase().startsWith(day.toLowerCase()))
    : null;
  const schedule = matching ?? (weekly.length === 1 ? weekly[0] : null);

  if (destination?.daylight_only) {
    return schedule
      ? `Opening-time warning: ${schedule}. Complete this outdoor stop in daylight and recheck for closures.`
      : "Opening-time warning: Complete this outdoor stop in daylight and check current access notices before departure.";
  }
  if (schedule) {
    return `Opening-time warning: ${schedule}. Public-holiday or temporary closures may differ, so check again before departure.`;
  }
  return "Opening-time warning: Published hours are unavailable. Check the official listing before departure.";
}

function redactIdentity(
  source: string,
  destination: PreviewDestination,
): string {
  let result = source.replace(/https?:\/\/\S+/gi, "").replace(/\s+/g, " ")
    .trim();
  for (const identity of [destination.name, destination.city, destination.state]) {
    if (!identity?.trim()) continue;
    result = result.replace(
      new RegExp(escapeRegExp(identity.trim()), "gi"),
      "this hidden stop",
    );
  }
  return result.replace(/\bthis hidden stop\b(?:\s+this hidden stop\b)+/gi, "this hidden stop");
}

function malaysiaWeekday(value: string): string | null {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    timeZone: "Asia/Kuala_Lumpur",
  }).format(date);
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function naturalList(items: string[]): string {
  if (items.length < 2) return items[0] ?? "local discovery";
  if (items.length === 2) return `${items[0]} and ${items[1]}`;
  return `${items[0]}, ${items[1]} and ${items[2]}`;
}

function lowerFirst(value: string): string {
  return value.length === 0
    ? value
    : `${value[0].toLowerCase()}${value.slice(1)}`;
}

function hash(value: string): number {
  let result = 0;
  for (const character of value) {
    result = (result * 31 + character.charCodeAt(0)) >>> 0;
  }
  return result;
}

function limit(value: string, maximum: number): string {
  if (value.length <= maximum) return value;
  const shortened = value.slice(0, maximum - 1).replace(/\s+\S*$/, "").trim();
  return `${shortened}…`;
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
