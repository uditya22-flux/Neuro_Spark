import 'dart:math';

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
  final String phase;
  final String? sessionId;
  final int completedVerticals;
  final int totalVerticals;

  const DeepeningState({
    this.currentTask,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isFunnelCompleted = false,
    this.supportLadderLevel = 0,
    this.currentLayer = 1,
    this.usedHint = false,
    this.phase = 'layer1',
    this.sessionId,
    this.completedVerticals = 0,
    this.totalVerticals = 2,
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
    String? phase,
    String? sessionId,
    int? completedVerticals,
    int? totalVerticals,
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
      phase: phase ?? this.phase,
      sessionId: sessionId ?? this.sessionId,
      completedVerticals: completedVerticals ?? this.completedVerticals,
      totalVerticals: totalVerticals ?? this.totalVerticals,
    );
  }
}

class DeepeningController extends StateNotifier<DeepeningState> {
  final Ref ref;
  final Stopwatch _latencyStopwatch = Stopwatch();
  final List<DeepeningTaskPayload> _layer1Queue = [];

  String? _pendingResponseId;

  DeepeningController(this.ref) : super(const DeepeningState());

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchNextTask(String childId) async {
    if (state.sessionId == null && _client != null) {
      await _startLayer1(childId);
      return;
    }
    if (state.phase == 'layer1' && _layer1Queue.isNotEmpty) {
      _showLayer1Task(_layer1Queue.first);
      return;
    }
    if (state.phase == 'deepening' && state.currentTask != null) {
      await _fetchDeepeningTask(childId, state.currentTask!.verticalId);
    }
  }

