import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export const VERTICALS = ["calendar_genius", "constellation_mapper", "discovery"] as const;
export type VerticalId = typeof VERTICALS[number];
export type SourceType = "curated" | "predicted" | "created";
export type PathType = "accelerated" | "standard" | "supported";
export type Modality = "visual" | "audio" | "animated" | "interactive";

export interface Engine1Config {
  sensory: Record<string, unknown>;
  layoutComplexityTier: "simple" | "standard" | "complex";
  activeVerticals: VerticalId[];
  hyperFocusTheme: string;
}

export interface TaskCandidate {
  verticalId: VerticalId;
  layer: number;
  sourceType: SourceType;
  difficultyTier: "baseline" | "progressive" | "advanced";
  modality: Modality;
  payload: Record<string, unknown>;
  answerKey: Record<string, unknown>;
  ruleVersion: string;
}

export interface ScoredResponse {
  accuracy: number;
  latencyMs: number;
  recovery: number;
  engagement: number;
  speed: number;
  isolationScore: number;
}

const SOURCE_CONFIDENCE: Record<SourceType, number> = {
  curated: 1,
  predicted: 0.95,
  created: 0.9,
};

const FORBIDDEN = [
  "diagnos",
  "autis",
  "disorder",
  "condition",
  "career",
  "job",
  "employ",
  "industry",
  "salary",
  "income",
  "assessment",
  "screening",
  "prediction",
];

const clamp = (value: number, min = 0, max = 1): number =>
  Math.max(min, Math.min(max, value));

export function confidenceFor(source: SourceType): number {
  return SOURCE_CONFIDENCE[source];
}

export function sanitizeText(value: string): string {
  const lower = value.toLowerCase();
  if (FORBIDDEN.some((term) => lower.includes(term))) {
    throw new Error("Generated task contains prohibited language.");
  }
  return value;
}

export function assertSafePayload(
  payload: Record<string, unknown>,
): Record<string, unknown> {
  const text = JSON.stringify(payload);
  sanitizeText(text);
  if (text.length > 20_000) {
    throw new Error("Task payload exceeds the size limit.");
  }
  return payload;
}

export async function contentHash(value: unknown): Promise<string> {
  const encoded = new TextEncoder().encode(JSON.stringify(value));
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return Array.from(new Uint8Array(digest)).map((b) =>
    b.toString(16).padStart(2, "0")
  ).join("");
}

export function pathForIsolation(
  isolationScore: number,
  recovery: number,
): PathType {
  if (recovery < 0.45) return "supported";
  if (isolationScore >= 0.75) return "accelerated";
  if (isolationScore >= 0.45) return "standard";
  return "supported";
}

export function pathLayers(path: PathType): number[] {
  if (path === "accelerated") return [2, 3, 7, 10];
  if (path === "supported") return [2, 5, 3, 4, 6, 7, 8, 9, 10];
  return [2, 3, 4, 5, 6, 7, 8, 9, 10];
}

export function requiredExecutions(layer: number): number {
  if (layer === 4) return 4;
  if (layer === 9) return 3;
  return 1;
}

export function normalizeModality(value: unknown): Modality {
  return value === "audio" || value === "animated" || value === "interactive"
    ? value
    : "visual";
}

export function scoreResponse(
  accuracy: number,
  latencyMs: number,
  retryCount: number,
  hintUsage: number,
  skipped: boolean,
  source: SourceType,
): ScoredResponse {
  const numericAccuracy = Number(accuracy);
  const normalizedAccuracy = Number.isFinite(numericAccuracy)
    ? clamp(numericAccuracy)
    : 0;
  const numericLatency = Number(latencyMs);
  const safeLatency = Number.isFinite(numericLatency)
    ? Math.max(0, numericLatency)
    : 0;
  const numericRetries = Number(retryCount);
  const safeRetries = Number.isFinite(numericRetries)
    ? Math.max(0, numericRetries)
    : 0;
  const recovery = skipped ? 0.35 : clamp(1 - Math.min(safeRetries, 5) / 5);
  const engagement = skipped
    ? 0.1
    : clamp(0.55 + (normalizedAccuracy * 0.25) + (hintUsage > 0 ? 0.05 : 0.15));
  const speed = clamp(1 - safeLatency / 60_000);
  const base = (0.4 * normalizedAccuracy) + (0.3 * recovery) +
    (0.2 * engagement) + (0.1 * speed);
  return {
    accuracy: normalizedAccuracy,
    latencyMs: safeLatency,
    recovery,
    engagement,
    speed,
    isolationScore: clamp(base * confidenceFor(source)),
  };
}

