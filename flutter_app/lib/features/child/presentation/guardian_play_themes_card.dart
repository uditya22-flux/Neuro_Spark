import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../strength_funnel/models/riasec_sector.dart';
import '../../strength_funnel/presentation/guardian_strength_summary_screen.dart';
import '../../../core/router/app_router.dart';
import '../../strength_funnel/presentation/widgets/sector_picture_widget.dart';
import '../../../providers/game_environment_provider.dart';
import '../../child/services/child_play_telemetry_service.dart';

/// Dashboard summary of explored play themes and recent child play activity.
class GuardianPlayThemesCard extends ConsumerWidget {
  const GuardianPlayThemesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final finalistsAsync = ref.watch(strengthFunnelFinalistsProvider);
    final childId = ref.watch(gameEnvironmentProvider)?.childId;

    return finalistsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (finalists) {
        if (finalists == null || finalists.sectorIds.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Play themes', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Complete the play-theme exploration to see your child\'s sparks here.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/strength-funnel'),
                    child: const Text('Start exploration'),
                  ),
                ],
              ),
            ),
          );
        }

        final topThemes = finalists.sectorIds.take(4).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Play themes explored',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/strength-summary'),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Present-moment enjoyment — not a diagnosis or career prediction.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topThemes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final sectorId = topThemes[index];
                      final sector = sectorById(sectorId);
                      return SizedBox(
                        width: 120,
                        child: Column(
                          children: [
                            Expanded(
                              child: SectorPictureWidget(
                                sectorId: sectorId,
                                height: 72,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sector?.displayName ?? sectorId,
                              style: theme.textTheme.labelSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (childId != null) ...[
                  const SizedBox(height: 12),
                  _PlayActivitySummary(childId: childId),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => restartStrengthFunnelExploration(ref, context),
                  icon: const Icon(Icons.layers_rounded),
                  label: const Text('Start 10 layers again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayActivitySummary extends ConsumerWidget {
  const _PlayActivitySummary({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: ref.read(childPlayTelemetryServiceProvider).countEnjoyedForChild(childId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Text(
          '$count fun moments recorded in recent play sessions.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        );
      },
    );
  }
}
