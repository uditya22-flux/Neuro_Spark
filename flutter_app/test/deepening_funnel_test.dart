import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindbridge_app/features/deepening/models/deepening_task_payload.dart';
import 'package:mindbridge_app/features/deepening/models/telemetry_payload.dart';
import 'package:mindbridge_app/features/deepening/providers/deepening_controller.dart';
import 'package:mindbridge_app/features/deepening/presentation/deepening_funnel_canvas.dart';
import 'package:mindbridge_app/features/deepening/presentation/widgets/calendar_genius_task_widget.dart';
import 'package:mindbridge_app/features/deepening/presentation/widgets/constellation_mapper_task_widget.dart';
import 'package:mindbridge_app/core/router/app_router.dart';

void main() {
  group('Deepening Funnel Assessment & Router Tests', () {
    test('TelemetryPayload serializes performance metrics correctly', () {
      const telemetry = TelemetryPayload(
        taskId: 'task_1',
        userId: 'user_101',
        layer: 1,
        accuracy: 1.0,
        latencyMs: 3400,
        recoveryCount: 0,
        engagementScore: 0.9,
        userResponse: 'Monday',
        usedHint: false,
      );

      final json = telemetry.toJson();
      expect(json['task_id'], equals('task_1'));
      expect(json['accuracy'], equals(1.0));
      expect(json['latency_ms'], equals(3400));
      expect(json['recovery_count'], equals(0));
      expect(json['used_hint'], isFalse);
    });

    test('DeepeningTaskPayload parses JSON payload correctly', () {
      final json = {
        'task_id': 'task_cal_1',
        'user_id': 'user_101',
        'layer': 1,
        'total_layers': 10,
        'vertical_id': 'calendar_genius',
        'theme_skin': 'sage_green',
        'prompt': 'Which day is July 20?',
        'task_data': {'target_date': '2026-07-20', 'correct_day': 'Monday'},
      };

      final payload = DeepeningTaskPayload.fromJson(json);
      expect(payload.taskId, equals('task_cal_1'));
      expect(payload.verticalId, equals('calendar_genius'));
      expect(payload.themeSkin, equals('sage_green'));
    });

    testWidgets('CalendarGeniusTaskWidget renders prompt and day choices', (WidgetTester tester) async {
      const payload = DeepeningTaskPayload(
        taskId: 'task_cal_1',
        userId: 'user_101',
        layer: 1,
        verticalId: 'calendar_genius',
        themeSkin: 'sage_green',
        prompt: 'Identify the target day of the week',
        taskData: {'target_date': '2026-07-20', 'correct_day': 'Monday'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarGeniusTaskWidget(
              payload: payload,
              onSubmit: ({required accuracy, required response, required errorCount}) {},
              onHintTriggered: () {},
            ),
          ),
        ),
      );

      expect(find.text('Calendar Genius Puzzle'), findsOneWidget);
      expect(find.text('Identify the target day of the week'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
    });

    testWidgets('GoRouter redirects users with pending assessments to /assessment-canvas', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authStatusProvider.overrideWith(
            (ref) => const AuthUserStatus(
              isLoggedIn: true,
              userId: 'user_101',
              hasCompletedAssessment: false,
            ),
          ),
        ],
      );

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals('/assessment-canvas'));
      expect(find.byType(DeepeningFunnelCanvas), findsOneWidget);
    });
  });
}
