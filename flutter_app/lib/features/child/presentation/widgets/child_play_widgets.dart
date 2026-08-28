import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../strength_funnel/presentation/widgets/sector_picture_widget.dart';
import '../../models/child_play_activity.dart';

/// Always-visible child safety controls — pause, skip, stop. No scores or streaks.
class ChildSafetyControls extends StatelessWidget {
  const ChildSafetyControls({
    super.key,
    required this.onPause,
    required this.onSkip,
    required this.onStop,
    this.isPaused = false,
    this.showSkip = true,
  });

  final VoidCallback onPause;
  final VoidCallback onSkip;
  final VoidCallback onStop;
  final bool isPaused;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPause,
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(isPaused ? 'Resume' : 'Pause'),
                ),
              ),
              if (showSkip) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Skip'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Stop play time?'),
                        content: const Text(
                          'This returns control to the guardian. You can start again anytime.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Keep playing'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) onStop();
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple concrete-activity picture card — no faces, minimal clutter.
class ChildPlayPictureCard extends StatelessWidget {
  const ChildPlayPictureCard({
    super.key,
    required this.activity,
    required this.showPromptText,
    this.onTapHaptic,
  });

  final ChildPlayActivity activity;
  final bool showPromptText;
  final VoidCallback? onTapHaptic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHaptic = activity.modality == 'haptic';

    Widget card = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SectorPictureWidget(
            sectorId: activity.sectorId,
            activityLabel: activity.activityLabel,
            height: 180,
          ),
          const SizedBox(height: 8),
          Text(
            activity.pictureDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );

    if (isHaptic && onTapHaptic != null) {
      card = Semantics(
        button: true,
        label: activity.presentMomentPrompt,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTapHaptic!();
          },
          borderRadius: BorderRadius.circular(20),
          child: card,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        if (showPromptText) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.visibility_rounded, color: theme.colorScheme.secondary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activity.presentMomentPrompt,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 12),
          Icon(Icons.visibility_rounded, size: 28, color: theme.colorScheme.secondary),
        ],
      ],
    );
  }
}
