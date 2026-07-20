import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/child_experience.dart';

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class ChildRepository {
  Future<ChildExperience> loadExperience(String sessionId);
  Future<void> recordStop(String sessionId);
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseChildRepository implements ChildRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Loads a child experience payload for the given active session.
  ///
  /// Validates that the session is not expired or revoked before returning
  /// experience data. The session must be owned by the currently signed-in
  /// guardian (enforced by RLS on the sessions table).
  @override
  Future<ChildExperience> loadExperience(String sessionId) async {
    // 1. Validate the session
    final sessionResp = await _db
        .from('sessions')
        .select('id, child_id, expires_at, revoked_at')
        .eq('id', sessionId)
        .maybeSingle();

    if (sessionResp == null) {
      throw Exception('Session not found or access denied.');
    }
    final session = sessionResp as Map<String, dynamic>;

    if (session['revoked_at'] != null) {
      throw Exception('Session has been revoked.');
    }
    final expiresAt = DateTime.parse(session['expires_at'] as String);
    if (expiresAt.isBefore(DateTime.now())) {
      throw Exception('Session has expired.');
    }

    final childId = session['child_id'] as String;

    // 2. Load the most recent child_experience row for this child.
    //    adult_exploratory_note is NOT fetched here — it is guardian-only.
    final expResp = await _db
        .from('child_experience')
        .select('id, payload, created_at')
        .eq('child_id', childId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // 3. Load sensory configuration (confirmed/active items only)
    final sensoryResp = await _db
        .from('sensory_configurations')
        .select('key, proposed_value')
        .eq('child_id', childId)
        .eq('status', 'confirmed')
        .eq('active', true);

    final sensoryMap = <String, dynamic>{};
    if (sensoryResp is List) {
      for (final row in sensoryResp) {
        sensoryMap[row['key'] as String] = row['proposed_value'];
      }
    }

    // 4. Map to domain model
    return _mapToExperience(sessionId, expResp as Map<String, dynamic>?, sensoryMap);
  }

  /// Revokes the session so the child can no longer access the experience.
  @override
  Future<void> recordStop(String sessionId) async {
    await _db.functions.invoke('revoke-session', body: {'sessionId': sessionId});
  }

  // ------------------------------------------------------------------
  // Mapping
  // ------------------------------------------------------------------

  ChildExperience _mapToExperience(
    String sessionId,
    Map<String, dynamic>? expRow,
    Map<String, dynamic> sensory,
  ) {
    final payload = expRow?['payload'] as Map<String, dynamic>? ?? {};

    final sensoryConfig = SensoryConfiguration(
      reduceMotion: _asBool(sensory['reduceMotion']),
      soundEnabled: _asBool(sensory['soundEnabled'], defaultValue: true),
      hapticsEnabled: _asBool(sensory['hapticsEnabled'], defaultValue: true),
      highContrast: _asBool(sensory['highContrast']),
      themeName: sensory['themeName'] as String? ?? 'default',
    );

    // Build puzzle payload from stored experience
    final puzzleType = payload['type'] as String? ?? 'timeline';
    final ChildPuzzlePayload puzzle;

    if (puzzleType == 'constellation') {
      final stars = (payload['stars'] as List<dynamic>? ?? [])
          .map(
            (s) => ConstellationStar(
              id: (s as Map<String, dynamic>)['id'] as String,
              x: (s['x'] as num).toDouble(),
              y: (s['y'] as num).toDouble(),
              isDifferent: s['isDifferent'] as bool? ?? false,
            ),
          )
          .toList();
      puzzle = ConstellationPuzzlePayload(
        id: payload['puzzleId'] as String? ?? '',
        seed: (payload['seed'] as num?)?.toInt() ?? 0,
        stars: stars,
      );
    } else {
      final items = (payload['items'] as List<dynamic>? ?? [])
          .map(
            (i) => TimelineItem(
              id: (i as Map<String, dynamic>)['id'] as String,
              label: i['label'] as String,
              order: (i['order'] as num).toInt(),
            ),
          )
          .toList();
      puzzle = TimelinePuzzlePayload(
        id: payload['puzzleId'] as String? ?? '',
        seed: (payload['seed'] as num?)?.toInt() ?? 0,
        items: items,
      );
    }

    return ChildExperience(
      sessionId: sessionId,
      sensory: sensoryConfig,
      puzzle: puzzle,
      celebration: const ChildCelebration(message: "Great work! 🌟"),
    );
  }

  bool _asBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is Map) return (value['value'] as bool?) ?? defaultValue;
    return defaultValue;
  }
}
