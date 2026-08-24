import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/intake_flow_provider.dart';
import 'intake_shared_widgets.dart';

class ClinicalIntakeStep extends ConsumerWidget {
  const ClinicalIntakeStep({super.key});

  static const _domains = <({String key, String label, String description})>[
    (
      key: 'socialRelationship',
      label: 'Social Relationship',
      description: 'Peer engagement, shared attention, and cooperative play tolerance.',
    ),
    (
      key: 'emotionalResponsiveness',
      label: 'Emotional Responsiveness',
      description: 'Regulation under surprise, frustration, or transitions.',
    ),
    (
      key: 'speechCommunication',
      label: 'Speech & Communication',
      description: 'Verbal load tolerance and preferred communication channels.',
    ),
    (
      key: 'behaviorPatterns',
      label: 'Behavior Patterns',
      description: 'Routine flexibility, impulse pacing, and self-directed exploration.',
    ),
    (
      key: 'sensoryAspects',
      label: 'Sensory Aspects',
      description: 'Auditory, visual, and tactile sensitivity during interactive tasks.',
    ),
    (
      key: 'cognitiveComponent',
      label: 'Cognitive Component',
      description: 'Pattern recognition, sequencing stamina, and problem-solving pace.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinical = ref.watch(intakeFlowProvider).clinical;
    final notifier = ref.read(intakeFlowProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const IntakeStepHeader(
          stepIndex: 0,
          totalSteps: 3,
          title: 'Clinical Baseline (ISAA)',
          subtitle:
              'Rate each domain from 1 (minimal support need) to 5 (elevated support need). These scores set global sensory constraints and starting difficulty.',
        ),
        const SizedBox(height: 20),
        IntakeSectionCard(
          child: Column(
            children: _domains.map((domain) {
              final value = switch (domain.key) {
                'socialRelationship' => clinical.socialRelationship,
                'emotionalResponsiveness' => clinical.emotionalResponsiveness,
                'speechCommunication' => clinical.speechCommunication,
                'behaviorPatterns' => clinical.behaviorPatterns,
                'sensoryAspects' => clinical.sensoryAspects,
                'cognitiveComponent' => clinical.cognitiveComponent,
                _ => clinical.cognitiveComponent,
              };

              return IntakeDomainSlider(
                label: domain.label,
                description: domain.description,
                value: value,
                onChanged: (score) {
                  switch (domain.key) {
                    case 'socialRelationship':
                      notifier.updateClinicalField(socialRelationship: score);
                    case 'emotionalResponsiveness':
                      notifier.updateClinicalField(emotionalResponsiveness: score);
                    case 'speechCommunication':
                      notifier.updateClinicalField(speechCommunication: score);
                    case 'behaviorPatterns':
                      notifier.updateClinicalField(behaviorPatterns: score);
                    case 'sensoryAspects':
                      notifier.updateClinicalField(sensoryAspects: score);
                    case 'cognitiveComponent':
                      notifier.updateClinicalField(cognitiveComponent: score);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
