import 'exploration_models.dart';
import 'visual_scene_spec.dart';

/// The small, allowlisted visual vocabulary that may leave Flutter during a
/// synthetic cloud showcase. It deliberately has no names, free-text themes,
/// child identifiers, ages, or guardian-entered descriptions.
class SyntheticEngine2VisualSettings {
  const SyntheticEngine2VisualSettings({
    required this.world,
    required this.palette,
    required this.objectStyle,
    required this.motionAllowed,
    required this.allowDistractors,
    required this.interaction,
  });

  final SyntheticDemoWorld world;
  final List<FamiliarColor> palette;
  final VisualStylePreference objectStyle;
  final bool motionAllowed;
  final bool allowDistractors;
  final InteractionPreference interaction;

  factory SyntheticEngine2VisualSettings.fromIntake(
    IntakeConfiguration intake,
  ) {
    final interface = intake.interface;
    return SyntheticEngine2VisualSettings(
      world: intake.syntheticDemoWorld,
      palette: _uniquePalette(intake.familiarColors),
      objectStyle: intake.visualStylePreference,
      motionAllowed: interface.allowMotion,
      allowDistractors: interface.allowDistractors,
      interaction: interface.preferredInteraction,
    );
  }

  factory SyntheticEngine2VisualSettings.fromJson(Map<String, dynamic> json) {
    return SyntheticEngine2VisualSettings(
      world: _enumByName(
        SyntheticDemoWorld.values,
        json['world'],
        SyntheticDemoWorld.vehicles,
      ),
      palette: _colorsFromJson(json['palette']),
      objectStyle: _enumByName(
        VisualStylePreference.values,
        json['object_style'],
        VisualStylePreference.illustratedObjects,
      ),
      motionAllowed: json['motion_allowed'] == true,
      allowDistractors: json['allow_distractors'] == true,
      interaction: _enumByName(
        InteractionPreference.values,
        json['interaction'],
        InteractionPreference.tapping,
      ),
    );
  }

  /// This is the complete synthetic visual payload. Keep it enum-only.
  Map<String, dynamic> toJson() => {
        'world': world.name,
        'palette': palette.isEmpty
            ? const ['blue']
            : palette.map((color) => color.name).toList(growable: false),
        'object_style': objectStyle.name,
        'motion_allowed': motionAllowed,
        'allow_distractors': allowDistractors,
        'interaction': interaction.name,
      };
}

/// Starts a server-owned, synthetic Engine 2 session. The session state is
/// intentionally opaque to Flutter; only the Edge Function owns its ID.
class SyntheticEngine2StartRequest {
  const SyntheticEngine2StartRequest({required this.visual});

  final SyntheticEngine2VisualSettings visual;

  factory SyntheticEngine2StartRequest.fromIntake(IntakeConfiguration intake) =>
      SyntheticEngine2StartRequest(
        visual: SyntheticEngine2VisualSettings.fromIntake(intake),
      );

  Map<String, dynamic> toJson() => {
        'action': 'start',
        'visual': visual.toJson(),
      };
}

/// Sends one selection to the synthetic cloud funnel. The Edge Function owns
/// correctness; Flutter only forwards a safe option token that was issued in
/// the previous task response along with cumulative aggregate telemetry.
class SyntheticEngine2SelectionRequest {
  const SyntheticEngine2SelectionRequest({
    required this.sessionId,
    required this.taskId,
    required this.sector,
    required this.layer,
    required this.optionId,
    required this.latencyMs,
    required this.misclicks,
    required this.recoveredErrors,
    required this.interactions,
    required this.supportLevel,
  });

  final String sessionId;
  final String taskId;
  final PlayMechanic sector;
  final int layer;
  final String optionId;
  final int latencyMs;
  final int misclicks;
  final int recoveredErrors;
  final int interactions;
  final int supportLevel;

