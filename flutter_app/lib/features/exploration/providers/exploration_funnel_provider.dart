import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/prototype_mode.dart';
import '../models/exploration_models.dart';
import '../models/synthetic_engine2_models.dart';
import '../models/visual_scene_spec.dart';
import '../services/deepening_task_factory.dart';
import '../services/layer1_generator.dart';
import '../services/play_routing_score_calculator.dart';
import '../services/synthetic_engine2_service.dart';
import 'intake_provider.dart';

enum ExplorationPhase { idle, ambientBaseline, deepening, complete }

/// Result of one server-validated visual option in synthetic cloud mode.
enum SyntheticCloudChoiceResult { solved, softMiss, unavailable }

class SupportLadderState {
  final int level;
  final bool timerPaused;
  final bool highlightTarget;
  final String message;

  const SupportLadderState({
    this.level = 0,
    this.timerPaused = false,
    this.highlightTarget = false,
    this.message = '',
  });
}

/// State for the active play canvas. Builder mode stays entirely local;
/// synthetic cloud mode uses an opaque anonymous session and contains no
/// guardian free text, real child identifier, or child-facing scorecard.
class ExplorationFunnelState {
  final ExplorationPhase phase;
  final PuzzleSpec? currentTask;
  final List<PuzzleSpec> taskQueue;
  final List<PlayObservation> sessionObservations;
  final List<PlayMechanic> activeMechanics;
  final List<PlayRoutingResult> routingResults;
  final PlayMechanic? finalMechanic;
  final int currentLayer;
  final String? syntheticCloudSessionId;
  final VisualSceneSpec? syntheticCloudScene;
  final bool usesSyntheticCloud;
  final SupportLadderState support;
  final String? error;

  const ExplorationFunnelState({
    this.phase = ExplorationPhase.idle,
    this.currentTask,
    this.taskQueue = const [],
    this.sessionObservations = const [],
    this.activeMechanics = const [],
    this.routingResults = const [],
    this.finalMechanic,
    this.currentLayer = 1,
    this.syntheticCloudSessionId,
    this.syntheticCloudScene,
    this.usesSyntheticCloud = false,
    this.support = const SupportLadderState(),
    this.error,
  });

  ExplorationFunnelState copyWith({
    ExplorationPhase? phase,
    PuzzleSpec? currentTask,
    bool clearTask = false,
    List<PuzzleSpec>? taskQueue,
    List<PlayObservation>? sessionObservations,
    List<PlayMechanic>? activeMechanics,
    List<PlayRoutingResult>? routingResults,
    PlayMechanic? finalMechanic,
    bool clearFinalMechanic = false,
    int? currentLayer,
    String? syntheticCloudSessionId,
    bool clearSyntheticCloudSession = false,
    VisualSceneSpec? syntheticCloudScene,
    bool clearSyntheticCloudScene = false,
    bool? usesSyntheticCloud,
    SupportLadderState? support,
    String? error,
    bool clearError = false,
  }) =>
      ExplorationFunnelState(
        phase: phase ?? this.phase,
        currentTask: clearTask ? null : (currentTask ?? this.currentTask),
        taskQueue: taskQueue ?? this.taskQueue,
        sessionObservations: sessionObservations ?? this.sessionObservations,
        activeMechanics: activeMechanics ?? this.activeMechanics,
        routingResults: routingResults ?? this.routingResults,
        finalMechanic: clearFinalMechanic ? null : (finalMechanic ?? this.finalMechanic),
        currentLayer: currentLayer ?? this.currentLayer,
        syntheticCloudSessionId: clearSyntheticCloudSession
            ? null
            : (syntheticCloudSessionId ?? this.syntheticCloudSessionId),
        syntheticCloudScene: clearSyntheticCloudScene
            ? null
            : (syntheticCloudScene ?? this.syntheticCloudScene),
        usesSyntheticCloud: usesSyntheticCloud ?? this.usesSyntheticCloud,
        support: support ?? this.support,
        error: clearError ? null : (error ?? this.error),
      );
}

