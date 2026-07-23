import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/intake_provider.dart';

/// Grounded glass panel: it uses in-flow layout and no elevation/shadow.
class SensoryGlassSurface extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SensoryGlassSurface({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(interfaceConfigurationProvider);
    final color = Theme.of(context).colorScheme.surface.withValues(alpha: config.glassOpacity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: config.glassBlur, sigmaY: config.glassBlur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: .22)),
          ),
          child: child,
        ),
      ),
    );
  }
}