export function evaluateAnswer(
  task: Record<string, unknown>,
  response: unknown,
): number {
  const answerKey = (task.answer_key ?? {}) as Record<string, unknown>;
  if (typeof answerKey.expected === "string") {
    return String(response ?? "").trim().toLowerCase() ===
        answerKey.expected.toLowerCase()
      ? 1
      : 0;
  }
  if (typeof answerKey.requiredCount === "number") {
    const selected = parseSelectedStarIds(response);
    if (!selected) return 0;
    const publicPayload = (task.public_payload ?? task) as Record<
      string,
      unknown
    >;
    const stars = Array.isArray(publicPayload.stars)
      ? publicPayload.stars
      : null;
    if (stars && selected.some((id) => id >= stars.length)) return 0;
    return selected.length === answerKey.requiredCount ? 1 : 0;
  }
  if (typeof answerKey.expected === "boolean") {
    return response === answerKey.expected ? 1 : 0;
  }
  return 0;
}

/**
 * Parses the stable response format emitted by the constellation widget.
 * Duplicate or out-of-band indices are rejected before scoring so a client
 * cannot turn a malformed response into a passing count.
 */
export function parseSelectedStarIds(response: unknown): number[] | null {
  if (
    typeof response !== "string" || !response.startsWith("connected_stars_")
  ) return null;
  const suffix = response.slice("connected_stars_".length);
  if (!suffix) return null;
  const ids = suffix.split("_");
  if (ids.some((id) => !/^(0|[1-9]\d*)$/.test(id))) return null;
  const parsed = ids.map((id) => Number(id));
  if (
    parsed.some((id) => !Number.isSafeInteger(id)) ||
    new Set(parsed).size !== parsed.length
  ) return null;
  return parsed;
}

export function supportTransition(
  current: number,
  input: {
    accuracy: number;
    latencyMs: number;
    retryCount: number;
    skipped: boolean;
    path: PathType;
  },
): { level: number; reason: string | null } {
  const highFriction = input.skipped ||
    (input.latencyMs >= 45_000 && input.retryCount >= 2);
  const miss = input.accuracy < 0.5;
  if (current < 5 && (highFriction || miss)) {
    if (current === 0 && input.path === "supported" && miss) {
      return { level: 2, reason: "first miss on supported path" };
    }
    return {
      level: current + 1,
      reason: highFriction ? "long idle or repeated retry" : "failed attempt",
    };
  }
  return { level: current, reason: null };
}

export async function chooseVariant(
  verticalId: VerticalId,
  layer: number,
  allowed: Array<
    {
      id: string;
      difficulty: TaskCandidate["difficultyTier"];
      modality: Modality;
    }
  >,
): Promise<
  {
    id: string;
    difficulty: TaskCandidate["difficultyTier"];
    modality: Modality;
  }
> {
  const provider = Deno.env.get("TASK_LLM_PROVIDER") ?? "deterministic";
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (provider !== "openai" || !apiKey) {
    if (Deno.env.get("TASK_LLM_REQUIRED") === "true") {
      throw new Error("Approved task LLM is not configured.");
    }
    return allowed[0];
  }

  const response = await fetch(
    Deno.env.get("OPENAI_BASE_URL") ??
      "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              'Select exactly one allowed variant. Return JSON only: {"variant_id":"..."}. Never create content.',
          },
          {
            role: "user",
            content: JSON.stringify({
              vertical_id: verticalId,
              layer,
              allowed_variants: allowed,
            }),
          },
        ],
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`Task LLM request failed with status ${response.status}.`);
  }
  const result = await response.json();
  const raw = result?.choices?.[0]?.message?.content;
  let selected: string | undefined;
  try {
    selected = JSON.parse(raw).variant_id;
  } catch {
    selected = undefined;
  }
  return allowed.find((item) => item.id === selected) ?? allowed[0];
}

