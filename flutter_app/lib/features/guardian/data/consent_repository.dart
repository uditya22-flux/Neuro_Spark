import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

class ConsentVersion {
  const ConsentVersion({
    required this.id,
    required this.version,
    required this.jurisdiction,
    required this.documentUrl,
  });

  final String id;
  final String version;
  final String jurisdiction;
  final String documentUrl;
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class ConsentRepository {
  Future<ConsentVersion?> loadActiveConsentVersion();
  Future<void> acceptConsent(String consentVersionId);
  Future<void> revokeConsent(String consentVersionId);
  Future<bool> hasActiveConsent();
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseConsentRepository implements ConsentRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Returns the current active consent version, or null if none exists.
  @override
  Future<ConsentVersion?> loadActiveConsentVersion() async {
    final response = await _db
        .from('consent_versions')
        .select('id, version, jurisdiction, document_url')
        .eq('active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    final row = response as Map<String, dynamic>;
    return ConsentVersion(
      id: row['id'] as String,
      version: row['version'] as String,
      jurisdiction: row['jurisdiction'] as String,
      documentUrl: row['document_url'] as String,
    );
  }

  /// Records that the guardian accepted the specified consent version.
  @override
  Future<void> acceptConsent(String consentVersionId) async {
    final userId = _requireUser();
    await _db.from('guardian_consents').upsert(
      {
        'guardian_id': userId,
        'consent_version_id': consentVersionId,
        'status': 'active',
        'accepted_at': DateTime.now().toIso8601String(),
        'revoked_at': null,
      },
      onConflict: 'guardian_id,consent_version_id',
    );
  }

  /// Revokes the guardian's consent for the specified version.
  @override
  Future<void> revokeConsent(String consentVersionId) async {
    final userId = _requireUser();
    await _db
        .from('guardian_consents')
        .update({
          'status': 'revoked',
          'revoked_at': DateTime.now().toIso8601String(),
        })
        .eq('guardian_id', userId)
        .eq('consent_version_id', consentVersionId);
  }

  /// Returns true if the guardian has at least one active consent record.
  @override
  Future<bool> hasActiveConsent() async {
    final userId = _requireUser();
    final response = await _db
        .from('guardian_consents')
        .select('id')
        .eq('guardian_id', userId)
        .eq('status', 'active')
        .limit(1)
        .maybeSingle();
    return response != null;
  }

  String _requireUser() {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.id;
  }
}
