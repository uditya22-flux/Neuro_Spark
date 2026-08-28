import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/strength_funnel/models/strength_funnel_finalists.dart';

/// Loads completed funnel finalists from Supabase for cross-device continuity.
class RemoteStrengthFunnelLoader {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<StrengthFunnelFinalists?> loadFinalistsForChild(String childId) async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return null;

    try {
      final row = await client
          .from('strength_funnel_sessions')
          .select('active_sector_ids, completed_at')
          .eq('child_id', childId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) return null;

      final sectorIds = (row['active_sector_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (sectorIds.isEmpty) return null;

      final completedAt = row['completed_at'] != null
          ? DateTime.parse(row['completed_at'] as String)
          : DateTime.now().toUtc();

      return StrengthFunnelFinalists(
        sectorIds: sectorIds,
        completedAt: completedAt,
        layerScores: const {},
      );
    } catch (e) {
      debugPrint('[RemoteStrengthFunnelLoader] load failed: $e');
      return null;
    }
  }
}

final remoteStrengthFunnelLoaderProvider = Provider<RemoteStrengthFunnelLoader>((ref) {
  return RemoteStrengthFunnelLoader();
});
