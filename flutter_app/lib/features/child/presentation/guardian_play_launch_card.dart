import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../strength_funnel/models/riasec_sector.dart';
import '../../strength_funnel/presentation/guardian_strength_summary_screen.dart';

/// Guardian dashboard card — start sensory-safe play from saved finalist themes.
class GuardianPlayLaunchCard extends ConsumerWidget {
  const GuardianPlayLaunchCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalistsAsync = ref.watch(strengthFunnelFinalistsProvider);
    final theme = Theme.of(context);

    return finalistsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (finalists) {
        if (finalists == null || finalists.sectorIds.isEmpty) {
          return const SizedBox.shrink();
        }

        final labels = finalists.sectorIds
            .map((id) => sectorById(id)?.displayName ?? id)
            .take(3)
            .join(', ');

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.toys_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Child play time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Top play themes: $labels',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/guardian-handoff'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start play'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
