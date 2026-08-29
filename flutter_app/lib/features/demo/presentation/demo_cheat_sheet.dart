import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_intake_prefills.dart';
import '../providers/demo_mode_provider.dart';
import '../../../providers/intake_flow_provider.dart';

/// Shows predefined hospital-demo answers during consent + intake.
class DemoCheatSheet extends ConsumerWidget {
  const DemoCheatSheet({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(demoModeProvider);
    if (!isDemo) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35),
      child: ExpansionTile(
        initiallyExpanded: !compact,
        leading: Icon(Icons.checklist_rtl_rounded, color: theme.colorScheme.primary),
        title: Text(
          'Hospital demo — predefined answers',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: compact
            ? const Text('Tap to see what to enter on each screen')
            : const Text('Fields are pre-filled; walk through like the real app'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in DemoIntakePrefills.cheatSheetLines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: theme.textTheme.bodyMedium),
                        Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(intakeFlowProvider.notifier).seedFromDemoPrefills();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo answers applied to intake forms.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Apply demo answers again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
