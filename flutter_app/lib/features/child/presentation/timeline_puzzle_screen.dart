import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'child_play_scaffold.dart';

class TimelinePuzzleScreen extends StatefulWidget {
  const TimelinePuzzleScreen({super.key});

  @override
  State<TimelinePuzzleScreen> createState() => _TimelinePuzzleScreenState();
}

class _TimelinePuzzleScreenState extends State<TimelinePuzzleScreen> {
  final List<String> _events = <String>[
    'Breakfast',
    'Morning walk',
    'Lunch',
    'Story time',
  ];
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    return ChildPlayScaffold(
      title: 'Place the day in order',
      onSkip: () => context.go('/play/constellation'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Move the cards into any order that makes sense to you.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _events.length,
                buildDefaultDragHandles: true,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final event = _events.removeAt(oldIndex);
                    _events.insert(newIndex, event);
                  });
                },
                itemBuilder: (context, index) => Card(
                  key: ValueKey<String>(_events[index]),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(_events[index]),
                    trailing: const Icon(Icons.drag_handle),
                  ),
                ),
              ),
            ),
            FilledButton(
              onPressed: () => setState(() => _complete = true),
              child: const Text('I am happy with this'),
            ),
            if (_complete) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Thanks for arranging the day your way.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              TextButton(
                onPressed: () => context.go('/play/constellation'),
                child: const Text('Try a star map'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
