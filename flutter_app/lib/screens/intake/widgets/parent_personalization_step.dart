import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/intake_models.dart';
import '../../../providers/intake_flow_provider.dart';
import 'intake_shared_widgets.dart';

class ParentPersonalizationStep extends ConsumerStatefulWidget {
  const ParentPersonalizationStep({super.key});

  @override
  ConsumerState<ParentPersonalizationStep> createState() => _ParentPersonalizationStepState();
}

class _ParentPersonalizationStepState extends ConsumerState<ParentPersonalizationStep> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final name = ref.read(intakeFlowProvider).parent.childName;
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateParent(ParentQualitativeProfile parent) {
    ref.read(intakeFlowProvider.notifier).updateParent(parent);
  }

  void _toggleTrigger({
    required List<String> current,
    required String option,
    required bool isSelected,
    required void Function(List<String> updated) apply,
  }) {
    final updated = List<String>.from(current);
    if (isSelected) {
      if (!updated.contains(option)) updated.add(option);
    } else {
      updated.remove(option);
    }
    apply(updated);
  }

  @override
  Widget build(BuildContext context) {
    final parent = ref.watch(intakeFlowProvider).parent;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const IntakeStepHeader(
          stepIndex: 1,
          totalSteps: 3,
          title: 'Parent Personalization',
          subtitle:
              'Anchor the play world to your child\'s interests and blacklist exact sensory triggers that must never appear.',
        ),
        const SizedBox(height: 20),
        IntakeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Child\'s preferred name',
                  hintText: 'How should we greet them in the app?',
                  border: OutlineInputBorder(),
                ),
                style: theme.textTheme.bodyLarge,
                textInputAction: TextInputAction.next,
                onChanged: (value) => _updateParent(parent.copyWith(childName: value.trim())),
              ),
              const SizedBox(height: 20),
              Text('Age (7–12)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: parent.childAge.toDouble(),
                      min: 7,
                      max: 12,
                      divisions: 5,
                      label: '${parent.childAge}',
                      onChanged: (value) => _updateParent(parent.copyWith(childAge: value.round())),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${parent.childAge}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IntakeChoiceChipGroup<HyperFixationCategory>(
                label: 'Primary hyper-fixation',
                options: HyperFixationCategory.values,
                selected: parent.hyperFixationCategory,
                labelBuilder: labelForHyperFixation,
                onSelected: (category) => _updateParent(parent.copyWith(hyperFixationCategory: category)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntakeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntakeTriggerCheckboxList(
                title: 'Sound triggers to blacklist',
                options: kSoundTriggerOptions,
                selected: parent.soundTriggers,
                onToggle: (option, isSelected) {
                  _toggleTrigger(
                    current: parent.soundTriggers,
                    option: option,
                    isSelected: isSelected,
                    apply: (updated) => _updateParent(parent.copyWith(soundTriggers: updated)),
                  );
                },
              ),
              const Divider(height: 32),
              IntakeTriggerCheckboxList(
                title: 'Visual triggers to blacklist',
                options: kVisualTriggerOptions,
                selected: parent.visualTriggers,
                onToggle: (option, isSelected) {
                  _toggleTrigger(
                    current: parent.visualTriggers,
                    option: option,
                    isSelected: isSelected,
                    apply: (updated) => _updateParent(parent.copyWith(visualTriggers: updated)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntakeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When audio is muted, confirmations can route through gentle haptics instead.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              IntakeChoiceChipGroup<TactilePreference>(
                label: 'Vibration preference',
                options: TactilePreference.values,
                selected: parent.tactilePreference,
                labelBuilder: _tactileChipLabel,
                onSelected: (preference) {
                  HapticFeedback.selectionClick();
                  _updateParent(parent.copyWith(tactilePreference: preference));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _tactileChipLabel(TactilePreference preference) {
    return switch (preference) {
      TactilePreference.prefersHaptics => 'Prefers haptics',
      TactilePreference.noVibrations => 'No vibrations',
      TactilePreference.neutral => 'Neutral',
    };
  }
}
