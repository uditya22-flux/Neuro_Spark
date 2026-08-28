import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/modality_router.dart';
import '../../strength_funnel/data/sector_template_catalog.dart';
import '../../strength_funnel/models/riasec_sector.dart';
import '../../strength_funnel/models/strength_funnel_finalists.dart';
import '../models/child_play_activity.dart';

/// Builds sensory-safe child play cards from funnel finalists + ISAA routing.
List<ChildPlayActivity> buildChildPlayActivities({
  required StrengthFunnelFinalists finalists,
  required IntakeSessionBundle bundle,
  ModalityRouter router = const ModalityRouter(),
}) {
  final constraints = router.routeFromIsaa(bundle.clinical, bundle.parent);
  final config = bundle.config;
  final useText = constraints.allowText &&
      config.instructionStyle == InstructionStyle.simpleText;

  return finalists.sectorIds.map((sectorId) {
    final sector = sectorById(sectorId);
    final template = sector != null
        ? templateForSector(sector)
        : sectorTemplateById(sectorId);

    final activityLabel = template?.activityLabel ?? sector?.displayName ?? sectorId;
    final prompt = template?.presentMomentPrompt ??
        'Is this kind of play fun for you right now?';
    final pictureDescription = template?.pictureDescription ??
        'Simple drawing of $activityLabel. No faces.';

    var modality = constraints.primaryModality;
    if (modality == 'text' && !useText) modality = 'picture';
    if (modality == 'video' && !constraints.allowVideo) modality = 'picture';
    if (modality == 'haptic' && !constraints.allowHaptics) modality = 'picture';

    return ChildPlayActivity(
      sectorId: sectorId,
      displayName: sector?.displayName ?? template?.displayName ?? sectorId,
      activityLabel: activityLabel,
      presentMomentPrompt: prompt,
      pictureDescription: pictureDescription,
      modality: modality,
      icon: iconForSectorId(sectorId),
    );
  }).toList();
}
