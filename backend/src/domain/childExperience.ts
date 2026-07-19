/**
 * This module is the complete child-facing contract. It must remain independent
 * of guardian-only field notes and must contain only play, sensory, and warm
 * non-clinical language.
 */
export type SensoryConfiguration = {
  soundEnabled: boolean;
  hapticsEnabled: boolean;
  reducedMotion: boolean;
  theme: 'calm' | 'night' | 'garden' | 'space';
  contrast: 'standard' | 'high';
};

export type CalendarPuzzle = {
  kind: 'calendar-order';
  prompt: string;
  cards: Array<{ id: string; label: string }>;
};

export type ConstellationPuzzle = {
  kind: 'constellation-anomaly';
  prompt: string;
  stars: Array<{ id: string; x: number; y: number; group: string }>;
  choices: Array<{ id: string; label: string }>;
};

export type ChildExperience = {
  sessionId: string;
  layer: number;
  track: 'calendar-genius' | 'constellation-mapper';
  sensory: SensoryConfiguration;
  puzzle: CalendarPuzzle | ConstellationPuzzle;
  celebration: string;
  canSkip: true;
  canPause: true;
};

const prohibitedChildTerms = [
  'diagnos', 'autis', 'disorder', 'condition', 'career', 'job', 'employ',
  'industry', 'salary', 'income', 'employer', 'assessment', 'screening',
];

export function assertSafeChildExperience(value: ChildExperience): ChildExperience {
  const serialized = JSON.stringify(value).toLowerCase();
  const forbidden = prohibitedChildTerms.find((term) => serialized.includes(term));
  if (forbidden) throw new Error(`Child experience contains prohibited content: ${forbidden}`);
  return value;
}
