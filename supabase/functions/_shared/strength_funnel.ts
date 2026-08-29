/**
 * 60% adaptive filtering for the 10-layer RIASEC strength funnel.
 *
 * Advancement is **score-driven**: only sectors the child enjoyed (≥60% on the slider)
 * move forward, capped at ceil(60% of sectors assessed this layer).
 * Fixed 30→18→11 targets apply only when all 30 sectors are assessed and qualify.
 */

export const TOTAL_SECTORS = 30;
export const FILTER_RATIO = 0.6;
export const ENGAGEMENT_ADVANCE_THRESHOLD = 0.6;

/** Reference sector counts when the full 30-sector funnel is used (not fixed advancement). */
export const LAYER_SECTOR_TARGETS: Record<number, number> = {
  1: 30,
  2: 18,
  3: 11,
  4: 7,
  5: 4,
  6: 4,
  7: 3,
  8: 3,
  9: 2,
  10: 2,
};

export interface SectorEngagement {
  sectorId: string;
  engagementScore: number;
}

export function computeAdvanceCap(scoredInLayer: number): number {
  if (scoredInLayer <= 0) return 0;
  if (scoredInLayer === 1) return 1;
  return Math.max(1, Math.min(scoredInLayer, Math.ceil(scoredInLayer * FILTER_RATIO)));
}

/** @deprecated Prefer computeAdvanceCap(actualScoredCount) */
export function sectorsAdvancingAfterLayer(layer: number): number {
  if (layer >= 6) {
    return LAYER_SECTOR_TARGETS[layer] ?? 2;
  }
  return LAYER_SECTOR_TARGETS[layer + 1] ??
    computeAdvanceCap(LAYER_SECTOR_TARGETS[layer] ?? TOTAL_SECTORS);
}

export function sectorsAtLayerStart(layer: number): number {
  return LAYER_SECTOR_TARGETS[layer] ?? TOTAL_SECTORS;
}

export function selectAdvancingSectors(
  scores: SectorEngagement[],
  layerNumber: number,
): string[] {
  if (scores.length === 0) return [];

  if (layerNumber >= 6) {
    return [...scores].map((s) => s.sectorId).sort();
  }

  const ranked = [...scores].sort((a, b) => {
    const diff = b.engagementScore - a.engagementScore;
    if (diff !== 0) return diff;
    return a.sectorId.localeCompare(b.sectorId);
  });

  const cap = computeAdvanceCap(scores.length);
  const aboveThreshold = ranked.filter(
    (s) => s.engagementScore >= ENGAGEMENT_ADVANCE_THRESHOLD,
  );

  if (aboveThreshold.length > 0) {
    return aboveThreshold.slice(0, cap).map((s) => s.sectorId);
  }

  return ranked.slice(0, cap).map((s) => s.sectorId);
}

export function isEliminationLayer(layer: number): boolean {
  return layer <= 5;
}

export function allSectorIds(): string[] {
  return [
    "r_build_fix", "r_nature_outdoors", "r_sports_movement", "r_crafts_making",
    "r_vehicles_machines",
    "i_puzzles_logic", "i_nature_science", "i_numbers_patterns", "i_maps_exploring",
    "i_experiments_trying",
    "a_drawing_color", "a_music_rhythm", "a_story_imagine", "a_build_design",
    "a_performance_show",
    "s_helping_caring", "s_teaching_showing", "s_team_play", "s_community_events",
    "s_friend_connections",
    "e_leading_groups", "e_selling_trading", "e_planning_events",
    "e_persuading_sharing", "e_starting_projects",
    "c_sorting_organizing", "c_schedules_routines", "c_lists_checklists",
    "c_collecting_sets", "c_patterns_order",
  ];
}

export function initialActiveSectors(): string[] {
  return allSectorIds();
}
