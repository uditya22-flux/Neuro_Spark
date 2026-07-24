import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/guardian_demo/models/guardian_demo_portal_models.dart';

void main() {
  group('GuardianDemoSessionSnapshot', () {
    test('parses sanitized synthetic session activity', () {
      final snapshot = GuardianDemoSessionSnapshot.fromJson({
        'session': {
          'session_id': '55f4f1aa-67bd-4f7e-8a78-bcdfcf010101',
          'status': 'in_progress',
          'current_layer': 2,
          'active_sectors': ['chronologicalSequencing', 'mapRouteNavigation'],
          'final_sector': null,
          'final_sandbox': null,
          'expires_at': '2026-07-24T12:00:00.000Z',
          'created_at': '2026-07-24T09:00:00.000Z',
          'updated_at': '2026-07-24T09:10:00.000Z',
          'completed_task_count': 1,
        },
        'completed_events': [
          {
            'layer': 1,
            'sector': 'chronologicalSequencing',
            'correct': false,
            'skipped': false,
            'latency_ms': 4200,
            'misclicks': 2,
            'recovered_errors': 1,
            'interactions': 3,
            'support_level': 1,
            'accuracy': 0.4,
            'recovery': 0.5,
            'engagement': 0.8,
            'speed': 0.65,
            'isolation_score': 0.53,
            'created_at': '2026-07-24T09:10:00.000Z',
          },
        ],
      });

      expect(snapshot.currentLayer, 2);
      expect(snapshot.completedTaskCount, 1);
      expect(snapshot.activeSectors, contains('mapRouteNavigation'));
      expect(snapshot.completedEvents.single.sectorLabel,
          'chronological sequencing');
      expect(
        snapshot.completedEvents.single.responseStatus,
        GuardianDemoResponseStatus.nonMatching,
      );
    });

    test('identifies a skipped activity without assigning a matching response',
        () {
      final activity = GuardianDemoActivity.fromJson({
        'layer': 1,
        'sector': 'visualPatternCompletion',
        'correct': false,
        'skipped': true,
        'latency_ms': 120000,
        'misclicks': 0,
        'recovered_errors': 0,
        'interactions': 0,
        'support_level': 3,
        'accuracy': 0,
        'recovery': 0,
        'engagement': 0,
        'speed': 0,
        'isolation_score': 0,
        'created_at': '2026-07-24T09:10:00.000Z',
      });

      expect(activity.responseStatus, GuardianDemoResponseStatus.noResponse);
      expect(activity.matched, isFalse);
    });

    test('derives a legacy Layer 10 showcase destination from its final event',
        () {
      final snapshot = GuardianDemoSessionSnapshot.fromJson({
        'session': {
          'session_id': '55f4f1aa-67bd-4f7e-8a78-bcdfcf010103',
          'status': 'complete',
          'current_layer': 10,
          'active_sectors': ['mapRouteNavigation'],
          'final_sector': null,
          'final_sandbox': null,
          'expires_at': '2026-07-24T12:00:00.000Z',
          'created_at': '2026-07-24T09:00:00.000Z',
          'updated_at': '2026-07-24T09:30:00.000Z',
          'completed_task_count': 1,
        },
        'completed_events': [
          {
            'layer': 10,
            'sector': 'mapRouteNavigation',
            'correct': true,
            'skipped': false,
            'latency_ms': 2800,
            'misclicks': 0,
            'recovered_errors': 0,
            'interactions': 1,
            'support_level': 0,
            'accuracy': 1,
            'recovery': 1,
            'engagement': 1,
            'speed': 1,
            'isolation_score': 1,
            'created_at': '2026-07-24T09:30:00.000Z',
          },
        ],
      });

      expect(snapshot.finalActivitySector, 'mapRouteNavigation');
      expect(snapshot.finalActivitySandbox, GuardianDemoSandbox.constellation);
    });
  });
}