class ExplorationFunnelController extends StateNotifier<ExplorationFunnelState> {
  ExplorationFunnelController(this.ref) : super(const ExplorationFunnelState());

  final Ref ref;
  Timer? _inactivityTimer;
  IntakeConfiguration? get _intake => ref.read(intakeProvider).configuration;

  /// The requested builder-only filtration schedule. Layer 1 is all thirty
  /// mechanics; every later number is the active pool for that layer.
  static const Map<int, int> _activeCountByLayer = {
    1: 30,
    2: 10,
    3: 8,
    4: 7,
    5: 6,
    6: 5,
    7: 4,
    8: 3,
    9: 2,
    10: 1,
  };

  static int activeDomainCountForLayer(int layer) => _activeCountByLayer[layer] ?? 1;

  Future<void> start() async {
    _inactivityTimer?.cancel();
    final intake = _intake;
    if (intake == null) {
      state = state.copyWith(
        error: 'Guardian preferences are needed before play can begin.',
      );
      return;
    }

    if (ref.read(syntheticEngine2ServiceProvider).supportsCloudSession) {
      state = const ExplorationFunnelState(
        phase: ExplorationPhase.ambientBaseline,
        currentLayer: 1,
        usesSyntheticCloud: true,
      );
      final result = await ref.read(syntheticEngine2ServiceProvider).startSession(
            intake: intake,
          );
      _adoptSyntheticCloudResult(result);
      return;
    }

    if (builderShowcaseMode) {
      final tasks = Layer1Generator.generateBuilderShowcase(intake: intake);
      if (tasks.isEmpty) {
        state = state.copyWith(error: 'Preparing play took longer than expected.');
        return;
      }
      state = ExplorationFunnelState(
        phase: ExplorationPhase.ambientBaseline,
        currentTask: tasks.first,
        taskQueue: tasks.skip(1).toList(growable: false),
        activeMechanics: PlayMechanic.values,
        currentLayer: 1,
      );
      return;
    }

    // Preserve the existing non-showcase experience. It is intentionally not
    // used as an adaptive ranking or routing system.
    final scenes = Layer1Generator.generate(intake: intake);
    state = ExplorationFunnelState(
      phase: ExplorationPhase.ambientBaseline,
      currentTask: scenes.first,
      taskQueue: scenes.skip(1).toList(growable: false),
      currentLayer: 1,
    );
  }

  void recordChildInteraction() {
    if (state.support.timerPaused) {
      state = state.copyWith(
        support: SupportLadderState(
          level: state.support.level,
          highlightTarget: state.support.highlightTarget,
        ),
      );
    }
    _watchInactivity();
  }

  void _watchInactivity() {
    _inactivityTimer?.cancel();
    if (state.phase != ExplorationPhase.deepening || state.currentTask == null) return;
    _inactivityTimer = Timer(const Duration(seconds: 6), _offerSupport);
  }

  void _offerSupport() {
    final task = state.currentTask;
    if (task == null || state.phase != ExplorationPhase.deepening) return;
    final nextLevel = (state.support.level + 1).clamp(1, 3).toInt();
    final simplify = nextLevel >= 2;
    state = state.copyWith(
      currentTask: simplify
          ? task.copyWith(itemCount: 3, showsDistractors: false)
          : task,
      support: SupportLadderState(
        level: nextLevel,
        timerPaused: true,
        highlightTarget: true,
        message: simplify
            ? 'The scene has quietly simplified.'
            : 'The matching area is gently glowing.',
      ),
    );
    // The support remains completely non-verbal. If the first gentle glow is
    // not enough and there is still no interaction, simplify the same scene
    // shortly afterwards while its active timer stays paused.
    if (!simplify) {
      _inactivityTimer = Timer(const Duration(milliseconds: 1400), _offerSupport);
    }
  }

