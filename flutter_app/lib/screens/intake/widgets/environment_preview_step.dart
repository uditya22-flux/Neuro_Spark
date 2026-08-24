import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/intake_models.dart';
import '../../../providers/intake_flow_provider.dart';
import 'intake_shared_widgets.dart';

class EnvironmentPreviewStep extends ConsumerWidget {
  const EnvironmentPreviewStep({
    super.key,
    this.onComplete,
  });

  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intake = ref.watch(intakeFlowProvider);
    final config = ref.watch(compiledEnvironmentProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const IntakeStepHeader(
          stepIndex: 2,
          totalSteps: 3,
          title: 'Live Sensory Safety Preview',
          subtitle:
              'This is the compiled GameEnvironmentConfig — updated in real time as clinical and parental inputs change.',
        ),
        const SizedBox(height: 20),
        IntakeSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sensory-safe environment for ${intake.parent.childName.isEmpty ? 'your child' : intake.parent.childName}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (config.pacingSlowed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Chip(
                    avatar: Icon(Icons.speed_rounded, size: 18, color: theme.colorScheme.secondary),
                    label: const Text('Pacing slowed for sensory load'),
                  ),
                ),
              const Divider(),
              ConfigPreviewRow(
                icon: Icons.palette_rounded,
                label: 'Theme palette',
                value: labelForThemePalette(config.themePalette),
                highlight: config.themePalette == ThemePalette.calmDark,
              ),
              ConfigPreviewRow(
                icon: Icons.volume_off_rounded,
                label: 'Audio mode',
                value: labelForAudioMode(config.audioMode),
                highlight: config.audioMode == AudioMode.completelyMuted,
              ),
              ConfigPreviewRow(
                icon: Icons.vibration_rounded,
                label: 'Haptic confirmations',
                value: config.hapticEnabled ? 'Enabled' : 'Disabled',
              ),
              ConfigPreviewRow(
                icon: Icons.touch_app_rounded,
                label: 'Instruction style',
                value: labelForInstructionStyle(config.instructionStyle),
              ),
              ConfigPreviewRow(
                icon: Icons.auto_awesome_rounded,
                label: 'Asset theme',
                value: config.assetTheme,
              ),
              ConfigPreviewRow(
                icon: Icons.landscape_rounded,
                label: 'Strict grounding',
                value: config.strictGroundingEnforced ? 'Enforced (no floating physics)' : 'Off',
                highlight: config.strictGroundingEnforced,
              ),
              ConfigPreviewRow(
                icon: Icons.stairs_rounded,
                label: 'Starting difficulty tier',
                value: 'Tier ${config.startingDifficultyTier}',
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
                'Payload preview (JSON)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: SelectableText(
                  _prettyJson(config.toJson()),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onComplete != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Confirm & Apply Environment'),
            ),
          ),
        ],
      ],
    );
  }

  String _prettyJson(Map<String, dynamic> json) {
    final buffer = StringBuffer('{\n');
    json.entries.toList().asMap().forEach((index, entry) {
      final comma = index < json.length - 1 ? ',' : '';
      buffer.writeln('  "${entry.key}": ${_formatValue(entry.value)}$comma');
    });
    buffer.write('}');
    return buffer.toString();
  }

  String _formatValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is bool) return value ? 'true' : 'false';
    return '$value';
  }
}
