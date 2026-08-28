import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/modality_router.dart';
import '../providers/child_play_session_controller.dart';
import 'widgets/child_play_widgets.dart';

/// Sensory-safe child play session driven by strength-funnel finalist themes.
class ChildPlaySessionScreen extends ConsumerStatefulWidget {
  const ChildPlaySessionScreen({
    super.key,
    required this.onSessionEnded,
  });

  final VoidCallback onSessionEnded;

  @override
  ConsumerState<ChildPlaySessionScreen> createState() => _ChildPlaySessionScreenState();
}

class _ChildPlaySessionScreenState extends ConsumerState<ChildPlaySessionScreen> {
  @override
  Widget build(BuildContext context) {
    final playState = ref.watch(childPlaySessionControllerProvider);
    final bundle = ref.watch(gameEnvironmentProvider);
    final theme = Theme.of(context);

    if (playState.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (playState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Play time')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(playState.error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (playState.completed || playState.currentActivity == null) {
      return _CompletionView(onDone: widget.onSessionEnded);
    }

    final activity = playState.currentActivity!;
    final constraints = bundle != null
        ? const ModalityRouter().routeFromIsaa(bundle.clinical, bundle.parent)
        : const ModalityConstraints(
            requiresVisualItems: true,
            allowText: false,
            allowVideo: false,
            allowHaptics: false,
            disableAnimations: false,
            useSimpleConcreteDrawings: true,
            primaryModality: 'picture',
            fallbackModalities: [],
            pacingMultiplier: 1.0,
          );

    final showPromptText = constraints.allowText &&
        (bundle?.config.instructionStyle != InstructionStyle.pureVisualGlowHints);

    final hapticsOn = bundle?.config.hapticEnabled == true && constraints.allowHaptics;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.toys_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${playState.currentIndex + 1} / ${playState.activities.length}',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChildPlayPictureCard(
                          activity: activity,
                          showPromptText: showPromptText,
                          onTapHaptic: hapticsOn ? () {} : null,
                        ),
                        const SizedBox(height: 28),
                        if (activity.modality == 'text' && constraints.allowText)
                          Text(
                            activity.presentMomentPrompt,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 20),
                        Semantics(
                          button: true,
                          label: 'This feels fun right now',
                          child: FilledButton.icon(
                            onPressed: playState.paused
                                ? null
                                : () {
                                    if (hapticsOn) HapticFeedback.selectionClick();
                                    ref
                                        .read(childPlaySessionControllerProvider.notifier)
                                        .markExplored();
                                  },
                            icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                            label: const Text('This feels fun right now'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap when the activity feels enjoyable in this moment — not for later or as a job.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                ChildSafetyControls(
                  isPaused: playState.paused,
                  onPause: () =>
                      ref.read(childPlaySessionControllerProvider.notifier).togglePause(),
                  onSkip: playState.paused
                      ? () {}
                      : () => ref.read(childPlaySessionControllerProvider.notifier).skip(),
                  onStop: () async {
                    await ref.read(childPlaySessionControllerProvider.notifier).stop();
                    if (context.mounted) widget.onSessionEnded();
                  },
                ),
              ],
            ),
          ),
          if (playState.paused) const _PauseOverlay(),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle_outline_rounded,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Paused',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Take your time. Tap Resume when ready.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Nice exploring!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You looked at fun play themes. Hand the device back to your grown-up.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
