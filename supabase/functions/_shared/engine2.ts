import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// These are exploration domains, not diagnostic labels.  Engine 1 may enable
// any subset, and Engine 2 must keep the domains independent all the way
// through the deepening funnel.
export const VERTICALS = [
  "calendar_genius",
  "constellation_mapper",
  "discovery",
  "visual_pattern_explorer",
  "sequence_navigator",
  "spatial_builder",
  "memory_weaver",
  "language_patterner",
  "number_navigator",
  "logic_lens",
] as const;
export type VerticalId = typeof VERTICALS[number];
export type SourceType = "curated" | "predicted" | "created";
export type PathType = "accelerated" | "standard" | "supported";
export type Modality = "visual" | "audio" | "animated" | "interactive";
export type SupportOutcome =
  | "resolved"
  | "escalated_further"
  | "de_escalated"
  | "abandoned";

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
  composition?: {
    curatedBaselineId: string;
    predictedVariantId: string;
    createdInstanceId: string;
  };
}

export interface ScoredResponse {
  accuracy: number;
  latencyMs: number;
  recovery: number;
  engagement: number;
  speed: number;
  isolationScore: number;
}

export interface LayerScore {
  accuracy: number;
  recovery: number;
  engagement: number;
  speed: number;
}

export interface LayerProtocol {
  requiredExecutions: number;
  modalities: Modality[];
  timingBudgetsMs: number[];
  instrumentationOnly: boolean;
  structureId: string;
  surfaceDomain: string | null;
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
  if (layer === 4 || layer === 5) return 4;
  if (layer === 9) return 3;
  return 1;
}

export function modalityForExecution(
  layer: number,
  executionIndex: number,
): Modality {
  if (layer !== 5) return "visual";
  return (["visual", "audio", "animated", "interactive"] as const)[
    Math.max(0, Math.min(3, executionIndex - 1))
  ];
}

export function layerProtocol(
  verticalId: VerticalId,
  layer: number,
): LayerProtocol {
  const required = requiredExecutions(layer);
  const timingBudgetsMs = layer === 4 ? [60_000, 45_000, 30_000, 15_000] : [];
  const modalities: Modality[] = layer === 5
    ? ["visual", "audio", "animated", "interactive"]
    : ["visual"];
  const transferSurfaces: Partial<Record<VerticalId, string>> = {
    calendar_genius: "route-planning",
    constellation_mapper: "garden-map",
    discovery: "treasure-map",
    visual_pattern_explorer: "tile-workshop",
    sequence_navigator: "train-schedule",
    spatial_builder: "playground-map",
    memory_weaver: "story-shelf",
    language_patterner: "message-workshop",
    number_navigator: "market-route",
    logic_lens: "mystery-club",
  };
  return {
    requiredExecutions: required,
    modalities,
    timingBudgetsMs,
    instrumentationOnly: layer === 8,
    // Layer 3 must always use a structure that did not appear in the two
    // preceding layers for this vertical. The layer-qualified family makes
    // that invariant explicit and auditable in the stored task payload.
    structureId: layer === 3
      ? `${verticalId}:novel-structure:v1`
      : `${verticalId}:core-structure:v${layer}`,
    surfaceDomain: layer === 7
      ? transferSurfaces[verticalId] ?? "new-surface"
      : null,
  };
}

export function supportGuidance(level: number): Record<string, unknown> {
  const bounded = Math.max(0, Math.min(5, Math.floor(level)));
  const guidance = [
    { mode: "independent", message: null, simplify_choices: false },
    {
      mode: "gentle_prompt",
      message: "Take your time and try one small step.",
      simplify_choices: false,
    },
    {
      mode: "cue",
      message: "Look for one part that repeats or stands out.",
      simplify_choices: false,
    },
    {
      mode: "step_by_step",
      message: "Start with the first part, then choose what comes next.",
      simplify_choices: false,
    },
    {
      mode: "simplified_choices",
      message: "Here are fewer choices to explore first.",
      simplify_choices: true,
    },
    {
      mode: "interactive_help",
      message: "Let’s work through the first step together.",
      simplify_choices: true,
    },
  ];
  return { level: bounded, ...guidance[bounded] };
}

