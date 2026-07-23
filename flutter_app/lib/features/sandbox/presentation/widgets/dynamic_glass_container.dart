import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../exploration/providers/intake_provider.dart';

class DynamicGlassContainer extends ConsumerWidget {
  final Widget child;
  final double blurFactorPx;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const DynamicGlassContainer({
    super.key,
    required this.child,
    this.blurFactorPx = 15.0,
    this.opacity = 0.12,
    this.borderRadius,
    this.padding = const EdgeInsets.all(16.0),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20.0);
    final theme = Theme.of(context);
    final interface = ref.watch(interfaceConfigurationProvider);
    final effectiveBlur = blurFactorPx < interface.glassBlur ? interface.glassBlur : blurFactorPx;

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: padding,
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.surface)
                .withValues(alpha: opacity > interface.glassOpacity ? opacity : interface.glassOpacity),
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: borderColor ?? theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
