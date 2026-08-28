import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records present-moment enjoyment taps during guardian-supervised child play.
class ChildPlayTelemetryService {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> recordResponse({
    required String sessionId,
    required String childId,
    required String sectorId,
    bool enjoyed = true,
    bool skipped = false,
  }) async {
    if (sessionId.startsWith('local_play_')) return;

    final client = _client;
    final guardianId = client?.auth.currentUser?.id;
    if (client == null || guardianId == null) return;

    try {
      await client.from('child_play_responses').insert({
        'session_id': sessionId,
        'child_id': childId,
        'guardian_id': guardianId,
        'sector_id': sectorId,
        'enjoyed': enjoyed,
        'skipped': skipped,
      });
    } catch (e) {
      debugPrint('[ChildPlayTelemetry] record failed: $e');
    }
  }

  Future<int> countEnjoyedForChild(String childId) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return 0;

    try {
      final rows = await client
          .from('child_play_responses')
          .select('id')
          .eq('child_id', childId)
          .eq('enjoyed', true);
      return rows.length;
    } catch (e) {
      debugPrint('[ChildPlayTelemetry] count failed: $e');
    }
    return 0;
  }
}

final childPlayTelemetryServiceProvider = Provider<ChildPlayTelemetryService>((ref) {
  return ChildPlayTelemetryService();
});
