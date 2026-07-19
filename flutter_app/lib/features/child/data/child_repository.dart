import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../domain/child_experience.dart';

abstract interface class ChildRepository {
  Future<ChildExperience> loadExperience(String childSessionId);
  Future<void> recordStop(String childSessionId);
}

class SupabaseChildRepository implements ChildRepository {
  SupabaseChildRepository(this._api);

  final ApiClient _api;

  SupabaseClient get _supabase => _api.supabase;

  @override
  Future<ChildExperience> loadExperience(String childSessionId) async {
    final row = await _supabase
        .from('child_experience')
        .select('id,child_session_id,payload,created_at')
        .eq('child_session_id', childSessionId)
        .order('created_at', ascending: false)
        .maybeSingle();
    if (row == null) {
      return ChildExperience.fromSupabase(sessionId: childSessionId, payload: <String, Object?>{});
    }
    final payload = Map<String, Object?>.from(row['payload'] as Map? ?? const <String, Object?>{});
    return ChildExperience.fromSupabase(sessionId: childSessionId, payload: payload);
  }

  @override
  Future<void> recordStop(String childSessionId) async {
    await _supabase
        .from('child_sessions')
        .update(<String, Object?>{'revoked_at': DateTime.now().toIso8601String(), 'revoke_reason': 'child_stopped'})
        .eq('id', childSessionId);
  }
}
