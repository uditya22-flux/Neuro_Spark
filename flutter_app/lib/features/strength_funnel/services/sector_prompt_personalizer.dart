import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/modality_router.dart';
import '../data/clinical_activity_bank.dart';
import '../data/sector_template_catalog.dart';
import '../models/riasec_sector.dart';

/// Selects and adapts sector prompts from the clinical activity bank using
/// the child's ISAA profile, age, hyperfixation, sensory triggers, and
/// prior engagement scores — not random or one-size-fits-all text.
class PersonalizedSectorPrompt {
  const PersonalizedSectorPrompt({
    required this.presentMomentPrompt,
    required this.activityLabel,
    required this.pictureDescription,
    required this.provenanceFramework,
    required this.personalizationReason,
  });

  final String presentMomentPrompt;
  final String activityLabel;
  final String pictureDescription;
  final String provenanceFramework;
  final String personalizationReason;
}

class SectorPromptPersonalizer {
  const SectorPromptPersonalizer({ModalityRouter? router})
      : _router = router ?? const ModalityRouter();

  final ModalityRouter _router;

  PersonalizedSectorPrompt resolve({
    required RiasecSector sector,
    required IntakeSessionBundle bundle,
    required int layer,
    Map<String, double> priorEngagement = const {},
  }) {
    final variants = variantsForSector(sector.id);
    final parent = bundle.parent;
    final clinical = bundle.clinical;
    final triggers = {...parent.soundTriggers, ...parent.visualTriggers};

    ClinicalActivityVariant? best;
    var bestScore = -999.0;
    String reason = 'Default sector template';

    for (final variant in variants) {
      var score = 0.0;

      if (parent.childAge >= variant.ageMin && parent.childAge <= variant.ageMax) {
        score += 1;
      }

      if (variant.affinity.contains(parent.hyperFixationCategory)) {
        score += 4;
        reason = 'Matched parent-noted hyperfixation theme';
      }

      for (final avoid in variant.avoidSensoryTriggers) {
        if (triggers.any((t) => t.toLowerCase().contains(avoid.toLowerCase()))) {
          score -= 8;
        }
      }

      if (clinical.sensoryAspects >= 4 &&
          variant.avoidSensoryTriggers.contains('loud_sudden_noise')) {
        score += 1;
      }

      if (clinical.speechCommunication >= 4 && variant.activityLabel.length > 28) {
        score -= 1;
      }

      final riasecPrefix = sector.id.split('_').first;
      final relatedHigh = priorEngagement.entries
          .where((e) => e.key.startsWith(riasecPrefix) && e.value >= 0.65)
          .length;
      score += relatedHigh * 1.5;

      if (score > bestScore) {
        bestScore = score;
        best = variant;
      }
    }

    final base = best ??
        _fallbackFromCatalog(sector);

    var prompt = base.presentMomentPrompt;
    if (layer > 1 && layer < 6) {
      final catalog = sectorTemplateById(sector.id);
      if (catalog != null) {
        prompt = catalog.promptForLayer(layer);
      }
    } else if (layer >= 6) {
      final catalog = sectorTemplateById(sector.id);
      if (catalog != null) {
        prompt = catalog.promptForLayer(layer);
      }
    }

    if (layer >= 6) {
      reason = 'Deep-dive layer — present-moment absorption cue';
    }

    _router.assertPresentMomentFraming(prompt);

    return PersonalizedSectorPrompt(
      presentMomentPrompt: prompt,
      activityLabel: base.activityLabel,
      pictureDescription: base.pictureDescription,
      provenanceFramework: base.provenanceFramework,
      personalizationReason: reason,
    );
  }

  ClinicalActivityVariant _fallbackFromCatalog(RiasecSector sector) {
    final sample = templateForSector(sector);
    return ClinicalActivityVariant(
      sectorId: sector.id,
      presentMomentPrompt: sample.presentMomentPrompt,
      activityLabel: sample.activityLabel,
      pictureDescription: sample.pictureDescription,
      provenanceFramework: 'RIASEC-${sector.riasecType}',
    );
  }
}
