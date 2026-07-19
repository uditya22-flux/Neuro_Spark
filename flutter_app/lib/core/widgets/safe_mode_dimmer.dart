import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/safe_mode_provider.dart';

class SafeModeDimmer extends ConsumerWidget {
  final Widget child;

  const SafeModeDimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeMode = ref.watch(safeModeProvider);

    return Stack(
      children: [
        child,
        if (safeMode.isEnabled && safeMode.dimmingOpacity > 0.0)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.black.withOpacity(safeMode.dimmingOpacity),
              ),
            ),
          ),
      ],
    );
  }
}