  Future<void> _startLayer1(String childId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, phase: 'layer1');
    _latencyStopwatch..reset()..start();
    final client = _client;
    if (client == null) {
      _showLayer1Task(_generateFallbackTask(childId, 1));
      return;
    }
    try {
      final response = await client.functions.invoke('layer1-tasks', body: {'child_id': childId});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['verticals'] as List<dynamic>? ?? [])
          .map((row) => DeepeningTaskPayload.fromJson({...Map<String, dynamic>.from(row as Map), 'session_id': data['session_id'], 'user_id': childId}))
          .toList();
      _layer1Queue
        ..clear()
        ..addAll(rows);
      state = state.copyWith(sessionId: data['session_id'] as String?, totalVerticals: rows.length);
      if (_layer1Queue.isEmpty) throw Exception('No production verticals are active.');
      _showLayer1Task(_layer1Queue.first);
    } catch (e) {
      debugPrint('[DeepeningController] Layer 1 error: $e');
      _showLayer1Task(_generateFallbackTask(childId, 1));
      state = state.copyWith(errorMessage: 'Using the safe offline task while the service reconnects.');
    }
  }

  void _showLayer1Task(DeepeningTaskPayload task) {
    state = state.copyWith(
      currentTask: task,
      isLoading: false,
      isSubmitting: false,
      currentLayer: task.layer,
      supportLadderLevel: task.supportLevel,
      usedHint: false,
      phase: task.layer == 1 ? 'layer1' : 'deepening',
    );
    _pendingResponseId = null;
    _latencyStopwatch..reset()..start();
  }

  Future<void> _fetchDeepeningTask(String childId, String? ignoredVerticalId) async {
    final sessionId = state.sessionId;
    if (sessionId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    _latencyStopwatch..reset()..start();
    final client = _client;
    if (client == null) {
      _pendingResponseId = null;
      state = state.copyWith(currentTask: _generateFallbackTask(childId, state.currentLayer), isLoading: false);
      return;
    }
    try {
      final response = await client.functions.invoke('deepening-next-task', body: {
        'child_id': childId,
        'session_id': sessionId,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['status'] == 'funnel_complete') {
        state = state.copyWith(isFunnelCompleted: true, isLoading: false, currentTask: null);
        return;
      }
      
      final rows = (data['verticals'] as List<dynamic>? ?? [])
          .map((row) => DeepeningTaskPayload.fromJson({...Map<String, dynamic>.from(row as Map), 'session_id': sessionId, 'user_id': childId}))
          .toList();
          
      if (rows.isEmpty) {
        throw Exception('No tasks returned for the layer.');
      }
      
      _layer1Queue
        ..clear()
        ..addAll(rows);
      _showLayer1Task(_layer1Queue.first);
    } catch (e) {
      debugPrint('[DeepeningController] Deepening task error: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'The next task could not be loaded. Please try again.');
    }
  }

  void triggerSupportLadderHint() {
    state = state.copyWith(
      supportLadderLevel: (state.supportLadderLevel + 1).clamp(0, 5).toInt(),
      usedHint: true,
    );
    final task = state.currentTask;
    final client = _client;
    if (task == null || client == null || state.sessionId == null) return;
    _requestSupport(client, task);
  }

  Future<void> _requestSupport(SupabaseClient client, DeepeningTaskPayload task) async {
    try {
      final response = await client.functions.invoke('deepening-support', body: {
        'child_id': task.userId,
        'session_id': state.sessionId,
        'task_id': task.taskId,
        'vertical_id': task.verticalId,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      final level = data['support_level'];
      if (level is int) {
        state = state.copyWith(supportLadderLevel: level.clamp(0, 5).toInt());
      }
    } catch (e) {
      debugPrint('[DeepeningController] Support request error: $e');
    }
  }

  Future<bool> submitResponse({
    required String userId,
    required double accuracy,
    required String responseText,
    required int errorCount,
  }) async {
    _latencyStopwatch.stop();
    final task = state.currentTask;
    if (task == null) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    final latencyMs = _latencyStopwatch.elapsedMilliseconds;
    _pendingResponseId ??= _newResponseId();
    final engagementScore = (accuracy * 0.5) + (state.usedHint ? 0.2 : 0.4) + (latencyMs < 15000 ? 0.1 : 0.0);
    final telemetry = TelemetryPayload(
      taskId: task.taskId,
      responseId: _pendingResponseId,
      userId: userId,
      sessionId: state.sessionId ?? task.sessionId,
      layer: task.layer,
      accuracy: accuracy,
      latencyMs: latencyMs,
      recoveryCount: errorCount,
      engagementScore: engagementScore,
      userResponse: responseText,
      usedHint: state.usedHint,
      supportLevelUsed: state.supportLadderLevel,
      retryCount: errorCount,
      modality: task.modality,
    );
    final client = _client;
    Map<String, dynamic> result = {};
    if (client != null && state.sessionId != null) {
      try {
        final function = state.phase == 'layer1' ? 'layer1-submit-response' : 'deepening-submit-response';
        final response = await client.functions.invoke(function, body: {
          'child_id': userId,
          'session_id': state.sessionId,
          'task_id': task.taskId,
          'response_id': _pendingResponseId,
          'vertical_id': task.verticalId,
          'response': responseText,
          'timing': {
            'latency_ms': latencyMs,
          },
          'behavior': {
            'retry_count': errorCount,
            'hint_usage': state.usedHint ? 1 : 0,
            'skipped': false,
          },
          ...telemetry.toJson(),
        });
        if (response.data is Map) {
          result = Map<String, dynamic>.from(response.data as Map);
        }
      } catch (e) {
        debugPrint('[DeepeningController] Response submission warning: $e');
      }
    }

    _layer1Queue.removeWhere((queued) => queued.taskId == task.taskId);
    
    if (result['funnel_complete'] == true || result['next_phase'] == 'complete' || task.layer >= 10) {
      state = state.copyWith(isSubmitting: false, isFunnelCompleted: true, currentTask: null);
      return true;
    }

    if (_layer1Queue.isNotEmpty) {
      _showLayer1Task(_layer1Queue.first);
    } else {
      final nextTaskIndex = (state.currentTask?.layer == 1) 
          ? ((state.currentTask?.taskId.hashCode ?? 0).abs() % 29 + 2) 
          : 1;
      final nextLayer = _layer1Queue.isEmpty ? (task.layer < 10 ? task.layer + 1 : 10) : task.layer;
      
      _populateFallbackQueue(userId, nextLayer);
      if (_layer1Queue.isNotEmpty) {
        _showLayer1Task(_layer1Queue.first);
      } else {
        state = state.copyWith(isSubmitting: false, isFunnelCompleted: true, currentTask: null);
      }
    }
    return true;
  }

  void _populateFallbackQueue(String userId, int layer) {
    _layer1Queue.clear();
    final count = layer == 1 ? 30 : 10;
    for (int i = 1; i <= count; i++) {
      _layer1Queue.add(_generateFallbackTask(userId, layer, taskIndex: i));
    }
  }

  String _newResponseId() {
    final random = Random.secure();
    String hex(int length) => List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
    final variant = ['8', '9', 'a', 'b'][random.nextInt(4)];
    return '${hex(8)}-${hex(4)}-4${hex(3)}-$variant${hex(3)}-${hex(12)}';
  }

  DeepeningTaskPayload _generateFallbackTask(String userId, int layer) {
    final verticals = [
      'calendar_genius',
      'constellation_mapper',
      'discovery',
      'visual_pattern_explorer',
      'sequence_navigator',
      'spatial_builder',
      'memory_weaver',
      'language_patterner',
      'number_navigator',
      'logic_lens',
    ];
    // Randomize selection per layer and session seed so baseline discovery is unpredictable
    final seed = ((state.sessionId?.hashCode ?? userId.hashCode) + layer * 31).abs();
    final verticalId = verticals[seed % verticals.length];
    final skins = ['cosmic_space', 'sage_green', 'pastel_dinosaur', 'terracotta_train'];
    final skin = skins[seed % skins.length];

    final totalQuestions = layer == 1 ? 30 : 10;

    switch (verticalId) {
      case 'calendar_genius':
        return DeepeningTaskPayload(
          taskId: 'fallback_cal_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'calendar_genius', themeSkin: skin,
          prompt: 'Find the day of the week for July 20, 2026.', taskData: {'target_date': '2026-07-20'},
        );
      case 'constellation_mapper':
        return DeepeningTaskPayload(
          taskId: 'fallback_const_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'constellation_mapper', themeSkin: skin,
          prompt: 'Select four stars that belong to the same pattern.', taskData: {'required_stars': 4, 'total_star_nodes': 6},
        );
      case 'discovery':
        return DeepeningTaskPayload(
          taskId: 'fallback_disc_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'discovery', themeSkin: skin,
          prompt: 'Which path on the map leads to the hidden treasure emblem?',
          taskData: {'options': ['Northern Pass', 'Crystal Cave', 'Sunset Valley', 'Echo River']},
        );
      case 'visual_pattern_explorer':
        return DeepeningTaskPayload(
          taskId: 'fallback_vis_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'visual_pattern_explorer', themeSkin: skin,
          prompt: 'Identify the tile pattern that completes the symmetrical sequence.',
          taskData: {'options': ['Pattern A (Rotated)', 'Pattern B (Mirrored)', 'Pattern C (Shifted)', 'Pattern D (Inverted)']},
        );
      case 'sequence_navigator':
        return DeepeningTaskPayload(
          taskId: 'fallback_seq_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'sequence_navigator', themeSkin: skin,
          prompt: 'Arrange the sequence order to keep the train schedule on time.',
          taskData: {'options': ['Station 1 -> 2 -> 3', 'Station 2 -> 1 -> 3', 'Station 3 -> 2 -> 1']},
        );
      case 'spatial_builder':
        return DeepeningTaskPayload(
          taskId: 'fallback_spat_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'spatial_builder', themeSkin: skin,
          prompt: 'Which 3D shape fits into the designated slot without overlapping?',
          taskData: {'options': ['Blue Prism', 'Green Pyramid', 'Red Cylinder', 'Yellow Cube']},
        );
      case 'memory_weaver':
        return DeepeningTaskPayload(
          taskId: 'fallback_mem_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'memory_weaver', themeSkin: skin,
          prompt: 'Which item was shown first in the story sequence?',
          taskData: {'options': ['Golden Key', 'Ancient Compass', 'Silver Lantern', 'Velvet Map']},
        );
      case 'language_patterner':
        return DeepeningTaskPayload(
          taskId: 'fallback_lang_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'language_patterner', themeSkin: skin,
          prompt: 'Find the word that follows the repeating rhyming pattern.',
          taskData: {'options': ['Glow', 'Bright', 'Flow', 'Shine']},
        );
      case 'number_navigator':
        return DeepeningTaskPayload(
          taskId: 'fallback_num_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'number_navigator', themeSkin: skin,
          prompt: 'Identify the missing number in the step progression: 3, 6, 9, ?, 15.',
          taskData: {'options': ['11', '12', '13', '14']},
        );
      case 'logic_lens':
      default:
        return DeepeningTaskPayload(
          taskId: 'fallback_logic_${layer}_$seed', userId: userId, layer: layer, totalLayers: totalQuestions, verticalId: 'logic_lens', themeSkin: skin,
          prompt: 'If shape A is larger than B, and B is larger than C, which shape is smallest?',
          taskData: {'options': ['Shape A', 'Shape B', 'Shape C']},
        );
    }
  }
}

final deepeningControllerProvider = StateNotifierProvider<DeepeningController, DeepeningState>((ref) {
  return DeepeningController(ref);
});
