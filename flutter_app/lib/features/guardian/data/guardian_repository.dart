import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/adult_exploratory_note.dart';

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

class ConsentDraft {
  const ConsentDraft({required this.consentVersionId, required this.confirmed});

  final String consentVersionId;
  final bool confirmed;
}

class IntakeHypothesis {
  const IntakeHypothesis({
    required this.id,
    required this.label,
    required this.enabled,
  });

  final String id;
  final String label;
  final bool enabled;
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class GuardianRepository {
  Future<void> submitConsent(ConsentDraft consent);
  Future<List<IntakeHypothesis>> loadIntakeReview(String childId);
  Future<void> confirmIntakeReview(String childId, List<String> approvedIds);
  Future<AdultExploratoryNote> loadExploratoryNote(String childId);
  Future<void> requestPrivacyExport({String? childId});
  Future<void> requestPurge({String? childId});
}

// ---------------------------------------------------------------------------
// Supabase implementation — no legacy ApiClient dependency
// ---------------------------------------------------------------------------

class SupabaseGuardianRepository implements GuardianRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ------------------------------------------------------------------
  // Consent
  // ------------------------------------------------------------------

  /// Accepts the current active consent version.
  @override
  Future<void> submitConsent(ConsentDraft consent) async {
    final userId = _requireUser();

    // Upsert so re-accepting the same version is idempotent
    final response = await _db.from('guardian_consents').upsert(
      {
        'guardian_id': userId,
        'consent_version_id': consent.consentVersionId,
        'status': consent.confirmed ? 'active' : 'pending',
        'accepted_at': consent.confirmed ? DateTime.now().toIso8601String() : null,
      },
      onConflict: 'guardian_id,consent_version_id',
    );

    _checkError(response, 'submitConsent');
  }

  // ------------------------------------------------------------------
  // Intake review
  // ------------------------------------------------------------------

  /// Loads pending sensory_configuration items awaiting guardian confirmation.
  @override
  Future<List<IntakeHypothesis>> loadIntakeReview(String childId) async {
    final response = await _db
        .from('sensory_configurations')
        .select('id, key, proposed_value, status')
        .eq('child_id', childId)
        .eq('status', 'pending');

    _checkError(response, 'loadIntakeReview');

    return (response as List<dynamic>)
        .map(
          (row) => IntakeHypothesis(
            id: row['id'] as String,
            label: row['key'] as String,
            enabled: true,
          ),
        )
        .toList();
  }

  @override
  Future<void> confirmIntakeReview(
    String childId,
    List<String> approvedIds,
  ) async {
    if (approvedIds.isEmpty) return;

    final response = await _db
        .from('sensory_configurations')
        .update({'status': 'confirmed', 'reviewed_at': DateTime.now().toIso8601String()})
        .eq('child_id', childId)
        .inFilter('id', approvedIds);

    _checkError(response, 'confirmIntakeReview');
  }

  // ------------------------------------------------------------------
  // Adult-only exploratory note (guardian-scoped RLS enforced on DB)
  // ------------------------------------------------------------------

  @override
  Future<AdultExploratoryNote> loadExploratoryNote(String childId) async {
    final response = await _db
        .from('adult_exploratory_note')
        .select('id, child_id, taxonomy_key, observations, evidence, disclaimer, created_at')
        .eq('child_id', childId)
        .order('created_at', ascending: false)
        .limit(1)
        .single();

    _checkError(response, 'loadExploratoryNote');

    final row = response;
    return AdultExploratoryNote(
      id: row['id'] as String,
      childProfileId: row['child_id'] as String,
      taxonomy: _parseTaxonomy(row['taxonomy_key'] as String),
      evidence: _parseEvidence(row['evidence'] as List<dynamic>),
      provenance: NoteProvenance(
        promptVersion: 'unknown',
        modelConfiguration: 'unknown',
        generatedAt: DateTime.parse(row['created_at'] as String),
      ),
      disclaimer: row['disclaimer'] as String? ?? illustrativeOnlyDisclaimer,
      explorationInProgress: false,
    );
  }

  // ------------------------------------------------------------------
  // Privacy export / purge — delegated to Edge Functions
  // ------------------------------------------------------------------

  @override
  Future<void> requestPrivacyExport({String? childId}) async {
    await _db.functions.invoke(
      'privacy-export',
      body: childId != null ? {'childId': childId} : <String, dynamic>{},
    );
  }

  @override
  Future<void> requestPurge({String? childId}) async {
    await _db.functions.invoke(
      'privacy-purge',
      body: childId != null ? {'childId': childId} : <String, dynamic>{},
    );
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  String _requireUser() {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.id;
  }

  void _checkError(dynamic response, String context) {
    if (response is PostgrestException) {
      throw Exception('[$context] ${response.message}');
    }
  }

  ClosedTaxonomyField _parseTaxonomy(String key) {
    return ClosedTaxonomyField.values.firstWhere(
      (e) => e.name == key,
      orElse: () => ClosedTaxonomyField.chronologicalOrganization,
    );
  }

  List<ObservedEvidence> _parseEvidence(List<dynamic> raw) {
    return raw
        .map(
          (e) => ObservedEvidence(
            activityId: (e as Map<String, dynamic>)['activityId'] as String? ?? '',
            description: e['description'] as String? ?? '',
          ),
        )
        .toList();
  }
}
