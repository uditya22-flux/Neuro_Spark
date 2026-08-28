import 'package:flutter/material.dart';

/// Brief guardian handoff before child takes the device.
class GuardianHandoffScreen extends StatelessWidget {
  const GuardianHandoffScreen({
    super.key,
    required this.childName,
    required this.onReady,
    required this.onCancel,
  });

  final String childName;
  final VoidCallback onReady;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = childName.trim().isEmpty ? 'your child' : childName.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Handoff to child')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Ready for $name?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Hand the device to your child. They will see simple picture cards about '
                'play activities — no reading test, no scores, no career questions.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your child can always:', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _row(Icons.pause_rounded, 'Pause'),
                      _row(Icons.skip_next_rounded, 'Skip'),
                      _row(Icons.stop_rounded, 'Stop and return the device'),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onReady,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start play time'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onCancel,
                child: const Text('Not yet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
