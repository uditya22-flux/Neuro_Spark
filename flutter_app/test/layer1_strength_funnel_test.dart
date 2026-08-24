import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/data/strength_funnel_repository.dart';
import 'package:mindbridge_app/features/strength_funnel/models/layer1_sector_task.dart';
import 'package:mindbridge_app/features/strength_funnel/data/strength_funnel_math.dart';
import 'package:mindbridge_app/features/strength_funnel/presentation/layer1_sector_prompt_widget.dart';
import 'package:mindbridge_app/features/strength_funnel/providers/strength_funnel_controller.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/providers/game_environment_provider.dart';
import 'package:mindbridge_app/services/modality_router.dart';

void main() {
  group('ModalityRouter', () {
    const router = ModalityRouter();

    test('high speech support need disables text modality', () {
      const clinical = ISAAClinicalProfile(speechCommunication: 5);
      const parent = ParentQualitativeProfile();
      final c = router.routeFromIsaa(clinical, parent);
      expect(c.allowText, isFalse);
      expect(c.requiresVisualItems, isTrue);
    });

    test('resolveRendererModality picks picture when text disallowed', () {
      const clinical = ISAAClinicalProfile(speechCommunication: 5);
      const parent = ParentQualitativeProfile();
      final c = router.routeFromIsaa(clinical, parent);
      expect(router.resolveRendererModality(c), 'picture');
    });

    test('golden rule rejects career language', () {
      expect(
        () => router.assertPresentMomentFraming('Would you like this career?'),
        throwsStateError,
      );
    });
  });

  group('StrengthFunnelRepository local fallback', () {
    test('startLayer1 returns 30 present-moment tasks', () async {
      const repo = StrengthFunnelRepository();
      const bundle = IntakeSessionBundle(
        clinical: ISAAClinicalProfile(speechCommunication: 5),
        parent: ParentQualitativeProfile(),
        config: GameEnvironmentConfig(
          themePalette: ThemePalette.calmDark,
          audioMode: AudioMode.completelyMuted,
          hapticEnabled: false,
          instructionStyle: InstructionStyle.pureVisualGlowHints,
          assetTheme: 'cosmic_space',
          strictGroundingEnforced: true,
          startingDifficultyTier: 1,
        ),
      );

      final result = await repo.startLayer1(bundle);
      expect(result.tasks.length, 30);
      expect(result.remote, isFalse);
      expect(result.tasks.first.rendererModality, 'picture');
    });
  });

  group('Layer1SectorPromptWidget', () {
    testWidgets('renders picture modality for low-verbal profile', (tester) async {
      const router = ModalityRouter();
      const clinical = ISAAClinicalProfile(speechCommunication: 5);
      const parent = ParentQualitativeProfile();
      final constraints = router.routeFromIsaa(clinical, parent);
      final modality = router.resolveRendererModality(constraints);
      final task = Layer1SectorTask.sampleRealistic(rendererModality: modality);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Layer1SectorPromptWidget(task: task, constraints: constraints),
          ),
        ),
      );

      expect(find.textContaining('Picture card'), findsOneWidget);
      expect(find.textContaining('fun for you right now'), findsOneWidget);
    });
  });

  group('StrengthFunnelMath', () {
    test('selectAdvancingSectors picks top 60% by engagement', () {
      final scores = <String, double>{
        for (var i = 0; i < 30; i++) 'sector_$i': i / 30,
      };
      final advancing = selectAdvancingSectors(scores, sectorsAdvancingAfterLayer(1));
      expect(advancing.length, 18);
      expect(advancing.first, 'sector_29');
      expect(advancing.last, 'sector_12');
    });
  });

  group('StrengthFunnelController', () {
    test('local session completes a layer after all sectors scored', () async {
      const bundle = IntakeSessionBundle(
        clinical: ISAAClinicalProfile(),
        parent: ParentQualitativeProfile(),
        config: GameEnvironmentConfig(
          themePalette: ThemePalette.calmDark,
          audioMode: AudioMode.ambientBinauralSoft,
          hapticEnabled: true,
          instructionStyle: InstructionStyle.pictorialGuideCards,
          assetTheme: 'cosmic_space',
          strictGroundingEnforced: false,
          startingDifficultyTier: 1,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          gameEnvironmentProvider.overrideWith((ref) => GameEnvironmentNotifier()..set(bundle)),
          strengthFunnelRepositoryProvider.overrideWith(
            (ref) => _MiniStrengthFunnelRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(strengthFunnelControllerProvider.notifier);
      await controller.startLayer1();

      var complete = false;
      for (var i = 0; i < 3; i++) {
        complete = await controller.submitCurrentScore(0.8);
      }

      expect(complete, isFalse);
      final state = container.read(strengthFunnelControllerProvider);
      expect(state.layerComplete, isTrue);
      expect(state.canStartNextLayer, isTrue);
      expect(state.advancingSectorIds?.length, 3);
    });
  });
}

/// Repository stub that returns three sectors for fast controller tests.
class _MiniStrengthFunnelRepository extends StrengthFunnelRepository {
  @override
  Future<StrengthFunnelStartResult> startLayer(
    IntakeSessionBundle bundle, {
    required int layerNumber,
    String? sessionId,
  }) async {
    const router = ModalityRouter();
    final constraints = router.routeFromIsaa(bundle.clinical, bundle.parent);
    final modality = router.resolveRendererModality(constraints);
    final tasks = List.generate(
      layerNumber == 1 ? 3 : 2,
      (i) => Layer1SectorTask(
        sectorId: 'sector_${layerNumber}_$i',
        displayName: 'Sector $i',
        presentMomentPrompt: 'Is play $i fun for you right now?',
        activityLabel: 'Activity $i',
        pictureDescription: 'Simple drawing $i',
        rendererModality: modality,
        minEnjoymentLabel: 'Not fun right now',
        maxEnjoymentLabel: 'Really fun right now',
      ),
    );
    return StrengthFunnelStartResult(
      sessionId: sessionId ?? 'local_session_test',
      layerRunId: 'local_layer_${layerNumber}_test',
      layerNumber: layerNumber,
      totalSectors: tasks.length,
      constraints: constraints,
      tasks: tasks,
      completedSectorIds: const [],
      remote: false,
    );
  }
}
