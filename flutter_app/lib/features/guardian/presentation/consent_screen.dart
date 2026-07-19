import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardian consent')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Text(
            'A calm, guardian-led play experience',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Text(
            'MindBridge uses guardian-approved settings to make two play activities more comfortable. '
            'It is not a medical or educational assessment.',
          ),
          const SizedBox(height: 16),
          const Text(
            'You can review each suggested setting, request an export, or ask us to delete your family data. '
            'Your child may pause or stop at any time.',
          ),
          const SizedBox(height: 24),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            title: const Text('I am the child’s parent or legal guardian and agree to this version of the consent notice.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _accepted ? () => context.go('/guardian/review') : null,
            child: const Text('Continue to settings review'),
          ),
        ],
      ),
    );
  }
}