export function compositeScore(score: LayerScore): number {
  return clamp(
    (0.4 * clamp(score.accuracy)) +
      (0.3 * clamp(score.recovery)) +
      (0.2 * clamp(score.engagement)) +
      (0.1 * clamp(score.speed)),
  );
}

/**
 * Layer 1 remains the authoritative isolation signal. Later layers only add
 * fresh context for routing; they never overwrite or re-run that score.
 */
export function reEvaluatePath(
  layer1: { isolationScore: number; recovery: number },
  latest: LayerScore,
): { path: PathType; routingSignal: number; reason: string } {
  if (latest.recovery < 0.45) {
    return {
      path: "supported",
      routingSignal: compositeScore(latest),
      reason: "recovery component needs additional support",
    };
  }
  const routingSignal = clamp(
    (layer1.isolationScore + compositeScore(latest)) / 2,
  );
  const path = pathForIsolation(
    routingSignal,
    Math.min(layer1.recovery, latest.recovery),
  );
  return {
    path,
    routingSignal,
    reason:
      `Layer 1 isolation retained; latest layer signal selected ${path} route`,
  };
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
  const base = compositeScore({
    accuracy: normalizedAccuracy,
    recovery,
    engagement,
    speed,
  });
  return {
    accuracy: normalizedAccuracy,
    latencyMs: safeLatency,
    recovery,
    engagement,
    speed,
    // Source provenance is retained separately. It must not change the fixed
    // isolation formula, otherwise scores are not comparable across verticals.
    isolationScore: base,
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
  if (typeof answerKey.expected === "number") {
    return Number(response) === answerKey.expected ? 1 : 0;
  }
  if (
    typeof answerKey.expectedIndex === "number" ||
    typeof answerKey.odd_shape_index === "number"
  ) {
    const expected = Number(
      answerKey.expectedIndex ?? answerKey.odd_shape_index,
    );
    return Number(response) === expected ? 1 : 0;
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
): { level: number; reason: string | null; outcome: SupportOutcome | null } {
  const highFriction = input.skipped ||
    (input.latencyMs >= 45_000 && input.retryCount >= 2);
  const miss = input.accuracy < 0.5;
  if (current < 5 && (highFriction || miss)) {
    if (current === 0 && input.path === "supported" && miss) {
      return {
        level: 2,
        reason: "first miss on supported path",
        outcome: "escalated_further",
      };
    }
    return {
      level: current + 1,
      reason: highFriction ? "long idle or repeated retry" : "failed attempt",
      outcome: "escalated_further",
    };
  }
  if (
    current > 0 && input.accuracy >= 0.85 && input.retryCount === 0 &&
    !input.skipped && input.latencyMs < 20_000
  ) {
    return {
      level: current - 1,
      reason: "sustained independent response",
      outcome: "de_escalated",
    };
  }
  return { level: current, reason: null, outcome: null };
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
  config?: Pick<
    Engine1Config,
    "sensory" | "layoutComplexityTier" | "hyperFocusTheme"
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

  try {
    const headers: Record<string, string> = {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    };
    const organization = Deno.env.get("OPENAI_ORGANIZATION");
    if (organization) {
      headers["OpenAI-Organization"] = organization;
    }

    const response = await fetch(
      Deno.env.get("OPENAI_BASE_URL") ??
        "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers,
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
                sensory_preferences: config?.sensory ?? {},
                layout_complexity_tier: config?.layoutComplexityTier ??
                  "standard",
                theme: config?.hyperFocusTheme ?? "general",
              }),
            },
          ],
        }),
      },
    );
    if (!response.ok) {
      console.warn(`[engine2:chooseVariant] LLM returned status ${response.status}. Falling back to deterministic variant.`);
      if (Deno.env.get("TASK_LLM_REQUIRED") === "true") {
        throw new Error(`Task LLM request failed with status ${response.status}.`);
      }
      return allowed[0];
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
  } catch (err) {
    console.warn(`[engine2:chooseVariant] LLM fetch error: ${err}. Falling back to deterministic variant.`);
    if (Deno.env.get("TASK_LLM_REQUIRED") === "true") {
      throw err;
    }
    return allowed[0];
  }
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
  previousScores: Record<
    string,
    { accuracy: number; speed: number; isolationScore: number }
  >,
): Promise<
  Record<
    string,
    { difficulty: "baseline" | "progressive" | "advanced"; modality: Modality }
  >
