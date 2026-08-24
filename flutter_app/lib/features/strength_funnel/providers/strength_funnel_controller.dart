import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/strength_funnel_repository.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/modality_router.dart';
import '../data/strength_funnel_math.dart';
import '../models/layer1_sector_task.dart';

class StrengthFunnelState {
  const StrengthFunnelState({
    this.loading = false,
    this.error,
    this.sessionId,
    this.layerRunId,
    this.childId,
    this.layerNumber = 1,
    this.constraints,
    this.tasks = const [],
    this.currentIndex = 0,
    this.completedSectorIds = const {},
    this.scores = const {},
    this.layerComplete = false,
    this.advancingSectorIds,
    this.remote = false,
    this.funnelPhaseComplete = false,
  });

  final bool loading;
  final String? error;
  final String? sessionId;
  final String? layerRunId;
  final String? childId;
  final int layerNumber;
  final ModalityConstraints? constraints;
  final List<Layer1SectorTask> tasks;
  final int currentIndex;
  final Set<String> completedSectorIds;
  final Map<String, double> scores;
  final bool layerComplete;
  final List<String>? advancingSectorIds;
  final bool remote;
  final bool funnelPhaseComplete;

  Layer1SectorTask? get currentTask =>
      currentIndex >= 0 && currentIndex < tasks.length ? tasks[currentIndex] : null;

  int get totalTasks => tasks.length;

  int get scoredCount => completedSectorIds.length;

  double get progress =>
      totalTasks == 0 ? 0 : scoredCount / totalTasks;

  bool get canStartNextLayer =>
      layerComplete &&
      !funnelPhaseComplete &&
      layerNumber < kStrengthFunnelBetaExitLayer &&
      (advancingSectorIds?.isNotEmpty ?? false);

  bool get readyForAssessment =>
      funnelPhaseComplete || (layerComplete && layerNumber >= kStrengthFunnelBetaExitLayer);

  StrengthFunnelState copyWith({
    bool? loading,
    String? error,
    String? sessionId,
    String? layerRunId,
    String? childId,
    int? layerNumber,
    ModalityConstraints? constraints,
    List<Layer1SectorTask>? tasks,
    int? currentIndex,
    Set<String>? completedSectorIds,
    Map<String, double>? scores,
    bool? layerComplete,
    List<String>? advancingSectorIds,
    bool? remote,
    bool? funnelPhaseComplete,
  }) {
    return StrengthFunnelState(
      loading: loading ?? this.loading,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      layerRunId: layerRunId ?? this.layerRunId,
      childId: childId ?? this.childId,
      layerNumber: layerNumber ?? this.layerNumber,
      constraints: constraints ?? this.constraints,
      tasks: tasks ?? this.tasks,
      currentIndex: currentIndex ?? this.currentIndex,
      completedSectorIds: completedSectorIds ?? this.completedSectorIds,
      scores: scores ?? this.scores,
      layerComplete: layerComplete ?? this.layerComplete,
      advancingSectorIds: advancingSectorIds ?? this.advancingSectorIds,
      remote: remote ?? this.remote,
      funnelPhaseComplete: funnelPhaseComplete ?? this.funnelPhaseComplete,
    );
  }
}

class StrengthFunnelController extends StateNotifier<StrengthFunnelState> {
  StrengthFunnelController(this._repository, this._readBundle)
      : super(const StrengthFunnelState());

  final StrengthFunnelRepository _repository;
  final IntakeSessionBundle? Function() _readBundle;

  Future<void> startLayer1() => _startLayer(1);

  Future<void> startNextLayer() async {
    final nextLayer = state.layerNumber + 1;
    final advancing = state.advancingSectorIds;
    if (advancing == null || advancing.isEmpty) {
      state = state.copyWith(error: 'No advancing sectors available for the next layer.');
      return;
    }
    await _startLayer(nextLayer, advancingSectorIds: advancing);
  }

  Future<void> _startLayer(int layerNumber, {List<String>? advancingSectorIds}) async {
    final bundle = _readBundle();
    if (bundle == null) {
      state = state.copyWith(loading: false, error: 'Intake profile not loaded.');
      return;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      StrengthFunnelStartResult result;
      if (layerNumber == 1) {
        result = await _repository.startLayer(bundle, layerNumber: 1);
      } else {
        final sessionId = state.sessionId;
        if (sessionId != null && advancingSectorIds != null && sessionId.startsWith('local_')) {
          result = _repository.startLocalLayerFromScores(
            bundle: bundle,
            layerNumber: layerNumber,
            sessionId: sessionId,
            advancingSectorIds: advancingSectorIds,
          );
        } else {
          result = await _repository.startLayer(
            bundle,
            layerNumber: layerNumber,
            sessionId: state.sessionId,
          );
        }
      }

      final completed = Set<String>.from(result.completedSectorIds);
      var startIndex = 0;
      for (var i = 0; i < result.tasks.length; i++) {
        if (!completed.contains(result.tasks[i].sectorId)) {
          startIndex = i;
          break;
        }
      }

      state = StrengthFunnelState(
        loading: false,
        sessionId: result.sessionId,
        layerRunId: result.layerRunId,
        childId: bundle.childId ?? 'local_child',
        layerNumber: result.layerNumber,
        constraints: result.constraints,
        tasks: result.tasks,
        currentIndex: startIndex,
        completedSectorIds: completed,
        remote: result.remote,
        layerComplete: completed.length >= result.tasks.length,
        scores: layerNumber == 1 ? {} : state.scores,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> submitCurrentScore(double engagement) async {
    final task = state.currentTask;
    final sessionId = state.sessionId;
    final layerRunId = state.layerRunId;
    final childId = state.childId;
    if (task == null || sessionId == null || layerRunId == null || childId == null) {
      return false;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _repository.submitScore(
        sessionId: sessionId,
        layerRunId: layerRunId,
        childId: childId,
        sectorId: task.sectorId,
        engagementScore: engagement,
        modalityUsed: task.rendererModality,
        layerNumber: state.layerNumber,
        totalSectorsInLayer: state.totalTasks,
      );

      final completed = Set<String>.from(state.completedSectorIds)..add(task.sectorId);
      final scores = Map<String, double>.from(state.scores)..[task.sectorId] = engagement;

      var nextIndex = state.currentIndex;
      var layerComplete = result.layerComplete;
      if (!layerComplete) {
        for (var i = state.currentIndex + 1; i < state.tasks.length; i++) {
          if (!completed.contains(state.tasks[i].sectorId)) {
            nextIndex = i;
            break;
          }
        }
        if (completed.length >= state.tasks.length) {
          layerComplete = true;
        }
      }

      List<String>? advancing = result.advancingSectorIds;
      if (sessionId.startsWith('local_') && layerComplete) {
        advancing = _repository.computeAdvancingLocally(scores, state.layerNumber);
      }

      final funnelDone = layerComplete && state.layerNumber >= kStrengthFunnelBetaExitLayer;

      state = state.copyWith(
        loading: false,
        completedSectorIds: completed,
        scores: scores,
        currentIndex: nextIndex,
        layerComplete: layerComplete,
        advancingSectorIds: advancing,
        funnelPhaseComplete: funnelDone,
      );
      return funnelDone;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}

final strengthFunnelRepositoryProvider = Provider<StrengthFunnelRepository>((ref) {
  return const StrengthFunnelRepository();
});

final strengthFunnelControllerProvider =
    StateNotifierProvider<StrengthFunnelController, StrengthFunnelState>((ref) {
  return StrengthFunnelController(
    ref.watch(strengthFunnelRepositoryProvider),
    () => ref.watch(gameEnvironmentProvider),
  );
});
