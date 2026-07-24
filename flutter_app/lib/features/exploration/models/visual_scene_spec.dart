import 'exploration_models.dart';

/// A compact, allowlisted visual plan for one word-free play scene.
///
/// This is deliberately presentation data only: it contains no prompt text,
/// names, images, or answers. The issued task remains the source of truth for
/// the correct option; [resolveFor] never lets an incoming plan change it.
enum VisualPuzzleKind {
  match,
  sequence,
  route,
  rotate,
  distance,
  pattern,
  sort,
  quantity,
  shape,
  search,
  memory,
  repair,
  precision,
  rhythm,
  switching,
}

/// The complete, fixed rule vocabulary accepted from the synthetic Edge
/// Function. Values are never displayed as text in the child interface.
enum VisualPuzzleRule {
  // Spatial / visual
  matchMentalRotation,
  completeVisualPattern,
  detectPointCloudAnomaly,
  navigateMapRoute,
  reconstructSpatialTarget,

  // Temporal / sequential
  orderPictureCycle,
  orderStoryPanels,
  chooseEffect,
  repeatRhythm,
  orderProcedureIcons,

  // Numeric / logical
  completeQuantityPattern,
  discoverVisualRule,
  sortMultipleAttributes,
  findSharedProperty,
  chooseLargerDotCloud,

  // Language / meaning, still rendered without written language.
  matchPictureAssociation,
  matchPhonologicalPattern,
  chooseStoryNext,
  completePictureAnalogy,
  arrangeStoryPanels,

  // Memory / attention
  replayCellSequence,
  findSceneChange,
  identifyTargetStream,
  replayToneSequence,
  findSelectiveTarget,

  // Social-emotional / creative
  matchEmotionIcon,
  choosePerspectiveOutcome,
  chooseTurnStrategy,
  matchMelodyPattern,
  completeVisualComposition,

  // Legacy accepted values keep already-issued synthetic sessions drawable
  // while the Edge Function rolls to the fixed taxonomy above.
  ascending,
  matchDuration,
  nextEvent,
  followRoute,
  matchRotation,
  matchDistance,
  repeatNext,
  completePattern,
  matchGroup,
  sortAttribute,
  matchQuantity,
  completePairs,
  matchShape,
  findHidden,
  findTarget,
  findChange,
  recallToken,
  followPath,
  triggerEffect,
  selectTool,
  dropTarget,
  tapTarget,
  pairSides,
  waitForTurn,
  repeatBeat,
  matchSignal,
  viewFromSide,
  switchRule,
  completeBuild,
  repairMismatch,
}

VisualPuzzleRule? visualPuzzleRuleFromWire(Object? raw) {
  if (raw is! String) return null;
  for (final rule in VisualPuzzleRule.values) {
    if (rule.name == raw) return rule;
  }
  return null;
}

extension VisualPuzzleKindX on VisualPuzzleKind {
  String get wireName => switch (this) {
        VisualPuzzleKind.match => 'match',
        VisualPuzzleKind.sequence => 'sequence',
        VisualPuzzleKind.route => 'route',
        VisualPuzzleKind.rotate => 'rotate',
        VisualPuzzleKind.distance => 'distance',
        VisualPuzzleKind.pattern => 'pattern',
        VisualPuzzleKind.sort => 'sort',
        VisualPuzzleKind.quantity => 'quantity',
        VisualPuzzleKind.shape => 'shape',
        VisualPuzzleKind.search => 'search',
        VisualPuzzleKind.memory => 'memory',
        VisualPuzzleKind.repair => 'repair',
        VisualPuzzleKind.precision => 'precision',
        VisualPuzzleKind.rhythm => 'rhythm',
        VisualPuzzleKind.switching => 'switch',
      };
}