  void completeCurrentTask(ExplorationTelemetry telemetry) {
    final task = state.currentTask;
    if (task == null) return;
    _inactivityTimer?.cancel();

    final observations = [
      ...state.sessionObservations,
      PlayObservation(
        mechanics: task.mechanics,
        telemetry: telemetry,
        layer: task.layer,
        expectedInteractions: task.expectedInteractions,
        speedBudgetMs: task.speedBudgetMs,
        supportLevelUsed: state.support.level,
      ),
    ];

    if (state.taskQueue.isNotEmpty) {
      _showNextQueuedTask(observations);
      return;
    }

    if (builderShowcaseMode) {
      _completeBuilderLayer(observations);
      return;
    }

    _completeStandardFlow(task, observations);
  }

  /// Sends exactly one issued visual option to the anonymous cloud function.
  /// The function owns answer validation, synthetic persistence, scoring, and
  /// issuing the next OpenAI-generated puzzle specification.
  Future<SyntheticCloudChoiceResult> submitSyntheticCloudSelection({
    required String optionId,
    required ExplorationTelemetry telemetry,
  }) async {
    final task = state.currentTask;
    final sessionId = state.syntheticCloudSessionId;
    if (!state.usesSyntheticCloud || task == null || sessionId == null) {
      return SyntheticCloudChoiceResult.unavailable;
    }

    final result = await ref.read(syntheticEngine2ServiceProvider).submitSelection(
          sessionId: sessionId,
          task: task,
          optionId: optionId,
          telemetry: telemetry,
          supportLevel: state.support.level,
        );
    if (result.status == SyntheticEngine2Status.unavailable) {
      state = state.copyWith(error: result.reason ?? 'The synthetic cloud task is unavailable.');
      return SyntheticCloudChoiceResult.unavailable;
    }
    if (result.isUnsolved) {
      // The server deliberately retained the current task after a soft miss.
      return SyntheticCloudChoiceResult.softMiss;
    }

    _inactivityTimer?.cancel();
    _adoptSyntheticCloudResult(result);
    return result.isSolved || result.isComplete
        ? SyntheticCloudChoiceResult.solved
        : SyntheticCloudChoiceResult.unavailable;
  }

  void _adoptSyntheticCloudResult(SyntheticEngine2Result result) {
    if (result.status == SyntheticEngine2Status.unavailable) {
      state = state.copyWith(error: result.reason ?? 'The synthetic cloud task is unavailable.');
      return;
    }
    if (result.isComplete) {
      state = state.copyWith(
        phase: ExplorationPhase.complete,
        clearTask: true,
        taskQueue: const [],
        activeMechanics: result.activeSectors,
        currentLayer: result.currentLayer ?? state.currentLayer,
        finalMechanic: result.finalSector,
        syntheticCloudSessionId: result.sessionId,
        clearSyntheticCloudScene: true,
        usesSyntheticCloud: true,
        support: const SupportLadderState(),
        clearError: true,
      );
      return;
    }
    final task = result.nextTask;
    if (!result.isInProgress || task == null || result.sessionId == null) {
      state = state.copyWith(error: result.reason ?? 'The synthetic cloud task is incomplete.');
      return;
    }
    state = state.copyWith(
      phase: task.layer == 1 ? ExplorationPhase.ambientBaseline : ExplorationPhase.deepening,
      currentTask: task,
      taskQueue: const [],
      activeMechanics: result.activeSectors,
      currentLayer: result.currentLayer ?? task.layer,
      syntheticCloudSessionId: result.sessionId,
      syntheticCloudScene: result.scene,
      clearSyntheticCloudScene: result.scene == null,
      usesSyntheticCloud: true,
      support: const SupportLadderState(),
      clearError: true,
    );
    _watchInactivity();
  }

