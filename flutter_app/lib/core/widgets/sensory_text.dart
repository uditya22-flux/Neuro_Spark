import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/safe_mode_provider.dart';

class SensoryText extends ConsumerStatefulWidget {
  final String text;
  final int collapsedMaxLines;
  final TextStyle? style;

  const SensoryText({
    super.key,
    required this.text,
    this.collapsedMaxLines = 3,
    this.style,
  });

  @override
  ConsumerState<SensoryText> createState() => _SensoryTextState();
}

class _SensoryTextState extends ConsumerState<SensoryText> {
  bool _isManuallyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final safeMode = ref.watch(safeModeProvider);
    final shouldCollapse = safeMode.collapseText && !_isManuallyExpanded;

    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyLarge;

    // Soft slate text style adjustment based on Safe Mode (high contrast)
    final adjustedStyle = baseStyle?.copyWith(
      color: safeMode.isEnabled
          ? Theme.of(context).colorScheme.onSurface
          : baseStyle.color?.withOpacity(0.85),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Text(
            widget.text,
            maxLines: shouldCollapse ? widget.collapsedMaxLines : null,
            overflow: shouldCollapse ? TextOverflow.ellipsis : null,
            style: adjustedStyle,
          ),
        ),
        if (safeMode.collapseText) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              setState(() {
                _isManuallyExpanded = !_isManuallyExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isManuallyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isManuallyExpanded ? "Collapse Content" : "Show Full Content",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