/// Parses only the small visual vocabulary that Flutter knows how to render.
/// Aliases make this compatible with current `scene_type` and legacy values
/// from the Edge Function.
VisualPuzzleKind? visualPuzzleKindFromWire(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim().toLowerCase().replaceAll('_', '').replaceAll('-', '');
  return <String, VisualPuzzleKind>{
    'match': VisualPuzzleKind.match,
    'matching': VisualPuzzleKind.match,
    'sequence': VisualPuzzleKind.sequence,
    'ordering': VisualPuzzleKind.sequence,
    'route': VisualPuzzleKind.route,
    'connect': VisualPuzzleKind.route,
    'rotation': VisualPuzzleKind.rotate,
    'rotate': VisualPuzzleKind.rotate,
    'distance': VisualPuzzleKind.distance,
    'pattern': VisualPuzzleKind.pattern,
    'sort': VisualPuzzleKind.sort,
    'quantity': VisualPuzzleKind.quantity,
    'shape': VisualPuzzleKind.shape,
    'search': VisualPuzzleKind.search,
    'memory': VisualPuzzleKind.memory,
    'repair': VisualPuzzleKind.repair,
    'precision': VisualPuzzleKind.precision,
    'rhythm': VisualPuzzleKind.rhythm,
    'switch': VisualPuzzleKind.switching,
    'switching': VisualPuzzleKind.switching,
  }[value];
}

/// The deterministic fallback keeps legacy tasks sector-distinct even before
/// an Edge Function supplies an explicit [VisualPuzzlePlan].
VisualPuzzleKind visualPuzzleKindForMechanic(PlayMechanic mechanic) {
  switch (mechanic) {
    case PlayMechanic.mentalRotation:
      return VisualPuzzleKind.rotate;
    case PlayMechanic.visualPatternCompletion:
    case PlayMechanic.numberPatternRecognition:
      return VisualPuzzleKind.pattern;
    case PlayMechanic.pointCloudAnomalyDetection:
    case PlayMechanic.sustainedAttention:
    case PlayMechanic.selectiveAttention:
      return VisualPuzzleKind.search;
    case PlayMechanic.mapRouteNavigation:
    case PlayMechanic.visualSpatialConstruction:
    case PlayMechanic.creativeStorytelling:
    case PlayMechanic.visualArtisticComposition:
      return VisualPuzzleKind.route;
    case PlayMechanic.chronologicalSequencing:
    case PlayMechanic.narrativeEventOrdering:
    case PlayMechanic.proceduralSequencing:
    case PlayMechanic.wordlessInference:
    case PlayMechanic.perspectiveTaking:
      return VisualPuzzleKind.sequence;
    case PlayMechanic.causeAndEffectChains:
      return VisualPuzzleKind.repair;
    case PlayMechanic.rhythmicMotorSequencing:
    case PlayMechanic.phonologicalPatternRecognition:
    case PlayMechanic.auditorySequenceRecall:
    case PlayMechanic.turnTakingStrategy:
    case PlayMechanic.musicalPatternRecognition:
      return VisualPuzzleKind.rhythm;
    case PlayMechanic.ruleDiscovery:
    case PlayMechanic.multiAttributeSorting:
    case PlayMechanic.systemizing:
      return VisualPuzzleKind.sort;
    case PlayMechanic.quantitativeEstimation:
      return VisualPuzzleKind.quantity;
    case PlayMechanic.pictureAssociation:
    case PlayMechanic.analogyMapping:
    case PlayMechanic.emotionRecognition:
      return VisualPuzzleKind.match;
    case PlayMechanic.workingMemorySpan:
    case PlayMechanic.visualSceneMemory:
      return VisualPuzzleKind.memory;
  }
}

