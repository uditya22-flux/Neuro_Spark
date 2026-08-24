import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/intake_models.dart';

/// Renders task prompts according to the compiled instruction modality.
class TaskInstructionPrompt extends StatelessWidget {
  const TaskInstructionPrompt({
    super.key,
    required this.style,
    required this.prompt,
    required this.icon,
    required this.accentColor,
    this.compact = false,
  });

  final InstructionStyle style;
  final String prompt;
  final IconData icon;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      InstructionStyle.pureVisualGlowHints => _GlowHintPrompt(
          icon: icon,
          accentColor: accentColor,
        ),
      InstructionStyle.pictorialGuideCards => _PictorialPrompt(
          prompt: prompt,
          icon: icon,
          accentColor: accentColor,
          compact: compact,
        ),
      InstructionStyle.gentleAudioGuide => _PictorialPrompt(
          prompt: prompt,
          icon: Icons.hearing_rounded,
          accentColor: accentColor,
          compact: compact,
          caption: 'Gentle audio guidance available',
        ),
      InstructionStyle.simpleText => Text(
          prompt,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
    };
  }
}

class TaskContinueButton extends StatelessWidget {
  const TaskContinueButton({
    super.key,
    required this.style,
    required this.onPressed,
    required this.accentColor,
    this.textLabel = 'Continue',
  });

  final InstructionStyle style;
  final VoidCallback? onPressed;
  final Color accentColor;
  final String textLabel;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case InstructionStyle.pureVisualGlowHints:
        return Semantics(
          button: true,
          label: 'Continue task',
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onPressed!();
                      },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: onPressed == null ? 0.25 : 0.85),
                    boxShadow: onPressed == null
                        ? null
                        : [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.45),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        );
      case InstructionStyle.pictorialGuideCards:
      case InstructionStyle.gentleAudioGuide:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(textLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        );
      case InstructionStyle.simpleText:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              textLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
    }
  }
}

/// Sensory-safe feedback — no snackbar text for wordless instruction mode.
void showTaskFeedback(BuildContext context, InstructionStyle style, {required bool advanced}) {
  if (style == InstructionStyle.pureVisualGlowHints) {
    HapticFeedback.mediumImpact();
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(advanced ? 'Great job! Moving forward…' : 'Recorded — adapting next step…'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class _GlowHintPrompt extends StatelessWidget {
  const _GlowHintPrompt({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.15),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 40, color: accentColor),
        ),
        const SizedBox(height: 12),
        Text(
          'Follow the glowing guide',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PictorialPrompt extends StatelessWidget {
  const _PictorialPrompt({
    required this.prompt,
    required this.icon,
    required this.accentColor,
    required this.compact,
    this.caption,
  });

  final String prompt;
  final IconData icon;
  final Color accentColor;
  final bool compact;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 48 : 56,
          height: compact ? 48 : 56,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(
                  caption!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
