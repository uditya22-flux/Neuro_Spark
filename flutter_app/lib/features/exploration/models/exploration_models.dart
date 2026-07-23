/// The fixed, balanced Layer 1 wide-net catalogue.
///
/// These identifiers are an API contract with the synthetic Engine 2 edge
/// function. They are never rendered as words in the child play surface; the
/// developer-only inspector may use [PlayMechanicX.label].
enum PlayMechanic {
  // Spatial / visual
  mentalRotation,
  visualPatternCompletion,
  pointCloudAnomalyDetection,
  mapRouteNavigation,
  visualSpatialConstruction,

  // Temporal / sequential
  chronologicalSequencing,
  narrativeEventOrdering,
  causeAndEffectChains,
  rhythmicMotorSequencing,
  proceduralSequencing,

  // Numeric / logical
  numberPatternRecognition,
  ruleDiscovery,
  multiAttributeSorting,
  systemizing,
  quantitativeEstimation,

  // Language / meaning, represented wordlessly in the child interface.
  pictureAssociation,
  phonologicalPatternRecognition,
  wordlessInference,
  analogyMapping,
  creativeStorytelling,

  // Memory / attention
  workingMemorySpan,
  visualSceneMemory,
  sustainedAttention,
  auditorySequenceRecall,
  selectiveAttention,

  // Social-emotional / creative
  emotionRecognition,
  perspectiveTaking,
  turnTakingStrategy,
  musicalPatternRecognition,
  visualArtisticComposition,
}

enum PlayMechanicGroup {
  spatialVisual,
  temporalSequential,
  numericLogical,
  languageMeaning,
  memoryAttention,
  socialCreative,
}

extension PlayMechanicX on PlayMechanic {
  String get label => switch (this) {
        PlayMechanic.mentalRotation => '3D mental rotation',
        PlayMechanic.visualPatternCompletion => 'visual pattern completion',
        PlayMechanic.pointCloudAnomalyDetection => 'point-cloud anomaly detection',
        PlayMechanic.mapRouteNavigation => 'map and route navigation',
        PlayMechanic.visualSpatialConstruction => 'visual-spatial construction',
        PlayMechanic.chronologicalSequencing => 'chronological sequencing',
        PlayMechanic.narrativeEventOrdering => 'narrative event ordering',
        PlayMechanic.causeAndEffectChains => 'cause-and-effect chains',
        PlayMechanic.rhythmicMotorSequencing => 'rhythmic motor sequencing',
        PlayMechanic.proceduralSequencing => 'procedural sequencing',
        PlayMechanic.numberPatternRecognition => 'number pattern recognition',
        PlayMechanic.ruleDiscovery => 'rule discovery',
        PlayMechanic.multiAttributeSorting => 'multi-attribute sorting',
        PlayMechanic.systemizing => 'systemizing',
        PlayMechanic.quantitativeEstimation => 'quantitative estimation',
        PlayMechanic.pictureAssociation => 'picture association',
        PlayMechanic.phonologicalPatternRecognition => 'phonological pattern recognition',
        PlayMechanic.wordlessInference => 'wordless inference',
        PlayMechanic.analogyMapping => 'analogy mapping',
        PlayMechanic.creativeStorytelling => 'creative storytelling',
        PlayMechanic.workingMemorySpan => 'working memory span',
        PlayMechanic.visualSceneMemory => 'visual scene memory',
        PlayMechanic.sustainedAttention => 'sustained attention',
        PlayMechanic.auditorySequenceRecall => 'auditory sequence recall',
        PlayMechanic.selectiveAttention => 'selective attention',
        PlayMechanic.emotionRecognition => 'emotion recognition',
        PlayMechanic.perspectiveTaking => 'perspective taking',
        PlayMechanic.turnTakingStrategy => 'turn-taking and strategy',
        PlayMechanic.musicalPatternRecognition => 'musical pattern recognition',
        PlayMechanic.visualArtisticComposition => 'visual-artistic composition',
      };