/// Maps the fixed Layer 1 taxonomy to the exact word-free visual treatment
/// Flutter draws. Keeping this mapping local means an offline builder session
/// is never reduced to a generic colour-match prompt while a cloud scene is
/// loading or unavailable.
VisualPuzzleRule visualPuzzleRuleForMechanic(PlayMechanic mechanic) => switch (mechanic) {
      // Spatial / visual
      PlayMechanic.mentalRotation => VisualPuzzleRule.matchMentalRotation,
      PlayMechanic.visualPatternCompletion => VisualPuzzleRule.completeVisualPattern,
      PlayMechanic.pointCloudAnomalyDetection => VisualPuzzleRule.detectPointCloudAnomaly,
      PlayMechanic.mapRouteNavigation => VisualPuzzleRule.navigateMapRoute,
      PlayMechanic.visualSpatialConstruction => VisualPuzzleRule.reconstructSpatialTarget,

      // Temporal / sequential
      PlayMechanic.chronologicalSequencing => VisualPuzzleRule.orderPictureCycle,
      PlayMechanic.narrativeEventOrdering => VisualPuzzleRule.orderStoryPanels,
      PlayMechanic.causeAndEffectChains => VisualPuzzleRule.chooseEffect,
      PlayMechanic.rhythmicMotorSequencing => VisualPuzzleRule.repeatRhythm,
      PlayMechanic.proceduralSequencing => VisualPuzzleRule.orderProcedureIcons,

      // Numeric / logical
      PlayMechanic.numberPatternRecognition => VisualPuzzleRule.completeQuantityPattern,
      PlayMechanic.ruleDiscovery => VisualPuzzleRule.discoverVisualRule,
      PlayMechanic.multiAttributeSorting => VisualPuzzleRule.sortMultipleAttributes,
      PlayMechanic.systemizing => VisualPuzzleRule.findSharedProperty,
      PlayMechanic.quantitativeEstimation => VisualPuzzleRule.chooseLargerDotCloud,

      // Wordless language / meaning proxies
      PlayMechanic.pictureAssociation => VisualPuzzleRule.matchPictureAssociation,
      PlayMechanic.phonologicalPatternRecognition => VisualPuzzleRule.matchPhonologicalPattern,
      PlayMechanic.wordlessInference => VisualPuzzleRule.chooseStoryNext,
      PlayMechanic.analogyMapping => VisualPuzzleRule.completePictureAnalogy,
      PlayMechanic.creativeStorytelling => VisualPuzzleRule.arrangeStoryPanels,

      // Memory / attention
      PlayMechanic.workingMemorySpan => VisualPuzzleRule.replayCellSequence,
      PlayMechanic.visualSceneMemory => VisualPuzzleRule.findSceneChange,
      PlayMechanic.sustainedAttention => VisualPuzzleRule.identifyTargetStream,
      PlayMechanic.auditorySequenceRecall => VisualPuzzleRule.replayToneSequence,
      PlayMechanic.selectiveAttention => VisualPuzzleRule.findSelectiveTarget,

      // Social-emotional / creative play
      PlayMechanic.emotionRecognition => VisualPuzzleRule.matchEmotionIcon,
      PlayMechanic.perspectiveTaking => VisualPuzzleRule.choosePerspectiveOutcome,
      PlayMechanic.turnTakingStrategy => VisualPuzzleRule.chooseTurnStrategy,
      PlayMechanic.musicalPatternRecognition => VisualPuzzleRule.matchMelodyPattern,
      PlayMechanic.visualArtisticComposition => VisualPuzzleRule.completeVisualComposition,
    };

/// A bounded, deterministic visual trace for a local Layer 1 plan. These are
/// not answers or scores: they only make each mechanic visibly different when
/// the synthetic scene service is deliberately disabled for a builder demo.
List<int> visualStimulusForMechanic(PlayMechanic mechanic) {
  final seed = mechanic.index + 1;
  return List<int>.unmodifiable(
    List<int>.generate(4 + (seed % 2), (index) => (seed * 3 + index * 5) % 16),
  );
}

class VisualPuzzlePlan {
  const VisualPuzzlePlan({
    required this.kind,
    required this.variant,
    this.version = 1,
    this.requestedSector,
    this.targetIndex,
    this.stimulus = const [],
    this.optionValues = const [],
    this.answerValue,
    this.rule,
  });

  /// The type of non-verbal interaction Flutter should draw.
  final VisualPuzzleKind kind;

  /// Version 1 is the only currently supported plan contract.
  final int version;

  /// A bounded visual seed. It varies arrangements without becoming free text
  /// or an arbitrary server-provided drawing instruction.
  final int variant;

  /// Parsed for compatibility and validation. The issued [PuzzleSpec]
  /// mechanic always wins when a plan is resolved for rendering.
  final PlayMechanic? requestedSector;

  /// Optional server hint. It must agree with the issued correct option before
  /// it is used; otherwise Flutter safely uses the issued option index.
  final int? targetIndex;

  /// A bounded, non-text pattern displayed in the visual stage.
  final List<int> stimulus;

  /// Bounded visual values for the option cards, in the exact order of the
  /// opaque issued option IDs.
  final List<int> optionValues;

  /// The bounded visual value rendered in the target stage. It is trusted only
  /// after [resolveFor] confirms it agrees with the issued correct option.
  final int? answerValue;

