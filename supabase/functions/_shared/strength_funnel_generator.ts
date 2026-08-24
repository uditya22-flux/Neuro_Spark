/**
 * Task generation for the RIASEC strength funnel.
 * Default: deterministic synthesis from JSON templates (no external LLM).
 * Optional: STRENGTH_FUNNEL_LLM_ENABLED=true with OPENAI_API_KEY for live generation.
 * Charter: present-moment enjoyment only; golden rule validated on every output.
 */

import {
  constraintsToJson,
  routeModalityFromIsaa,
  type IsaaProfile,
  type ModalityConstraints,
} from "./modality_router.ts";
import {
  buildTaskFromTemplate,
  type Layer1TaskPayload,
  type SectorRow,
} from "./strength_funnel_tasks.ts";
import { isDeepDiveLayer } from "./sector_template_catalog.ts";

export interface GenerateTaskInput {
  sector: SectorRow;
  templateJson: Record<string, unknown> | null;
  isaa?: Partial<IsaaProfile>;
  modalityConstraints?: ModalityConstraints;
  layer?: number;
}

export interface GeneratedTaskResult {
  task: Layer1TaskPayload;
  source: "template" | "llm" | "template_fallback";
  layer: number;
  deep_dive: boolean;
}

function llmEnabled(): boolean {
  return Deno.env.get("STRENGTH_FUNNEL_LLM_ENABLED") === "true" &&
    Boolean(Deno.env.get("OPENAI_API_KEY"));
}

/** Synthesizes a task from template + ISAA routing (primary path). */
export function generateTaskFromTemplate(
  input: GenerateTaskInput,
): GeneratedTaskResult {
  const layer = input.layer ?? 1;
  const constraints = input.modalityConstraints ??
    routeModalityFromIsaa(input.isaa ?? {});
  const task = buildTaskFromTemplate(
    input.sector,
    input.templateJson,
    constraints,
    layer,
  );
  return {
    task,
    source: "template",
    layer,
    deep_dive: isDeepDiveLayer(layer),
  };
}

/**
 * Generates a sector task. Uses LLM only when explicitly enabled; otherwise template synthesis.
 * LLM failures fall back to template output — never block the funnel.
 */
export async function generateSectorTask(
  input: GenerateTaskInput,
): Promise<GeneratedTaskResult> {
  const templateResult = generateTaskFromTemplate(input);
  if (!llmEnabled()) return templateResult;

  try {
    const llmTask = await generateWithOpenAi(input, templateResult.task);
    return { ...templateResult, task: llmTask, source: "llm" };
  } catch (err) {
    console.warn(
      "[strength_funnel_generator] LLM fallback:",
      (err as Error).message,
    );
    return { ...templateResult, source: "template_fallback" };
  }
}

async function generateWithOpenAi(
  input: GenerateTaskInput,
  seed: Layer1TaskPayload,
): Promise<Layer1TaskPayload> {
  const layer = input.layer ?? 1;
  const template = input.templateJson ?? {};
  const framing = (template.framing_rules ?? {}) as Record<string, unknown>;

  const systemPrompt = [
    "You generate child play-activity prompts for present-moment enjoyment ONLY.",
    "Never mention careers, jobs, salaries, or future work.",
    String(framing.golden_rule ?? ""),
    "Return JSON with: present_moment_prompt, activity_label, picture_description.",
  ].join(" ");

  const userPrompt = JSON.stringify({
    sector: input.sector.display_name,
    play_theme: input.sector.play_theme,
    layer,
    deep_dive: isDeepDiveLayer(layer),
    seed_prompt: seed.present_moment_prompt,
    generation_schema: template.generation_schema ?? null,
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("STRENGTH_FUNNEL_LLM_MODEL") ?? "gpt-4o-mini",
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.4,
      max_tokens: 300,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI HTTP ${response.status}`);
  }

  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (!content) throw new Error("Empty LLM response");

  const parsed = JSON.parse(content) as Record<string, unknown>;
  const constraints = input.modalityConstraints ??
    routeModalityFromIsaa(input.isaa ?? {});

  return buildTaskFromTemplate(
    input.sector,
    {
      ...template,
      sample_generated_task: {
        present_moment_prompt: String(
          parsed.present_moment_prompt ?? seed.present_moment_prompt,
        ),
        activity_scene: {
          activity_label: String(
            parsed.activity_label ?? seed.activity_label,
          ),
          simple_picture_description: String(
            parsed.picture_description ?? seed.picture_description,
          ),
        },
        enjoyment_scale: {
          min_label: seed.min_enjoyment_label,
          max_label: seed.max_enjoyment_label,
        },
      },
    },
    constraints,
    layer,
  );
}

export function constraintsFromSessionJson(
  raw: Record<string, unknown> | null | undefined,
): ModalityConstraints | undefined {
  if (!raw) return undefined;
  return raw as unknown as ModalityConstraints;
}

export { constraintsToJson };