export async function loadEngine1Config(
  db: SupabaseClient,
  guardianId: string,
  childId: string,
): Promise<Engine1Config> {
  const [sensoryRes, profileRes] = await Promise.all([
    db.from("sensory_configurations").select("key, proposed_value").eq(
      "child_id",
      childId,
    ).eq("active", true).eq("status", "confirmed"),
    db.from("profiles").select(
      "sensory_control_matrix, generative_ui_parameters",
    ).eq("id", guardianId).maybeSingle(),
  ]);
  if (sensoryRes.error) {
    throw new Error("Engine 1 sensory configuration could not be read.");
  }
  if (!sensoryRes.data || sensoryRes.data.length === 0) {
    throw new Error("A guardian-confirmed Engine 1 configuration is required.");
  }
  const sensory = Object.fromEntries(
    sensoryRes.data.map((
      row: { key: string; proposed_value: unknown },
    ) => [row.key, row.proposed_value]),
  );
  const ui = (profileRes.data?.generative_ui_parameters ?? {}) as Record<
    string,
    unknown
  >;
  const active = Array.isArray(ui.active_verticals)
    ? ui.active_verticals.filter((v): v is VerticalId =>
      VERTICALS.includes(v as VerticalId)
    )
    : [...VERTICALS];
  return {
    sensory,
    layoutComplexityTier: ui.layout_complexity_tier === "simple" ||
        ui.layout_complexity_tier === "complex"
      ? ui.layout_complexity_tier
      : "standard",
    activeVerticals: active.length > 0 ? active : [...VERTICALS],
    hyperFocusTheme: typeof ui.hyper_focus_theme === "string"
      ? ui.hyper_focus_theme.slice(0, 80)
      : "general",
  };
}

function dayForDate(year: number, month: number, day: number): string {
  return new Intl.DateTimeFormat("en-US", { weekday: "long", timeZone: "UTC" })
    .format(new Date(Date.UTC(year, month - 1, day)));
}

function seededNumber(seed: string, max: number): number {
  let value = 2166136261;
  for (const char of seed) {
    value = Math.imul(value ^ char.charCodeAt(0), 16777619);
  }
  return Math.abs(value) % max;
}

function calendarTask(
  layer: number,
  seed: string,
  theme: string,
  modality: Modality,
): TaskCandidate {
  const year = 2026 + seededNumber(`${seed}:${layer}`, 3);
  const month = 1 + seededNumber(`${seed}:month:${layer}`, 12);
  const day = 1 + seededNumber(`${seed}:day:${layer}`, 27);
  const date = `${year}-${String(month).padStart(2, "0")}-${
    String(day).padStart(2, "0")
  }`;
  const expected = dayForDate(year, month, day);
  return {
    verticalId: "calendar_genius",
    layer,
    sourceType: layer === 1 ? "curated" : "created",
    difficultyTier: layer >= 7
      ? "advanced"
      : layer >= 2
      ? "progressive"
      : "baseline",
    modality,
    payload: {
      kind: "calendar-order",
      prompt: `Find the day of the week for ${date}.`,
      target_date: date,
      theme_skin: theme,
      modality,
      objective: layerObjective(layer),
    },
    answerKey: { expected },
    ruleVersion: `calendar-v1-layer-${layer}`,
  };
}

function constellationTask(
  layer: number,
  seed: string,
  theme: string,
  modality: Modality,
): TaskCandidate {
  const requiredCount = Math.min(3 + Math.floor(layer / 2), 7);
  const total = Math.min(
    requiredCount + 2 + seededNumber(`${seed}:noise`, 3),
    12,
  );
  const stars = Array.from({ length: total }, (_, index) => ({
    id: `star-${index}`,
    x: 10 + seededNumber(`${seed}:x:${index}`, 80),
    y: 10 + seededNumber(`${seed}:y:${index}`, 80),
  }));
  return {
    verticalId: "constellation_mapper",
    layer,
    sourceType: layer === 1 ? "curated" : "created",
    difficultyTier: layer >= 7
      ? "advanced"
      : layer >= 2
      ? "progressive"
      : "baseline",
    modality,
    payload: {
      kind: "constellation-anomaly",
      prompt: `Select ${requiredCount} stars that belong to the same pattern.`,
      stars,
      required_stars: requiredCount,
      total_star_nodes: total,
      theme_skin: theme,
      modality,
      distractor_density: layer >= 6 ? Math.min(0.8, 0.2 + layer / 20) : 0.1,
      objective: layerObjective(layer),
    },
    answerKey: { requiredCount },
    ruleVersion: `constellation-v1-layer-${layer}`,
  };
}

