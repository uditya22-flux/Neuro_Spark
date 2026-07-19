import { createHash } from 'node:crypto';
import type { Track } from '@prisma/client';
import type { ChildExperience, SensoryConfiguration } from '../domain/childExperience';
import { assertSafeChildExperience } from '../domain/childExperience';

const DEFAULT_SENSORY: SensoryConfiguration = {
  soundEnabled: false,
  hapticsEnabled: false,
  reducedMotion: true,
  theme: 'calm',
  contrast: 'standard',
};

export const MAX_LAYER = 10;

function deterministicNumber(seed: string, index: number): number {
  const digest = createHash('sha256').update(`${seed}:${index}`).digest();
  return digest.readUInt32BE(0);
}

function shuffle<T>(items: readonly T[], seed: string): T[] {
  const result = [...items];
  for (let index = result.length - 1; index > 0; index -= 1) {
    const other = deterministicNumber(seed, index) % (index + 1);
    [result[index], result[other]] = [result[other], result[index]];
  }
  return result;
}

function calendarPuzzle(seed: string, layer: number) {
  const base = new Date(Date.UTC(2024 + (deterministicNumber(seed, 1) % 3), deterministicNumber(seed, 2) % 12, 1));
  const cardCount = Math.min(3 + Math.ceil(layer / 2), 6);
  const dates = Array.from({ length: cardCount }, (_, index) => {
    const date = new Date(base);
    date.setUTCDate(base.getUTCDate() + (deterministicNumber(seed, index + 8) % 27));
    return { id: `date-${index}`, label: date.toLocaleDateString('en-GB', { timeZone: 'UTC', day: 'numeric', month: 'short', year: 'numeric' }) };
  });
  return {
    kind: 'calendar-order' as const,
    prompt: 'Place these days in the order that feels right to you.',
    cards: shuffle(dates, `${seed}:calendar:${layer}`),
  };
}

function constellationPuzzle(seed: string, layer: number) {
  const pointCount = Math.min(5 + layer, 12);
  const stars = Array.from({ length: pointCount }, (_, index) => ({
    id: `star-${index}`,
    x: 10 + (deterministicNumber(seed, index + 24) % 80),
    y: 10 + (deterministicNumber(seed, index + 48) % 80),
    group: index === pointCount - 1 ? 'different' : 'pattern',
  }));
  return {
    kind: 'constellation-anomaly' as const,
    prompt: 'Notice the star that looks a little different. You can take your time or skip it.',
    stars,
    choices: shuffle(stars.map((star) => ({ id: star.id, label: `Star ${star.id.replace('star-', '')}` })), `${seed}:stars:${layer}`),
  };
}

export function normalizeSensoryConfiguration(value: unknown): SensoryConfiguration {
  const maybe = (value ?? {}) as Partial<SensoryConfiguration>;
  return {
    soundEnabled: typeof maybe.soundEnabled === 'boolean' ? maybe.soundEnabled : DEFAULT_SENSORY.soundEnabled,
    hapticsEnabled: typeof maybe.hapticsEnabled === 'boolean' ? maybe.hapticsEnabled : DEFAULT_SENSORY.hapticsEnabled,
    reducedMotion: typeof maybe.reducedMotion === 'boolean' ? maybe.reducedMotion : DEFAULT_SENSORY.reducedMotion,
    theme: ['calm', 'night', 'garden', 'space'].includes(maybe.theme ?? '') ? maybe.theme as SensoryConfiguration['theme'] : DEFAULT_SENSORY.theme,
    contrast: ['standard', 'high'].includes(maybe.contrast ?? '') ? maybe.contrast as SensoryConfiguration['contrast'] : DEFAULT_SENSORY.contrast,
  };
}

export function buildExperience(input: {
  sessionId: string;
  seed: string;
  track: Track;
  layer: number;
  sensory: unknown;
}): ChildExperience {
  const layer = Math.max(1, Math.min(MAX_LAYER, input.layer));
  const track = input.track === 'CALENDAR_GENIUS' ? 'calendar-genius' : 'constellation-mapper';
  return assertSafeChildExperience({
    sessionId: input.sessionId,
    layer,
    track,
    sensory: normalizeSensoryConfiguration(input.sensory),
    puzzle: track === 'calendar-genius' ? calendarPuzzle(input.seed, layer) : constellationPuzzle(input.seed, layer),
    celebration: 'Thanks for exploring. You can continue, pause, or choose another activity.',
    canSkip: true,
    canPause: true,
  });
}

export type FrictionResult = { shouldOfferCooldown: boolean; reason?: 'pause-pattern' | 'skip-pattern' };

/** A neutral safety circuit breaker, not a performance or engagement signal. */
export function evaluateFrictionCircuitBreaker(events: Array<{ kind: string }>): FrictionResult {
  const recent = events.slice(-3).map((event) => event.kind);
  if (recent.length < 3) return { shouldOfferCooldown: false };
  if (recent.every((kind) => kind === 'PAUSE_REQUESTED')) return { shouldOfferCooldown: true, reason: 'pause-pattern' };
  if (recent.every((kind) => kind === 'TASK_SKIPPED')) return { shouldOfferCooldown: true, reason: 'skip-pattern' };
  return { shouldOfferCooldown: false };
}
