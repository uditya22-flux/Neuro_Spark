import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindbridge_app/features/sandbox/services/procedural_puzzle_generator.dart';
import 'package:mindbridge_app/features/sandbox/models/sandbox_session.dart';
import 'package:mindbridge_app/features/sandbox/models/sandbox_attempt.dart';
import 'package:mindbridge_app/features/sandbox/presentation/engine4_sandbox_screen.dart';

void main() {
  group('Open-ended play workshop tests', () {
    test('ProceduralPuzzleGenerator timeline puzzle generates scrambled blocks', () {
      final blocks = ProceduralPuzzleGenerator.generateTimelinePuzzle(
        count: 5,
        scrambleCount: 2,
        difficultyTier: 1,
        seed: 1234,
      );

      expect(blocks.length, equals(5));
      expect(blocks.map((b) => b.originalIndex).toSet().length, equals(5));
    });

    test('ProceduralPuzzleGenerator constellation puzzle generates 3D points and anomalies', () {
      final points = ProceduralPuzzleGenerator.generateConstellationPuzzle(
        pointCount: 20,
        anomalyCount: 4,
        difficultyTier: 2,
        seed: 5678,
      );

      expect(points.length, equals(20));
      final anomalies = points.where((p) => p.isAnomaly).toList();
      expect(anomalies.length, equals(4));
    });

    test('SandboxAttempt serializes metrics payload correctly', () {
      final attempt = SandboxAttempt(
        attemptId: 'att_101',
        sessionId: 'sess_202',
        puzzleSeed: 999,
        timeToSolveMs: 8400,
        correctionsCount: 0,
        difficultyTier: 2,
        completed: true,
        occurredAt: DateTime.parse('2026-07-21T10:00:00Z'),
      );

      final json = attempt.toJson();
      expect(json['attempt_id'], equals('att_101'));
      expect(json['time_to_solve_ms'], equals(8400));
      expect(json['corrections_count'], equals(0));
      expect(json['difficulty_tier'], equals(2));

      final parsed = SandboxAttempt.fromJson(json);
      expect(parsed.attemptId, equals('att_101'));
      expect(parsed.timeToSolveMs, equals(8400));
    });

    testWidgets('Engine4SandboxScreen renders track selector and canvas', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Engine4SandboxScreen(
              userId: 'user_guardian_101',
              initialVerticalId: 'calendar_genius',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Open-ended play workshop'), findsOneWidget);
      expect(find.text('Timeline workshop'), findsOneWidget);
      expect(find.text('Constellation workshop'), findsOneWidget);
      expect(find.textContaining('Timeline workshop'), findsWidgets);
    });
  });
}