  PlayMechanicGroup get group => switch (this) {
        PlayMechanic.mentalRotation ||
        PlayMechanic.visualPatternCompletion ||
        PlayMechanic.pointCloudAnomalyDetection ||
        PlayMechanic.mapRouteNavigation ||
        PlayMechanic.visualSpatialConstruction => PlayMechanicGroup.spatialVisual,
        PlayMechanic.chronologicalSequencing ||
        PlayMechanic.narrativeEventOrdering ||
        PlayMechanic.causeAndEffectChains ||
        PlayMechanic.rhythmicMotorSequencing ||
        PlayMechanic.proceduralSequencing => PlayMechanicGroup.temporalSequential,
        PlayMechanic.numberPatternRecognition ||
        PlayMechanic.ruleDiscovery ||
        PlayMechanic.multiAttributeSorting ||
        PlayMechanic.systemizing ||
        PlayMechanic.quantitativeEstimation => PlayMechanicGroup.numericLogical,
        PlayMechanic.pictureAssociation ||
        PlayMechanic.phonologicalPatternRecognition ||
        PlayMechanic.wordlessInference ||
        PlayMechanic.analogyMapping ||
        PlayMechanic.creativeStorytelling => PlayMechanicGroup.languageMeaning,
        PlayMechanic.workingMemorySpan ||
        PlayMechanic.visualSceneMemory ||
        PlayMechanic.sustainedAttention ||
        PlayMechanic.auditorySequenceRecall ||
        PlayMechanic.selectiveAttention => PlayMechanicGroup.memoryAttention,
        PlayMechanic.emotionRecognition ||
        PlayMechanic.perspectiveTaking ||
        PlayMechanic.turnTakingStrategy ||
        PlayMechanic.musicalPatternRecognition ||
        PlayMechanic.visualArtisticComposition => PlayMechanicGroup.socialCreative,
      };
}

extension PlayMechanicGroupX on PlayMechanicGroup {
  String get label => switch (this) {
        PlayMechanicGroup.spatialVisual => 'spatial / visual',
        PlayMechanicGroup.temporalSequential => 'temporal / sequential',
        PlayMechanicGroup.numericLogical => 'numeric / logical',
        PlayMechanicGroup.languageMeaning => 'language / meaning',
        PlayMechanicGroup.memoryAttention => 'memory / attention',
        PlayMechanicGroup.socialCreative => 'social-emotional / creative',
      };
}

enum VisualClutterTolerance { low, medium, high }
enum SandboxPreference { calendar, constellation }
enum AudioFeedbackPreference { mutedHaptics, calm, rhythmic }
enum SensoryTolerance { low, medium, high }
enum InteractionPreference { tapping, swiping, dragging }
enum CommunicationPreference { shortLiteral, visualSteps, symbolsOrAac }
enum KnownTrigger {
  timers,
  loudAudio,
  brightScreens,
  busyScreens,
  complexText,
  unexpectedChanges,
}

/// Guardian-selected visual details used only to make play feel familiar.
/// They are presentation preferences, never an inferred child profile.
enum FamiliarColor { red, orange, yellow, green, blue, purple, pink }
enum VisualStylePreference { simpleShapes, illustratedObjects, realWorldObjects }
enum AvoidableVisualElement { faces, eyes, foodImages, crowdedGroups }

/// A fixed fictional world available only in [syntheticDemoMode]. Its enum
/// name is the complete server allowlist; no guardian or child free text is
/// ever sent to the demo scene generator.
enum SyntheticDemoWorld { vehicles, rail, space, pipes, animals, garden }

extension FamiliarColorX on FamiliarColor {
  String get label => switch (this) {
        FamiliarColor.red => 'Red',
        FamiliarColor.orange => 'Orange',
        FamiliarColor.yellow => 'Yellow',
        FamiliarColor.green => 'Green',
        FamiliarColor.blue => 'Blue',
        FamiliarColor.purple => 'Purple',
        FamiliarColor.pink => 'Pink',
      };
}

extension VisualStylePreferenceX on VisualStylePreference {
  String get label => switch (this) {
        VisualStylePreference.simpleShapes => 'Simple shapes',
        VisualStylePreference.illustratedObjects => 'Illustrated objects',
        VisualStylePreference.realWorldObjects => 'Everyday objects',
      };
}

extension SyntheticDemoWorldX on SyntheticDemoWorld {
  String get label => switch (this) {
        SyntheticDemoWorld.vehicles => 'Vehicles and roads',
        SyntheticDemoWorld.rail => 'Railways and tracks',
        SyntheticDemoWorld.space => 'Planets and stars',
        SyntheticDemoWorld.pipes => 'Pipes and repair shapes',
        SyntheticDemoWorld.animals => 'Animal trails',
        SyntheticDemoWorld.garden => 'Garden paths',
      };
}

extension AvoidableVisualElementX on AvoidableVisualElement {
  String get label => switch (this) {
        AvoidableVisualElement.faces => 'Faces',
        AvoidableVisualElement.eyes => 'Large eyes',
        AvoidableVisualElement.foodImages => 'Food pictures',
        AvoidableVisualElement.crowdedGroups => 'Crowded groups',
      };
}

