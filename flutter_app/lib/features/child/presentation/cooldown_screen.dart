import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/sensory_regulation_service.dart';

class CooldownScreen extends ConsumerWidget {
  const CooldownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sensoryRegulationProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.cloud_outlined, size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    'Quiet space',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.cooldownReason ?? 'You can pause here for as long as you like.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      ref.read(sensoryRegulationProvider.notifier).resume();
                      context.go('/play/timeline');
                    },
                    child: const Text('Continue when ready'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/guardian/home'),
                    child: const Text('Finish for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