  /// An allowlisted backend rule. Flutter never renders its name as text; it
  /// only uses the enum to choose a fixed visual treatment.
  final VisualPuzzleRule? rule;

  /// Produces a fixed, safe visual plan for a local/builder session. The
  /// opaque issued task remains authoritative for which option is correct;
  /// [resolveFor] binds that answer after this plan is created.
  factory VisualPuzzlePlan.localForMechanic(PlayMechanic mechanic) => VisualPuzzlePlan(
        kind: visualPuzzleKindForMechanic(mechanic),
        variant: mechanic.index % 8,
        requestedSector: mechanic,
        stimulus: visualStimulusForMechanic(mechanic),
        rule: visualPuzzleRuleForMechanic(mechanic),
      );

  factory VisualPuzzlePlan.fromJson(Map<String, dynamic> json) {
    final rawOptionValues =
        json['option_values'] ?? json['choice_variants'] ?? json['variants'];
    final parsedVersion = _boundedPlanInt(json['version'], minimum: 1, maximum: 1);
    final compatibleVersion = !json.containsKey('version') || parsedVersion == 1;
    return VisualPuzzlePlan(
      // The cloud contract uses `kind` for the 30-sector enum and
      // `scene_type` for Flutter's renderer type. Older payloads may still
      // have their renderer type in `kind`, so retain that fallback.
      kind: compatibleVersion
          ? visualPuzzleKindFromWire(json['scene_type'] ?? json['kind']) ??
              VisualPuzzleKind.match
          : VisualPuzzleKind.match,
      variant: compatibleVersion
          ? _boundedPlanInt(json['variant'], minimum: 0, maximum: 7) ?? 0
          : 0,
      version: parsedVersion ?? 1,
      requestedSector: compatibleVersion
          ? _playMechanicFromWire(json['sector']) ?? _playMechanicFromWire(json['kind'])
          : null,
      targetIndex: _boundedPlanInt(
        json['target_index'] ?? json['targetIndex'] ?? json['target'],
        minimum: 0,
        maximum: 4,
      ),
      stimulus: compatibleVersion
          ? _boundedPlanList(json['stimulus'], minimumLength: 1, maximumLength: 6)
          : const [],
      optionValues: _boundedPlanList(
        compatibleVersion ? rawOptionValues : null,
        minimumLength: 2,
        maximumLength: 5,
        requireUnique: true,
      ),
      answerValue: compatibleVersion
          ? _boundedPlanInt(json['answer_value'], minimum: 0, maximum: 15)
          : null,
      rule: compatibleVersion ? visualPuzzleRuleFromWire(json['rule']) : null,
    );
  }

  /// Resolves a plan against the task that the server actually issued.
  /// The target always maps to [correctIndex], even if an invalid or stale
  /// `target_index` arrived with the presentation data.
  VisualPuzzlePlan resolveFor({
    required PlayMechanic sector,
    required int optionCount,
    required int correctIndex,
  }) {
    final safeCount = optionCount.clamp(2, 5).toInt();
    final safeCorrect = correctIndex.clamp(0, safeCount - 1).toInt();
    final hasIssuedPlan =
        (requestedSector == null || requestedSector == sector) &&
            targetIndex == safeCorrect &&
            answerValue != null &&
            optionValues.length == safeCount &&
            optionValues.toSet().length == safeCount &&
            optionValues[safeCorrect] == answerValue;
    final targetVariant = hasIssuedPlan
        ? answerValue!
        : (variant.clamp(0, 7).toInt() * 2) % 16;
    final resolved = <int>[];
    final used = <int>{targetVariant};
    for (var index = 0; index < safeCount; index++) {
      if (index == safeCorrect) {
        resolved.add(targetVariant);
        continue;
      }
      var candidate = hasIssuedPlan
          ? optionValues[index]
          : (targetVariant + index + 1) % 16;
      while (used.contains(candidate)) {
        candidate = (candidate + 1) % 16;
      }
      used.add(candidate);
      resolved.add(candidate);
    }
    return VisualPuzzlePlan(
      kind: kind == VisualPuzzleKind.match
          ? visualPuzzleKindForMechanic(sector)
          : kind,
      variant: targetVariant,
      version: version,
      requestedSector: sector,
      // Deliberately write the verified target, not an incoming hint.
      targetIndex: safeCorrect,
      stimulus: stimulus,
      optionValues: resolved,
      answerValue: targetVariant,
      rule: rule,
    );
  }

