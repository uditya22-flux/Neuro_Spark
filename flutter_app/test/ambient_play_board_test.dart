import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/exploration/models/exploration_models.dart';
import 'package:mindbridge_app/features/exploration/presentation/ambient_play_board.dart';

void main() {
  const task = PuzzleSpec(
    id: 'recovery-test',
    mechanics: [PlayMechanic.visualPatternCompletion],
    layer: 1,
    themedPrompt: 'Visual only',
    options: ['Blue bay', 'Gold bay', 'Green bay'],
    correctOption: 'Gold bay',
    itemCount: 3,
  );

  testWidgets('a soft miss stays on the same visual activity until recovery', (tester) async {
    final choices = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmbientPlayBoard(
            task: task,
            scene: null,
            highlightTarget: false,
            onChoice: (choice) async {
              choices.add(choice);
              return choice == task.correctOption;
            },
          ),
        ),
      ),
    );

    final options = find.byType(GestureDetector);
    expect(options, findsNWidgets(3));

    await tester.tap(options.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(choices, ['Blue bay']);
    expect(find.byType(GestureDetector), findsNWidgets(3));

    await tester.tap(find.byType(GestureDetector).at(1));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(choices, ['Blue bay', 'Gold bay']);
  });

  testWidgets('every non-audio Layer 1 mechanic mounts its direct interaction surface',
      (tester) async {
    const audioOnly = {
      PlayMechanic.phonologicalPatternRecognition,
      PlayMechanic.auditorySequenceRecall,
      PlayMechanic.musicalPatternRecognition,
    };

    for (final mechanic in PlayMechanic.values.where(
      (mechanic) => !audioOnly.contains(mechanic),
    )) {
      final mechanicTask = PuzzleSpec(
        id: 'direct-board-${mechanic.name}',
        mechanics: [mechanic],
        layer: 1,
        themedPrompt: '',
        options: const ['blue', 'gold', 'green', 'silver'],
        correctOption: 'gold',
        itemCount: 3,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 720,
              child: AmbientPlayBoard(
                task: mechanicTask,
                scene: null,
                highlightTarget: false,
                onChoice: (_) async => true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${mechanic.name} direct interaction surface did not mount.',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
