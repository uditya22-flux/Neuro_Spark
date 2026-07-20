import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/deepening_task_payload.dart';
import '../models/telemetry_payload.dart';

class DeepeningState {
  final DeepeningTaskPayload? currentTask;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isFunnelCompleted;
  final int supportLadderLevel;
  final int currentLayer;
  final bool usedHint;

  const DeepeningState({
    this.currentTask,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isFunnelCompleted = false,
    this.supportLadderLevel = 0,
    this.currentLayer = 1,
    this.usedHint = false,
  });

  DeepeningState copyWith({
    DeepeningTaskPayload? currentTask,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool? isFunnelCompleted,
    int? supportLadderLevel,
    int? currentLayer,
    bool? usedHint,
  }) {
    return DeepeningState(
      currentTask: currentTask ?? this.currentTask,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isFunnelCompleted: isFunnelCompleted ?? this.isFunnelCompleted,
      supportLadderLevel: supportLadderLevel ?? this.supportLadderLevel,
      currentLayer: currentLayer ?? this.currentLayer,
      usedHint: usedHint ?? this.usedHint,
    );
  }
}

class DeepeningController extends StateNotifier<DeepeningState> {
  final Ref ref;
  final Stopwatch _latencyStopwatch = Stopwatch();

  DeepeningController(this.ref) : super(const DeepeningState());

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Fetches the procedural/adapted next task for the given user from Layer 1 through 10.
  Future<void> fetchNextTask(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    _latencyStopwatch.reset();
    _latencyStopwatch.start();

    final client = _client;
    if (client == null) {
      // Offline / Fallback procedurally generated task
      final mockTask = _generateFallbackTask(userId, state.currentLayer);
      state = state.copyWith(
        currentTask: mockTask,
        isLoading: false,
      );
      return;
    }

    try {
      final response = await client.functions.invoke(
        'deepening-next-task',
        body: {'user_id': userId, 'layer': state.currentLayer},
      );

      if (response.data != null && response.data is Map) {
        final payload = DeepeningTaskPayload.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
        state = state.copyWith(
          currentTask: payload,
          isLoading: false,
          currentLayer: payload.layer,
        );
      } else {
        final mockTask = _generateFallbackTask(userId, state.currentLayer);
        state = state.copyWith(currentTask: mockTask, isLoading: false);
      }
    } catch (e) {
      debugPrint('[DeepeningController] Error fetching next task: $e');
      final mockTask = _generateFallbackTask(userId, state.currentLayer);
      state = state.copyWith(currentTask: mockTask, isLoading: false);
    }
  }

  /// Trigger Support Ladder hint increment.
  void triggerSupportLadderHint() {
    state = state.copyWith(
      supportLadderLevel: state.supportLadderLevel + 1,
      usedHint: true,
    );
  }

  /// Submits telemetry to recalculate path difficulty and Support Ladder states.
  Future<bool> submitResponse({
    required String userId,
    required double accuracy,
    required String responseText,
    required int errorCount,
  }) async {
    _latencyStopwatch.stop();
    final latencyMs = _latencyStopwatch.elapsedMilliseconds;

    final task = state.currentTask;
    if (task == null) return false;

    // Calculate engagement score (higher for active response, lower latency penalty)
    final engagementScore = (accuracy * 0.5) + (state.usedHint ? 0.2 : 0.4) + (latencyMs < 15000 ? 0.1 : 0.0);

    final telemetry = TelemetryPayload(
      taskId: task.taskId,
      userId: userId,
      layer: task.layer,
      accuracy: accuracy,
      latencyMs: latencyMs,
      recoveryCount: errorCount,
      engagementScore: engagementScore,
      userResponse: responseText,
      usedHint: state.usedHint,
    );

    state = state.copyWith(isSubmitting: true);

    final client = _client;
    bool success = true;

    if (client != null) {
      try {
        await client.functions.invoke(
          'deepening-submit-response',
          body: telemetry.toJson(),
        );
      } catch (e) {
        debugPrint('[DeepeningController] Error submitting telemetry: $e');
      }
    }

    if (state.currentLayer >= 10) {
      state = state.copyWith(
        isSubmitting: false,
        isFunnelCompleted: true,
      );
    } else {
      final nextLayer = state.currentLayer + 1;
      state = state.copyWith(
        isSubmitting: false,
        currentLayer: nextLayer,
        usedHint: false,
        supportLadderLevel: 0,
      );
      await fetchNextTask(userId);
    }

    return success;
  }

  DeepeningTaskPayload _generateFallbackTask(String userId, int layer) {
    final verticalId = (layer % 2 == 1) ? 'calendar_genius' : 'constellation_mapper';
    final skins = ['cosmic_space', 'sage_green', 'pastel_dinosaur', 'terracotta_train'];
    final skin = skins[(layer - 1) % skins.length];

    if (verticalId == 'calendar_genius') {
      return DeepeningTaskPayload(
        taskId: 'task_cal_$layer',
        userId: userId,
        layer: layer,
        totalLayers: 10,
        verticalId: 'calendar_genius',
        themeSkin: skin,
        prompt: 'Analyze the date pattern: Which day of the week will July 20, 2026 fall on?',
        taskData: {
          'target_date': '2026-07-20',
          'correct_day': 'Monday',
        },
      );
    } else {
      return DeepeningTaskPayload(
        taskId: 'task_const_$layer',
        userId: userId,
        layer: layer,
        totalLayers: 10,
        verticalId: 'constellation_mapper',
        themeSkin: skin,
        prompt: 'Connect 4 glowing star nodes to complete the adaptive constellation pattern.',
        taskData: {
          'required_stars': 4,
          'total_star_nodes': 6,
        },
      );
    }
  }
}

final deepeningControllerProvider = StateNotifierProvider<DeepeningController, DeepeningState>((ref) {
  return DeepeningController(ref);
});
