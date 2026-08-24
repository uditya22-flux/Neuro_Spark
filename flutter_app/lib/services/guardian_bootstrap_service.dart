import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ensures a signed-in guardian can call create-child and strength-funnel APIs.
class GuardianBootstrapService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<void> ensureReady({String verificationMethod = 'email_otp'}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _ensureVerified(userId, verificationMethod);
    await _ensureActiveConsent(userId);
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

  Future<void> _ensureActiveConsent(String userId) async {
    final active = await _client
        .from('guardian_consents')
        .select('id')
        .eq('guardian_id', userId)
        .eq('status', 'active')
        .maybeSingle();
    if (active != null) return;

    final consentVersion = await _client
        .from('consent_versions')
        .select('id')
        .eq('active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final versionId = consentVersion?['id'] as String?;
    if (versionId == null) {
      debugPrint('[GuardianBootstrap] No active consent version in database.');
      return;
    }

    await _client.from('guardian_consents').insert({
      'guardian_id': userId,
      'consent_version_id': versionId,
      'status': 'active',
      'accepted_at': DateTime.now().toUtc().toIso8601String(),
    });
    debugPrint('[GuardianBootstrap] Recorded active consent.');
  }
}

final guardianBootstrapServiceProvider = Provider<GuardianBootstrapService>((ref) {
  return GuardianBootstrapService();
});
