export const EXPLORATION_TAXONOMY = {
  version: '2026-07-01',
  keys: [
    'calendar-sequencing-exploration',
    'visual-pattern-exploration',
  ] as const,
} as const;

export type TaxonomyKey = (typeof EXPLORATION_TAXONOMY.keys)[number];

export function isTaxonomyKey(value: string): value is TaxonomyKey {
  return (EXPLORATION_TAXONOMY.keys as readonly string[]).includes(value);
}
