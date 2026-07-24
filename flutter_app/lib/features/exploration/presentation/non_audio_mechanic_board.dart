import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exploration_models.dart';

/// Dedicated, word-free play surfaces for the non-audio sectors that need a
/// richer interaction than selecting a generic picture tile. The parent owns
/// correctness and telemetry through [onChoice]; these widgets only turn each
/// sector into its intended tap, drag, sequence, or open-composition gesture.
///
/// This is intentionally limited to single-mechanic tasks. Compound ambient
/// scenes continue to use the existing ambient board so their combined visual
/// plan remains intact.
class NonAudioMechanicBoard extends StatelessWidget {
  const NonAudioMechanicBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final FutureOr<bool> Function(String choice) onChoice;

  static const Set<PlayMechanic> _supportedMechanics = {
    PlayMechanic.numberPatternRecognition,
    PlayMechanic.ruleDiscovery,
    PlayMechanic.multiAttributeSorting,
    PlayMechanic.systemizing,
    PlayMechanic.quantitativeEstimation,
    PlayMechanic.pictureAssociation,
    PlayMechanic.wordlessInference,
    PlayMechanic.analogyMapping,
    PlayMechanic.creativeStorytelling,
    PlayMechanic.workingMemorySpan,
    PlayMechanic.visualSceneMemory,
    PlayMechanic.sustainedAttention,
    PlayMechanic.selectiveAttention,
  };

  static bool supports(PuzzleSpec task) =>
      task.mechanics.length == 1 && _supportedMechanics.contains(task.mechanics.single);

  @override
  Widget build(BuildContext context) {
    if (!supports(task)) return const SizedBox.shrink();
    final key = ValueKey('non-audio-mechanic-${task.id}');
    final mechanic = task.mechanics.single;
    return switch (mechanic) {
      PlayMechanic.numberPatternRecognition => _NumberPatternBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.ruleDiscovery => _RuleDiscoveryBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.multiAttributeSorting => _MultiAttributeSortingBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.systemizing => _SystemizingBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.quantitativeEstimation => _QuantitativeEstimationBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.pictureAssociation => _PictureAssociationBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.wordlessInference => _WordlessInferenceBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.analogyMapping => _AnalogyMappingBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.creativeStorytelling => _CreativeStorytellingBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.workingMemorySpan => _WorkingMemoryBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.visualSceneMemory => _VisualSceneMemoryBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.sustainedAttention => _SustainedAttentionBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.selectiveAttention => _SelectiveAttentionBoard(
          key: key,
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

typedef _ChoiceCallback = FutureOr<bool> Function(String choice);

/// Maps the opaque task options to visual slots without ever displaying their
/// strings. The external flow still receives exactly the option it expects.
class _TaskChoices {
  _TaskChoices(PuzzleSpec task)
      : _correct = task.correctOption,
        _options = _visibleOptions(task);

  final String _correct;
  final List<String> _options;

  int get length => _options.length;
  int get correctIndex {
    final index = _options.indexOf(_correct);
    return index < 0 ? 0 : index;
  }

  String get correct => _correct;
  String at(int index) => _options[index % _options.length];

  String incorrectAt(int index) {
    for (var offset = 0; offset < _options.length; offset++) {
      final candidate = at(index + offset);
      if (candidate != _correct) return candidate;
    }
    // A malformed one-option task cannot expose a soft miss. Returning the
    // task option keeps its contract intact instead of inventing a value.
    return _correct;
  }

  static List<String> _visibleOptions(PuzzleSpec task) {
    final source = task.options.isEmpty ? <String>[task.correctOption] : task.options;
    final requested = task.itemCount.clamp(1, source.length).toInt();
    final options = source.take(requested).toList(growable: true);
    if (!options.contains(task.correctOption)) {
      options[options.length - 1] = task.correctOption;
    }
    return options;
  }
}

mixin _ChoiceSubmitter<T extends StatefulWidget> on State<T> {
  bool _submitting = false;

  bool get isSubmitting => _submitting;

  Future<bool> submitChoice(_ChoiceCallback callback, String choice) async {
    if (_submitting) return false;
    setState(() => _submitting = true);
    final solved = await callback(choice);
    if (mounted && !solved) setState(() => _submitting = false);
    return solved;
  }
}

class _PlayPalette {
  const _PlayPalette(this.primary, this.secondary, this.tertiary);

  final Color primary;
  final Color secondary;
  final Color tertiary;

  factory _PlayPalette.forTask(PuzzleSpec task) {
    final colors = task.familiarColors.map(_fromFamiliarColor).toList(growable: false);
    if (colors.isEmpty) {
      return const _PlayPalette(
        Color(0xff5270a2),
        Color(0xffd76b5e),
        Color(0xffe3ad45),
      );
    }
    return _PlayPalette(
      colors[0],
      colors.length > 1 ? colors[1] : const Color(0xffd76b5e),
      colors.length > 2 ? colors[2] : const Color(0xffe3ad45),
    );
  }

  static Color _fromFamiliarColor(FamiliarColor color) => switch (color) {
        FamiliarColor.red => const Color(0xffc95c54),
        FamiliarColor.orange => const Color(0xffd7873e),
        FamiliarColor.yellow => const Color(0xffc89c2e),
        FamiliarColor.green => const Color(0xff4e7a5d),
        FamiliarColor.blue => const Color(0xff5270a2),
        FamiliarColor.purple => const Color(0xff7b609c),
        FamiliarColor.pink => const Color(0xffb56483),
      };
}

class _BoardFrame extends StatelessWidget {
  const _BoardFrame({
    required this.color,
    required this.highlightTarget,
    required this.child,
  });

  final Color color;
  final bool highlightTarget;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: color.withValues(alpha: highlightTarget ? .92 : .28),
            width: highlightTarget ? 3 : 1.5,
          ),
        ),
        child: child,
      );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.child,
    required this.color,
    required this.onTap,
    this.highlight = false,
    this.size = const Size(104, 96),
    this.selected = false,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final bool highlight;
  final Size size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: selected ? .92 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .84),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: highlight ? .98 : .28),
                  width: highlight ? 3 : 1.4,
                ),
                boxShadow: highlight
                    ? [BoxShadow(color: color.withValues(alpha: .22), blurRadius: 13, spreadRadius: 1)]
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      );
}