  factory SyntheticEngine2SelectionRequest.fromSelection({
    required String sessionId,
    required PuzzleSpec task,
    required String optionId,
    required ExplorationTelemetry telemetry,
    required int supportLevel,
  }) {
    _validateSyntheticTaskContext(sessionId: sessionId, task: task);
    final safeOption = _safeOption(optionId);
    if (safeOption == null || !task.options.contains(safeOption)) {
      throw ArgumentError.value(
        optionId,
        'optionId',
        'Must be an option issued for this synthetic task.',
      );
    }
    final safeTelemetry = _SyntheticEngine2Telemetry.fromExploration(
      telemetry,
      supportLevel,
    );
    return SyntheticEngine2SelectionRequest(
      sessionId: sessionId,
      taskId: task.id,
      sector: task.mechanics.single,
      layer: task.layer,
      optionId: safeOption,
      latencyMs: safeTelemetry.latencyMs,
      misclicks: safeTelemetry.misclicks,
      recoveredErrors: safeTelemetry.recoveredErrors,
      interactions: safeTelemetry.interactions,
      supportLevel: safeTelemetry.supportLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': 'answer',
        'session_id': sessionId,
        'task_id': taskId,
        'sector': sector.name,
        'layer': layer,
        'option_id': optionId,
        'telemetry': {
          'latency_ms': latencyMs,
          'misclicks': misclicks,
          'recovered_errors': recoveredErrors,
          'interactions': interactions,
          'support_level': supportLevel,
        },
      };
}

/// Finalizes an issued synthetic task after an inactivity timeout. This is an
/// enum/number-only payload: it deliberately has no answer, reason, or text
/// field that could carry personal data to the synthetic cloud boundary.
class SyntheticEngine2SkipRequest {
  const SyntheticEngine2SkipRequest({
    required this.sessionId,
    required this.taskId,
    required this.sector,
    required this.layer,
    required this.latencyMs,
    required this.misclicks,
    required this.recoveredErrors,
    required this.interactions,
    required this.supportLevel,
  });

  final String sessionId;
  final String taskId;
  final PlayMechanic sector;
  final int layer;
  final int latencyMs;
  final int misclicks;
  final int recoveredErrors;
  final int interactions;
  final int supportLevel;

  factory SyntheticEngine2SkipRequest.fromInactivity({
    required String sessionId,
    required PuzzleSpec task,
    required ExplorationTelemetry telemetry,
    required int supportLevel,
  }) {
    _validateSyntheticTaskContext(sessionId: sessionId, task: task);
    final safeTelemetry = _SyntheticEngine2Telemetry.fromExploration(
      telemetry,
      supportLevel,
    );
    return SyntheticEngine2SkipRequest(
      sessionId: sessionId,
      taskId: task.id,
      sector: task.mechanics.single,
      layer: task.layer,
      latencyMs: safeTelemetry.latencyMs,
      misclicks: safeTelemetry.misclicks,
      recoveredErrors: safeTelemetry.recoveredErrors,
      interactions: safeTelemetry.interactions,
      supportLevel: safeTelemetry.supportLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': 'skip',
        'session_id': sessionId,
        'task_id': taskId,
        'sector': sector.name,
        'layer': layer,
        'telemetry': {
          'latency_ms': latencyMs,
          'misclicks': misclicks,
          'recovered_errors': recoveredErrors,
          'interactions': interactions,
          'support_level': supportLevel,
        },
      };
}

void _validateSyntheticTaskContext({
  required String sessionId,
  required PuzzleSpec task,
}) {
  if (!_isOpaqueId(sessionId)) {
    throw ArgumentError.value(
      sessionId,
      'sessionId',
      'Must be an issued opaque session ID.',
    );
  }
  if (!_isOpaqueId(task.id)) {
    throw ArgumentError.value(
      task.id,
      'task.id',
      'Must be an issued opaque task ID.',
    );
  }
  if (task.mechanics.length != 1) {
    throw ArgumentError.value(
      task.mechanics,
      'task.mechanics',
      'A synthetic task must have one sector.',
    );
  }
  if (task.layer < 1 || task.layer > 10) {
    throw ArgumentError.value(
      task.layer,
      'task.layer',
      'Must be between 1 and 10.',
    );
  }
}

class _SyntheticEngine2Telemetry {
  const _SyntheticEngine2Telemetry({
    required this.latencyMs,
    required this.misclicks,
    required this.recoveredErrors,
    required this.interactions,
    required this.supportLevel,
  });

