/// 60% filter math — mirrors `supabase/functions/_shared/strength_funnel.ts`.

const layerSectorTargets = <int, int>{
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

int sectorsAtLayerStart(int layer) => layerSectorTargets[layer] ?? 30;

int sectorsAdvancingAfterLayer(int layer) {
  if (layer >= 6) return layerSectorTargets[layer] ?? 2;
  return layerSectorTargets[layer + 1] ??
      (layerSectorTargets[layer]! * 0.6).ceil().clamp(2, 30);
}

List<String> selectAdvancingSectors(
  Map<String, double> scores,
  int advanceCount,
) {
  final entries = scores.entries.toList()
    ..sort((a, b) {
      final diff = b.value.compareTo(a.value);
      if (diff != 0) return diff;
      return a.key.compareTo(b.key);
    });
  return entries.take(advanceCount).map((e) => e.key).toList();
}

/// Layers 1–2 are offered before the deepening assessment in the current beta flow.
const kStrengthFunnelBetaExitLayer = 2;

bool isEliminationLayer(int layer) => layer <= 5;
