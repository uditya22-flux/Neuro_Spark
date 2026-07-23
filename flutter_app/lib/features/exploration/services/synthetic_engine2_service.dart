import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/prototype_mode.dart';
import '../models/exploration_models.dart';
import '../models/synthetic_engine2_models.dart';

/// Client for the anonymous, synthetic-only Engine 2 Edge Function.
///
/// This client has no persistence logic and deliberately never invokes the
/// function in local or builder showcase builds. The Edge Function is the
/// only cloud boundary for synthetic session state and LLM puzzle generation.
class SyntheticEngine2Service {
  static const _functionName = 'synthetic-engine2-next-task';

  bool get supportsCloudSession => _cloudSyntheticMode;

  Future<SyntheticEngine2Result> startSession({
    required IntakeConfiguration intake,
  }) async {
    if (!_cloudSyntheticMode) return _disabledResult();
    final request = SyntheticEngine2StartRequest.fromIntake(intake);
    return _invoke(request.toJson());
  }

  /// Submits one issued option token. The response tells the canvas whether
  /// the task was solved and, if so, carries the next generated puzzle or a
  /// completion state. It never sends a free-text answer.
  Future<SyntheticEngine2Result> submitSelection({
    required String sessionId,
    required PuzzleSpec task,
    required String optionId,
    required ExplorationTelemetry telemetry,
    required int supportLevel,
  }) async {
    if (!_cloudSyntheticMode) return _disabledResult();
    final request = SyntheticEngine2SelectionRequest.fromSelection(
      sessionId: sessionId,
      task: task,
      optionId: optionId,
      telemetry: telemetry,
      supportLevel: supportLevel,
    );
    return _invoke(request.toJson());
  }

  Future<SyntheticEngine2Result> _invoke(Map<String, dynamic> body) async {
    if (!_cloudSyntheticMode) return _disabledResult();

    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return SyntheticEngine2Result.unavailable('Supabase is not initialized.');
    }
    if (client.auth.currentSession == null) {
      return SyntheticEngine2Result.unavailable('A synthetic session is not available.');
    }

    try {
      final response = await client.functions.invoke(_functionName, body: body);
      if (response.status >= 400 || response.data is! Map) {
        return SyntheticEngine2Result.unavailable('Synthetic Engine 2 is temporarily unavailable.');
      }
      return SyntheticEngine2Result.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FunctionException {
      return SyntheticEngine2Result.unavailable('Synthetic Engine 2 is temporarily unavailable.');
    } catch (error) {
      // Do not log request data: even synthetic mode should keep telemetry
      // aggregates out of device logs.
      debugPrint('[SyntheticEngine2Service] next task unavailable: ${error.runtimeType}');
      return SyntheticEngine2Result.unavailable('Synthetic Engine 2 is temporarily unavailable.');
    }
  }

  SyntheticEngine2Result _disabledResult() => SyntheticEngine2Result.unavailable(
        'Synthetic cloud Engine 2 is disabled in this build mode.',
      );
}

bool get _cloudSyntheticMode =>
    syntheticDemoMode && !localPrototypeMode && !builderShowcaseMode;

final syntheticEngine2ServiceProvider = Provider<SyntheticEngine2Service>(
  (ref) => SyntheticEngine2Service(),
);
