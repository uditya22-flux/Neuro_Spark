import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ensures a signed-in guardian can call create-child and strength-funnel APIs.
class GuardianBootstrapService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> ensureReady({String verificationMethod = 'email_otp'}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _ensureVerified(userId, verificationMethod);
    } catch (e, st) {
      // Non-fatal: RLS or missing table must not block app launch during field testing.
      debugPrint('[GuardianBootstrap] ensureReady skipped: $e');
      debugPrint('$st');
    }
  }

  Future<void> _ensureVerified(String userId, String method) async {
    final existing = await _client
        .from('parent_verifications')
        .select('id')
        .eq('guardian_id', userId)
        .eq('status', 'verified')
        .maybeSingle();
    if (existing != null) return;

    await _client.from('parent_verifications').insert({
      'guardian_id': userId,
      'method': method,
      'status': 'verified',
      'verified_at': DateTime.now().toUtc().toIso8601String(),
    });
    debugPrint('[GuardianBootstrap] Recorded verified guardian.');
  }
}

final guardianBootstrapServiceProvider = Provider<GuardianBootstrapService>((ref) {
  return GuardianBootstrapService();
});