  int get targetVariant => variant;

  int choiceVariantAt(int index) {
    if (optionValues.isEmpty) return (variant + index + 1) % 16;
    return optionValues[index.clamp(0, optionValues.length - 1).toInt()];
  }
}

PlayMechanic? _playMechanicFromWire(Object? raw) {
  if (raw is! String) return null;
  for (final mechanic in PlayMechanic.values) {
    if (mechanic.name == raw) return mechanic;
  }
  return null;
}

int? _boundedPlanInt(Object? raw, {required int minimum, required int maximum}) {
  if (raw is! num || !raw.isFinite || raw != raw.toInt()) return null;
  final value = raw.toInt();
  return value >= minimum && value <= maximum ? value : null;
}

List<int> _boundedPlanList(
  Object? raw, {
  required int minimumLength,
  required int maximumLength,
  bool requireUnique = false,
}) {
  if (raw is! List || raw.length < minimumLength || raw.length > maximumLength) {
    return const [];
  }
  final values = <int>[];
  for (final entry in raw) {
    final value = _boundedPlanInt(entry, minimum: 0, maximum: 15);
    if (value == null) return const [];
    values.add(value);
  }
  return requireUnique && values.toSet().length != values.length
      ? const []
      : List<int>.unmodifiable(values);
}

class VisualSceneSpec {
  const VisualSceneSpec({
    required this.sceneType,
    required this.subject,
    required this.palette,
    required this.objectStyle,
    required this.layout,
    required this.itemCount,
    required this.onTapAnimation,
    required this.successAnimation,
    this.puzzlePlan,
  });

  final String sceneType;
  final String subject;
  final List<String> palette;
  final String objectStyle;
  final String layout;
  final int itemCount;
  final String onTapAnimation;
  final String successAnimation;
  final VisualPuzzlePlan? puzzlePlan;

  /// A local, deterministic scene for builder/offline sessions. It uses the
  /// same bounded plan contract as the cloud response, so the renderer sees
  /// the exact sector rule even when no network request is made.
  factory VisualSceneSpec.localForMechanic({
    required PlayMechanic mechanic,
    required int itemCount,
    required String subject,
    required List<String> palette,
    required String objectStyle,
    required bool motionAllowed,
  }) {
    final kind = visualPuzzleKindForMechanic(mechanic);
    return VisualSceneSpec(
      sceneType: kind.wireName,
      subject: subject,
      palette: palette.isEmpty ? const ['blue', 'green', 'yellow'] : palette.take(3).toList(growable: false),
      objectStyle: objectStyle,
      layout: switch (kind) {
        VisualPuzzleKind.route => 'path',
        VisualPuzzleKind.sequence => 'leftToRight',
        _ => 'grid',
      },
      itemCount: itemCount.clamp(3, 5).toInt(),
      onTapAnimation: motionAllowed ? 'snap' : 'none',
      successAnimation: motionAllowed ? 'gentlePulse' : 'settle',
      puzzlePlan: VisualPuzzlePlan.localForMechanic(mechanic),
    );
  }

  factory VisualSceneSpec.fromJson(Map<String, dynamic> json) {
    final animation = json['animation'] as Map<String, dynamic>? ?? const {};
    final rawPlan = json['puzzle_plan'] ?? json['puzzlePlan'];
    return VisualSceneSpec(
      sceneType: json['scene_type'] as String? ?? 'match',
      subject: json['subject'] as String? ?? 'play_shape',
      palette: (json['palette'] as List? ?? const [])
          .whereType<String>()
          .take(3)
          .toList(growable: false),
      objectStyle: json['object_style'] as String? ?? 'illustratedObjects',
      layout: json['layout'] as String? ?? 'grid',
      itemCount: ((json['item_count'] as num?)?.toInt() ?? 5).clamp(3, 5).toInt(),
      onTapAnimation: animation['on_tap'] as String? ?? 'snap',
      successAnimation: animation['success'] as String? ?? 'gentlePulse',
      puzzlePlan: rawPlan is Map
          ? VisualPuzzlePlan.fromJson(Map<String, dynamic>.from(rawPlan))
          : null,
    );
  }
}
