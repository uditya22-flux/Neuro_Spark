import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/deepening/presentation/deepening_funnel_canvas.dart';
import 'package:mindbridge_app/features/exploration/models/exploration_models.dart';
import 'package:mindbridge_app/features/exploration/providers/exploration_funnel_provider.dart';
import 'package:mindbridge_app/features/exploration/providers/intake_provider.dart';

void main() {
  testWidgets('a completed selected answer advances after the change window',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(intakeProvider.notifier).setForLocalPreview(
          const IntakeConfiguration(
            childId: 'test-child',
            audioLimit: 40,
            visualClutterTolerance: VisualClutterTolerance.low,
            hyperFocusTheme: 'Trains',
            sandboxPreference: SandboxPreference.calendar,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: DeepeningFunnelCanvas(
            userId: 'test-child',
            onCompleted: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final before = container.read(explorationFunnelProvider);
    final beforeTask = before.currentTask;
    expect(beforeTask, isNotNull);
    expect(find.byType(GestureDetector), findsWidgets);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();

    final after = container.read(explorationFunnelProvider);
    expect(after.currentTask?.id, isNot(beforeTask?.id));
    expect(after.sessionObservations, hasLength(1));
  });

  testWidgets('two minutes without a response advances to the next activity',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(intakeProvider.notifier).setForLocalPreview(
          const IntakeConfiguration(
            childId: 'test-child',
            audioLimit: 40,
            visualClutterTolerance: VisualClutterTolerance.low,
            hyperFocusTheme: 'Trains',
            sandboxPreference: SandboxPreference.calendar,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: DeepeningFunnelCanvas(
            userId: 'test-child',
            onCompleted: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final before = container.read(explorationFunnelProvider);
    final beforeTask = before.currentTask;
    expect(beforeTask, isNotNull);
    expect(before.taskQueue, isNotEmpty);

    await tester.pump(taskAutoAdvanceAfterInactivity);
    await tester.pump();

    final after = container.read(explorationFunnelProvider);
    expect(after.currentTask?.id, isNot(beforeTask?.id));
    expect(after.sessionObservations, hasLength(1));
    expect(after.sessionObservations.single.telemetry.correctInteractions, 0);
  });
}
