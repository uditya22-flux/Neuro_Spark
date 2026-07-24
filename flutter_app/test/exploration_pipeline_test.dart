import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/exploration/models/exploration_models.dart';
import 'package:mindbridge_app/features/exploration/models/visual_scene_spec.dart';
import 'package:mindbridge_app/features/exploration/services/capstone_router.dart';
import 'package:mindbridge_app/features/exploration/services/deepening_task_factory.dart';
import 'package:mindbridge_app/features/exploration/services/layer1_generator.dart';
import 'package:mindbridge_app/features/exploration/services/play_routing_score_calculator.dart';
import 'package:mindbridge_app/features/exploration/services/synthetic_demo_scene_mapper.dart';

void main() {
  const intake = IntakeConfiguration(
    childId: '00000000-0000-0000-0000-000000000001',
    audioLimit: 40,
    visualClutterTolerance: VisualClutterTolerance.low,
    hyperFocusTheme: 'Trains',
    sandboxPreference: SandboxPreference.constellation,
  );

  test('ambient baseline covers all 30 mechanics through ten compounded scenes',
      () {
    final scenes = Layer1Generator.generate(intake: intake, seed: 2);
    expect(scenes, hasLength(10));
    expect(scenes.expand((scene) => scene.mechanics).toSet(),
        equals(PlayMechanic.values.toSet()));
    expect(scenes.every((scene) => scene.mechanics.length == 3), isTrue);
  });

  test('Layer 1 stays a balanced six-group, thirty-sector visual catalogue',
      () {
    expect(PlayMechanic.values, hasLength(30));
    expect(PlayMechanicGroup.values, hasLength(6));
    for (final group in PlayMechanicGroup.values) {
      expect(
        PlayMechanic.values.where((mechanic) => mechanic.group == group),
        hasLength(5),
        reason: '${group.label} must keep five word-free visual sectors.',
      );
    }

    // Every sector has an allowlisted renderer type. The child surface never
    // needs a written question to distinguish the wide-net tasks.
    for (final mechanic in PlayMechanic.values) {
      expect(visualPuzzleKindForMechanic(mechanic), isA<VisualPuzzleKind>());
    }
  });

  test('local builder scenes keep all thirty mechanics visually distinct', () {
    final plans = PlayMechanic.values
        .map(VisualPuzzlePlan.localForMechanic)
        .toList(growable: false);

    expect(plans, hasLength(30));
    expect(
      plans.map((plan) => plan.rule).toSet(),
      hasLength(30),
      reason: 'Each Layer 1 sector needs its own word-free visual rule.',
    );

    for (final mechanic in PlayMechanic.values) {
      final plan = VisualPuzzlePlan.localForMechanic(mechanic);
      final scene = VisualSceneSpec.localForMechanic(
        mechanic: mechanic,
        itemCount: 3,
        subject: 'vehicles',
        palette: const ['blue', 'green'],
        objectStyle: VisualStylePreference.illustratedObjects.name,
        motionAllowed: true,
      );

      expect(plan.rule, visualPuzzleRuleForMechanic(mechanic));
      expect(plan.stimulus, isNotEmpty);
      expect(scene.puzzlePlan?.rule, plan.rule);
      expect(scene.sceneType, plan.kind.wireName);
    }
  });

  test('builder Layer 1 contains one shuffled, themed task for every mechanic',
      () {
    final firstRun =
        Layer1Generator.generateBuilderShowcase(intake: intake, seed: 27);
    final secondRun =
        Layer1Generator.generateBuilderShowcase(intake: intake, seed: 27);

    expect(firstRun, hasLength(30));
    expect(firstRun.map((task) => task.id),
        equals(secondRun.map((task) => task.id)));
    expect(firstRun.map((task) => task.mechanics.single).toSet(),
        equals(PlayMechanic.values.toSet()));
    expect(firstRun.every((task) => task.mechanics.length == 1), isTrue);
    expect(firstRun.every((task) => task.layer == 1), isTrue);
    expect(firstRun.every((task) => task.visualThemeKey.contains('Trains')),
        isTrue);
  });

  test('builder layers only create tasks for their surviving mechanics', () {
    final survivors = PlayMechanic.values.take(10).toList(growable: false);
    final layer2 = DeepeningTaskFactory.buildBuilderLayer(
      intake: intake,
      layer: 2,
      activeMechanics: survivors,
      seed: 5,
    );
    final layer6 = DeepeningTaskFactory.buildBuilderLayer(
      intake: intake,
      layer: 6,
      activeMechanics: survivors.take(5).toList(growable: false),
      seed: 5,
    );

    expect(layer2, hasLength(10));
    expect(layer2.map((task) => task.mechanics.single).toSet(),
        equals(survivors.toSet()));
    expect(layer2.every((task) => task.difficulty == 2), isTrue);
    expect(layer2.every((task) => task.itemCount > 3), isTrue);
    expect(layer6, hasLength(5));
    expect(layer6.every((task) => task.difficulty == 6), isTrue);
  });

  test('Layer 1 retains every deterministic strong sector, not a fixed Top 10',
      () {
    const results = [
      PlayRoutingResult(
        mechanic: PlayMechanic.mentalRotation,
        score: 92,
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .2,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.visualPatternCompletion,
        score: 65,
        accuracy: .7,
        recovery: 1,
        engagement: .8,
        speed: .2,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.pointCloudAnomalyDetection,
        score: 59,
        accuracy: .7,
        recovery: 1,
        engagement: .8,
        speed: .2,
        supportLevelUsed: 0,
      ),
    ];

    expect(
      BuilderSurvivorSelector.selectForNextLayer(
        completedLayer: 1,
        latestLayerResults: results.reversed,
      ),
      equals([
        PlayMechanic.mentalRotation,
        PlayMechanic.visualPatternCompletion,
      ]),
    );
  });

  test('later builder layers filter only their most recent response scores',
      () {
    const latestLayerResults = [
      PlayRoutingResult(
        mechanic: PlayMechanic.mapRouteNavigation,
        score: 95,
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .5,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.visualSpatialConstruction,
        score: 84,
        accuracy: .9,
        recovery: 1,
        engagement: .9,
        speed: .4,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.chronologicalSequencing,
        score: 83.5,
        accuracy: .9,
        recovery: 1,
        engagement: .9,
        speed: .4,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.narrativeEventOrdering,
        score: 70,
        accuracy: .8,
        recovery: .8,
        engagement: .8,
        speed: .4,
        supportLevelUsed: 0,
      ),
    ];

    // 95 × .88 = 83.6. The selection is driven solely by these latest
    // results: no historical rank and no fixed sector count is consulted.
    expect(
      BuilderSurvivorSelector.selectForNextLayer(
        completedLayer: 4,
        latestLayerResults: latestLayerResults,
      ),
      equals([
        PlayMechanic.mapRouteNavigation,
        PlayMechanic.visualSpatialConstruction,
        PlayMechanic.chronologicalSequencing,
        PlayMechanic.narrativeEventOrdering,
      ]),
    );
  });

  test('response-driven threshold can narrow a Layer 1 pool from 30 to 20', () {
    final results = List<PlayRoutingResult>.generate(
      PlayMechanic.values.length,
      (index) => PlayRoutingResult(
        mechanic: PlayMechanic.values[index],
        score: (index < 20 ? 80 - index : 59).toDouble(),
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .2,
        supportLevelUsed: 0,
      ),
    );

    final survivors = BuilderSurvivorSelector.selectForNextLayer(
      completedLayer: 1,
      latestLayerResults: results.reversed,
    );

    expect(survivors, hasLength(20));
    expect(survivors, equals(PlayMechanic.values.take(20).toList()));
  });

  test('response-driven threshold can narrow a later pool from 20 to 5', () {
    final results = List<PlayRoutingResult>.generate(
      20,
      (index) => PlayRoutingResult(
        mechanic: PlayMechanic.values[index],
        score: (index < 5 ? 80 - index : 59).toDouble(),
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .2,
        supportLevelUsed: 0,
      ),
    );

    final survivors = BuilderSurvivorSelector.selectForNextLayer(
      completedLayer: 5,
      latestLayerResults: results,
    );

    expect(survivors, hasLength(5));
    expect(survivors, equals(PlayMechanic.values.take(5).toList()));
  });

  test('the Layer 10 capstone receives exactly one latest-layer winner', () {
    const results = [
      PlayRoutingResult(
        mechanic: PlayMechanic.chronologicalSequencing,
        score: 88,
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .2,
        supportLevelUsed: 0,
      ),
      PlayRoutingResult(
        mechanic: PlayMechanic.mapRouteNavigation,
        score: 93,
        accuracy: 1,
        recovery: 1,
        engagement: 1,
        speed: .3,
        supportLevelUsed: 0,
      ),
    ];

    expect(
      BuilderSurvivorSelector.selectForNextLayer(
        completedLayer: 9,
        latestLayerResults: results,
      ),
      equals([PlayMechanic.mapRouteNavigation]),
    );
  });

  test('builder routing uses the fixed 40/30/20/10 formula', () {
    const observation = PlayObservation(
      mechanics: [PlayMechanic.mapRouteNavigation],
      layer: 1,
      expectedInteractions: 2,
      speedBudgetMs: 6000,
      telemetry: ExplorationTelemetry(
        activeLatencyMs: 3000,
        misclicks: 1,
        recoveredErrors: 1,
        interactions: 2,
        correctInteractions: 1,
      ),
    );

    final result = PlayRoutingScoreCalculator.fromObservation(observation);

    // .40 × .50 + .30 × 1 + .20 × 1 + .10 × .50 = .75
    expect(result.score, closeTo(75, .001));
    expect(result.accuracy, .5);
    expect(result.recovery, 1);
    expect(result.engagement, 1);
    expect(result.speed, .5);
  });

  test('a weak Layer 1 still keeps the strongest response moving', () {
    final observations = PlayMechanic.values
        .map(
          (mechanic) => PlayObservation(
            mechanics: [mechanic],
            layer: 1,
            expectedInteractions: 1,
            speedBudgetMs: 30000,
            telemetry: ExplorationTelemetry(
              activeLatencyMs: 300 + mechanic.index * 500,
              misclicks: 0,
              recoveredErrors: 0,
              interactions: 1,
              correctInteractions: 1,
            ),
          ),
        )
        .toList(growable: false);

    final ranked = PlayRoutingScoreCalculator.rank(observations);
    final survivors = BuilderSurvivorSelector.selectForNextLayer(
      completedLayer: 1,
      latestLayerResults: ranked.map(
        (result) => PlayRoutingResult(
          mechanic: result.mechanic,
          score: 20 + result.mechanic.index * .01,
          accuracy: result.accuracy,
          recovery: result.recovery,
          engagement: result.engagement,
          speed: result.speed,
          supportLevelUsed: result.supportLevelUsed,
        ),
      ),
    );

    expect(survivors, hasLength(1));
    expect(survivors.single, PlayMechanic.visualArtisticComposition);
  });

  test(
      'deepening rotates play mechanics without removing them from a child ranking',
      () {
    final layer2 = DeepeningTaskFactory.build(intake: intake, layer: 2);
    final layer8 = DeepeningTaskFactory.build(intake: intake, layer: 8);
    expect(layer2.mechanics, isNot(equals(layer8.mechanics)));
    expect(layer8.themedPrompt, contains('Trains'));
  });

  test('low visual-clutter preference disables optional distractors', () {
    final layer6 = DeepeningTaskFactory.build(intake: intake, layer: 6);
    expect(layer6.showsDistractors, isFalse);
  });

  test(
      'guardian support preferences restore into the same interface configuration',
      () {
    const configured = IntakeConfiguration(
      childId: '00000000-0000-0000-0000-000000000001',
      audioLimit: 20,
      visualClutterTolerance: VisualClutterTolerance.low,
      hyperFocusTheme: 'Space',
      audioFeedbackPreference: AudioFeedbackPreference.mutedHaptics,
      brightnessTolerance: SensoryTolerance.low,
      motionTolerance: SensoryTolerance.low,
      interactionPreference: InteractionPreference.tapping,
      visualRepetitionHelpful: true,
      communicationPreference: CommunicationPreference.symbolsOrAac,
      knownTriggers: {KnownTrigger.timers, KnownTrigger.busyScreens},
    );

    final restored = IntakeConfiguration.fromJson(
      childId: configured.childId,
      json: configured.toJson(),
    );

    expect(restored, isNotNull);
    expect(restored!.hyperFocusTheme, 'Space');
    expect(restored.interface.allowDistractors, isFalse);
    expect(restored.interface.preferHaptics, isTrue);
    expect(restored.interface.allowMotion, isFalse);
    expect(restored.interface.showTimePressure, isFalse);
    expect(restored.interface.communicationPreference,
        CommunicationPreference.symbolsOrAac);
  });

  test('guardian sandbox preference determines the final destination', () {
    expect(CapstoneRouter.verticalIdFor(intake.sandboxPreference),
        'constellation_mapper');
  });

  test('capstone mapping is available only for direct sandbox mechanics', () {
    expect(
      CapstoneRouter.verticalIdForPlayMechanic(
          PlayMechanic.chronologicalSequencing),
      'calendar_genius',
    );
    expect(
      CapstoneRouter.verticalIdForPlayMechanic(PlayMechanic.mapRouteNavigation),
      'constellation_mapper',
    );
    expect(
      CapstoneRouter.verticalIdForPlayMechanic(
          PlayMechanic.visualArtisticComposition),
      isNull,
    );
  });

  test(
      'every fictional parent-text input gets a stable demo scene family locally',
      () {
    expect(
      SyntheticDemoSceneMapper.fromIntakeText(
        theme: 'Metro maps and train stations',
        favouriteObjects: 'small locomotives',
        familiarScenes: 'platforms and rails',
      ),
      SyntheticDemoWorld.rail,
    );
    expect(
      SyntheticDemoSceneMapper.fromIntakeText(
        theme: 'planetary orbits',
        favouriteObjects: 'stars',
        familiarScenes: 'night sky',
      ),
      SyntheticDemoWorld.space,
    );
    expect(
      SyntheticDemoSceneMapper.fromIntakeText(
        theme: 'an unfamiliar fictional collection of objects',
        favouriteObjects: '',
        familiarScenes: '',
      ),
      isIn(SyntheticDemoWorld.values),
    );
  });

  test('intake preferences are carried into the word-free play surface', () {
    const personalised = IntakeConfiguration(
      childId: 'local-demo-child',
      audioLimit: 25,
      visualClutterTolerance: VisualClutterTolerance.low,
      hyperFocusTheme: 'City buses and road maps',
      interactionPreference: InteractionPreference.dragging,
      visualRepetitionHelpful: true,
      motionTolerance: SensoryTolerance.low,
      audioFeedbackPreference: AudioFeedbackPreference.mutedHaptics,
      familiarColors: {FamiliarColor.blue, FamiliarColor.green},
      visualStylePreference: VisualStylePreference.illustratedObjects,
    );
    final scene = Layer1Generator.generate(intake: personalised, seed: 7).first;

    expect(scene.visualThemeKey, contains('City buses'));
    expect(scene.familiarColors,
        containsAll({FamiliarColor.blue, FamiliarColor.green}));
    expect(scene.interactionPreference, InteractionPreference.dragging);
    expect(scene.visualRepetitionHelpful, isTrue);
    expect(scene.allowMotion, isFalse);
    expect(scene.preferHaptics, isTrue);
  });
}
