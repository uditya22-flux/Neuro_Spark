import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntakeReviewScreen extends StatefulWidget {
  const IntakeReviewScreen({super.key});

  @override
  State<IntakeReviewScreen> createState() => _IntakeReviewScreenState();
}

class _IntakeReviewScreenState extends State<IntakeReviewScreen> {
  final Map<String, bool> _settings = <String, bool>{
    'Use a quieter sound setting': true,
    'Use gentler screen movement': true,
    'Use the calm colour theme': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review play settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Text(
            'Choose what to use',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text('These are suggested comfort settings. You can change them at any time.'),
          const SizedBox(height: 16),
          ..._settings.entries.map(
            (entry) => SwitchListTile(
              value: entry.value,
              onChanged: (value) => setState(() => _settings[entry.key] = value),
              title: Text(entry.key),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/guardian/home'),
            child: const Text('Save approved settings'),
          ),
        ],
      ),
    );
  }
}
