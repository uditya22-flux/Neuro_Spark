import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/strength_funnel/data/strength_funnel_math.dart';
import 'package:mindbridge_app/features/strength_funnel/models/strength_funnel_finalists.dart';
import 'package:mindbridge_app/features/strength_funnel/models/strength_funnel_progress.dart';
import 'package:mindbridge_app/services/strength_funnel_progress_service.dart';

void main() {
  group('StrengthFunnelMath layer targets', () {
    test('elimination layers follow 60% progression', () {
      expect(sectorsAtLayerStart(1), 30);
      expect(sectorsAtLayerStart(2), 18);
      expect(sectorsAtLayerStart(3), 11);
      expect(sectorsAtLayerStart(4), 7);
      expect(sectorsAtLayerStart(5), 4);
      expect(sectorsAdvancingAfterLayer(1), 18);
      expect(sectorsAdvancingAfterLayer(2), 11);
      expect(sectorsAdvancingAfterLayer(3), 7);
      expect(sectorsAdvancingAfterLayer(4), 4);
    });

    test('beta exit is after all ten layers', () {
      expect(kStrengthFunnelBetaExitLayer, 10);
      expect(isDeepDiveLayer(6), isTrue);
      expect(isEliminationLayer(5), isTrue);
    });
  });

  group('StrengthFunnelProgress', () {
    test('JSON round-trip preserves awaiting-next-layer state', () {
      const progress = StrengthFunnelProgress(
        sessionId: 'local_session_abc',
        layerNumber: 2,
        awaitingNextLayer: true,
        advancingSectorIds: ['r_build_fix', 'a_drawing_color'],
      );

      final restored = StrengthFunnelProgress.fromJson(progress.toJson());
      expect(restored.sessionId, 'local_session_abc');
      expect(restored.layerNumber, 2);
      expect(restored.awaitingNextLayer, isTrue);
      expect(restored.advancingSectorIds.length, 2);
    });

    test('decode helper matches fromJson', () {
      const progress = StrengthFunnelProgress(
        sessionId: 'sess-1',
        layerNumber: 3,
        completedSectorIds: ['sector_a'],
        layerScores: {'sector_a': 0.9},
      );
      final raw = jsonEncode(progress.toJson());
      final restored = decodeStrengthFunnelProgressJson(raw);
      expect(restored.completedSectorIds, ['sector_a']);
      expect(restored.layerScores['sector_a'], 0.9);
    });
    test('finalists JSON round-trip', () {
      final finalists = StrengthFunnelFinalists(
        sectorIds: const ['r_build_fix', 'a_drawing_color'],
        completedAt: DateTime.utc(2026, 8, 24),
        layerScores: const {'r_build_fix': 0.9},
      );
      final restored = StrengthFunnelFinalists.fromJson(finalists.toJson());
      expect(restored.sectorIds.length, 2);
      expect(restored.layerScores['r_build_fix'], 0.9);
    });
  });
}