  final int latencyMs;
  final int misclicks;
  final int recoveredErrors;
  final int interactions;
  final int supportLevel;

  factory _SyntheticEngine2Telemetry.fromExploration(
    ExplorationTelemetry telemetry,
    int supportLevel,
  ) {
    final interactions = _bounded(
      telemetry.interactions,
      minimum: 1,
      maximum: 100,
    );
    final misclicks = _bounded(
      telemetry.misclicks,
      minimum: 0,
      maximum: interactions < 50 ? interactions : 50,
    );
    return _SyntheticEngine2Telemetry(
      latencyMs: _bounded(
        telemetry.activeLatencyMs,
        minimum: 0,
        maximum: 600000,
      ),
      misclicks: misclicks,
      recoveredErrors: _bounded(
        telemetry.recoveredErrors,
        minimum: 0,
        maximum: misclicks,
      ),
      interactions: interactions,
      supportLevel: _bounded(supportLevel, minimum: 0, maximum: 3),
    );
  }
}

enum SyntheticEngine2Status { inProgress, complete, unavailable }

enum SyntheticEngine2Sandbox { calendar, constellation }

/// Parsed response from `synthetic-engine2-next-task`. `unavailable` is a
/// safe no-network result for local/builder modes, a missing anonymous
/// session, transport errors, or invalid server JSON.
class SyntheticEngine2Result {
  const SyntheticEngine2Result._({
    required this.status,
    this.sessionId,
    this.currentLayer,
    this.activeSectors = const [],
    this.nextTask,
    this.scene,
    this.finalSector,
    this.sandbox,
    this.solved,
    this.skipped = false,
    this.reason,
  });

  final SyntheticEngine2Status status;
  final String? sessionId;
  final int? currentLayer;
  final List<PlayMechanic> activeSectors;
  final PuzzleSpec? nextTask;
  final VisualSceneSpec? scene;
  final PlayMechanic? finalSector;
  final SyntheticEngine2Sandbox? sandbox;
  /// `false` means the server retained the current task after a soft miss;
  /// `true` means it accepted a correct selection and may have issued a new
  /// task. A final inactivity skip is represented separately by [skipped].
  /// It is null for a newly started session.
  final bool? solved;
  final bool skipped;
  final String? reason;

  bool get isInProgress => status == SyntheticEngine2Status.inProgress;
  bool get hasNextTask => nextTask != null;
  bool get isSolved => solved == true;
  bool get isUnsolved => solved == false && !skipped && !hasNextTask;
  bool get isSkipped => skipped;
  bool get isComplete => status == SyntheticEngine2Status.complete;

  factory SyntheticEngine2Result.unavailable(String reason) =>
      SyntheticEngine2Result._(
        status: SyntheticEngine2Status.unavailable,
        reason: reason,
      );

  factory SyntheticEngine2Result.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    if (rawStatus == 'complete') {
      final skipped = json['skipped'] == true;
      final solved = json['solved'] is bool ? json['solved'] as bool : !skipped;
      if (skipped && solved) {
        return SyntheticEngine2Result.unavailable(
          'Synthetic Engine 2 returned an invalid skipped completion.',
        );
      }
      return SyntheticEngine2Result._(
        status: SyntheticEngine2Status.complete,
        sessionId: _opaqueIdOrNull(json['session_id']),
        currentLayer: _layerOrNull(json['current_layer']),
        activeSectors: _mechanicsFromJson(json['active_sectors']),
        finalSector: _mechanicOrNull(json['final_sector']),
        sandbox: _sandboxOrNull(json['sandbox']),
        solved: solved,
        skipped: skipped,
      );
    }
    if (rawStatus != 'in_progress') {
      return SyntheticEngine2Result.unavailable('Unexpected synthetic Engine 2 response.');
    }

    final sessionId = _opaqueIdOrNull(json['session_id']);
    final currentLayer = _layerOrNull(json['current_layer']);
    final rawTask = json['next_task'];
    if (sessionId == null || currentLayer == null) {
      return SyntheticEngine2Result.unavailable('Synthetic Engine 2 returned an incomplete task.');
    }

