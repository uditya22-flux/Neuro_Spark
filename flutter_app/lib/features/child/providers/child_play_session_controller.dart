import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_environment_provider.dart';
import '../../strength_funnel/models/strength_funnel_finalists.dart';
import '../models/child_play_activity.dart';
import '../services/child_play_session_service.dart';

class ChildPlaySessionState {
  const ChildPlaySessionState({
    this.sessionId,
    this.activities = const [],
    this.currentIndex = 0,
    this.paused = false,
    this.loading = false,
    this.completed = false,
    this.error,
  });

  final String? sessionId;
  final List<ChildPlayActivity> activities;
  final int currentIndex;
  final bool paused;
  final bool loading;
  final bool completed;
  final String? error;

  ChildPlayActivity? get currentActivity {
    if (currentIndex < 0 || currentIndex >= activities.length) return null;
    return activities[currentIndex];
  }

  bool get hasNext => currentIndex < activities.length - 1;

  ChildPlaySessionState copyWith({
    String? sessionId,
    List<ChildPlayActivity>? activities,
    int? currentIndex,
    bool? paused,
    bool? loading,
    bool? completed,
    String? error,
  }) {
    return ChildPlaySessionState(
      sessionId: sessionId ?? this.sessionId,
      activities: activities ?? this.activities,
      currentIndex: currentIndex ?? this.currentIndex,
      paused: paused ?? this.paused,
      loading: loading ?? this.loading,
      completed: completed ?? this.completed,
      error: error,
    );
  }
}

class ChildPlaySessionController extends StateNotifier<ChildPlaySessionState> {
  ChildPlaySessionController(this._service) : super(const ChildPlaySessionState());

  final ChildPlaySessionService _service;

  Future<void> start({
    required IntakeSessionBundle bundle,
    required StrengthFunnelFinalists finalists,
  }) async {
    state = state.copyWith(loading: true, error: null, completed: false, paused: false);
    try {
      final launch = await _service.launch(bundle: bundle, finalists: finalists);
      state = ChildPlaySessionState(
        sessionId: launch.sessionId,
        activities: launch.activities,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void togglePause() {
    state = state.copyWith(paused: !state.paused);
  }

  void skip() {
    if (state.hasNext) {
      state = state.copyWith(currentIndex: state.currentIndex + 1, paused: false);
    } else {
      state = state.copyWith(completed: true, paused: false);
    }
  }

  void markExplored() {
    skip();
  }

  Future<void> stop() async {
    final sessionId = state.sessionId;
    if (sessionId != null) {
      await _service.endSession(sessionId);
    }
    state = const ChildPlaySessionState();
  }
}

final childPlaySessionControllerProvider =
    StateNotifierProvider<ChildPlaySessionController, ChildPlaySessionState>((ref) {
  return ChildPlaySessionController(ref.watch(childPlaySessionServiceProvider));
});