> {
  const provider = Deno.env.get("TASK_LLM_PROVIDER") ?? "deterministic";
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (provider !== "openai" || !apiKey) {
    if (Deno.env.get("TASK_LLM_REQUIRED") === "true") {
      throw new Error("Approved task LLM is not configured.");
    }
    const plan: Record<
      string,
      {
        difficulty: "baseline" | "progressive" | "advanced";
        modality: Modality;
      }
    > = {};
    for (const v of activeVerticals) {
      plan[v] = {
        difficulty: layer >= 7
          ? "advanced"
          : (layer >= 2 ? "progressive" : "baseline"),
        modality: "visual",
      };
    }
    return plan;
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
    const plan: Record<
      string,
      {
        difficulty: "baseline" | "progressive" | "advanced";
        modality: Modality;
      }
    > = {};
    for (const v of activeVerticals) {
      plan[v] = {
        difficulty: layer >= 7
          ? "advanced"
          : (layer >= 2 ? "progressive" : "baseline"),
        modality: "visual",
      };
    }
    return plan;
  }
}

// ─── Discovery Domain Definitions ────────────────────────────────────────────
// These are completely independent from calendar_genius or constellation_mapper.
// The discovery funnel tests broad foundational skills (shape reasoning, colour
// patterns, sequences, spatial logic, memory) so the engine can surface the
// child's strengths without presupposing the output vertical.

const SHAPES = [
  "circle",
  "square",
  "triangle",
  "star",
  "hexagon",
  "diamond",
  "rectangle",
  "oval",
] as const;
const COLOURS = [
  "red",
  "blue",
  "green",
  "yellow",
  "orange",
  "purple",
  "pink",
  "brown",
] as const;

type DiscoveryDomain =
  | "shape_sort"
  | "colour_pattern"
  | "number_sequence"
  | "spatial_mirror"
  | "memory_match";

// How many question domains are unlocked per layer (more domains = harder)
function discoveryDomainsForLayer(layer: number): DiscoveryDomain[] {
  const all: DiscoveryDomain[] = [
    "shape_sort",
    "colour_pattern",
    "number_sequence",
    "spatial_mirror",
    "memory_match",
  ];
  // Layer 1-2: simple shape/colour; layers 3-5 add sequences; layers 6+ add spatial/memory
  if (layer <= 2) return ["shape_sort", "colour_pattern"];
  if (layer <= 5) return ["shape_sort", "colour_pattern", "number_sequence"];
  return all;
}

function discoveryDifficulty(
  layer: number,
): "baseline" | "progressive" | "advanced" {
  if (layer >= 7) return "advanced";
  if (layer >= 2) return "progressive";
  return "baseline";
}

function buildShapeSort(
  layer: number,
  seed: string,
): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const shapeCount = 3 + Math.min(layer, 5); // 4 to 8 shapes
  const targetIdx = seededNumber(`${seed}:tgt`, shapeCount);
  const shapes = Array.from(
    { length: shapeCount },
    (_, i) => SHAPES[seededNumber(`${seed}:s${i}`, SHAPES.length)],
  );
  const target = shapes[targetIdx];
  // The odd-one-out: replace target with a different shape
  const oddShape = SHAPES[
    (SHAPES.indexOf(target as typeof SHAPES[number]) + 1 +
      seededNumber(`${seed}:odd`, SHAPES.length - 1)) % SHAPES.length
  ];
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

function buildColourPattern(
  layer: number,
  seed: string,
): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const patternLen = 3 + Math.min(layer - 1, 4); // 3 to 7 colours in sequence
  const sequence = Array.from(
    { length: patternLen },
    (_, i) => COLOURS[seededNumber(`${seed}:c${i}`, COLOURS.length)],
  );
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

function buildNumberSequence(
  layer: number,
  seed: string,
): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
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

function buildSpatialMirror(
  layer: number,
  seed: string,
): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const gridSize = 3 + Math.floor(layer / 4); // 3x3 to 5x5
  const cells = Array.from(
    { length: gridSize * gridSize },
    (_, i) => seededNumber(`${seed}:cell${i}`, 2),
  );
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

