/// Guardian-only, illustrative observations. This type is never imported by play code.
class AdultExploratoryNote {
  const AdultExploratoryNote({
    required this.id,
    required this.childProfileId,
    required this.taxonomy,
    required this.evidence,
    required this.provenance,
    required this.disclaimer,
    required this.explorationInProgress,
  });

  final String id;
  final String childProfileId;
  final ClosedTaxonomyField taxonomy;
  final List<ObservedEvidence> evidence;
  final NoteProvenance provenance;
  final String disclaimer;
  final bool explorationInProgress;
}

enum ClosedTaxonomyField { chronologicalOrganization, spatialPatternNoticing }

class ObservedEvidence {
  const ObservedEvidence({required this.activityId, required this.description});

  final String activityId;
  final String description;
}

class NoteProvenance {
  const NoteProvenance({
    required this.promptVersion,
    required this.modelConfiguration,
    required this.generatedAt,
  });

  final String promptVersion;
  final String modelConfiguration;
  final DateTime generatedAt;
}

const String illustrativeOnlyDisclaimer =
    'Illustrative only. This is a non-clinical observation from play activities.';