export function layerObjective(layer: number): string {
  const objectives: Record<number, string> = {
    1: "baseline pattern exploration",
    2: "progressive difficulty",
    3: "novel structure",
    4: "timing flexibility",
    5: "modality comparison",
    6: "distractor resistance",
    7: "transfer of strategy",
    8: "strategy signals",
    9: "consistency and fatigue",
    10: "real-world simulation",
  };
  return objectives[layer] ?? objectives[1];
}

export async function orchestrateLayer(
  layer: number,
  activeVerticals: VerticalId[],
  previousScores: Record<string, { accuracy: number; speed: number; isolationScore: number }>,
): Promise<Record<string, { difficulty: "baseline" | "progressive" | "advanced", modality: Modality }>> {
  const provider = Deno.env.get("TASK_LLM_PROVIDER") ?? "deterministic";
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (provider !== "openai" || !apiKey) {
    if (Deno.env.get("TASK_LLM_REQUIRED") === "true") {
      throw new Error("Approved task LLM is not configured.");
    }
    const plan: Record<string, { difficulty: "baseline" | "progressive" | "advanced", modality: Modality }> = {};
    for (const v of activeVerticals) {
      plan[v] = { difficulty: layer >= 7 ? "advanced" : (layer >= 2 ? "progressive" : "baseline"), modality: "visual" };
    }
    return plan;
  }

  const response = await fetch(
    Deno.env.get("OPENAI_BASE_URL") ?? "https://api.openai.com/v1/chat/completions",
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content:
              'You are a strengths exploration orchestrator. Review the child\'s previous scores and select the best subjects and difficulties for the next layer. Output JSON matching: { "plan": { "<vertical_id>": { "difficulty": "baseline"|"progressive"|"advanced", "modality": "visual"|"audio" } } }. Do not diagnose or assess. Simply route.',
          },
          {
            role: "user",
            content: JSON.stringify({
              target_layer: layer,
              active_verticals: activeVerticals,
              previous_scores: previousScores,
            }),
          },
        ],
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`Task LLM request failed with status ${response.status}.`);
  }
  const result = await response.json();
  const raw = result?.choices?.[0]?.message?.content;
  try {
    const parsed = JSON.parse(raw);
    return parsed.plan ?? {};
  } catch {
    const plan: Record<string, { difficulty: "baseline" | "progressive" | "advanced", modality: Modality }> = {};
    for (const v of activeVerticals) {
      plan[v] = { difficulty: layer >= 7 ? "advanced" : (layer >= 2 ? "progressive" : "baseline"), modality: "visual" };
    }
    return plan;
  }
}

// ─── Discovery Domain Definitions ────────────────────────────────────────────
// These are completely independent from calendar_genius or constellation_mapper.
// The discovery funnel tests broad foundational skills (shape reasoning, colour
// patterns, sequences, spatial logic, memory) so the engine can surface the
// child's strengths without presupposing the output vertical.

const SHAPES = ["circle", "square", "triangle", "star", "hexagon", "diamond", "rectangle", "oval"] as const;
const COLOURS = ["red", "blue", "green", "yellow", "orange", "purple", "pink", "brown"] as const;

type DiscoveryDomain = "shape_sort" | "colour_pattern" | "number_sequence" | "spatial_mirror" | "memory_match";

// How many question domains are unlocked per layer (more domains = harder)
function discoveryDomainsForLayer(layer: number): DiscoveryDomain[] {
  const all: DiscoveryDomain[] = ["shape_sort", "colour_pattern", "number_sequence", "spatial_mirror", "memory_match"];
  // Layer 1-2: simple shape/colour; layers 3-5 add sequences; layers 6+ add spatial/memory
  if (layer <= 2) return ["shape_sort", "colour_pattern"];
  if (layer <= 5) return ["shape_sort", "colour_pattern", "number_sequence"];
  return all;
}

