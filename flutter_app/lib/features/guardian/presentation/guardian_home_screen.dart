import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MindBridge')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Ready for a gentle play activity?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.go('/play/timeline'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Explore a day timeline'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/play/constellation'),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Explore a star map'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/guardian/review'),
                  child: const Text('Review comfort settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
