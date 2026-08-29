import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/intake_models.dart';
import '../../../../services/modality_router.dart';
import '../../../deepening/presentation/widgets/task_instruction_widgets.dart';
import '../../models/riasec_sector.dart';

/// Short hands-on activity the child completes before rating present-moment enjoyment.
class SectorPlayActivityWidget extends StatefulWidget {
  const SectorPlayActivityWidget({
    super.key,
    required this.sectorId,
    required this.activityLabel,
    required this.presentMomentPrompt,
    required this.constraints,
    required this.instructionStyle,
    required this.layer,
    required this.onCompleted,
  });

  final String sectorId;
  final String activityLabel;
  final String presentMomentPrompt;
  final ModalityConstraints constraints;
  final InstructionStyle instructionStyle;
  final int layer;
  final VoidCallback onCompleted;

  @override
  State<SectorPlayActivityWidget> createState() => _SectorPlayActivityWidgetState();
}

class _SectorPlayActivityWidgetState extends State<SectorPlayActivityWidget> {
  int _progress = 0;
  String? _picked;
  final Set<int> _sorted = {};

  int get _targetSteps => widget.layer >= 6 ? 4 : 3;

  String get _riasecPrefix => widget.sectorId.split('_').first;

  void _bumpProgress() {
    if (widget.constraints.allowHaptics) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _progress++;
      if (_progress >= _targetSteps) {
        widget.onCompleted();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SectorPlayActivityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectorId != widget.sectorId || oldWidget.layer != widget.layer) {
      _progress = 0;
      _picked = null;
      _sorted.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final done = _progress >= _targetSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.touch_app_rounded, color: accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Step 1 · Try this activity',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TaskInstructionPrompt(
          style: widget.instructionStyle,
          prompt: _actionPrompt(),
          icon: _actionIcon(),
          accentColor: accent,
          compact: true,
        ),
        const SizedBox(height: 16),
        _buildInteraction(theme, accent),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_progress / _targetSteps).clamp(0.0, 1.0),
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        Text(
          done
              ? 'Nice — you tried it. Now say how fun it felt.'
              : 'Tap or choose to do the activity ($_progress / $_targetSteps)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  String _actionPrompt() {
    final sector = sectorById(widget.sectorId);
    final theme = sector?.playTheme ?? widget.activityLabel;
    return switch (_riasecPrefix) {
      'r' => 'Try ${widget.activityLabel.toLowerCase()} — tap to build or move pieces.',
      'i' => 'Try solving this — pick the option that fits $theme.',
      'a' => 'Try making something — tap the colors or shapes.',
      's' => 'Try this together play — tap to pass or share.',
      'e' => 'Try leading — pick the card you would choose.',
      'c' => 'Try organizing — tap each item into the right group.',
      _ => widget.presentMomentPrompt,
    };
  }

  IconData _actionIcon() {
    return switch (_riasecPrefix) {
      'r' => Icons.construction_rounded,
      'i' => Icons.psychology_rounded,
      'a' => Icons.palette_rounded,
      's' => Icons.groups_rounded,
      'e' => Icons.campaign_rounded,
      'c' => Icons.sort_rounded,
      _ => Icons.extension_rounded,
    };
  }

  Widget _buildInteraction(ThemeData theme, Color accent) {
    return switch (_riasecPrefix) {
      'r' => _buildStackInteraction(theme, accent),
      'i' => _buildPickInteraction(theme, accent, const ['Option A', 'Option B', 'Option C']),
      'a' => _buildColorInteraction(theme, accent),
      's' => _buildPassInteraction(theme, accent),
      'e' => _buildCardPick(theme, accent),
      'c' => _buildSortInteraction(theme, accent),
      _ => _buildStackInteraction(theme, accent),
    };
  }

  Widget _buildStackInteraction(ThemeData theme, Color accent) {
    return Semantics(
      button: true,
      label: 'Tap to stack blocks for ${widget.activityLabel}',
      child: InkWell(
        onTap: _bumpProgress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_targetSteps, (index) {
              final filled = index < _progress;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: filled ? 48 + index * 8.0 : 40,
                  decoration: BoxDecoration(
                    color: filled ? accent : accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildPickInteraction(ThemeData theme, Color accent, List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return ActionChip(
          label: Text(option),
          onPressed: () {
            setState(() => _picked = option);
            _bumpProgress();
          },
        );
      }).toList(),
    );
  }

  Widget _buildColorInteraction(ThemeData theme, Color accent) {
    const colors = [Color(0xFFE57373), Color(0xFF64B5F6), Color(0xFFFFF176), Color(0xFF81C784)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(colors.length, (index) {
        final tapped = _progress > index;
        return Semantics(
          button: true,
          label: 'Color ${index + 1}',
          child: GestureDetector(
            onTap: _bumpProgress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tapped ? colors[index] : colors[index].withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: accent, width: tapped ? 2 : 1),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPassInteraction(ThemeData theme, Color accent) {
    return FilledButton.tonalIcon(
      onPressed: _bumpProgress,
      icon: const Icon(Icons.swap_horiz_rounded),
      label: Text('Pass (${_progress}/$_targetSteps)'),
    );
  }

  Widget _buildCardPick(ThemeData theme, Color accent) {
    return _buildPickInteraction(
      theme,
      accent,
      const ['Plan A', 'Plan B', 'Plan C'],
    );
  }

  Widget _buildSortInteraction(ThemeData theme, Color accent) {
    const labels = ['Red', 'Blue', 'Green'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        final sorted = _sorted.contains(index);
        return ActionChip(
          label: Text(sorted ? '${labels[index]} ✓' : labels[index]),
          onPressed: sorted
              ? null
              : () {
                  setState(() => _sorted.add(index));
                  _bumpProgress();
                },
        );
      }),
    );
  }
}