  void _showNextQueuedTask(List<PlayObservation> observations) {
    final next = state.taskQueue.first;
    state = state.copyWith(
      currentTask: next,
      taskQueue: state.taskQueue.skip(1).toList(growable: false),
      sessionObservations: observations,
      support: const SupportLadderState(),
    );
    _watchInactivity();
  }

  void _completeStandardFlow(
    PuzzleSpec task,
    List<PlayObservation> observations,
  ) {
    if (state.phase == ExplorationPhase.ambientBaseline) {
      state = state.copyWith(sessionObservations: observations);
      _showStandardLayer(2);
      return;
    }
    if (task.layer >= 10) {
      state = state.copyWith(
        phase: ExplorationPhase.complete,
        clearTask: true,
        sessionObservations: observations,
      );
      return;
    }
    state = state.copyWith(sessionObservations: observations);
    _showStandardLayer(task.layer + 1);
  }

  void _showStandardLayer(int layer) {
    final intake = _intake;
    if (intake == null) return;
    state = state.copyWith(
      phase: ExplorationPhase.deepening,
      currentTask: DeepeningTaskFactory.build(intake: intake, layer: layer),
      taskQueue: const [],
      currentLayer: layer,
      support: const SupportLadderState(),
    );
    _watchInactivity();
  }

  void _completeBuilderLayer(List<PlayObservation> observations) {
    final layerObservations = observations
        .where((observation) => observation.layer == state.currentLayer)
        .toList(growable: false);
    final ranked = PlayRoutingScoreCalculator.rank(layerObservations);

    if (state.currentLayer >= 10) {
      state = state.copyWith(
        phase: ExplorationPhase.complete,
        clearTask: true,
        taskQueue: const [],
        sessionObservations: observations,
        routingResults: ranked,
        finalMechanic: ranked.isEmpty ? null : ranked.first.mechanic,
        support: const SupportLadderState(),
      );
      return;
    }

    final nextLayer = state.currentLayer + 1;
    final survivorCount = activeDomainCountForLayer(nextLayer);
    final survivors = ranked
        .take(survivorCount)
        .map((result) => result.mechanic)
        .toList(growable: false);

    // A full builder queue always has one observation for every active
    // mechanic. The defensive fallback prevents a broken task from creating a
    // child-facing failure screen if a future renderer yields no result.
    if (survivors.isEmpty) {
      state = state.copyWith(
        phase: ExplorationPhase.complete,
        clearTask: true,
        sessionObservations: observations,
        routingResults: ranked,
        support: const SupportLadderState(),
      );
      return;
    }
    _beginBuilderLayer(
      layer: nextLayer,
      activeMechanics: survivors,
      observations: observations,
      routingResults: ranked,
    );
  }

  void _beginBuilderLayer({
    required int layer,
    required List<PlayMechanic> activeMechanics,
    required List<PlayObservation> observations,
    required List<PlayRoutingResult> routingResults,
  }) {
    final intake = _intake;
    if (intake == null) return;
    final tasks = DeepeningTaskFactory.buildBuilderLayer(
      intake: intake,
      layer: layer,
      activeMechanics: activeMechanics,
    );
    if (tasks.isEmpty) {
      state = state.copyWith(
        phase: ExplorationPhase.complete,
        clearTask: true,
        sessionObservations: observations,
        routingResults: routingResults,
      );
      return;
    }
    state = state.copyWith(
      phase: ExplorationPhase.deepening,
      currentTask: tasks.first,
      taskQueue: tasks.skip(1).toList(growable: false),
      sessionObservations: observations,
      activeMechanics: activeMechanics,
      routingResults: routingResults,
      currentLayer: layer,
      support: const SupportLadderState(),
      clearError: true,
    );
    _watchInactivity();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}

final explorationFunnelProvider =
    StateNotifierProvider<ExplorationFunnelController, ExplorationFunnelState>(
  (ref) => ExplorationFunnelController(ref),
);
