import '../models/exploration_models.dart';
import '../models/visual_scene_spec.dart';

/// Draft-only metadata for the one baseline item assigned to every Layer 1
/// sector. This is not presented to the child: the renderer uses the mechanic
/// and visual rule to make the word-free scene.
class Layer1ItemDraft {
  const Layer1ItemDraft({
    required this.taskId,
    required this.verticalId,
    required this.category,
    required this.format,
    required this.taskTitle,
    required this.taskDescriptionNonVerbal,
    required this.visualSpec,
    required this.interaction,
    required this.targetMetrics,
  });

  final String taskId;
  final String verticalId;
  final String category;
  final String format;
  final String taskTitle;
  final String taskDescriptionNonVerbal;
  final String visualSpec;
  final String interaction;
  final String targetMetrics;

  static const int layerNumber = 1;
  static const String sourceType = 'curated_draft';
  static const bool themeSkinCompatible = true;
  static const String reviewStatus = 'draft_pending_review';
}

/// The authoritative, balanced Layer 1 draft catalog: exactly 30 items, one
/// per sector. It remains a draft catalog until an appropriate review process
/// approves any real-world use.
class Layer1Catalog {
  const Layer1Catalog._();

  static List<Layer1ItemDraft> get all => PlayMechanic.values
      .map(_draftFor)
      .toList(growable: false);

  static Layer1ItemDraft _draftFor(PlayMechanic mechanic) {
    final plan = VisualPuzzlePlan.localForMechanic(mechanic);
    return Layer1ItemDraft(
      taskId: 'l1_${mechanic.name}',
      verticalId: mechanic.name,
      category: mechanic.group.label,
      format: _formatFor(mechanic),
      taskTitle: _titleFor(mechanic),
      taskDescriptionNonVerbal:
          'A word-free ${_titleFor(mechanic).toLowerCase()} scene is shown.',
      visualSpec: '${plan.stimulus}; rule: ${plan.rule}.',
      interaction: _interactionFor(mechanic),
      targetMetrics: 'accuracy, latency, recovery, engagement',
    );
  }

  static String _formatFor(PlayMechanic mechanic) => switch (mechanic) {
        PlayMechanic.mentalRotation ||
        PlayMechanic.pointCloudAnomalyDetection ||
        PlayMechanic.mapRouteNavigation ||
        PlayMechanic.causeAndEffectChains ||
        PlayMechanic.rhythmicMotorSequencing ||
        PlayMechanic.multiAttributeSorting ||
        PlayMechanic.quantitativeEstimation ||
        PlayMechanic.workingMemorySpan ||
        PlayMechanic.sustainedAttention ||
        PlayMechanic.perspectiveTaking ||
        PlayMechanic.musicalPatternRecognition => 'animation',
        PlayMechanic.phonologicalPatternRecognition => 'audio+picture',
        PlayMechanic.auditorySequenceRecall => 'audio',
        PlayMechanic.turnTakingStrategy ||
        PlayMechanic.visualArtisticComposition => 'interactive',
        _ => 'picture',
      };

  static String _interactionFor(PlayMechanic mechanic) => switch (mechanic) {
        PlayMechanic.mapRouteNavigation ||
        PlayMechanic.visualSpatialConstruction ||
        PlayMechanic.chronologicalSequencing ||
        PlayMechanic.narrativeEventOrdering ||
        PlayMechanic.proceduralSequencing ||
        PlayMechanic.ruleDiscovery ||
        PlayMechanic.multiAttributeSorting ||
        PlayMechanic.creativeStorytelling ||
        PlayMechanic.visualArtisticComposition => 'drag',
        PlayMechanic.mentalRotation => 'rotate',
        _ => 'tap',
      };

  static String _titleFor(PlayMechanic mechanic) => switch (mechanic) {
        PlayMechanic.mentalRotation => 'Turn and match',
        PlayMechanic.visualPatternCompletion => 'Finish the pattern',
        PlayMechanic.pointCloudAnomalyDetection => 'Find the odd point',
        PlayMechanic.mapRouteNavigation => 'Guide the route',
        PlayMechanic.visualSpatialConstruction => 'Build the picture',
        PlayMechanic.chronologicalSequencing => 'Put the cycle in order',
        PlayMechanic.narrativeEventOrdering => 'Put the story in order',
        PlayMechanic.causeAndEffectChains => 'Find what happens next',
        PlayMechanic.rhythmicMotorSequencing => 'Repeat the rhythm',
        PlayMechanic.proceduralSequencing => 'Put the steps in order',
        PlayMechanic.numberPatternRecognition => 'Finish the dot pattern',
        PlayMechanic.ruleDiscovery => 'Find the sorting rule',
        PlayMechanic.multiAttributeSorting => 'Sort the pieces',
        PlayMechanic.systemizing => 'Find what belongs',
        PlayMechanic.quantitativeEstimation => 'Choose the larger group',
        PlayMechanic.pictureAssociation => 'Match the pictures',
        PlayMechanic.phonologicalPatternRecognition => 'Match the sounds',
        PlayMechanic.wordlessInference => 'Choose the story next',
        PlayMechanic.analogyMapping => 'Complete the picture pair',
        PlayMechanic.creativeStorytelling => 'Make a picture story',
        PlayMechanic.workingMemorySpan => 'Remember the lights',
        PlayMechanic.visualSceneMemory => 'Find what changed',
        PlayMechanic.sustainedAttention => 'Watch for the target',
        PlayMechanic.auditorySequenceRecall => 'Repeat the tones',
        PlayMechanic.selectiveAttention => 'Find the target',
        PlayMechanic.emotionRecognition => 'Match the feeling picture',
        PlayMechanic.perspectiveTaking => 'Choose what comes next',
        PlayMechanic.turnTakingStrategy => 'Take the next turn',
        PlayMechanic.musicalPatternRecognition => 'Match the music pattern',
        PlayMechanic.visualArtisticComposition => 'Complete the design',
      };
}

/// Chooses the baseline sample without ranking or interpreting it. The caller
/// supplies prior session evidence; this utility only applies the documented
/// first-session/re-baseline sampling policy.
class Layer1DomainSampler {
  const Layer1DomainSampler._();

  static List<PlayMechanic> firstSession() =>
      List<PlayMechanic>.of(PlayMechanic.values);

  static List<PlayMechanic> rebaseline({
    required Iterable<PlayMechanic> previousRanked,
    required Iterable<PlayMechanic> previouslyTested,
  }) {
    final strongest = previousRanked.take(8).toList(growable: false);
    final strongestSet = strongest.toSet();
    final tested = previouslyTested.toSet();
    final fresh = PlayMechanic.values
        .where((mechanic) => !tested.contains(mechanic))
        .where((mechanic) => !strongestSet.contains(mechanic))
        .take(7);
    return [...strongest, ...fresh];
  }
}
