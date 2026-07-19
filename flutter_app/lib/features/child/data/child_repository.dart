import '../../../core/api/api_client.dart';
import '../domain/child_experience.dart';

abstract interface class ChildRepository {
  Future<ChildExperience> loadExperience(String childSessionId);
  Future<void> recordStop(String childSessionId);
}

class ApiChildRepository implements ChildRepository {
  ApiChildRepository(this._api);

  final ApiClient _api;

  @override
  Future<ChildExperience> loadExperience(String childSessionId) {
    throw UnimplementedError('Connect this mapper to GET /child/experience.');
  }

  @override
  Future<void> recordStop(String childSessionId) async {
    await _api.post<void>('/child/sessions/$childSessionId/stop');
  }
}
