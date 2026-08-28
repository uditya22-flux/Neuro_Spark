import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_environment_provider.dart';
import '../../../services/remote_strength_funnel_loader.dart';
import '../data/sector_template_catalog.dart';
import '../models/riasec_sector.dart';
import '../models/strength_funnel_finalists.dart';
import '../providers/strength_funnel_controller.dart';

/// Guardian-facing summary of top play themes — exploratory only, not diagnostic.
class GuardianStrengthSummaryScreen extends ConsumerWidget {
  const GuardianStrengthSummaryScreen({
    super.key,
    required this.finalists,
    required this.onContinue,
    required this.onStartPlay,
    required this.onGoToDashboard,
  });

  final StrengthFunnelFinalists finalists;
  final VoidCallback onContinue;
  final VoidCallback onStartPlay;
  final VoidCallback onGoToDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bundle = ref.watch(gameEnvironmentProvider);
    final childName = bundle?.parent.childName.trim().isNotEmpty == true
        ? bundle!.parent.childName.trim()
        : 'your child';

    final entries = finalists.sectorIds.map((id) {
      final sector = sectorById(id);
      final sample = sector != null ? templateForSector(sector) : null;
      return _FinalistEntry(
        sectorId: id,
        displayName: sector?.displayName ?? id,
        playTheme: sector?.playTheme ?? '',
        samplePrompt: sample?.presentMomentPrompt,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Play themes explored')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.explore_outlined, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Present-moment sparks',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on $childName\'s enjoyment during play-theme exploration — '
            'not a diagnosis, label, or career prediction.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...entries.map((entry) => _FinalistCard(entry: entry)),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'These themes reflect what felt fun right now. They may shift over time. '
                'Use them to choose activities your child already enjoys.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onStartPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start child\'s play'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onGoToDashboard,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Go to guardian home'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onContinue,
            child: const Text('Optional: deeper strength activities'),
          ),
        ],
      ),
    );
  }
}

class _FinalistEntry {
  const _FinalistEntry({
    required this.sectorId,
    required this.displayName,
    required this.playTheme,
    this.samplePrompt,
  });

  final String sectorId;
  final String displayName;
  final String playTheme;
  final String? samplePrompt;
}

class _FinalistCard extends StatelessWidget {
  const _FinalistCard({required this.entry});

  final _FinalistEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.displayName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (entry.playTheme.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.playTheme, style: theme.textTheme.bodySmall),
            ],
            if (entry.samplePrompt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Enjoyment cue: ${entry.samplePrompt}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final strengthFunnelFinalistsProvider = FutureProvider<StrengthFunnelFinalists?>((ref) async {
  final childId = ref.watch(gameEnvironmentProvider)?.childId;
  if (childId != null) {
    final remote = await ref.watch(remoteStrengthFunnelLoaderProvider).loadFinalistsForChild(childId);
    if (remote != null) {
      await ref.watch(strengthFunnelProgressServiceProvider).saveFinalists(remote);
      return remote;
    }
  }
  return ref.watch(strengthFunnelProgressServiceProvider).loadFinalists();
});
