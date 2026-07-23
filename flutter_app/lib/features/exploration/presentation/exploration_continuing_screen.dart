import 'package:flutter/material.dart';

/// A calm neutral destination when a completed builder-showcase mechanic has
/// no direct correspondence to either currently available sandbox.
class ExplorationContinuingScreen extends StatelessWidget {
  const ExplorationContinuingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Semantics(
              liveRegion: true,
              label: 'Preparing the next exploration',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.58),
                  border: Border(top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45))),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Preparing more exploration',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
