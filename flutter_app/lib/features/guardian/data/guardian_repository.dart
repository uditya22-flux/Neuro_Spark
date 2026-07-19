import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../domain/adult_exploratory_note.dart';

class ConsentDraft {
  const ConsentDraft({required this.consentVersion, required this.confirmed});

  final String consentVersion;
  final bool confirmed;
}

class IntakeHypothesis {
  const IntakeHypothesis({required this.id, required this.label, required this.enabled});

  final String id;
  final String label;
  final bool enabled;
}

abstract interface class GuardianRepository {
  Future<void> submitConsent(ConsentDraft consent);
  Future<List<IntakeHypothesis>> loadIntakeReview(String childProfileId);
  Future<void> confirmIntakeReview(String childProfileId, List<String> approvedIds);
  Future<AdultExploratoryNote> loadExploratoryNote(String childProfileId);
  Future<void> requestPrivacyExport();
  Future<void> requestPurge();
}

class SupabaseGuardianRepository implements GuardianRepository {
  SupabaseGuardianRepository(this._api);

  final ApiClient _api;

  SupabaseClient get _supabase => _api.supabase;

  String? get _guardianId => _supabase.auth.currentUser?.id;

  @override
  Future<void> confirmIntakeReview(String childProfileId, List<String> approvedIds) async {
    if (_guardianId == null) throw StateError('No signed-in guardian session.');
    await _supabase
        .from('sensory_configurations')
        .update(<String, Object?>{'status': 'CONFIRMED', 'reviewed_at': DateTime.now().toIso8601String()})
        .eq('child_id', childProfileId)
        .inFilter('id', approvedIds);
  }

  @override
  Future<AdultExploratoryNote> loadExploratoryNote(String childProfileId) async {
    final row = await _supabase
        .from('adult_exploratory_notes')
        .select('id,child_id,track,evidence,disclaimer,created_at,exploration_in_progress,prompt_version,model_config')
        .eq('child_id', childProfileId)
        .order('created_at', ascending: false)
        .maybeSingle();
    if (row == null) {
      throw StateError('No exploratory note is available yet.');
    }
    return AdultExploratoryNote.fromSupabaseRow(childProfileId: childProfileId, row: Map<String, Object?>.from(row));
  }

  @override
  Future<List<IntakeHypothesis>> loadIntakeReview(String childProfileId) async {
    final rows = await _supabase
        .from('sensory_configurations')
        .select('id,key,status,proposed_value')
        .eq('child_id', childProfileId)
        .order('created_at', ascending: false);
    return rows
        .cast<Map<String, Object?>>()
        .map(
          (row) => IntakeHypothesis(
            id: row['id']?.toString() ?? '',
            label: row['key']?.toString() ?? 'Configuration item',
            enabled: row['status']?.toString() == 'CONFIRMED',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> requestPrivacyExport() async {
    if (_guardianId == null) throw StateError('No signed-in guardian session.');
    await _supabase.from('audit_log').select('id').limit(1);
  }

  @override
  Future<void> requestPurge() async {
    if (_guardianId == null) throw StateError('No signed-in guardian session.');
    await _supabase.from('purge_requests').insert(<String, Object?>{
      'guardian_id': _guardianId,
      'status': 'REQUESTED',
    });
  }

  @override
  Future<void> submitConsent(ConsentDraft consent) async {
    final guardianId = _guardianId;
    if (guardianId == null) throw StateError('No signed-in guardian session.');
    if (!consent.confirmed) throw StateError('Consent must be confirmed before it can be saved.');
    await _supabase.from('parent_verifications').upsert(<String, Object?>{
      'guardian_id': guardianId,
      'method': 'email_otp',
      'status': 'verified',
      'verified_at': DateTime.now().toIso8601String(),
      'metadata': <String, Object?>{'consentVersion': consent.consentVersion},
    });
  }
}
