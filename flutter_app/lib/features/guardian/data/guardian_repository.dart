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

class ApiGuardianRepository implements GuardianRepository {
  ApiGuardianRepository(this._api);

  final ApiClient _api;

  @override
  Future<void> confirmIntakeReview(String childProfileId, List<String> approvedIds) {
    return _api.post<void>(
      '/guardian/children/$childProfileId/intake-review',
      data: <String, Object?>{'approvedIds': approvedIds},
    );
  }

  @override
  Future<AdultExploratoryNote> loadExploratoryNote(String childProfileId) {
    throw UnimplementedError('Connect this mapper to guardian-only note endpoint.');
  }

  @override
  Future<List<IntakeHypothesis>> loadIntakeReview(String childProfileId) {
    throw UnimplementedError('Connect this mapper to intake review endpoint.');
  }

  @override
  Future<void> requestPrivacyExport() => _api.post<void>('/guardian/privacy-export');

  @override
  Future<void> requestPurge() => _api.post<void>('/guardian/purge');

  @override
  Future<void> submitConsent(ConsentDraft consent) {
    return _api.post<void>(
      '/guardian/consent',
      data: <String, Object?>{
        'consentVersion': consent.consentVersion,
        'confirmed': consent.confirmed,
      },
    );
  }
}