extension AudioFeedbackPreferenceX on AudioFeedbackPreference {
  String get label => switch (this) {
        AudioFeedbackPreference.mutedHaptics => 'Muted sounds with gentle haptics',
        AudioFeedbackPreference.calm => 'Calm, optional feedback',
        AudioFeedbackPreference.rhythmic => 'Rhythmic, engaging feedback',
      };
}

extension SensoryToleranceX on SensoryTolerance {
  String get label => switch (this) {
        SensoryTolerance.low => 'Low tolerance',
        SensoryTolerance.medium => 'Medium tolerance',
        SensoryTolerance.high => 'High tolerance',
      };
}

extension InteractionPreferenceX on InteractionPreference {
  String get label => switch (this) {
        InteractionPreference.tapping => 'Tapping',
        InteractionPreference.swiping => 'Swiping',
        InteractionPreference.dragging => 'Dragging',
      };
}

extension CommunicationPreferenceX on CommunicationPreference {
  String get label => switch (this) {
        CommunicationPreference.shortLiteral => 'Short, literal instructions',
        CommunicationPreference.visualSteps => 'Visual step-by-step instructions',
        CommunicationPreference.symbolsOrAac => 'Symbols or AAC-friendly prompts',
      };
}

extension KnownTriggerX on KnownTrigger {
  String get label => switch (this) {
        KnownTrigger.timers => 'Visible timers',
        KnownTrigger.loudAudio => 'Loud sounds',
        KnownTrigger.brightScreens => 'Bright screens',
        KnownTrigger.busyScreens => 'Busy screens',
        KnownTrigger.complexText => 'Long or complex text',
        KnownTrigger.unexpectedChanges => 'Unexpected changes',
      };
}

class ChildProfile {
  final String id;
  final String preferredName;
  final int birthYear;

  const ChildProfile({
    required this.id,
    required this.preferredName,
    required this.birthYear,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        preferredName: json['preferred_name'] as String? ??
            json['preferredName'] as String? ??
            'Child',
        birthYear: ((json['birth_year'] ?? json['birthYear']) as num?)?.toInt() ?? 0,
      );
}

class InterfaceConfiguration {
  final double glassBlur;
  final double glassOpacity;
  final double contrastScale;
  final bool allowDistractors;
  final bool allowAudioFeedback;
  final bool preferHaptics;
  final bool allowMotion;
  final bool showTimePressure;
  final InteractionPreference preferredInteraction;
  final CommunicationPreference communicationPreference;

  const InterfaceConfiguration({
    required this.glassBlur,
    required this.glassOpacity,
    required this.contrastScale,
    required this.allowDistractors,
    required this.allowAudioFeedback,
    required this.preferHaptics,
    required this.allowMotion,
    required this.showTimePressure,
    required this.preferredInteraction,
    required this.communicationPreference,
  });
}

/// Guardian-configured presentation preferences. These are not a clinical
/// profile and do not make a claim about a child's abilities.
class IntakeConfiguration {
  final String childId;
  final int audioLimit;
  final VisualClutterTolerance visualClutterTolerance;
  final String hyperFocusTheme;
  final SandboxPreference sandboxPreference;
  final AudioFeedbackPreference audioFeedbackPreference;
  final SensoryTolerance brightnessTolerance;
  final SensoryTolerance motionTolerance;
  final InteractionPreference interactionPreference;
  final bool visualRepetitionHelpful;
  final CommunicationPreference communicationPreference;
  final Set<KnownTrigger> knownTriggers;
  final String favouriteObjects;
  final String familiarScenes;
  final Set<FamiliarColor> familiarColors;
  final VisualStylePreference visualStylePreference;
  final Set<AvoidableVisualElement> avoidableVisualElements;
  final SyntheticDemoWorld syntheticDemoWorld;

  const IntakeConfiguration({
    required this.childId,
    required this.audioLimit,
    required this.visualClutterTolerance,
    required this.hyperFocusTheme,
    this.sandboxPreference = SandboxPreference.calendar,
    this.audioFeedbackPreference = AudioFeedbackPreference.calm,
    this.brightnessTolerance = SensoryTolerance.medium,
    this.motionTolerance = SensoryTolerance.medium,
    this.interactionPreference = InteractionPreference.dragging,
    this.visualRepetitionHelpful = false,
    this.communicationPreference = CommunicationPreference.visualSteps,
    this.knownTriggers = const {},
    this.favouriteObjects = '',
    this.familiarScenes = '',
    this.familiarColors = const {},
    this.visualStylePreference = VisualStylePreference.illustratedObjects,
    this.avoidableVisualElements = const {},
    this.syntheticDemoWorld = SyntheticDemoWorld.vehicles,
  });

