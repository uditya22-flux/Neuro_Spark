import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/core/events/offline_event_queue.dart';

void main() {
  test('queue only removes acknowledged events', () async {
    final queue = MemoryOfflineEventQueue();
    await queue.enqueue(
      QueuedPlayEvent(
        id: 'first',
        childSessionId: 'session-a',
        eventType: 'puzzle_opened',
        occurredAt: DateTime.utc(2026),
      ),
    );
    await queue.enqueue(
      QueuedPlayEvent(
        id: 'second',
        childSessionId: 'session-a',
        eventType: 'puzzle_stopped',
        occurredAt: DateTime.utc(2026),
      ),
    );

    await queue.acknowledge(<String>['first']);

    expect((await queue.takeBatch()).map((event) => event.id), <String>['second']);
  });

  test('revoking a child session removes its unsent events', () async {
    final queue = MemoryOfflineEventQueue();
    await queue.enqueue(
      QueuedPlayEvent(
        id: 'a',
        childSessionId: 'revoked',
        eventType: 'puzzle_opened',
        occurredAt: DateTime.utc(2026),
      ),
    );
    await queue.enqueue(
      QueuedPlayEvent(
        id: 'b',
        childSessionId: 'active',
        eventType: 'puzzle_opened',
        occurredAt: DateTime.utc(2026),
      ),
    );

    await queue.clearForRevokedSession('revoked');

    expect((await queue.takeBatch()).map((event) => event.id), <String>['b']);
  });
}