function discoveryDifficulty(layer: number): "baseline" | "progressive" | "advanced" {
  if (layer >= 7) return "advanced";
  if (layer >= 2) return "progressive";
  return "baseline";
}

function buildShapeSort(layer: number, seed: string): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const shapeCount = 3 + Math.min(layer, 5); // 4 to 8 shapes
  const targetIdx = seededNumber(`${seed}:tgt`, shapeCount);
  const shapes = Array.from({ length: shapeCount }, (_, i) =>
    SHAPES[(seededNumber(`${seed}:s${i}`, SHAPES.length))]);
  const target = shapes[targetIdx];
  // The odd-one-out: replace target with a different shape
  const oddShape = SHAPES[(SHAPES.indexOf(target as typeof SHAPES[number]) + 1 + seededNumber(`${seed}:odd`, SHAPES.length - 1)) % SHAPES.length];
  const options = [...shapes];
  options[targetIdx] = oddShape;
  return {
    payload: {
      kind: "shape-sort",
      prompt: `Which shape does NOT belong in this group?`,
      shapes: options,
      distractor_count: Math.floor(layer / 3),
    },
    answerKey: { odd_shape_index: targetIdx, odd_shape: oddShape },
  };
}

function buildColourPattern(layer: number, seed: string): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const patternLen = 3 + Math.min(layer - 1, 4); // 3 to 7 colours in sequence
  const sequence = Array.from({ length: patternLen }, (_, i) =>
    COLOURS[seededNumber(`${seed}:c${i}`, COLOURS.length)]);
  const nextColour = COLOURS[seededNumber(`${seed}:next`, COLOURS.length)];
  return {
    payload: {
      kind: "colour-pattern",
      prompt: "What colour comes next in the pattern?",
      sequence,
      options: COLOURS.slice(0, 4 + Math.floor(layer / 3)),
    },
    answerKey: { expected: nextColour },
  };
}

function buildNumberSequence(layer: number, seed: string): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const step = 1 + seededNumber(`${seed}:step`, layer + 1); // step size grows with layer
  const start = 1 + seededNumber(`${seed}:start`, 10);
  const length = 4 + Math.min(layer, 3);
  const sequence = Array.from({ length }, (_, i) => start + i * step);
  const nextVal = start + length * step;
  return {
    payload: {
      kind: "number-sequence",
      prompt: "What number comes next?",
      sequence,
    },
    answerKey: { expected: nextVal },
  };
}

function buildSpatialMirror(layer: number, seed: string): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const gridSize = 3 + Math.floor(layer / 4); // 3x3 to 5x5
  const cells = Array.from({ length: gridSize * gridSize }, (_, i) => seededNumber(`${seed}:cell${i}`, 2));
  // The "mirror" answer is the horizontal flip of the row at position seededNumber
  const targetRow = seededNumber(`${seed}:row`, gridSize);
  const row = cells.slice(targetRow * gridSize, (targetRow + 1) * gridSize);
  const mirrored = [...row].reverse();
  return {
    payload: {
      kind: "spatial-mirror",
      prompt: "Which row is the mirror image of the highlighted row?",
      grid: cells,
      grid_size: gridSize,
      target_row: targetRow,
    },
    answerKey: { mirrored_row: mirrored },
  };
}

function buildMemoryMatch(layer: number, seed: string): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const pairCount = 2 + Math.min(layer, 4); // 2 to 6 pairs
  const allShapes = Array.from({ length: pairCount }, (_, i) =>
    SHAPES[seededNumber(`${seed}:m${i}`, SHAPES.length)]);
  // Shuffle by seeding
  const shuffled = [...allShapes, ...allShapes].sort((a, b) =>
    seededNumber(`${seed}:sort${a}${b}`, 100) - 50);
  return {
    payload: {
      kind: "memory-match",
      prompt: "Remember the positions, then match the pairs.",
      cards: shuffled,
      pair_count: pairCount,
    },
    answerKey: { pairs: allShapes },
  };
}

