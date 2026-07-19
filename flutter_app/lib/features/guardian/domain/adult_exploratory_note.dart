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

  factory AdultExploratoryNote.fromSupabaseRow({
    required String childProfileId,
    required Map<String, Object?> row,
  }) {
    final evidenceRows = (row['evidence'] as List? ?? const <Object?>[]).whereType<Map>().toList(growable: false);
    final evidence = evidenceRows.isEmpty
        ? <ObservedEvidence>[
            const ObservedEvidence(activityId: 'supabase', description: 'Generated from Supabase observations.'),
          ]
        : evidenceRows
            .map(
              (entry) => ObservedEvidence(
                activityId: entry['activityId']?.toString() ?? entry['activity_id']?.toString() ?? 'activity',
                description: entry['description']?.toString() ?? entry['text']?.toString() ?? 'Observation',
              ),
            )
            .toList(growable: false);
    final generatedAt = DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now();
    final track = row['track']?.toString() ?? '';
    final taxonomy = track.contains('constellation')
        ? ClosedTaxonomyField.spatialPatternNoticing
        : ClosedTaxonomyField.chronologicalOrganization;
    return AdultExploratoryNote(
      id: row['id']?.toString() ?? '',
      childProfileId: childProfileId,
      taxonomy: taxonomy,
      evidence: evidence,
      provenance: NoteProvenance(
        promptVersion: row['prompt_version']?.toString() ?? 'supabase-edge',
        modelConfiguration: row['model_config']?.toString() ?? 'supabase-edge',
        generatedAt: generatedAt,
      ),
      disclaimer: row['disclaimer']?.toString() ?? illustrativeOnlyDisclaimer,
      explorationInProgress: row['exploration_in_progress'] as bool? ?? false,
    );
  }
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
