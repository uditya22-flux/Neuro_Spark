/// 60% adaptive filtering — advancement is driven by the child's scores, not fixed layer sizes.

import '../../../core/config/demo_config.dart';

/// Enjoyment at or above this (0–1 slider) qualifies a sector to advance.
const double kEngagementAdvanceThreshold = 0.6;

const double kLayerAdvanceRatio = 0.6;

/// Reference targets when all 30 sectors start layer 1 (documentation / UI hints only).
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

/// Max sectors that may advance after a layer (ceil(60% of how many were scored)).
int computeAdvanceCap(int scoredInLayer) {
  if (scoredInLayer <= 0) return 0;
  if (scoredInLayer == 1) return 1;
  return (scoredInLayer * kLayerAdvanceRatio).ceil().clamp(1, scoredInLayer);
}

/// Legacy fixed lookup — only matches a full 30-sector funnel where every child hits threshold.
int sectorsAdvancingAfterLayer(int layer) {
  if (layer >= 6) return layerSectorTargets[layer] ?? 2;
  return layerSectorTargets[layer + 1] ??
      computeAdvanceCap(layerSectorTargets[layer] ?? 30);
}

/// Picks sectors for the next layer from this layer's enjoyment scores.
///
/// - Layers 1–5: sectors scored ≥ [kEngagementAdvanceThreshold], up to [computeAdvanceCap].
///   If none meet the threshold, the top cap scorers still advance so the funnel can continue.
/// - Layers 6–10: deep-dive — all assessed sectors continue (no elimination).
List<String> selectAdvancingSectors(
  Map<String, double> scores, {
  required int layerNumber,
}) {
  if (scores.isEmpty) return [];

  if (layerNumber >= 6) {
    final ids = scores.keys.toList()..sort();
    return ids;
  }

  final ranked = scores.entries.toList()
    ..sort((a, b) {
      final diff = b.value.compareTo(a.value);
      if (diff != 0) return diff;
      return a.key.compareTo(b.key);
    });

  final cap = computeAdvanceCap(scores.length);
  final aboveThreshold =
      ranked.where((e) => e.value >= kEngagementAdvanceThreshold).toList();

  if (aboveThreshold.isNotEmpty) {
    return aboveThreshold.take(cap).map((e) => e.key).toList();
  }

  return ranked.take(cap).map((e) => e.key).toList();
}

/// Full production funnel depth (guardian + child field testing).
const int kFullStrengthFunnelLayers = 10;

int get kStrengthFunnelBetaExitLayer =>
    DemoConfig.isActive ? DemoConfig.exitLayer : kFullStrengthFunnelLayers;

bool isEliminationLayer(int layer) => layer <= 5;

bool isDeepDiveLayer(int layer) => layer >= 6;

int sectorsAdvancingDisplayCount(int completedLayer, int scoredInLayer) {
  if (!isEliminationLayer(completedLayer)) return scoredInLayer;
  return computeAdvanceCap(scoredInLayer);
}
