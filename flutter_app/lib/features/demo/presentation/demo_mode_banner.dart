import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/demo_config.dart';
import '../presentation/demo_methodology_sheet.dart';
import '../providers/demo_mode_provider.dart';

/// Banner shown during hospital demo walkthroughs.
class DemoModeBanner extends ConsumerWidget {
  const DemoModeBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(demoModeProvider);
    if (!isDemo) return child;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.science_outlined,
                      size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hospital demo — synthetic data only',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => DemoMethodologySheet.show(context),
                    child: const Text('Research'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(demoModeProvider.notifier).state = false;
                      context.go('/login');
                    },
                    child: const Text('Exit'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

/// Intro screen before the shortened demo funnel.
class DemoIntroScreen extends StatelessWidget {
  const DemoIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital demo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.local_hospital_outlined, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Guardian-led strengths walkthrough',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This 8–10 minute demo shows how MindBridge explores present-moment play interests '
                'for ${DemoConfig.demoChildName} (age ${DemoConfig.demoChildAge}, synthetic profile).',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You will see:', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _step('1', '6 play-theme cards (one per RIASEC type) with picture-first routing'),
                      _step('2', '60% adaptive filter narrowing to top themes'),
                      _step('3', 'Guardian summary → child handoff → sensory-safe play'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => DemoMethodologySheet.show(context),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('How the question engine works'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.go('/strength-funnel'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start demo funnel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