  /// Text supplied by the guardian to select familiar visual motifs locally.
  String get visualThemeKey => '$hyperFocusTheme $favouriteObjects $familiarScenes';

  InterfaceConfiguration get interface {
    final visualIsSensitive = visualClutterTolerance == VisualClutterTolerance.low ||
        brightnessTolerance == SensoryTolerance.low ||
        knownTriggers.contains(KnownTrigger.busyScreens) ||
        knownTriggers.contains(KnownTrigger.brightScreens);
    return InterfaceConfiguration(
      glassBlur: visualIsSensitive ? 28 : visualClutterTolerance == VisualClutterTolerance.medium ? 20 : 14,
      glassOpacity: visualIsSensitive ? .22 : visualClutterTolerance == VisualClutterTolerance.medium ? .16 : .12,
      contrastScale: visualIsSensitive ? .70 : visualClutterTolerance == VisualClutterTolerance.medium ? .84 : 1,
      allowDistractors: !visualIsSensitive,
      allowAudioFeedback: audioFeedbackPreference != AudioFeedbackPreference.mutedHaptics &&
          !knownTriggers.contains(KnownTrigger.loudAudio),
      preferHaptics: audioFeedbackPreference == AudioFeedbackPreference.mutedHaptics,
      allowMotion: motionTolerance != SensoryTolerance.low &&
          !knownTriggers.contains(KnownTrigger.unexpectedChanges),
      showTimePressure: !knownTriggers.contains(KnownTrigger.timers),
      preferredInteraction: interactionPreference,
      communicationPreference: communicationPreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': 2,
        'audio_limit': audioLimit,
        'audio_feedback_preference': audioFeedbackPreference.name,
        'visual_clutter_tolerance': visualClutterTolerance.name,
        'brightness_tolerance': brightnessTolerance.name,
        'motion_tolerance': motionTolerance.name,
        'interaction_preference': interactionPreference.name,
        'visual_repetition_helpful': visualRepetitionHelpful,
        'communication_preference': communicationPreference.name,
        'known_triggers': knownTriggers.map((trigger) => trigger.name).toList()..sort(),
        'hyper_focus_theme': hyperFocusTheme,
        'sandbox_preference': sandboxPreference.name,
        'favourite_objects': favouriteObjects,
        'familiar_scenes': familiarScenes,
        'familiar_colors': familiarColors.map((color) => color.name).toList()..sort(),
        'visual_style_preference': visualStylePreference.name,
        'avoidable_visual_elements': avoidableVisualElements.map((item) => item.name).toList()..sort(),
      };

  static IntakeConfiguration? fromJson({
    required String childId,
    required Map<String, dynamic> json,
  }) {
    final theme = json['hyper_focus_theme'];
    if (theme is! String || theme.trim().isEmpty) return null;
    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      return values.firstWhere(
        (value) => value.name == raw,
        orElse: () => fallback,
      );
    }

    final rawTriggers = json['known_triggers'];
    final triggers = rawTriggers is List
        ? rawTriggers
            .whereType<String>()
            .map((name) => KnownTrigger.values.where((value) => value.name == name))
            .where((matches) => matches.isNotEmpty)
            .map((matches) => matches.first)
            .toSet()
        : <KnownTrigger>{};
    Set<T> enumSet<T extends Enum>(List<T> values, Object? raw) => raw is List
        ? raw
            .whereType<String>()
            .map((name) => values.where((value) => value.name == name))
            .where((matches) => matches.isNotEmpty)
            .map((matches) => matches.first)
            .toSet()
        : <T>{};
    return IntakeConfiguration(
      childId: childId,
      audioLimit: ((json['audio_limit'] as num?) ?? 50).round().clamp(0, 100).toInt(),
      visualClutterTolerance: enumValue(
        VisualClutterTolerance.values,
        json['visual_clutter_tolerance'],
        VisualClutterTolerance.medium,
      ),
      hyperFocusTheme: theme.trim(),
      sandboxPreference: enumValue(
        SandboxPreference.values,
        json['sandbox_preference'],
        SandboxPreference.calendar,
      ),
      audioFeedbackPreference: enumValue(
        AudioFeedbackPreference.values,
        json['audio_feedback_preference'],
        AudioFeedbackPreference.calm,
      ),
      brightnessTolerance: enumValue(
        SensoryTolerance.values,
        json['brightness_tolerance'],
        SensoryTolerance.medium,
      ),
      motionTolerance: enumValue(
        SensoryTolerance.values,
        json['motion_tolerance'],
        SensoryTolerance.medium,
      ),
      interactionPreference: enumValue(
        InteractionPreference.values,
        json['interaction_preference'],
        InteractionPreference.dragging,
      ),
      visualRepetitionHelpful: json['visual_repetition_helpful'] == true,
      communicationPreference: enumValue(
        CommunicationPreference.values,
        json['communication_preference'],
        CommunicationPreference.visualSteps,
      ),
      knownTriggers: triggers,
      favouriteObjects: (json['favourite_objects'] as String? ?? '').trim(),
      familiarScenes: (json['familiar_scenes'] as String? ?? '').trim(),
      familiarColors: enumSet(FamiliarColor.values, json['familiar_colors']),
      visualStylePreference: enumValue(
        VisualStylePreference.values,
        json['visual_style_preference'],
        VisualStylePreference.illustratedObjects,
      ),
      avoidableVisualElements: enumSet(
        AvoidableVisualElement.values,
        json['avoidable_visual_elements'],
      ),
    );
  }
}

class PuzzleSpec {
  final String id;
  final List<PlayMechanic> mechanics;
  final int layer;
  final String themedPrompt;
  final List<String> options;
  final String correctOption;
  final int itemCount;
  final bool showsDistractors;
  final String visualThemeKey;
  final List<FamiliarColor> familiarColors;
  final VisualStylePreference visualStylePreference;
  final InteractionPreference interactionPreference;
  final bool allowMotion;
  final bool visualRepetitionHelpful;
  final bool preferHaptics;
  final CommunicationPreference communicationPreference;
  final int expectedInteractions;
  final int speedBudgetMs;
  final int difficulty;

