// Synthetic showcase Engine 2 survivor selection. This is deliberately a
// deterministic response-signal filter: it does not make a diagnostic or
// predictive conclusion about a child.

export type SyntheticLayerSignal<Sector extends string = string> = {
  sector: Sector;
  isolationScore: number;
  supportLevel: number;
  activeIndex: number;
};

// The score is already the fixed 40% accuracy / 30% recovery / 20%
// engagement / 10% speed calculation. A sector proceeds only when its latest
// completed-layer score meets this explicit shared response-signal bar.
//
// Layer 1 intentionally has no count cap: if 20 sectors meet 0.60, all 20
// appear in Layer 2; if five meet it, only those five appear in Layer 2.
export const SYNTHETIC_SURVIVAL_SCORE_THRESHOLD = 0.60;

export function survivalThresholdAfterLayer(_completedLayer: number): number {
  return SYNTHETIC_SURVIVAL_SCORE_THRESHOLD;
}

function boundedScore(value: number, fallback: number): number {
  return Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : fallback;
}

function nonNegativeNumber(value: number, fallback: number): number {
  return Number.isFinite(value) ? Math.max(0, value) : fallback;
}

function orderedSignals<Sector extends string>(
  signals: readonly SyntheticLayerSignal<Sector>[],
): SyntheticLayerSignal<Sector>[] {
  return [...signals].sort((left, right) => {
    const scoreDelta = boundedScore(right.isolationScore, 0) -
      boundedScore(left.isolationScore, 0);
    if (scoreDelta !== 0) return scoreDelta;

    // Lower support use wins an otherwise equal interaction signal.
    const supportDelta =
      nonNegativeNumber(left.supportLevel, Number.MAX_SAFE_INTEGER) -
      nonNegativeNumber(right.supportLevel, Number.MAX_SAFE_INTEGER);
    if (supportDelta !== 0) return supportDelta;

    const activeDelta = left.activeIndex - right.activeIndex;
    if (activeDelta !== 0) return activeDelta;
    return left.sector.localeCompare(right.sector);
  });
}

/**
 * Selects sectors from the latest completed layer's interaction signals.
 *
 * A layer with no signals above the score bar still keeps its deterministic
 * highest-ranked sector so the fictional flow never dead-ends. The transition
 * from Layer 9 to the Layer 10 capstone resolves the remaining candidates to
 * exactly one sector using the same score/support/order tie-breakers.
 */
export function selectSyntheticSurvivors<Sector extends string>(
  signals: readonly SyntheticLayerSignal<Sector>[],
  completedLayer: number,
): Sector[] {
  const ranked = orderedSignals(signals);
  if (ranked.length === 0) return [];

  const threshold = survivalThresholdAfterLayer(completedLayer);
  const passing = ranked.filter((signal) =>
    boundedScore(signal.isolationScore, 0) >= threshold
  );
  const retained = passing.length > 0 ? passing : [ranked[0]];

  // Layer 10 is the single-sector capstone. This is not a fixed top-N cut at
  // earlier layers: it is the terminal deterministic tie-break after nine
  // response-driven filtering passes.
  if (completedLayer >= 9) return [retained[0].sector];
  return retained.map((signal) => signal.sector);
}