function buildMemoryMatch(
  layer: number,
  seed: string,
): { payload: Record<string, unknown>; answerKey: Record<string, unknown> } {
  const pairCount = 2 + Math.min(layer, 4); // 2 to 6 pairs
  const allShapes = Array.from(
    { length: pairCount },
    (_, i) => SHAPES[seededNumber(`${seed}:m${i}`, SHAPES.length)],
  );
  // Shuffle by seeding
  const shuffled = [...allShapes, ...allShapes].sort((a, b) =>
    seededNumber(`${seed}:sort${a}${b}`, 100) - 50
  );
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
  const domain = availableDomains[
    seededNumber(`${adaptSeed}:domain`, availableDomains.length)
  ];

  let content: {
    payload: Record<string, unknown>;
    answerKey: Record<string, unknown>;
  };
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

const CURATED_BASELINES: Record<VerticalId, { id: string; family: string }> = {
  calendar_genius: { id: "calendar-baseline-v1", family: "calendar-order" },
  constellation_mapper: {
    id: "constellation-baseline-v1",
    family: "constellation-anomaly",
  },
  discovery: { id: "discovery-baseline-v1", family: "broad-pattern" },
  visual_pattern_explorer: {
    id: "visual-pattern-baseline-v1",
    family: "visual-pattern",
  },
  sequence_navigator: {
    id: "sequence-baseline-v1",
    family: "ordered-sequence",
  },
  spatial_builder: { id: "spatial-baseline-v1", family: "spatial-relation" },
  memory_weaver: { id: "memory-baseline-v1", family: "memory-recall" },
  language_patterner: {
    id: "language-baseline-v1",
    family: "language-pattern",
  },
  number_navigator: { id: "number-baseline-v1", family: "number-pattern" },
  logic_lens: { id: "logic-baseline-v1", family: "logic-relation" },
};

const GENERIC_VERTICAL_PROMPTS: Partial<Record<VerticalId, string>> = {
  visual_pattern_explorer: "Which symbol completes this visual pattern?",
  sequence_navigator: "Which step comes next in this sequence?",
  spatial_builder: "Which map marker matches the shown relation?",
  memory_weaver: "Which item belongs with the pattern you just explored?",
  language_patterner: "Which word follows the same pattern?",
  number_navigator: "Which number completes the route?",
  logic_lens: "Which choice follows the rule?",
};

function genericVerticalTask(
  verticalId: Exclude<
    VerticalId,
    "calendar_genius" | "constellation_mapper" | "discovery"
  >,
  layer: number,
  seed: string,
  theme: string,
  modality: Modality,
): TaskCandidate {
  const options = ["A", "B", "C", "D"];
  const expected = options[seededNumber(`${seed}:expected`, options.length)];
  const prompt = GENERIC_VERTICAL_PROMPTS[verticalId] ??
    "Which choice completes the pattern?";
  return {
    verticalId,
    layer,
    sourceType: layer === 1 ? "curated" : "created",
    difficultyTier: layer >= 7
      ? "advanced"
      : layer >= 2
      ? "progressive"
      : "baseline",
    modality,
    payload: {
      kind: "choice-pattern",
      prompt,
      options,
      theme_skin: theme,
      modality,
      objective: layerObjective(layer),
    },
    answerKey: { expected },
    ruleVersion: `${verticalId}-v1-layer-${layer}`,
  };
}

function applyLayerProtocol(
  task: TaskCandidate,
  protocol: LayerProtocol,
  seed: string,
): TaskCandidate {
  const payload = { ...task.payload } as Record<string, unknown>;
  payload.structure_id = protocol.structureId;
  payload.layer_protocol = {
    required_executions: protocol.requiredExecutions,
    modalities: protocol.modalities,
    timing_budgets_ms: protocol.timingBudgetsMs,
    instrumentation_only: protocol.instrumentationOnly,
    surface_domain: protocol.surfaceDomain,
  };
  if (task.layer === 3) payload.novel_structure = true;
  if (task.layer === 4) payload.timing_budgets_ms = protocol.timingBudgetsMs;
  if (task.layer === 5) payload.presentation_modalities = protocol.modalities;
  if (task.layer === 6) {
    payload.distractor_density = 0.5;
    payload.distractor_set_id = `${task.verticalId}:layer6:${
      seededNumber(seed, 10_000)
    }`;
  }
  if (task.layer === 7) {
    payload.transfer_surface = protocol.surfaceDomain;
    payload.prompt = `${
      String(payload.prompt)
    } Imagine the same rule in a ${protocol.surfaceDomain} adventure.`;
  }
  if (task.layer === 8) payload.instrumentation_only = true;
  if (task.layer === 9) {
    payload.held_difficulty = true;
    payload.consistency_window = 3;
  }
  if (task.layer === 10) {
    payload.applied_scenario = {
      context: protocol.surfaceDomain ?? "everyday planning",
      goal: "Use the same pattern in a practical story scenario.",
    };
    payload.prompt = `${
      String(payload.prompt)
    } Use it to help with this everyday story.`;
  }
  task.payload = payload;
  return task;
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
  let choice = await chooseVariant(verticalId, layer, allowed, config);
  if (forcedDifficulty) {
    choice = { ...choice, difficulty: forcedDifficulty };
  }
  const theme = config.hyperFocusTheme ||
    (choice.id === "calm-visual" ? "calm" : "general");
  const task = verticalId === "discovery"
    ? discoveryTask(
      layer,
      seed,
      theme,
      normalizeModality(choice.modality),
      previousScore,
    )
    : verticalId === "calendar_genius"
    ? calendarTask(layer, seed, theme, normalizeModality(choice.modality))
    : verticalId === "constellation_mapper"
    ? constellationTask(layer, seed, theme, normalizeModality(choice.modality))
    : genericVerticalTask(
      verticalId,
      layer,
      seed,
      theme,
      normalizeModality(choice.modality),
    );
  const baseline = CURATED_BASELINES[verticalId];
  const protocol = layerProtocol(verticalId, layer);
  task.composition = {
    curatedBaselineId: baseline.id,
    predictedVariantId: choice.id,
    createdInstanceId: `${verticalId}:${layer}:${
      seededNumber(`${seed}:instance`, 1_000_000)
    }`,
  };
  task.payload = {
    ...task.payload,
    content_composition: {
      curated_baseline_id: task.composition.curatedBaselineId,
      curated_family: baseline.family,
      predicted_variant_id: task.composition.predictedVariantId,
      created_instance_id: task.composition.createdInstanceId,
    },
  };
  applyLayerProtocol(task, protocol, seed);
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
  options: {
    supportLevel?: number;
    executionIndex?: number;
    requiredExecutions?: number;
  } = {},
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
  const protocol = (payload.layer_protocol ?? {}) as Record<string, unknown>;
  const executionIndex = Math.max(1, Number(options.executionIndex ?? 1));
  const required = Math.max(
    1,
    Number(options.requiredExecutions ?? protocol.required_executions ?? 1),
  );
  const timingBudgets = Array.isArray(protocol.timing_budgets_ms)
    ? protocol.timing_budgets_ms
    : [];
  const modalities = Array.isArray(protocol.modalities)
    ? protocol.modalities
    : [];
  const modality = modalities[executionIndex - 1] ?? payload.modality ??
    "visual";
  const supportLevel = Math.max(
    0,
    Math.min(5, Number(options.supportLevel ?? 0)),
  );
  payload.support = supportGuidance(supportLevel);
  if (supportLevel >= 4 && Array.isArray(payload.options) && answerKey) {
    const expected = answerKey.expected;
    if (typeof expected === "string" && payload.options.includes(expected)) {
      payload.options = [
        expected,
        ...payload.options.filter((option) => option !== expected).slice(0, 1),
      ];
    }
  }
  if (supportLevel >= 4 && payload.kind === "calendar-order" && answerKey) {
    const expected = answerKey.expected;
    if (typeof expected === "string") {
      const days = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
      ];
      payload.visible_options = [
        expected,
        ...days.filter((day) => day !== expected).slice(0, 1),
      ];
    }
  }
  payload.execution_index = executionIndex;
  payload.required_executions = required;
  if (timingBudgets.length) {
    payload.timing_budget_ms = timingBudgets[executionIndex - 1] ?? null;
  }
  payload.modality = modality;
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
    modality,
    support_level: supportLevel,
    timing_variant: executionIndex,
    required_executions: required,
    objective: payload.objective ??
      layerObjective(Number(taskRow.layer_number)),
  };
}
