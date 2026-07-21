import 'dart:ui';
import 'package:flutter/material.dart';

class DynamicGlassContainer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20.0);
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurFactorPx, sigmaY: blurFactorPx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: padding,
          decoration: BoxDecoration(
            color: (theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.surface)
                .withValues(alpha: opacity),
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
