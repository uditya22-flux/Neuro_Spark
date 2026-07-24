import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/exploration/models/exploration_models.dart';
import 'package:mindbridge_app/features/exploration/models/synthetic_engine2_models.dart';
import 'package:mindbridge_app/features/exploration/models/visual_scene_spec.dart';

void main() {
  test('start request keeps guardian free text out of the cloud payload', () {
    const intake = IntakeConfiguration(
      childId: 'not-sent',
      audioLimit: 20,
      visualClutterTolerance: VisualClutterTolerance.low,
      hyperFocusTheme: 'private locomotive collection',
      favouriteObjects: 'private favourite object',
      familiarScenes: 'private familiar place',
      familiarColors: {FamiliarColor.pink, FamiliarColor.blue},
      visualStylePreference: VisualStylePreference.simpleShapes,
      interactionPreference: InteractionPreference.swiping,
      motionTolerance: SensoryTolerance.low,
      syntheticDemoWorld: SyntheticDemoWorld.rail,
    );

    final payload = SyntheticEngine2StartRequest.fromIntake(intake).toJson();
    final encoded = jsonEncode(payload);

    expect(payload, {
      'action': 'start',
      'visual': {
        'world': 'rail',
        'palette': ['blue', 'pink'],
        'object_style': 'simpleShapes',
        'motion_allowed': false,
        'allow_distractors': false,
        'interaction': 'swiping',
      },
    });
    expect(encoded, isNot(contains('not-sent')));
    expect(encoded, isNot(contains('private locomotive')));
    expect(encoded, isNot(contains('private favourite')));
    expect(encoded, isNot(contains('private familiar')));
  });

  test('selection request sends an issued option and aggregate telemetry only',
      () {
    const task = PuzzleSpec(
      id: 'task_1',
      mechanics: [PlayMechanic.chronologicalSequencing],
      layer: 2,
      themedPrompt: '',
      options: ['option_a', 'option_b', 'option_c'],
      correctOption: 'option_b',
      itemCount: 3,
    );
    const telemetry = ExplorationTelemetry(
      activeLatencyMs: 1530,
      misclicks: 1,
      recoveredErrors: 1,
      interactions: 2,
      correctInteractions: 1,
    );

    final payload = SyntheticEngine2SelectionRequest.fromSelection(
      sessionId: 'session_1',
      task: task,
      optionId: 'option_b',
      telemetry: telemetry,
      supportLevel: 1,
    ).toJson();

    expect(payload['action'], 'answer');
    expect(payload['option_id'], 'option_b');
    expect(payload['telemetry'], {
      'latency_ms': 1530,
      'misclicks': 1,
      'recovered_errors': 1,
      'interactions': 2,
      'support_level': 1,
    });
    expect(jsonEncode(payload), isNot(contains('correct_option')));
  });

  test(
    'inactivity skip sends no answer and stays within server telemetry bounds',
    () {
      const task = PuzzleSpec(
        id: 'task_1',
        mechanics: [PlayMechanic.chronologicalSequencing],
        layer: 2,
        themedPrompt: '',
        options: ['option_a', 'option_b', 'option_c'],
        correctOption: 'option_b',
        itemCount: 3,
      );
      const telemetry = ExplorationTelemetry(
        activeLatencyMs: 700000,
        misclicks: 99,
        recoveredErrors: 99,
        interactions: 0,
        correctInteractions: 0,
      );

      final payload = SyntheticEngine2SkipRequest.fromInactivity(
        sessionId: 'session_1',
        task: task,
        telemetry: telemetry,
        supportLevel: 9,
      ).toJson();

      expect(payload['action'], 'skip');
      expect(payload.containsKey('option_id'), isFalse);
      expect(payload['telemetry'], {
        'latency_ms': 600000,
        'misclicks': 1,
        'recovered_errors': 1,
        'interactions': 1,
        'support_level': 3,
      });
      expect(jsonEncode(payload), isNot(contains('correct_option')));
    },
  );

  test('response parser returns the generated puzzle and a soft-miss state',
      () {
    final result = SyntheticEngine2Result.fromJson({
      'status': 'in_progress',
      'session_id': 'session_1',
      'current_layer': 1,
      'active_sectors': ['chronologicalSequencing'],
      'solved': false,
    });

    expect(result.isInProgress, isTrue);
    expect(result.isUnsolved, isTrue);
    expect(result.nextTask, isNull);

    final invalidSoftMiss = SyntheticEngine2Result.fromJson({
      'status': 'in_progress',
      'session_id': 'session_1',
      'current_layer': 1,
      'active_sectors': ['chronologicalSequencing'],
      'solved': false,
      'next_task': <String, dynamic>{},
    });
    expect(invalidSoftMiss.status, SyntheticEngine2Status.unavailable);

    final incorrectWithNextTask = SyntheticEngine2Result.fromJson({
      'status': 'in_progress',
      'session_id': 'session_1',
      'current_layer': 1,
      'active_sectors': ['chronologicalSequencing'],
      'solved': false,
      'next_task': <String, dynamic>{
        'id': 'task_2',
        'sector': 'chronologicalSequencing',
        'layer': 1,
        'options': ['option_a', 'option_b'],
        'correct_option': 'option_b',
      },
    });
    expect(incorrectWithNextTask.status, SyntheticEngine2Status.inProgress);
    expect(incorrectWithNextTask.isUnsolved, isFalse);
    expect(incorrectWithNextTask.isSkipped, isFalse);
    expect(incorrectWithNextTask.hasNextTask, isTrue);

    final skippedWithNextTask = SyntheticEngine2Result.fromJson({
      'status': 'in_progress',
      'session_id': 'session_1',
      'current_layer': 1,
      'active_sectors': ['chronologicalSequencing'],
      'solved': false,
      'skipped': true,
      'next_task': <String, dynamic>{
        'id': 'task_2',
        'sector': 'chronologicalSequencing',
        'layer': 1,
        'options': ['option_a', 'option_b'],
        'correct_option': 'option_b',
      },
    });
    expect(skippedWithNextTask.isSkipped, isTrue);
    expect(skippedWithNextTask.isUnsolved, isFalse);
    expect(skippedWithNextTask.hasNextTask, isTrue);

    final skippedCompletion = SyntheticEngine2Result.fromJson({
      'status': 'complete',
      'session_id': 'session_1',
      'current_layer': 10,
      'active_sectors': ['chronologicalSequencing'],
      'final_sector': 'chronologicalSequencing',
      'sandbox': 'calendar',
      'solved': false,
      'skipped': true,
    });
    expect(skippedCompletion.isComplete, isTrue);
    expect(skippedCompletion.isSkipped, isTrue);
    expect(skippedCompletion.isSolved, isFalse);

    final issuedTask = SyntheticEngine2Result.fromJson({
      'status': 'in_progress',
      'session_id': 'session_1',
      'current_layer': 1,
      'active_sectors': ['chronologicalSequencing'],
      'next_task': <String, dynamic>{
        'id': 'task_1',
        'sector': 'chronologicalSequencing',
        'layer': 1,
        'difficulty': 1,
        'item_count': 3,
        'shows_distractors': false,
        'visual': <String, dynamic>{
          'world': 'rail',
          'palette': ['blue'],
          'object_style': 'simpleShapes',
          'motion_allowed': false,
          'allow_distractors': false,
          'interaction': 'tapping',
        },
        'scene': <String, dynamic>{
          'scene_type': 'sequence',
          'layout': 'row',
          'item_count': 3,
          'animation': <String, dynamic>{
            'on_tap': 'snap',
            'success': 'gentlePulse',
          },
          'show_text': false,
          'puzzle_plan': <String, dynamic>{
            'version': 1,
            'kind': 'chronologicalSequencing',
            'scene_type': 'sequence',
            'rule': 'orderPictureCycle',
            'variant': 2,
            'stimulus': [1, 2, 3],
            'option_values': [4, 8, 12],
            'answer_value': 8,
            'target_index': 1,
          },
        },
        'options': ['option_a', 'option_b', 'option_c'],
        'correct_option': 'option_b',
      },
    });

    expect(issuedTask.isInProgress, isTrue);
    expect(
        issuedTask.nextTask?.mechanics, [PlayMechanic.chronologicalSequencing]);
    expect(issuedTask.nextTask?.visualThemeKey, 'rail');
    expect(issuedTask.scene?.sceneType, 'sequence');
    expect(issuedTask.scene?.subject, 'rail');
    final plan = issuedTask.scene?.puzzlePlan;
    expect(plan?.version, 1);
    expect(plan?.requestedSector, PlayMechanic.chronologicalSequencing);
    expect(plan?.kind.wireName, 'sequence');
    expect(plan?.rule?.name, 'orderPictureCycle');
    expect(plan?.stimulus, [1, 2, 3]);
    final resolved = plan?.resolveFor(
      sector: PlayMechanic.chronologicalSequencing,
      optionCount: 3,
      correctIndex: 1,
    );
    expect(resolved?.targetVariant, 8);
    expect(resolved?.choiceVariantAt(1), 8);
  });
}
