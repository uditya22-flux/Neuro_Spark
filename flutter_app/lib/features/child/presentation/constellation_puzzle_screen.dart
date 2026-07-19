import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'child_play_scaffold.dart';

class ConstellationPuzzleScreen extends StatefulWidget {
  const ConstellationPuzzleScreen({super.key});

  @override
  State<ConstellationPuzzleScreen> createState() => _ConstellationPuzzleScreenState();
}

class _ConstellationPuzzleScreenState extends State<ConstellationPuzzleScreen> {
  final Set<int> _noticed = <int>{};

  @override
  Widget build(BuildContext context) {
    return ChildPlayScaffold(
      title: 'Explore the star map',
      onSkip: () => context.go('/guardian/home'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Tap any stars that catch your eye. There is no wrong choice.',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xff101b3a),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: List<Widget>.generate(8, (index) {
                      final x = (index * 73 + 35) % constraints.maxWidth;
                      final y = (index * 97 + 40) % constraints.maxHeight;
                      final selected = _noticed.contains(index);
                      return Positioned(
                        left: x,
                        top: y,
                        child: Semantics(
                          button: true,
                          label: 'Star ${index + 1}',
                          child: IconButton(
                            onPressed: () => setState(() => _noticed.add(index)),
                            icon: Icon(
                              selected ? Icons.star : Icons.star_border,
                              color: selected ? const Color(0xffffd76e) : Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/guardian/home'),
              child: const Text('Finish exploring'),
            ),
          ],
        ),
      ),
    );
  }
}
