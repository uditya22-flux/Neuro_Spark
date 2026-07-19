/// Child event storage is intentionally limited to opaque, non-PII play events.
class QueuedPlayEvent {
  const QueuedPlayEvent({
    required this.id,
    required this.childSessionId,
    required this.eventType,
    required this.occurredAt,
    this.payload = const <String, Object?>{},
  });

  final String id;
  final String childSessionId;
  final String eventType;
  final DateTime occurredAt;
  final Map<String, Object?> payload;
}

abstract interface class OfflineEventQueue {
  Future<void> enqueue(QueuedPlayEvent event);
  Future<List<QueuedPlayEvent>> takeBatch({int limit = 50});
  Future<void> acknowledge(Iterable<String> ids);
  Future<void> clearForRevokedSession(String childSessionId);
}

class MemoryOfflineEventQueue implements OfflineEventQueue {
  final List<QueuedPlayEvent> _events = <QueuedPlayEvent>[];

  @override
  Future<void> acknowledge(Iterable<String> ids) async {
    final acknowledged = ids.toSet();
    _events.removeWhere((event) => acknowledged.contains(event.id));
  }

  @override
  Future<void> clearForRevokedSession(String childSessionId) async {
    _events.removeWhere((event) => event.childSessionId == childSessionId);
  }

  @override
  Future<void> enqueue(QueuedPlayEvent event) async {
    _events.add(event);
  }

  @override
  Future<List<QueuedPlayEvent>> takeBatch({int limit = 50}) async {
    return List<QueuedPlayEvent>.unmodifiable(_events.take(limit));
  }
}