  const PuzzleSpec({
    required this.id,
    required this.mechanics,
    required this.layer,
    required this.themedPrompt,
    required this.options,
    required this.correctOption,
    required this.itemCount,
    this.showsDistractors = false,
    this.visualThemeKey = '',
    this.familiarColors = const [],
    this.visualStylePreference = VisualStylePreference.illustratedObjects,
    this.interactionPreference = InteractionPreference.tapping,
    this.allowMotion = true,
    this.visualRepetitionHelpful = false,
    this.preferHaptics = false,
    this.communicationPreference = CommunicationPreference.visualSteps,
    this.expectedInteractions = 1,
    this.speedBudgetMs = 12000,
    this.difficulty = 1,
  });

  PuzzleSpec copyWith({int? itemCount, bool? showsDistractors}) => PuzzleSpec(
        id: id,
        mechanics: mechanics,
        layer: layer,
        themedPrompt: themedPrompt,
        options: options.take(itemCount ?? this.itemCount).toList(),
        correctOption: correctOption,
        itemCount: itemCount ?? this.itemCount,
        showsDistractors: showsDistractors ?? this.showsDistractors,
        visualThemeKey: visualThemeKey,
        familiarColors: familiarColors,
        visualStylePreference: visualStylePreference,
        interactionPreference: interactionPreference,
        allowMotion: allowMotion,
        visualRepetitionHelpful: visualRepetitionHelpful,
        preferHaptics: preferHaptics,
        communicationPreference: communicationPreference,
        expectedInteractions: expectedInteractions,
        speedBudgetMs: speedBudgetMs,
        difficulty: difficulty,
      );
}

/// An opaque interaction aggregate. It informs immediate presentation support.
/// Normal experiences never turn it into a profile or recommendation. The
/// compile-time builder showcase may use fictional, session-only aggregates to
/// demonstrate its local state machine.
class ExplorationTelemetry {
  final int activeLatencyMs;
  final int misclicks;
  final int recoveredErrors;
  final int interactions;
  final int correctInteractions;

  const ExplorationTelemetry({
    required this.activeLatencyMs,
    required this.misclicks,
    required this.recoveredErrors,
    required this.interactions,
    required this.correctInteractions,
  });
}

/// Associates an aggregate interaction with every mechanic present in the
/// scene. This remains session-only data and is not a child-facing scorecard.
class PlayObservation {
  final List<PlayMechanic> mechanics;
  final ExplorationTelemetry telemetry;
  final int layer;
  final int expectedInteractions;
  final int speedBudgetMs;
  final int supportLevelUsed;

  const PlayObservation({
    required this.mechanics,
    required this.telemetry,
    this.layer = 1,
    this.expectedInteractions = 1,
    this.speedBudgetMs = 12000,
    this.supportLevelUsed = 0,
  });
}