    // A soft miss deliberately stays on the same word-free surface. The
    // caller retains its current puzzle while the server has recorded the
    // aggregate response; there is no new puzzle to parse here.
    final skipped = json['skipped'] == true;
    if (json['solved'] == false) {
      if (rawTask == null) {
        if (skipped) {
          return SyntheticEngine2Result.unavailable(
            'Synthetic Engine 2 returned an incomplete skipped response.',
          );
        }
        return SyntheticEngine2Result._(
          status: SyntheticEngine2Status.inProgress,
          sessionId: sessionId,
          currentLayer: currentLayer,
          activeSectors: _mechanicsFromJson(json['active_sectors']),
          solved: false,
        );
      }
      if (!skipped) {
        return SyntheticEngine2Result.unavailable(
          'Synthetic Engine 2 returned an invalid soft-miss response.',
        );
      }
    } else if (skipped) {
      return SyntheticEngine2Result.unavailable(
        'Synthetic Engine 2 returned an invalid skipped response.',
      );
    }
    if (rawTask is! Map) {
      return SyntheticEngine2Result.unavailable('Synthetic Engine 2 returned an incomplete task.');
    }

    final taskJson = Map<String, dynamic>.from(rawTask);
    final visual = taskJson['visual'] is Map
        ? SyntheticEngine2VisualSettings.fromJson(
            Map<String, dynamic>.from(taskJson['visual'] as Map),
          )
        : const SyntheticEngine2VisualSettings(
            world: SyntheticDemoWorld.vehicles,
            palette: [FamiliarColor.blue],
            objectStyle: VisualStylePreference.illustratedObjects,
            motionAllowed: true,
            allowDistractors: false,
            interaction: InteractionPreference.tapping,
          );
    final task = _puzzleFromJson(taskJson, visual, currentLayer);
    if (task == null) {
      return SyntheticEngine2Result.unavailable('Synthetic Engine 2 returned an invalid task.');
    }
    final activeSectors = _mechanicsFromJson(json['active_sectors']);
    return SyntheticEngine2Result._(
      status: SyntheticEngine2Status.inProgress,
      sessionId: sessionId,
      currentLayer: currentLayer,
      activeSectors: activeSectors,
      nextTask: task,
      scene: _sceneFromJson(
        taskJson['scene'],
        visual,
        puzzlePlan: taskJson['puzzle_plan'],
        sector: task.mechanics.single,
      ),
      solved: json['solved'] is bool ? json['solved'] as bool : null,
      skipped: skipped,
    );
  }
}

PuzzleSpec? _puzzleFromJson(
  Map<String, dynamic> json,
  SyntheticEngine2VisualSettings visual,
  int currentLayer,
) {
  final id = _opaqueIdOrNull(json['id'] ?? json['task_id']);
  final sector = _mechanicOrNull(json['sector']);
  final options = _optionsFromJson(json['options']);
  final correctOption = _safeOption(json['correct_option']);
  if (id == null || sector == null || options.length < 2 || correctOption == null || !options.contains(correctOption)) {
    return null;
  }
  final requestedItemCount = _bounded(
    (json['item_count'] as num?)?.toInt() ?? options.length,
    minimum: 2,
    maximum: options.length,
  );
  return PuzzleSpec(
    id: id,
    mechanics: [sector],
    layer: _layerOrNull(json['layer']) ?? currentLayer,
    // The generated scene has `show_text: false`; never render model text as
    // an instruction in the child-facing play surface.
    themedPrompt: '',
    options: options,
    correctOption: correctOption,
    itemCount: requestedItemCount,
    showsDistractors: json['shows_distractors'] == true && visual.allowDistractors,
    visualThemeKey: visual.world.name,
    familiarColors: visual.palette,
    visualStylePreference: visual.objectStyle,
    interactionPreference: visual.interaction,
    allowMotion: visual.motionAllowed,
    expectedInteractions: 1,
    speedBudgetMs: 12000,
    difficulty: _bounded((json['difficulty'] as num?)?.toInt() ?? currentLayer, minimum: 1, maximum: 10),
  );
}

VisualSceneSpec? _sceneFromJson(
  Object? raw,
  SyntheticEngine2VisualSettings visual, {
  Object? puzzlePlan,
  PlayMechanic? sector,
}) {
  if (raw is! Map) return null;
  final json = Map<String, dynamic>.from(raw);
  // The model cannot supply a displayed subject; it is always the allowlisted
  // visual world that Flutter originally sent.
  json['subject'] = visual.world.name;
  json['palette'] = visual.palette.isEmpty
      ? const ['blue']
      : visual.palette.map((color) => color.name).toList(growable: false);
  json['object_style'] = visual.objectStyle.name;
  // The deterministic puzzle plan belongs to the task payload, while visual
  // skinning belongs to `scene`. Merge them only for Flutter's local parser;
  // neither field contains free text or a user identity.
  if (puzzlePlan is Map && json['puzzle_plan'] == null) {
    final plan = Map<String, dynamic>.from(puzzlePlan);
    if (sector != null && !plan.containsKey('kind') && !plan.containsKey('sector')) {
      plan['kind'] = sector.name;
    }
    json['puzzle_plan'] = plan;
  }
  return VisualSceneSpec.fromJson(json);
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  return values.firstWhere(
    (value) => value.name == raw,
    orElse: () => fallback,
  );
}

List<FamiliarColor> _uniquePalette(Iterable<FamiliarColor> colors) {
  final palette = colors.map((color) => color.name).toSet().toList()..sort();
  return palette
      .map((name) => _enumByName(FamiliarColor.values, name, FamiliarColor.blue))
      .take(3)
      .toList(growable: false);
}

List<FamiliarColor> _colorsFromJson(Object? raw) {
  if (raw is! List) return const [FamiliarColor.blue];
  final colors = <FamiliarColor>{};
  for (final value in raw) {
    if (value is! String) continue;
    final color = FamiliarColor.values.where((candidate) => candidate.name == value);
    if (color.isNotEmpty) colors.add(color.first);
    if (colors.length == 3) break;
  }
  return colors.isEmpty ? const [FamiliarColor.blue] : colors.toList(growable: false);
}

List<PlayMechanic> _mechanicsFromJson(Object? raw) {
  if (raw is! List) return const [];
  final mechanics = <PlayMechanic>{};
  for (final value in raw) {
    final mechanic = _mechanicOrNull(value);
    if (mechanic != null) mechanics.add(mechanic);
  }
  return mechanics.toList(growable: false);
}

PlayMechanic? _mechanicOrNull(Object? raw) {
  if (raw is! String) return null;
  for (final mechanic in PlayMechanic.values) {
    if (mechanic.name == raw) return mechanic;
  }
  return null;
}

SyntheticEngine2Sandbox? _sandboxOrNull(Object? raw) => switch (raw) {
      'calendar' || 'calendar_sandbox' => SyntheticEngine2Sandbox.calendar,
      'constellation' || 'constellation_sandbox' => SyntheticEngine2Sandbox.constellation,
      _ => null,
    };

List<String> _optionsFromJson(Object? raw) {
  if (raw is! List) return const [];
  final options = <String>[];
  for (final value in raw) {
    final option = _safeOption(value);
    if (option != null && !options.contains(option)) options.add(option);
    if (options.length == 5) break;
  }
  return options;
}

String? _safeOption(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  if (value.isEmpty || value.length > 40 || !RegExp(r'^[A-Za-z0-9 _-]+$').hasMatch(value)) {
    return null;
  }
  return value;
}

bool _isOpaqueId(String value) => RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value);

String? _opaqueIdOrNull(Object? raw) => raw is String && _isOpaqueId(raw) ? raw : null;

int? _layerOrNull(Object? raw) {
  final value = (raw as num?)?.toInt();
  return value != null && value >= 1 && value <= 10 ? value : null;
}

int _bounded(int value, {required int minimum, required int maximum}) =>
    value.clamp(minimum, maximum).toInt();
