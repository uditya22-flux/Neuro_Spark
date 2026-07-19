import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/sensory_regulation_service.dart';

class ChildPlayScaffold extends ConsumerWidget {
  const ChildPlayScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onSkip,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regulation = ref.watch(sensoryRegulationProvider);
    final config = regulation.configuration;
    final colors = Theme.of(context).colorScheme;
    final animationDuration =
        config.reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

    return AnimatedContainer(
      duration: animationDuration,
      color: config.highContrast ? colors.surface : colors.surfaceContainerLowest,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.transparent,
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  ref.read(sensoryRegulationProvider.notifier).openCooldown();
                  context.go('/play/cooldown');
                },
                child: const Text('Take a pause'),
              ),
              if (onSkip != null)
                TextButton(onPressed: onSkip, child: const Text('Skip')),
            ],
          ),
          body: child,
        ),
      ),
    );
  }
}
