import { z } from 'zod';

export const ENGINE2_SCHEMA_VERSION = '1.0';
export const ENGINE2_PROMPT_VERSION = 'engine2-baseline-v1';
export const ENGINE2_DOMAINS = [
  'visual-pattern-reasoning',
  'sequencing-and-planning',
  'language-and-story-understanding',
  'memory-and-attention-preferences',
  'flexible-problem-solving',
  'interests-sensory-preferences-and-support-conditions',
] as const;
export type Engine2Domain = typeof ENGINE2_DOMAINS[number];

export const ENGINE2_INTERACTION_TYPES = ['singleChoice', 'multiChoice', 'visualMatch', 'sequence'] as const;
export type Engine2InteractionType = typeof ENGINE2_INTERACTION_TYPES[number];

/** These semantic names are the only names the Flutter icon registry accepts. */
export const ENGINE2_ICON_KEYS = [
  'circle', 'triangle', 'square', 'diamond', 'star', 'arrow', 'book', 'lightbulb',
  'puzzle', 'map', 'clock', 'music', 'headphones', 'palette', 'leaf', 'rocket',
] as const;

const prohibited = /diagnos|autis|disorder|condition|screening|assessment|score|correct|wrong|career|job|employ|salary|predict/i;
const safeText = (max: number) => z.string().trim().min(1).max(max).refine((value) => !prohibited.test(value), 'contains prohibited child-facing language');

export const engine2OptionSchema = z.object({
  id: z.string().regex(/^[a-z][a-z0-9-]{1,63}$/),
  label: safeText(32),
  semanticDescription: safeText(90),
  iconKey: z.enum(ENGINE2_ICON_KEYS),
}).strict();

export const engine2QuestionSchema = z.object({
  id: z.string().regex(/^[a-z][a-z0-9-]{1,63}$/),
  domain: z.enum(ENGINE2_DOMAINS),
  interactionType: z.enum(ENGINE2_INTERACTION_TYPES),
  prompt: safeText(180),
  options: z.array(engine2OptionSchema).min(3).max(4).superRefine((items, context) => {
    if (new Set(items.map((item) => item.id)).size !== items.length) context.addIssue({ code: z.ZodIssueCode.custom, message: 'option IDs must be unique' });
  }),
}).strict();

export const engine2QuestionsSchema = z.array(engine2QuestionSchema).superRefine((questions, context) => {
  if (new Set(questions.map((question) => question.id)).size !== questions.length) context.addIssue({ code: z.ZodIssueCode.custom, message: 'question IDs must be unique' });
  const content = new Set<string>();
  for (const question of questions) {
    const normalized = question.prompt.toLowerCase().replace(/[^a-z0-9]/g, '');
    if (content.has(normalized)) context.addIssue({ code: z.ZodIssueCode.custom, message: 'duplicate question content' });
    content.add(normalized);
  }
});

export type Engine2Option = z.infer<typeof engine2OptionSchema>;
export type Engine2Question = z.infer<typeof engine2QuestionSchema>;

export function validateBaselineQuestions(value: unknown): Engine2Question[] {
  const questions = engine2QuestionsSchema.parse(value);
  if (questions.length !== 30) throw new Error('Engine 2A must contain exactly 30 questions');
  for (const domain of ENGINE2_DOMAINS) {
    if (questions.filter((question) => question.domain === domain).length !== 5) {
      throw new Error(`Engine 2A must contain exactly five ${domain} questions`);
    }
  }
  return questions;
}

export function validateAdaptiveQuestions(value: unknown, neededDomains: readonly Engine2Domain[]): Engine2Question[] {
  const questions = engine2QuestionsSchema.parse(value);
  if (questions.length < 6 || questions.length > 12) throw new Error('Engine 2B must contain 6 to 12 questions');
  if (questions.some((question) => !neededDomains.includes(question.domain))) throw new Error('Engine 2B includes a domain with enough evidence');
  return questions;
}

export function childQuestion(question: Engine2Question): Engine2Question {
  // This explicit mapping makes it impossible to accidentally add adult metadata later.
  return { id: question.id, domain: question.domain, interactionType: question.interactionType, prompt: question.prompt, options: question.options.map((option) => ({ ...option })) };
}

export const ENGINE2_OBSERVED_PROFILE_DISCLAIMER = 'These are observations from this exploration, not a diagnosis, screening result, comparison, prediction, or clinical advice.';
