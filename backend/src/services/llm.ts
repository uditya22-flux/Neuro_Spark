import { z } from 'zod';
import { assertSafeChildExperience } from '../domain/childExperience';
import { EXPLORATION_TAXONOMY, type TaxonomyKey } from '../domain/taxonomy';

const sensoryDraftSchema = z.object({
  items: z.array(z.object({
    key: z.enum(['soundEnabled', 'hapticsEnabled', 'reducedMotion', 'theme', 'contrast']),
    value: z.union([z.boolean(), z.enum(['calm', 'night', 'garden', 'space', 'standard', 'high'])]),
    rationale: z.string().max(240),
  })).min(1).max(5),
});

const childRevealSchema = z.object({ title: z.string().min(1).max(80), message: z.string().min(1).max(280) });
const adultNoteSchema = z.object({
  taxonomyKey: z.enum(EXPLORATION_TAXONOMY.keys),
  observations: z.array(z.string().max(220)).min(1).max(3),
  evidence: z.record(z.union([z.string(), z.number(), z.boolean()])),
});

export type SensoryDraft = z.infer<typeof sensoryDraftSchema>;
export type ChildRevealDraft = z.infer<typeof childRevealSchema>;
export type AdultNoteDraft = z.infer<typeof adultNoteSchema>;

export interface LlmProvider {
  readonly modelConfig: Record<string, string | number | boolean>;
  draftSensoryConfiguration(redactedIntake: string): Promise<SensoryDraft>;
  createChildReveal(track: 'CALENDAR_GENIUS' | 'CONSTELLATION_MAPPER'): Promise<ChildRevealDraft>;
  createAdultNote(track: 'CALENDAR_GENIUS' | 'CONSTELLATION_MAPPER', evidence: Record<string, number | string | boolean>): Promise<AdultNoteDraft>;
}

/** Deterministic development adapter. It accepts only redacted text and has no network access. */
export class FakeLlmProvider implements LlmProvider {
  readonly modelConfig = { provider: 'fake', model: 'mindbridge-schema-fixture', temperature: 0 };

  async draftSensoryConfiguration(redactedIntake: string): Promise<SensoryDraft> {
    const input = redactedIntake.toLowerCase();
    const items = [
      { key: 'soundEnabled' as const, value: !/sound|noise|quiet/.test(input), rationale: 'Start with a gentle sound setting that the guardian can review.' },
      { key: 'hapticsEnabled' as const, value: false, rationale: 'Start with haptics off unless the guardian chooses otherwise.' },
      { key: 'reducedMotion' as const, value: /motion|movement|dizzy/.test(input), rationale: 'Use reduced movement when it may make play more comfortable.' },
      { key: 'theme' as const, value: /space|star/.test(input) ? 'space' as const : 'calm' as const, rationale: 'Offer a calm visual theme that can be changed at any time.' },
      { key: 'contrast' as const, value: 'standard' as const, rationale: 'Begin with standard contrast and let the guardian choose high contrast if useful.' },
    ];
    return sensoryDraftSchema.parse({ items });
  }

  async createChildReveal(track: 'CALENDAR_GENIUS' | 'CONSTELLATION_MAPPER'): Promise<ChildRevealDraft> {
    const result = track === 'CALENDAR_GENIUS'
      ? { title: 'Thoughtful organiser', message: 'You explored ways to put days in an order. Thanks for sharing your ideas.' }
      : { title: 'Careful star explorer', message: 'You explored shapes in a star map. Thanks for taking time to notice details.' };
    // Re-use the child DTO content guard for prohibited vocabulary checks.
    assertSafeChildExperience({ sessionId: 'safe-check', layer: 1, track: 'calendar-genius', sensory: { soundEnabled: false, hapticsEnabled: false, reducedMotion: true, theme: 'calm', contrast: 'standard' }, puzzle: { kind: 'calendar-order', prompt: result.message, cards: [] }, celebration: result.title, canSkip: true, canPause: true });
    return childRevealSchema.parse(result);
  }

  async createAdultNote(track: 'CALENDAR_GENIUS' | 'CONSTELLATION_MAPPER', evidence: Record<string, number | string | boolean>): Promise<AdultNoteDraft> {
    const taxonomyKey: TaxonomyKey = track === 'CALENDAR_GENIUS' ? 'calendar-sequencing-exploration' : 'visual-pattern-exploration';
    return adultNoteSchema.parse({
      taxonomyKey,
      observations: [track === 'CALENDAR_GENIUS' ? 'The child chose to explore ordering date cards.' : 'The child chose to explore visual star-map patterns.'],
      evidence,
    });
  }
}

export function createLlmProvider(): LlmProvider {
  // Development deliberately has no network LLM dependency. Production permits
  // OpenAI only; a live adapter is enabled only after its privacy controls,
  // project key, and schema-conformance integration have been approved.
  if ((process.env.LLM_PROVIDER ?? 'fake') !== 'fake') throw new Error('The approved OpenAI adapter is not configured for this environment');
  return new FakeLlmProvider();
}
