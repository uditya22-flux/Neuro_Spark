import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/modality_router.dart';
import '../../strength_funnel/models/riasec_sector.dart';
import '../../strength_funnel/models/strength_funnel_finalists.dart';
import '../../strength_funnel/services/sector_prompt_personalizer.dart';
import '../models/child_play_activity.dart';

/// Builds sensory-safe child play cards from funnel finalists + ISAA routing.
List<ChildPlayActivity> buildChildPlayActivities({
  required StrengthFunnelFinalists finalists,
  required IntakeSessionBundle bundle,
  ModalityRouter router = const ModalityRouter(),
  SectorPromptPersonalizer personalizer = const SectorPromptPersonalizer(),
}) {
  final constraints = router.routeFromIsaa(bundle.clinical, bundle.parent);
  final config = bundle.config;
  final useText = constraints.allowText &&
      config.instructionStyle == InstructionStyle.simpleText;

  return finalists.sectorIds.map((sectorId) {
    final sector = sectorById(sectorId);
    if (sector == null) {
      return ChildPlayActivity(
        sectorId: sectorId,
        displayName: sectorId,
        activityLabel: sectorId,
        presentMomentPrompt: 'Is this kind of play fun for you right now?',
        pictureDescription: 'Simple drawing. No faces.',
        modality: 'picture',
        icon: iconForSectorId(sectorId),
      );
    }

    final personalized = personalizer.resolve(
      sector: sector,
      bundle: bundle,
      layer: 10,
      priorEngagement: finalists.layerScores,
    );

    final activityLabel = personalized.activityLabel;
    final prompt = personalized.presentMomentPrompt;
    final pictureDescription = personalized.pictureDescription;

    var modality = constraints.primaryModality;
    if (modality == 'text' && !useText) modality = 'picture';
    if (modality == 'video' && !constraints.allowVideo) modality = 'picture';
    if (modality == 'haptic' && !constraints.allowHaptics) modality = 'picture';

    return ChildPlayActivity(
      sectorId: sectorId,
      displayName: sector.displayName,
      activityLabel: activityLabel,
      presentMomentPrompt: prompt,
      pictureDescription: pictureDescription,
      modality: modality,
      icon: iconForSectorId(sectorId),
    );
  }).toList();
}