class _DotCloud extends StatelessWidget {
  const _DotCloud({
    required this.count,
    required this.color,
    this.size = 74,
  });

  final int count;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final columns = count > 8 ? 4 : 3;
    return SizedBox(
      width: size,
      height: size,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: size * .065,
        runSpacing: size * .065,
        children: List.generate(
          count,
          (index) => Container(
            width: size / (columns + 2.7),
            height: size / (columns + 2.7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .86 - (index % 3) * .08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

enum _TokenShape { circle, square, triangle }

class _ShapeToken extends StatelessWidget {
  const _ShapeToken({
    required this.color,
    required this.shape,
    this.size = 38,
    this.faded = false,
  });

  final Color color;
  final _TokenShape shape;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final painted = color.withValues(alpha: faded ? .28 : .94);
    return switch (shape) {
      _TokenShape.circle => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: painted, shape: BoxShape.circle),
        ),
      _TokenShape.square => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: painted, borderRadius: BorderRadius.circular(size * .16)),
        ),
      _TokenShape.triangle => CustomPaint(
          size: Size.square(size),
          painter: _TrianglePainter(painted),
        ),
    };
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _NumberPatternBoard extends StatefulWidget {
  const _NumberPatternBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_NumberPatternBoard> createState() => _NumberPatternBoardState();
}

class _NumberPatternBoardState extends State<_NumberPatternBoard> with _ChoiceSubmitter<_NumberPatternBoard> {
  int? _selected;

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final start = 1 + (widget.task.difficulty % 2);
    final targetCount = start + 3;
    final counts = List<int>.generate(choices.length, (index) {
      if (index == choices.correctIndex) return targetCount;
      final delta = index.isEven ? -1 - (index ~/ 2) : 1 + (index ~/ 2);
      return math.max(1, targetCount + delta).toInt();
    });
    return _BoardFrame(
      color: palette.primary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DotCloud(count: start, color: palette.primary, size: 48),
              _DotCloud(count: start + 1, color: palette.primary, size: 48),
              _DotCloud(count: start + 2, color: palette.primary, size: 48),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: palette.primary.withValues(alpha: .55), width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              choices.length,
              (index) => _ChoiceTile(
                color: palette.primary,
                highlight: widget.highlightTarget && index == choices.correctIndex,
                selected: _selected == index,
                onTap: isSubmitting ? null : () => _choose(choices, index),
                child: _DotCloud(count: counts[index], color: palette.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleDiscoveryBoard extends StatefulWidget {
  const _RuleDiscoveryBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_RuleDiscoveryBoard> createState() => _RuleDiscoveryBoardState();
}

class _RuleDiscoveryBoardState extends State<_RuleDiscoveryBoard> with _ChoiceSubmitter<_RuleDiscoveryBoard> {
  bool _placed = false;

  Future<void> _drop(_TaskChoices choices, int bin, int correctBin) async {
    if (isSubmitting || _placed) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    final solved = await submitChoice(widget.onChoice, choices.at(bin));
    if (mounted && solved && bin == correctBin) setState(() => _placed = true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final binCount = math.max(2, math.min(3, choices.length)).toInt();
    final correctBin = choices.correctIndex % binCount;
    final binColors = [palette.primary, palette.secondary, palette.tertiary];
    const binShapes = [_TokenShape.circle, _TokenShape.square, _TokenShape.triangle];
    return _BoardFrame(
      color: palette.secondary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              binCount,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _RuleBin(
                    color: binColors[index],
                    shape: binShapes[index],
                    highlighted: widget.highlightTarget && index == correctBin,
                    onAccept: isSubmitting || _placed ? null : () => _drop(choices, index, correctBin),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Draggable<int>(
            data: correctBin,
            feedback: Material(
              color: Colors.transparent,
              child: _ShapeToken(color: binColors[correctBin], shape: binShapes[correctBin], size: 54),
            ),
            childWhenDragging: _ShapeToken(
              color: binColors[correctBin],
              shape: binShapes[correctBin],
              size: 54,
              faded: true,
            ),
            child: _ShapeToken(
              color: binColors[correctBin],
              shape: binShapes[correctBin],
              size: 54,
              faded: _placed,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleBin extends StatelessWidget {
  const _RuleBin({
    required this.color,
    required this.shape,
    required this.highlighted,
    required this.onAccept,
  });

  final Color color;
  final _TokenShape shape;
  final bool highlighted;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
        onWillAcceptWithDetails: (_) => onAccept != null,
        onAcceptWithDetails: (_) => onAccept?.call(),
        builder: (context, candidates, rejected) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 106,
          decoration: BoxDecoration(
            color: color.withValues(alpha: candidates.isNotEmpty ? .22 : .1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(12)),
            border: Border.all(
              color: color.withValues(alpha: highlighted ? .94 : .42),
              width: highlighted ? 3 : 1.5,
            ),
          ),
          child: Center(
            child: Wrap(
              spacing: 8,
              children: [
                _ShapeToken(color: color, shape: shape, size: 27),
                _ShapeToken(color: color, shape: shape, size: 27),
              ],
            ),
          ),
        ),
      );
}

class _MultiAttributeSortingBoard extends StatefulWidget {
  const _MultiAttributeSortingBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_MultiAttributeSortingBoard> createState() => _MultiAttributeSortingBoardState();
}

class _MultiAttributeSortingBoardState extends State<_MultiAttributeSortingBoard>
    with _ChoiceSubmitter<_MultiAttributeSortingBoard> {
  final Set<int> _placed = <int>{};

  Future<void> _drop({
    required _TaskChoices choices,
    required int item,
    required int bin,
    required List<int> targets,
  }) async {
    if (isSubmitting || _placed.contains(item)) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    if (targets[item] != bin) {
      await submitChoice(widget.onChoice, choices.incorrectAt(bin));
      return;
    }

    setState(() => _placed.add(item));
    if (_placed.length != targets.length) return;

    final solved = await submitChoice(widget.onChoice, choices.correct);
    if (mounted && !solved) setState(_placed.clear);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final colors = [palette.primary, palette.secondary, palette.tertiary];
    const shapes = [_TokenShape.circle, _TokenShape.square, _TokenShape.triangle];
    final itemTotal = math.max(3, math.min(5, 3 + widget.task.difficulty ~/ 3)).toInt();
    final targets = List<int>.generate(itemTotal, (index) => index % 3);
    return _BoardFrame(
      color: palette.tertiary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              3,
              (bin) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SortingBin(
                    color: colors[bin],
                    shape: shapes[bin],
                    highlight: widget.highlightTarget && bin == 0,
                    contents: List<int>.generate(itemTotal, (index) => index)
                        .where((item) => _placed.contains(item) && targets[item] == bin)
                        .map(
                          (item) => _ShapeToken(
                            color: colors[targets[item]],
                            shape: shapes[targets[item]],
                            size: 25,
                          ),
                        )
                        .toList(growable: false),
                    onItem: isSubmitting
                        ? null
                        : (item) => _drop(
                              choices: choices,
                              item: item,
                              bin: bin,
                              targets: targets,
                            ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              itemTotal,
              (item) {
                final target = targets[item];
                return Draggable<int>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _ShapeToken(color: colors[target], shape: shapes[target], size: 46),
                  ),
                  childWhenDragging: _ShapeToken(
                    color: colors[target],
                    shape: shapes[target],
                    size: 46,
                    faded: true,
                  ),
                  child: _ShapeToken(
                    color: colors[target],
                    shape: shapes[target],
                    size: 46,
                    faded: _placed.contains(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortingBin extends StatelessWidget {
  const _SortingBin({
    required this.color,
    required this.shape,
    required this.highlight,
    required this.contents,
    required this.onItem,
  });

  final Color color;
  final _TokenShape shape;
  final bool highlight;
  final List<Widget> contents;
  final ValueChanged<int>? onItem;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
        onWillAcceptWithDetails: (_) => onItem != null,
        onAcceptWithDetails: (details) => onItem?.call(details.data),
        builder: (context, candidates, rejected) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: candidates.isNotEmpty ? .23 : .09),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(12)),
            border: Border.all(
              color: color.withValues(alpha: highlight ? .94 : .4),
              width: highlight ? 3 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShapeToken(color: color, shape: shape, size: 28),
              Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: contents),
            ],
          ),
        ),
      );
}

class _SystemizingBoard extends StatefulWidget {
  const _SystemizingBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_SystemizingBoard> createState() => _SystemizingBoardState();
}

class _SystemizingBoardState extends State<_SystemizingBoard> with _ChoiceSubmitter<_SystemizingBoard> {
  int? _selected;

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    const shared = [Icons.directions_car_rounded, Icons.directions_bus_rounded, Icons.two_wheeler_rounded];
    const distractors = [
      Icons.pets_rounded,
      Icons.local_florist_rounded,
      Icons.home_rounded,
      Icons.restaurant_rounded,
      Icons.park_rounded,
    ];
    const belonging = Icons.directions_boat_rounded;
    return _BoardFrame(
      color: palette.primary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .62),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: [
                for (final icon in shared) Icon(icon, size: 43, color: palette.primary),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              choices.length,
              (index) => _ChoiceTile(
                color: palette.primary,
                selected: _selected == index,
                highlight: widget.highlightTarget && index == choices.correctIndex,
                onTap: isSubmitting ? null : () => _choose(choices, index),
                child: Icon(
                  index == choices.correctIndex ? belonging : distractors[index % distractors.length],
                  color: index == choices.correctIndex ? palette.primary : palette.secondary,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantitativeEstimationBoard extends StatefulWidget {
  const _QuantitativeEstimationBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_QuantitativeEstimationBoard> createState() => _QuantitativeEstimationBoardState();
}

class _QuantitativeEstimationBoardState extends State<_QuantitativeEstimationBoard>
    with _ChoiceSubmitter<_QuantitativeEstimationBoard> {
  Timer? _flashTimer;
  bool _flash = true;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _flashTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (_flash || isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final counts = List<int>.generate(choices.length, (index) {
      if (index == choices.correctIndex) return 10 + widget.task.difficulty % 3;
      return 4 + (index * 2) % 5;
    });
    return _BoardFrame(
      color: palette.tertiary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _flash ? 1 : .38,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 14,
              children: List.generate(
                choices.length,
                (index) => _ChoiceTile(
                  color: palette.tertiary,
                  size: const Size(118, 106),
                  selected: _selected == index,
                  highlight: !_flash && widget.highlightTarget && index == choices.correctIndex,
                  onTap: _flash || isSubmitting ? null : () => _choose(choices, index),
                  child: _DotCloud(
                    count: counts[index],
                    color: index.isEven ? palette.primary : palette.secondary,
                    size: 82,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: _flash ? .65 : 0,
            child: Icon(Icons.visibility_rounded, color: palette.tertiary.withValues(alpha: .85), size: 26),
          ),
        ],
      ),
    );
  }
}

class _PictureAssociationBoard extends StatefulWidget {
  const _PictureAssociationBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_PictureAssociationBoard> createState() => _PictureAssociationBoardState();
}

class _PictureAssociationBoardState extends State<_PictureAssociationBoard>
    with _ChoiceSubmitter<_PictureAssociationBoard> {
  int? _selected;

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    const distractors = [Icons.pets_rounded, Icons.directions_car_rounded, Icons.park_rounded, Icons.cloud_rounded];
    return _BoardFrame(
      color: palette.secondary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AssociationAnchor(color: palette.secondary),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              choices.length,
              (index) => _ChoiceTile(
                color: palette.secondary,
                selected: _selected == index,
                highlight: widget.highlightTarget && index == choices.correctIndex,
                onTap: isSubmitting ? null : () => _choose(choices, index),
                child: Icon(
                  index == choices.correctIndex ? Icons.palette_rounded : distractors[index % distractors.length],
                  size: 52,
                  color: index == choices.correctIndex ? palette.secondary : palette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationAnchor extends StatelessWidget {
  const _AssociationAnchor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 114,
        height: 94,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Icon(Icons.brush_rounded, color: color, size: 56),
      );
}

class _WordlessInferenceBoard extends StatefulWidget {
  const _WordlessInferenceBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_WordlessInferenceBoard> createState() => _WordlessInferenceBoardState();
}

class _WordlessInferenceBoardState extends State<_WordlessInferenceBoard>
    with _ChoiceSubmitter<_WordlessInferenceBoard> {
  int? _selected;

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    const distractors = [Icons.icecream_rounded, Icons.directions_run_rounded, Icons.celebration_rounded, Icons.pets_rounded];
    return _BoardFrame(
      color: palette.primary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StoryPanel(icon: Icons.cloud_rounded, color: palette.primary),
              Icon(Icons.arrow_forward_rounded, color: palette.primary.withValues(alpha: .6)),
              _StoryPanel(icon: Icons.person_rounded, color: palette.secondary),
              Icon(Icons.arrow_forward_rounded, color: palette.primary.withValues(alpha: .6)),
              _StoryPanel(icon: Icons.help_outline_rounded, color: palette.tertiary),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              choices.length,
              (index) => _ChoiceTile(
                color: palette.primary,
                selected: _selected == index,
                highlight: widget.highlightTarget && index == choices.correctIndex,
                onTap: isSubmitting ? null : () => _choose(choices, index),
                child: Icon(
                  index == choices.correctIndex ? Icons.umbrella_rounded : distractors[index % distractors.length],
                  size: 50,
                  color: index == choices.correctIndex ? palette.primary : palette.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 70,
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Icon(icon, color: color, size: 36),
      );
}

class _AnalogyMappingBoard extends StatefulWidget {
  const _AnalogyMappingBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_AnalogyMappingBoard> createState() => _AnalogyMappingBoardState();
}

class _AnalogyMappingBoardState extends State<_AnalogyMappingBoard> with _ChoiceSubmitter<_AnalogyMappingBoard> {
  int? _selected;

  Future<void> _choose(_TaskChoices choices, int index) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = index);
    final solved = await submitChoice(widget.onChoice, choices.at(index));
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    const distractors = [Icons.cloud_rounded, Icons.pets_rounded, Icons.home_rounded, Icons.directions_car_rounded];
    return _BoardFrame(
      color: palette.tertiary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnalogyStrip(
            left: Icons.egg_alt_rounded,
            right: Icons.flutter_dash_rounded,
            color: palette.primary,
          ),
          const SizedBox(height: 10),
          _AnalogyStrip(
            left: Icons.eco_rounded,
            right: Icons.help_outline_rounded,
            color: palette.secondary,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              choices.length,
              (index) => _ChoiceTile(
                color: palette.tertiary,
                selected: _selected == index,
                highlight: widget.highlightTarget && index == choices.correctIndex,
                onTap: isSubmitting ? null : () => _choose(choices, index),
                child: Icon(
                  index == choices.correctIndex ? Icons.local_florist_rounded : distractors[index % distractors.length],
                  color: index == choices.correctIndex ? palette.secondary : palette.primary,
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogyStrip extends StatelessWidget {
  const _AnalogyStrip({required this.left, required this.right, required this.color});

  final IconData left;
  final IconData right;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StoryPanel(icon: left, color: color),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: color.withValues(alpha: .62)),
          ),
          _StoryPanel(icon: right, color: color),
        ],
      );
}

class _CreativeStorytellingBoard extends StatefulWidget {
  const _CreativeStorytellingBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_CreativeStorytellingBoard> createState() => _CreativeStorytellingBoardState();
}

class _CreativeStorytellingBoardState extends State<_CreativeStorytellingBoard>
    with _ChoiceSubmitter<_CreativeStorytellingBoard> {
  final List<int?> _slots = <int?>[null, null, null];

  bool get _canFinish => _slots.whereType<int>().length == _slots.length;

  void _place(int item, int slot) {
    if (isSubmitting) return;
    setState(() {
      final oldSlot = _slots.indexOf(item);
      if (oldSlot >= 0) _slots[oldSlot] = null;
      _slots[slot] = item;
    });
  }

  Future<void> _finish() async {
    if (!_canFinish || isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    await submitChoice(widget.onChoice, _TaskChoices(widget.task).correct);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    const storyIcons = [
      Icons.person_rounded,
      Icons.pets_rounded,
      Icons.park_rounded,
      Icons.celebration_rounded,
      Icons.home_rounded,
    ];
    return _BoardFrame(
      color: palette.secondary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              _slots.length,
              (slot) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _StoryDropSlot(
                    item: _slots[slot],
                    iconForItem: (item) => storyIcons[item],
                    color: palette.secondary,
                    highlight: widget.highlightTarget && slot == 0,
                    onItem: isSubmitting ? null : (item) => _place(item, slot),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: List.generate(
              storyIcons.length,
              (item) => Draggable<int>(
                data: item,
                feedback: Material(
                  color: Colors.transparent,
                  child: _StoryToken(icon: storyIcons[item], color: palette.secondary, size: 48),
                ),
                childWhenDragging: _StoryToken(
                  icon: storyIcons[item],
                  color: palette.secondary,
                  size: 48,
                  faded: true,
                ),
                child: _StoryToken(
                  icon: storyIcons[item],
                  color: palette.secondary,
                  size: 48,
                  faded: _slots.contains(item),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: 'Continue picture story',
            child: GestureDetector(
              onTap: _canFinish && !isSubmitting ? _finish : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.secondary.withValues(alpha: _canFinish ? .92 : .18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: _canFinish ? Colors.white : palette.secondary.withValues(alpha: .5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryDropSlot extends StatelessWidget {
  const _StoryDropSlot({
    required this.item,
    required this.iconForItem,
    required this.color,
    required this.highlight,
    required this.onItem,
  });

  final int? item;
  final IconData Function(int item) iconForItem;
  final Color color;
  final bool highlight;
  final ValueChanged<int>? onItem;

  @override
  Widget build(BuildContext context) => DragTarget<int>(
        onWillAcceptWithDetails: (_) => onItem != null,
        onAcceptWithDetails: (details) => onItem?.call(details.data),
        builder: (context, candidates, rejected) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: candidates.isNotEmpty ? .22 : .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: highlight ? .94 : .34),
              width: highlight ? 3 : 1.5,
            ),
          ),
          child: item == null
              ? Icon(Icons.more_horiz_rounded, color: color.withValues(alpha: .42), size: 30)
              : Draggable<int>(
                  data: item!,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _StoryToken(icon: iconForItem(item!), color: color, size: 45),
                  ),
                  child: _StoryToken(icon: iconForItem(item!), color: color, size: 45),
                ),
        ),
      );
}

class _StoryToken extends StatelessWidget {
  const _StoryToken({
    required this.icon,
    required this.color,
    required this.size,
    this.faded = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool faded;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: faded ? .25 : 1,
        child: Container(
          width: size + 18,
          height: size + 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: size),
        ),
      );
}

class _WorkingMemoryBoard extends StatefulWidget {
  const _WorkingMemoryBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_WorkingMemoryBoard> createState() => _WorkingMemoryBoardState();
}

class _WorkingMemoryBoardState extends State<_WorkingMemoryBoard> with _ChoiceSubmitter<_WorkingMemoryBoard> {
  Timer? _previewTimer;
  int _previewIndex = 0;
  bool _previewing = true;
  final List<int> _entered = <int>[];

  List<int> get _sequence {
    final length = math.min(5, 3 + widget.task.difficulty ~/ 3).toInt();
    final start = (widget.task.id.length + widget.task.difficulty) % 9;
    return List<int>.generate(length, (index) => (start + index * 4) % 9);
  }

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  void _startPreview() {
    _previewTimer?.cancel();
    setState(() {
      _previewing = true;
      _previewIndex = 0;
      _entered.clear();
    });
    _previewTimer = Timer.periodic(
      Duration(milliseconds: widget.task.allowMotion ? 560 : 760),
      (timer) {
        if (!mounted) return;
        final next = _previewIndex + 1;
        if (next >= _sequence.length) {
          timer.cancel();
          setState(() => _previewing = false);
        } else {
          setState(() => _previewIndex = next);
        }
      },
    );
  }

  Future<void> _tapCell(_TaskChoices choices, int cell) async {
    if (_previewing || isSubmitting) return;
    final expected = _sequence[_entered.length];
    if (cell != expected) {
      if (widget.task.preferHaptics) HapticFeedback.selectionClick();
      final solved = await submitChoice(widget.onChoice, choices.incorrectAt(cell));
      if (mounted && !solved) setState(_entered.clear);
      return;
    }
    setState(() => _entered.add(cell));
    if (_entered.length != _sequence.length) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    final solved = await submitChoice(widget.onChoice, choices.correct);
    if (mounted && !solved) setState(_entered.clear);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final hintedCell = !_previewing && widget.highlightTarget && _entered.length < _sequence.length
        ? _sequence[_entered.length]
        : -1;
    return _BoardFrame(
      color: palette.primary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 250,
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              children: List.generate(
                9,
                (cell) => _MemoryCell(
                  key: ValueKey('memory-cell-$cell'),
                  color: palette.primary,
                  lit: _previewing && _sequence[_previewIndex] == cell,
                  selected: !_previewing && _entered.contains(cell),
                  highlighted: hintedCell == cell,
                  onTap: isSubmitting ? null : () => _tapCell(choices, cell),
                ),
              ),
            ),
          ),
          if (widget.task.visualRepetitionHelpful) ...[
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Replay lights',
              child: GestureDetector(
                onTap: isSubmitting ? null : _startPreview,
                child: Icon(Icons.visibility_rounded, color: palette.primary.withValues(alpha: .76), size: 31),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryCell extends StatelessWidget {
  const _MemoryCell({
    super.key,
    required this.color,
    required this.lit,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  final Color color;
  final bool lit;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: lit ? color : selected ? color.withValues(alpha: .44) : Colors.white.withValues(alpha: .68),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: highlighted ? .96 : .28),
                width: highlighted ? 3 : 1.3,
              ),
              boxShadow: lit ? [BoxShadow(color: color.withValues(alpha: .48), blurRadius: 13)] : null,
            ),
          ),
        ),
      );
}

class _VisualSceneMemoryBoard extends StatefulWidget {
  const _VisualSceneMemoryBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_VisualSceneMemoryBoard> createState() => _VisualSceneMemoryBoardState();
}

class _VisualSceneMemoryBoardState extends State<_VisualSceneMemoryBoard>
    with _ChoiceSubmitter<_VisualSceneMemoryBoard> {
  Timer? _sceneTimer;
  bool _remembering = true;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _showRememberingScene();
  }

  @override
  void dispose() {
    _sceneTimer?.cancel();
    super.dispose();
  }

  void _showRememberingScene() {
    _sceneTimer?.cancel();
    setState(() {
      _remembering = true;
      _selected = null;
    });
    _sceneTimer = Timer(
      Duration(milliseconds: widget.task.allowMotion ? 1050 : 1400),
      () {
        if (mounted) setState(() => _remembering = false);
      },
    );
  }

  Future<void> _tapObject(_TaskChoices choices, int object, int changedObject) async {
    if (_remembering || isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = object);
    final choice = object == changedObject ? choices.correct : choices.incorrectAt(object);
    final solved = await submitChoice(widget.onChoice, choice);
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final changedObject = (choices.correctIndex * 3 + widget.task.difficulty) % 4;
    return _BoardFrame(
      color: palette.secondary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MemoryScene(
            remembering: _remembering,
            changedObject: changedObject,
            selected: _selected,
            color: palette.secondary,
            accent: palette.tertiary,
            highlightChanged: !_remembering && widget.highlightTarget,
            onObject: isSubmitting ? null : (object) => _tapObject(choices, object, changedObject),
          ),
          if (widget.task.visualRepetitionHelpful) ...[
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'View picture again',
              child: GestureDetector(
                onTap: isSubmitting ? null : _showRememberingScene,
                child: Icon(Icons.replay_rounded, color: palette.secondary.withValues(alpha: .76), size: 30),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryScene extends StatelessWidget {
  const _MemoryScene({
    required this.remembering,
    required this.changedObject,
    required this.selected,
    required this.color,
    required this.accent,
    required this.highlightChanged,
    required this.onObject,
  });

  final bool remembering;
  final int changedObject;
  final int? selected;
  final Color color;
  final Color accent;
  final bool highlightChanged;
  final ValueChanged<int>? onObject;

  @override
  Widget build(BuildContext context) {
    const positions = <Alignment>[
      Alignment(-.72, -.54),
      Alignment(.64, -.5),
      Alignment(-.57, .54),
      Alignment(.66, .5),
    ];
    const original = <IconData>[
      Icons.directions_car_rounded,
      Icons.cloud_rounded,
      Icons.park_rounded,
      Icons.home_rounded,
    ];
    return Container(
      width: 300,
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .26)),
      ),
      child: Stack(
        children: List.generate(4, (index) {
          final changed = !remembering && index == changedObject;
          final icon = changed ? Icons.rocket_launch_rounded : original[index];
          return Align(
            alignment: positions[index],
            child: Semantics(
              button: onObject != null,
              child: GestureDetector(
                onTap: onObject == null ? null : () => onObject!(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 76,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (changed ? accent : color).withValues(alpha: selected == index ? .23 : .08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (changed ? accent : color).withValues(
                        alpha: highlightChanged && changed ? .98 : .18,
                      ),
                      width: highlightChanged && changed ? 3 : 1,
                    ),
                  ),
                  child: Icon(icon, color: changed ? accent : color, size: 42),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SustainedAttentionBoard extends StatefulWidget {
  const _SustainedAttentionBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_SustainedAttentionBoard> createState() => _SustainedAttentionBoardState();
}

class _SustainedAttentionBoardState extends State<_SustainedAttentionBoard>
    with _ChoiceSubmitter<_SustainedAttentionBoard> {
  Timer? _streamTimer;
  int _streamIndex = 0;

  int get _targetAt => 2 + widget.task.difficulty % 3;

  @override
  void initState() {
    super.initState();
    _streamTimer = Timer.periodic(
      Duration(milliseconds: widget.task.allowMotion ? 780 : 1100),
      (timer) {
        if (!mounted) return;
        if (_streamIndex >= _targetAt) {
          timer.cancel();
          return;
        }
        setState(() => _streamIndex += 1);
      },
    );
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  Future<void> _tapStream(_TaskChoices choices) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    final solved = await submitChoice(
      widget.onChoice,
      _streamIndex == _targetAt ? choices.correct : choices.incorrectAt(_streamIndex),
    );
    if (!mounted || solved) return;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    const distractors = [
      Icons.circle_rounded,
      Icons.square_rounded,
      Icons.change_history_rounded,
      Icons.hexagon_rounded,
      Icons.favorite_rounded,
    ];
    final isTarget = _streamIndex == _targetAt;
    final icon = isTarget ? Icons.star_rounded : distractors[_streamIndex % distractors.length];
    return _BoardFrame(
      color: palette.tertiary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.tertiary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.star_rounded, color: palette.tertiary, size: 31),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Moving picture',
            child: GestureDetector(
              onTap: isSubmitting ? null : () => _tapStream(choices),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 270,
                height: 138,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .67),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: palette.tertiary.withValues(
                      alpha: isTarget && widget.highlightTarget ? .98 : .25,
                    ),
                    width: isTarget && widget.highlightTarget ? 3 : 1.4,
                  ),
                  boxShadow: isTarget && widget.highlightTarget
                      ? [BoxShadow(color: palette.tertiary.withValues(alpha: .25), blurRadius: 15)]
                      : null,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  scale: isTarget ? 1.12 : .86 + (_streamIndex % 2) * .1,
                  child: Icon(icon, color: isTarget ? palette.tertiary : palette.primary, size: 68),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectiveAttentionBoard extends StatefulWidget {
  const _SelectiveAttentionBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_SelectiveAttentionBoard> createState() => _SelectiveAttentionBoardState();
}

class _SelectiveAttentionBoardState extends State<_SelectiveAttentionBoard>
    with _ChoiceSubmitter<_SelectiveAttentionBoard> {
  int? _selected;

  Future<void> _tapCell(_TaskChoices choices, int cell, int targetCell) async {
    if (isSubmitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selected = cell);
    final solved = await submitChoice(
      widget.onChoice,
      cell == targetCell ? choices.correct : choices.incorrectAt(cell),
    );
    if (mounted && !solved) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PlayPalette.forTask(widget.task);
    final choices = _TaskChoices(widget.task);
    final targetCell = (choices.correctIndex * 5 + widget.task.difficulty + 3) % 16;
    return _BoardFrame(
      color: palette.primary,
      highlightTarget: widget.highlightTarget,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: palette.primary, size: 36),
          const SizedBox(height: 14),
          SizedBox(
            width: 290,
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(
                16,
                (cell) {
                  final target = cell == targetCell;
                  final color = cell.isEven ? palette.primary : palette.secondary;
                  return Semantics(
                    button: true,
                    child: GestureDetector(
                      onTap: isSubmitting ? null : () => _tapCell(choices, cell, targetCell),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: _selected == cell ? .23 : .07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withValues(
                              alpha: target && widget.highlightTarget ? .98 : .12,
                            ),
                            width: target && widget.highlightTarget ? 3 : 1,
                          ),
                        ),
                        child: Icon(
                          target ? Icons.star_rounded : Icons.star_border_rounded,
                          color: target ? palette.primary : color.withValues(alpha: .74),
                          size: 33,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