function discoveryTask(
  layer: number,
  seed: string,
  theme: string,
  modality: Modality,
  previousScore?: Record<string, any>,
): TaskCandidate {
  // Select domain based on seed (not previous skill data — we don't presuppose the outcome)
  const adaptSeed = previousScore?.accuracy
    ? `${seed}:acc${Math.round(previousScore.accuracy * 10)}`
    : seed;
  const availableDomains = discoveryDomainsForLayer(layer);
  const domain = availableDomains[seededNumber(`${adaptSeed}:domain`, availableDomains.length)];

  let content: { payload: Record<string, unknown>; answerKey: Record<string, unknown> };
  switch (domain) {
    case "colour_pattern":
      content = buildColourPattern(layer, adaptSeed);
      break;
    case "number_sequence":
      content = buildNumberSequence(layer, adaptSeed);
      break;
    case "spatial_mirror":
      content = buildSpatialMirror(layer, adaptSeed);
      break;
    case "memory_match":
      content = buildMemoryMatch(layer, adaptSeed);
      break;
    case "shape_sort":
    default:
      content = buildShapeSort(layer, adaptSeed);
      break;
  }

  return {
    verticalId: "discovery",
    layer,
    sourceType: layer === 1 ? "curated" : "created",
    difficultyTier: discoveryDifficulty(layer),
    modality,
    payload: {
      ...content.payload,
      theme_skin: theme,
      modality,
      domain,
      objective: layerObjective(layer),
    },
    answerKey: content.answerKey,
    ruleVersion: `discovery-v1-layer-${layer}-${domain}`,
  };
}

export async function createTask(
  verticalId: VerticalId,
  layer: number,
  seed: string,
  config: Engine1Config,
  modality: Modality = "visual",
  forcedDifficulty?: "baseline" | "progressive" | "advanced",
  previousScore?: Record<string, any>,
): Promise<TaskCandidate> {
  const allowed = [
    {
      id: "calm-visual",
      difficulty: (layer >= 7 ? "advanced" : "progressive") as TaskCandidate[
        "difficultyTier"
      ],
      modality: "visual" as Modality,
    },
    {
      id: "theme-interactive",
      difficulty: (layer >= 7 ? "advanced" : "progressive") as TaskCandidate[
        "difficultyTier"
      ],
      modality,
    },
  ];
  let choice = await chooseVariant(verticalId, layer, allowed);
  if (forcedDifficulty) {
    choice = { ...choice, difficulty: forcedDifficulty };
  }
  const theme = config.hyperFocusTheme ||
    (choice.id === "calm-visual" ? "calm" : "general");
  const task = verticalId === "discovery"
    ? discoveryTask(layer, seed, theme, normalizeModality(choice.modality), previousScore)
    : verticalId === "calendar_genius"
    ? calendarTask(layer, seed, theme, normalizeModality(choice.modality))
    : constellationTask(layer, seed, theme, normalizeModality(choice.modality));
  task.sourceType = layer === 1
    ? "curated"
    : choice.id === "calm-visual"
    ? "predicted"
    : "created";
  task.difficultyTier = layer === 1 ? "baseline" : choice.difficulty;
  task.payload = assertSafePayload(task.payload);
  return task;
}

export function publicTask(
  taskRow: Record<string, unknown>,
): Record<string, unknown> {
  const full = (taskRow.item_payload ?? {}) as Record<string, unknown>;
  const payload = {
    ...((full.public_payload ?? full) as Record<string, unknown>),
  };
  const answerKey = full.answer_key as Record<string, unknown> | undefined;
  // Defense in depth for tasks created before answer isolation was enforced.
  // The client only needs the prompt and interaction data; scoring stays on
  // the server and answer keys never cross this boundary.
  delete payload.correct_day;
  delete payload.answer_key;
  delete payload.expected;
  // Keep the existing Flutter widgets compatible while the server remains the
  // scoring authority. The answer is not used to calculate server scores.
  return {
    task_id: taskRow.id,
    layer: taskRow.layer_number,
    total_layers: 10,
    vertical_id: taskRow.vertical_id,
    source_type: taskRow.source_type,
    difficulty_tier: taskRow.difficulty_tier,
    theme_skin: payload.theme_skin ?? "calm",
    prompt: payload.prompt ?? "Explore the pattern below.",
    task_data: payload,
    answer_key_present: !!answerKey,
    modality: payload.modality ?? "visual",
    objective: payload.objective ??
      layerObjective(Number(taskRow.layer_number)),
  };
}
