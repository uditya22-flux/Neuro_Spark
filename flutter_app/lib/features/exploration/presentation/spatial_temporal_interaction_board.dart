import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/exploration_models.dart';

/// Word-free, direct-manipulation activities for the spatial and temporal
/// sectors of the Layer 1 catalogue.
///
/// The issued [PuzzleSpec] remains the source of truth for completion. The
/// visuals in this file only decide how a child can make an opaque option
/// choice: they never render option IDs, prompt text, a score, or an inferred
/// result. Unsupported tasks intentionally render nothing so callers can
/// retain their existing generic board as a fallback.
class SpatialTemporalInteractionBoard extends StatelessWidget {
  const SpatialTemporalInteractionBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final FutureOr<bool> Function(String choice) onChoice;

  static const Set<PlayMechanic> supportedMechanics = {
    PlayMechanic.mentalRotation,
    PlayMechanic.visualPatternCompletion,
    PlayMechanic.pointCloudAnomalyDetection,
    PlayMechanic.mapRouteNavigation,
    PlayMechanic.visualSpatialConstruction,
    PlayMechanic.chronologicalSequencing,
    PlayMechanic.narrativeEventOrdering,
    PlayMechanic.causeAndEffectChains,
    PlayMechanic.rhythmicMotorSequencing,
    PlayMechanic.proceduralSequencing,
  };

  /// Allows a dispatcher to use this board only for the mechanics it owns.
  static bool supports(PuzzleSpec task) =>
      task.mechanics.length == 1 &&
      supportedMechanics.contains(task.mechanics.single);

  static bool supportsMechanic(PlayMechanic mechanic) =>
      supportedMechanics.contains(mechanic);

  @override
  Widget build(BuildContext context) {
    if (!supports(task)) return const SizedBox.shrink();

    final mechanic = task.mechanics.single;
    return switch (mechanic) {
      PlayMechanic.mentalRotation => _MentalRotationBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.visualPatternCompletion => _VisualPatternBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.pointCloudAnomalyDetection => _PointCloudBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.mapRouteNavigation => _RouteNavigationBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.visualSpatialConstruction => _SpatialConstructionBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.chronologicalSequencing => _SequenceOrderBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
          kind: _SequenceKind.cycle,
        ),
      PlayMechanic.narrativeEventOrdering => _SequenceOrderBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
          kind: _SequenceKind.story,
        ),
      PlayMechanic.causeAndEffectChains => _CauseAndEffectBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.rhythmicMotorSequencing => _RhythmReplayBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
        ),
      PlayMechanic.proceduralSequencing => _SequenceOrderBoard(
          task: task,
          highlightTarget: highlightTarget,
          onChoice: onChoice,
          kind: _SequenceKind.procedure,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

typedef _ChoiceCallback = FutureOr<bool> Function(String choice);

Future<bool> _sendChoice(_ChoiceCallback callback, String choice) async =>
    await callback(choice);

List<String> _visibleOptions(PuzzleSpec task) {
  if (task.options.isEmpty) return const [];
  final requestedCount = task.itemCount.clamp(1, task.options.length).toInt();
  final visible = task.options.take(requestedCount).toList(growable: true);
  if (!visible.contains(task.correctOption)) {
    visible[visible.length - 1] = task.correctOption;
  }
  return visible;
}

int _correctIndex(PuzzleSpec task, List<String> options) {
  final index = options.indexOf(task.correctOption);
  return index < 0 ? 0 : index;
}

String? _wrongOption(PuzzleSpec task, List<String> options) {
  for (final option in options) {
    if (option != task.correctOption) return option;
  }
  return null;
}

List<Color> _paletteFor(PuzzleSpec task) {
  final colors = task.familiarColors.map(_colorFor).toList(growable: false);
  return colors.isEmpty
      ? const [
          Color(0xff5270a2),
          Color(0xffd76b5e),
          Color(0xffe3ad45),
          Color(0xff4e7a5d),
        ]
      : colors;
}

Color _colorFor(FamiliarColor color) => switch (color) {
      FamiliarColor.red => const Color(0xffc95c54),
      FamiliarColor.orange => const Color(0xffd7873e),
      FamiliarColor.yellow => const Color(0xffc89c2e),
      FamiliarColor.green => const Color(0xff4e7a5d),
      FamiliarColor.blue => const Color(0xff5270a2),
      FamiliarColor.purple => const Color(0xff7b609c),
      FamiliarColor.pink => const Color(0xffb56483),
    };

class _InteractionFrame extends StatelessWidget {
  const _InteractionFrame({
    required this.color,
    required this.highlighted,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Color color;
  final bool highlighted;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: color.withValues(alpha: highlighted ? .92 : .32),
            width: highlighted ? 4 : 2,
          ),
        ),
        child: child,
      );
}

class _TapTile extends StatelessWidget {
  const _TapTile({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: selected ? .88 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: selected ? .96 : .36),
                width: selected ? 4 : 2,
              ),
            ),
            child: child,
          ),
        ),
      );
}

// Spatial / visual ----------------------------------------------------------

class _MentalRotationBoard extends StatefulWidget {
  const _MentalRotationBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_MentalRotationBoard> createState() => _MentalRotationBoardState();
}

class _MentalRotationBoardState extends State<_MentalRotationBoard> {
  double _turns = 0;
  double _lastAngle = 0;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _MentalRotationBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _turns = 0;
      _submitting = false;
    }
  }

  void _start(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _lastAngle = math.atan2(details.localPosition.dy - center.dy,
        details.localPosition.dx - center.dx);
  }

  void _rotate(DragUpdateDetails details, Size size) {
    if (_submitting) return;
    final center = Offset(size.width / 2, size.height / 2);
    final current = math.atan2(details.localPosition.dy - center.dy,
        details.localPosition.dx - center.dx);
    var delta = current - _lastAngle;
    if (delta > math.pi) delta -= math.pi * 2;
    if (delta < -math.pi) delta += math.pi * 2;
    setState(() {
      _turns += delta / (math.pi * 2);
      _lastAngle = current;
    });
  }

  Future<void> _finish() async {
    if (_submitting) return;
    final options = _visibleOptions(widget.task);
    if (options.isEmpty) return;
    final normalized = ((_turns % 1) + 1) % 1;
    final choiceIndex = (normalized * options.length).round() % options.length;
    setState(() => _submitting = true);
    final solved = await _sendChoice(widget.onChoice, options[choiceIndex]);
    if (!mounted || solved) return;
    setState(() {
      _submitting = false;
      _turns = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    final accent = palette.first;
    final options = _visibleOptions(widget.task);
    final targetTurns = options.isEmpty
        ? 0.0
        : _correctIndex(widget.task, options) / options.length;
    return _InteractionFrame(
      color: accent,
      highlighted: widget.highlightTarget,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math
              .min(constraints.maxWidth.isFinite ? constraints.maxWidth : 250,
                  250.0)
              .toDouble();
          final size = Size(side, side);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: side * .92,
                    height: side * .92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: accent.withValues(alpha: .30), width: 3),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    child: Opacity(
                      opacity: .45,
                      child: _RotationGlyph(
                        color: palette[1 % palette.length],
                        angle: targetTurns * math.pi * 2,
                        size: side * .30,
                      ),
                    ),
                  ),
                  GestureDetector(
                    key: const ValueKey('mental-rotation-wheel'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _start(details, size),
                    onPanUpdate: (details) => _rotate(details, size),
                    onPanEnd: (_) => _finish(),
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Center(
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 80),
                          turns: _turns,
                          child: _RotationGlyph(
                              color: accent, angle: 0, size: side * .42),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: Icon(Icons.rotate_right_rounded,
                        color: accent.withValues(alpha: .68), size: 32),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RotationGlyph extends StatelessWidget {
  const _RotationGlyph(
      {required this.color, required this.angle, required this.size});

  final Color color;
  final double angle;
  final double size;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: size * .08,
                top: size * .28,
                child: _block(size * .36, color.withValues(alpha: .90)),
              ),
              Positioned(
                left: size * .38,
                top: size * .28,
                child: _block(size * .36, color.withValues(alpha: .68)),
              ),
              Positioned(
                left: size * .38,
                top: 0,
                child: _block(size * .36, color),
              ),
            ],
          ),
        ),
      );

  Widget _block(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * .18),
          border:
              Border.all(color: Colors.white.withValues(alpha: .65), width: 2),
        ),
      );
}

class _VisualPatternBoard extends StatefulWidget {
  const _VisualPatternBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_VisualPatternBoard> createState() => _VisualPatternBoardState();
}

class _VisualPatternBoardState extends State<_VisualPatternBoard> {
  int? _selected;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _VisualPatternBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _selected = null;
      _submitting = false;
    }
  }

  Future<void> _choose(List<String> options, int index) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _selected = index;
    });
    final solved = await _sendChoice(widget.onChoice, options[index]);
    if (!mounted || solved) return;
    setState(() {
      _submitting = false;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    final options = _visibleOptions(widget.task);
    if (options.isEmpty) return const SizedBox.shrink();
    final correct = _correctIndex(widget.task, options);
    final expected = (correct + 4) % 5;
    final candidates = _patternCandidates(options.length, correct, expected);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractionFrame(
          color: palette.first,
          highlighted: widget.highlightTarget,
          child: Center(
            child: SizedBox(
              width: 214,
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (var index = 0; index < 9; index++)
                    _PatternCell(
                      color: palette[(index + expected) % palette.length],
                      missing: index == 8,
                      variant: (index ~/ 3 + index % 3 + expected) % 5,
                      highlighted: widget.highlightTarget && index == 8,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 13,
          runSpacing: 13,
          children: [
            for (var index = 0; index < options.length; index++)
              _TapTile(
                key: ValueKey('visual-pattern-choice-$index'),
                color: palette[index % palette.length],
                selected: _selected == index,
                onTap: _submitting ? null : () => _choose(options, index),
                child: _PatternGlyph(
                  variant: candidates[index],
                  color: palette[index % palette.length],
                  size: 44,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

List<int> _patternCandidates(int count, int correctIndex, int expected) {
  final result = List<int>.filled(count, 0);
  final used = <int>{expected};
  for (var index = 0; index < count; index++) {
    if (index == correctIndex) {
      result[index] = expected;
      continue;
    }
    var candidate = (expected + index + 1) % 5;
    while (used.contains(candidate)) {
      candidate = (candidate + 1) % 5;
    }
    used.add(candidate);
    result[index] = candidate;
  }
  return result;
}

class _PatternCell extends StatelessWidget {
  const _PatternCell({
    required this.color,
    required this.missing,
    required this.variant,
    required this.highlighted,
  });

  final Color color;
  final bool missing;
  final int variant;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: missing
              ? color.withValues(alpha: .05)
              : color.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: color.withValues(alpha: highlighted ? .95 : .42),
            width: highlighted ? 3 : 2,
          ),
        ),
        child: missing
            ? Icon(Icons.add_rounded,
                color: color.withValues(alpha: .65), size: 31)
            : _PatternGlyph(variant: variant, color: color, size: 34),
      );
}

class _PatternGlyph extends StatelessWidget {
  const _PatternGlyph(
      {required this.variant, required this.color, required this.size});

  final int variant;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => switch (variant % 5) {
        0 => Icon(Icons.circle_rounded, color: color, size: size),
        1 => Transform.rotate(
            angle: math.pi / 4,
            child:
                Container(width: size * .72, height: size * .72, color: color),
          ),
        2 => Icon(Icons.change_history_rounded, color: color, size: size),
        3 => Icon(Icons.star_rounded, color: color, size: size),
        _ => Container(
            width: size * .78,
            height: size * .78,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(size * .18)),
          ),
      };
}

class _PointCloudBoard extends StatefulWidget {
  const _PointCloudBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_PointCloudBoard> createState() => _PointCloudBoardState();
}

class _PointCloudBoardState extends State<_PointCloudBoard> {
  double _yaw = -.35;
  double _pitch = .15;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _PointCloudBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _yaw = -.35;
      _pitch = .15;
      _submitting = false;
    }
  }

  void _rotate(DragUpdateDetails details) {
    if (_submitting) return;
    setState(() {
      _yaw += details.delta.dx * .015;
      _pitch = (_pitch + details.delta.dy * .012).clamp(-1.1, 1.1).toDouble();
    });
  }

  Future<void> _tap(TapUpDetails details, Size size) async {
    if (_submitting) return;
    final points = _projectPointCloud(size: size, yaw: _yaw, pitch: _pitch);
    _ProjectedPoint? hit;
    for (final point in points.reversed) {
      if ((point.position - details.localPosition).distance <=
          point.radius + 13) {
        hit = point;
        break;
      }
    }
    if (hit == null) return;
    final options = _visibleOptions(widget.task);
    if (options.isEmpty) return;
    final choice = hit.isOutlier
        ? widget.task.correctOption
        : _wrongOption(widget.task, options);
    if (choice == null) return;
    setState(() => _submitting = true);
    final solved = await _sendChoice(widget.onChoice, choice);
    if (!mounted || solved) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    return _InteractionFrame(
      color: palette.first,
      highlighted: widget.highlightTarget,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math
              .min(constraints.maxWidth.isFinite ? constraints.maxWidth : 280,
                  280.0)
              .toDouble();
          final size = Size(side, side);
          return Center(
            child: GestureDetector(
              key: const ValueKey('point-cloud-canvas'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _rotate,
              onTapUp: (details) => _tap(details, size),
              child: CustomPaint(
                size: size,
                painter: _PointCloudPainter(
                  yaw: _yaw,
                  pitch: _pitch,
                  regular: palette.first,
                  outlier: palette[1 % palette.length],
                  highlighted: widget.highlightTarget,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.position,
    required this.depth,
    required this.radius,
    required this.isOutlier,
  });

  final Offset position;
  final double depth;
  final double radius;
  final bool isOutlier;
}

const List<_Vector3> _cloudPoints = [
  _Vector3(-.72, -.42, -.24),
  _Vector3(-.44, -.72, .08),
  _Vector3(-.08, -.82, -.20),
  _Vector3(.34, -.72, .24),
  _Vector3(.68, -.36, -.16),
  _Vector3(-.82, .04, .20),
  _Vector3(-.48, .26, -.52),
  _Vector3(-.10, .10, .62),
  _Vector3(.28, .34, -.54),
  _Vector3(.66, .20, .38),
  _Vector3(-.28, .70, .14),
  _Vector3(.16, .92, .64),
  _Vector3(.52, .68, -.06),
  _Vector3(.82, .52, .18),
  _Vector3(-.72, .50, -.08),
  _Vector3(.06, -.26, -.76),
  _Vector3(.80, -.02, -.34),
  _Vector3(-.08, .84, -.32),
];

List<_ProjectedPoint> _projectPointCloud({
  required Size size,
  required double yaw,
  required double pitch,
}) {
  final center = Offset(size.width / 2, size.height / 2);
  final scale = math.min(size.width, size.height) * .34;
  final cosYaw = math.cos(yaw);
  final sinYaw = math.sin(yaw);
  final cosPitch = math.cos(pitch);
  final sinPitch = math.sin(pitch);
  return List<_ProjectedPoint>.generate(_cloudPoints.length, (index) {
    final source = _cloudPoints[index];
    final x = source.x * cosYaw - source.z * sinYaw;
    final z = source.x * sinYaw + source.z * cosYaw;
    final y = source.y * cosPitch - z * sinPitch;
    final depth = source.y * sinPitch + z * cosPitch;
    final perspective = .78 + (depth + 1) * .17;
    return _ProjectedPoint(
      position:
          center + Offset(x * scale * perspective, y * scale * perspective),
      depth: depth,
      radius: 4.5 + (depth + 1) * 3.4 + (index == 11 ? 4 : 0),
      isOutlier: index == 11,
    );
  })
    ..sort((a, b) => a.depth.compareTo(b.depth));
}

class _PointCloudPainter extends CustomPainter {
  const _PointCloudPainter({
    required this.yaw,
    required this.pitch,
    required this.regular,
    required this.outlier,
    required this.highlighted,
  });

  final double yaw;
  final double pitch;
  final Color regular;
  final Color outlier;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .42;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = regular.withValues(alpha: .20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 3 : 2,
    );
    for (final point
        in _projectPointCloud(size: size, yaw: yaw, pitch: pitch)) {
      final color = point.isOutlier ? outlier : regular;
      canvas.drawCircle(
        point.position,
        point.radius,
        Paint()
          ..color = color.withValues(
              alpha: point.isOutlier ? .98 : .32 + (point.depth + 1) * .18),
      );
      if (point.isOutlier) {
        canvas.drawCircle(
          point.position,
          point.radius + 5,
          Paint()
            ..color = color.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PointCloudPainter oldDelegate) =>
      oldDelegate.yaw != yaw ||
      oldDelegate.pitch != pitch ||
      oldDelegate.regular != regular ||
      oldDelegate.outlier != outlier ||
      oldDelegate.highlighted != highlighted;
}

class _RouteNavigationBoard extends StatefulWidget {
  const _RouteNavigationBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_RouteNavigationBoard> createState() => _RouteNavigationBoardState();
}

class _RouteNavigationBoardState extends State<_RouteNavigationBoard> {
  static const List<Offset> _route = [
    Offset(.12, .80),
    Offset(.34, .80),
    Offset(.34, .49),
    Offset(.66, .49),
    Offset(.66, .20),
    Offset(.88, .20),
  ];

  final List<Offset> _trail = [];
  int _nextWaypoint = 1;
  bool _dragging = false;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _RouteNavigationBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) _reset();
  }

  Offset _normalise(Offset point, Size size) =>
      Offset(point.dx / size.width, point.dy / size.height);

  void _start(DragStartDetails details, Size size) {
    if (_submitting) return;
    final point = _normalise(details.localPosition, size);
    if ((point - _route.first).distance > .15) {
      _miss();
      return;
    }
    setState(() {
      _dragging = true;
      _trail
        ..clear()
        ..add(point);
      _nextWaypoint = 1;
    });
  }

  void _move(DragUpdateDetails details, Size size) {
    if (!_dragging || _submitting) return;
    final point = _normalise(details.localPosition, size);
    final prior = _route[_nextWaypoint > 0 ? _nextWaypoint - 1 : 0];
    final next = _route[_nextWaypoint.clamp(0, _route.length - 1).toInt()];
    if (_distanceToSegment(point, prior, next) > .16) {
      _miss();
      return;
    }
    setState(() => _trail.add(point));
    if ((point - next).distance < .13) {
      _nextWaypoint++;
      if (_nextWaypoint >= _route.length) _complete();
    }
  }

  void _end() {
    if (!_dragging || _submitting) return;
    _reset();
  }

  Future<void> _complete() async {
    if (_submitting) return;
    final options = _visibleOptions(widget.task);
    if (options.isEmpty) return;
    setState(() => _submitting = true);
    final solved =
        await _sendChoice(widget.onChoice, widget.task.correctOption);
    if (!mounted || solved) return;
    setState(() {
      _submitting = false;
      _reset();
    });
  }

  Future<void> _miss() async {
    if (_submitting) return;
    final wrong = _wrongOption(widget.task, _visibleOptions(widget.task));
    if (wrong == null) {
      _reset();
      return;
    }
    setState(() => _submitting = true);
    await _sendChoice(widget.onChoice, wrong);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _reset();
    });
  }

  void _reset() {
    _dragging = false;
    _nextWaypoint = 1;
    _trail.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    return _InteractionFrame(
      color: palette.first,
      highlighted: widget.highlightTarget,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math
              .min(constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
                  360.0)
              .toDouble();
          final size = Size(width, width * .64);
          return Center(
            child: GestureDetector(
              key: const ValueKey('route-navigation-map'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => _start(details, size),
              onPanUpdate: (details) => _move(details, size),
              onPanEnd: (_) => _end(),
              onPanCancel: _end,
              child: CustomPaint(
                size: size,
                painter: _RouteMapPainter(
                  route: _route,
                  trail: List<Offset>.of(_trail),
                  color: palette.first,
                  secondary: palette[1 % palette.length],
                  highlightGoal: widget.highlightTarget,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final vector = end - start;
  final lengthSquared = vector.dx * vector.dx + vector.dy * vector.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final fraction =
      (((point - start).dx * vector.dx) + ((point - start).dy * vector.dy)) /
          lengthSquared;
  final nearest = start + vector * fraction.clamp(0.0, 1.0).toDouble();
  return (point - nearest).distance;
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter({
    required this.route,
    required this.trail,
    required this.color,
    required this.secondary,
    required this.highlightGoal,
  });

  final List<Offset> route;
  final List<Offset> trail;
  final Color color;
  final Color secondary;
  final bool highlightGoal;

  Offset _scale(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final outer =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22));
    canvas.drawRRect(outer, Paint()..color = color.withValues(alpha: .06));

    final wallPaint = Paint()
      ..color = secondary.withValues(alpha: .38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final walls = [
      [const Offset(.08, .10), const Offset(.78, .10)],
      [const Offset(.08, .10), const Offset(.08, .90)],
      [const Offset(.08, .90), const Offset(.46, .90)],
      [const Offset(.46, .90), const Offset(.46, .66)],
      [const Offset(.46, .66), const Offset(.91, .66)],
      [const Offset(.91, .66), const Offset(.91, .12)],
    ];
    for (final wall in walls) {
      canvas.drawLine(_scale(wall[0], size), _scale(wall[1], size), wallPaint);
    }

    final routePath = Path()
      ..moveTo(_scale(route.first, size).dx, _scale(route.first, size).dy);
    for (final point in route.skip(1)) {
      routePath.lineTo(_scale(point, size).dx, _scale(point, size).dy);
    }
    canvas.drawPath(
      routePath,
      Paint()
        ..color = color.withValues(alpha: .24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (trail.isNotEmpty) {
      final path = Path()
        ..moveTo(_scale(trail.first, size).dx, _scale(trail.first, size).dy);
      for (final point in trail.skip(1)) {
        path.lineTo(_scale(point, size).dx, _scale(point, size).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final start = _scale(route.first, size);
    final goal = _scale(route.last, size);
    canvas.drawCircle(start, 13, Paint()..color = color);
    canvas.drawCircle(
        start, 5, Paint()..color = Colors.white.withValues(alpha: .86));
    canvas.drawCircle(
      goal,
      highlightGoal ? 18 : 14,
      Paint()
        ..color = secondary.withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlightGoal ? 4 : 2,
    );
    final flag = Path()
      ..moveTo(goal.dx - 3, goal.dy + 14)
      ..lineTo(goal.dx - 3, goal.dy - 16)
      ..lineTo(goal.dx + 16, goal.dy - 10)
      ..lineTo(goal.dx - 3, goal.dy - 3)
      ..close();
    canvas.drawPath(flag, Paint()..color = secondary);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) =>
      oldDelegate.trail != trail ||
      oldDelegate.color != color ||
      oldDelegate.secondary != secondary ||
      oldDelegate.highlightGoal != highlightGoal;
}

class _SpatialConstructionBoard extends StatefulWidget {
  const _SpatialConstructionBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_SpatialConstructionBoard> createState() =>
      _SpatialConstructionBoardState();
}

class _SpatialConstructionBoardState extends State<_SpatialConstructionBoard> {
  final Map<int, int> _placements = {};
  Timer? _settleTimer;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _SpatialConstructionBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _settleTimer?.cancel();
      _placements.clear();
      _submitting = false;
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  void _place(int piece, int slot) {
    if (_submitting ||
        _placements.containsKey(slot) ||
        _placements.containsValue(piece)) {
      return;
    }
    setState(() => _placements[slot] = piece);
    if (_placements.length == 4) _scheduleFinalization();
  }

  void _removePlacement(int slot) {
    if (_submitting || !_placements.containsKey(slot)) return;
    _settleTimer?.cancel();
    setState(() => _placements.remove(slot));
  }

  bool get _isCompleteConstruction => _placements.length == 4;

  bool get _isCorrectConstruction =>
      _isCompleteConstruction &&
      List<int>.generate(4, (slot) => slot)
          .every((slot) => _placements[slot] == slot);

  void _scheduleFinalization() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _submitting || !_isCompleteConstruction) return;
      if (_isCorrectConstruction) {
        unawaited(_complete());
      } else {
        unawaited(_miss());
      }
    });
  }

  Future<void> _complete() async {
    if (_submitting) return;
    _settleTimer?.cancel();
    setState(() => _submitting = true);
    final solved =
        await _sendChoice(widget.onChoice, widget.task.correctOption);
    if (!mounted || solved) return;
    setState(() {
      _submitting = false;
      _placements.clear();
    });
  }

  Future<void> _miss() async {
    if (_submitting) return;
    final wrong = _wrongOption(widget.task, _visibleOptions(widget.task));
    if (wrong == null) return;
    _settleTimer?.cancel();
    setState(() => _submitting = true);
    await _sendChoice(widget.onChoice, wrong);
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    final accent = palette.first;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractionFrame(
          color: accent,
          highlighted: widget.highlightTarget,
          child: Center(
            child: SizedBox(
              width: 224,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var slot = 0; slot < 4; slot++)
                    _buildSlot(slot, palette),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var piece = 0; piece < 4; piece++)
              if (!_placements.containsValue(piece))
                _buildPiece(piece, palette),
          ],
        ),
      ],
    );
  }

  Widget _buildSlot(int slot, List<Color> palette) => DragTarget<int>(
        key: ValueKey('construction-slot-$slot'),
        onWillAcceptWithDetails: (_) => !_placements.containsKey(slot),
        onAcceptWithDetails: (details) => _place(details.data, slot),
        builder: (context, candidates, rejected) {
          final placed = _placements[slot];
          final active = candidates.isNotEmpty;
          final color = palette[slot % palette.length];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: placed == null ? null : () => _removePlacement(slot),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 106,
              height: 106,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(
                    alpha: placed == null ? (active ? .24 : .08) : .20),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(slot.isEven ? 28 : 8),
                  bottomRight: Radius.circular(slot.isEven ? 8 : 28),
                ),
                border: Border.all(
                    color: color.withValues(alpha: .75), width: active ? 4 : 2),
              ),
              child: placed == null
                  ? Icon(Icons.add_rounded,
                      color: color.withValues(alpha: .58), size: 32)
                  : _ConstructionPiece(piece: placed, color: color, size: 62),
            ),
          );
        },
      );

  Widget _buildPiece(int piece, List<Color> palette) {
    final color = palette[piece % palette.length];
    final child = _ConstructionPiece(piece: piece, color: color, size: 58);
    return LongPressDraggable<int>(
      key: ValueKey('construction-piece-$piece'),
      data: piece,
      feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: .82, child: child)),
      childWhenDragging: Opacity(opacity: .20, child: child),
      child: child,
    );
  }
}

class _ConstructionPiece extends StatelessWidget {
  const _ConstructionPiece(
      {required this.piece, required this.color, required this.size});

  final int piece;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .82),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(piece.isEven ? size * .43 : size * .10),
            bottomRight:
                Radius.circular(piece.isEven ? size * .10 : size * .43),
          ),
          border:
              Border.all(color: Colors.white.withValues(alpha: .72), width: 2),
        ),
        child: Icon(
          switch (piece) {
            0 => Icons.circle_rounded,
            1 => Icons.change_history_rounded,
            2 => Icons.star_rounded,
            _ => Icons.square_rounded,
          },
          color: Colors.white.withValues(alpha: .82),
          size: size * .46,
        ),
      );
}

// Temporal / sequential -----------------------------------------------------

enum _SequenceKind { cycle, story, procedure }

class _SequenceOrderBoard extends StatefulWidget {
  const _SequenceOrderBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
    required this.kind,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;
  final _SequenceKind kind;

  @override
  State<_SequenceOrderBoard> createState() => _SequenceOrderBoardState();
}

class _SequenceOrderBoardState extends State<_SequenceOrderBoard> {
  List<int> _order = [2, 0, 3, 1];
  Timer? _settleTimer;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _SequenceOrderBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id || oldWidget.kind != widget.kind) {
      _settleTimer?.cancel();
      _order = [2, 0, 3, 1];
      _submitting = false;
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  void _reorder(int oldIndex, int newIndex) {
    if (_submitting) return;
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final card = _order.removeAt(oldIndex);
      _order.insert(newIndex, card);
    });
    _scheduleFinalization();
  }

  void _scheduleFinalization() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || _submitting) return;
      if (_isCompleteOrder) {
        unawaited(_complete());
      } else {
        unawaited(_miss());
      }
    });
  }

  bool get _isCompleteOrder {
    for (var index = 0; index < _order.length; index++) {
      if (_order[index] != index) return false;
    }
    return true;
  }

  Future<void> _complete() async {
    if (_submitting) return;
    _settleTimer?.cancel();
    setState(() => _submitting = true);
    final solved =
        await _sendChoice(widget.onChoice, widget.task.correctOption);
    if (!mounted || solved) return;
    setState(() {
      _submitting = false;
      _order = [2, 0, 3, 1];
    });
  }

  Future<void> _miss() async {
    if (_submitting) return;
    final wrong = _wrongOption(widget.task, _visibleOptions(widget.task));
    if (wrong == null) return;
    _settleTimer?.cancel();
    setState(() => _submitting = true);
    final advanced = await _sendChoice(widget.onChoice, wrong);
    if (!mounted || advanced) return;
    setState(() {
      _submitting = false;
      _order = [2, 0, 3, 1];
    });
  }

  List<IconData> get _icons => switch (widget.kind) {
        _SequenceKind.cycle => const [
            Icons.grass_rounded,
            Icons.eco_rounded,
            Icons.local_florist_rounded,
            Icons.park_rounded,
          ],
        _SequenceKind.story => const [
            Icons.cloud_rounded,
            Icons.umbrella_rounded,
            Icons.water_drop_rounded,
            Icons.wb_sunny_rounded,
          ],
        _SequenceKind.procedure => const [
            Icons.water_drop_rounded,
            Icons.brush_rounded,
            Icons.menu_book_rounded,
            Icons.nights_stay_rounded,
          ],
      };

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    return _InteractionFrame(
      color: palette.first,
      highlighted: widget.highlightTarget,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SizedBox(
        height: 108,
        child: ReorderableListView(
          key: ValueKey('sequence-${widget.kind.name}'),
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onReorder: _reorder,
          children: [
            for (var index = 0; index < _order.length; index++)
              Padding(
                key: ValueKey(
                    'sequence-card-${widget.kind.name}-${_order[index]}'),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  enabled: !_submitting,
                  child: _SequenceCard(
                    icon: _icons[_order[index]],
                    color: palette[_order[index] % palette.length],
                    position: _order[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SequenceCard extends StatelessWidget {
  const _SequenceCard(
      {required this.icon, required this.color, required this.position});

  final IconData icon;
  final Color color;
  final int position;

  @override
  Widget build(BuildContext context) => Container(
        width: 78,
        height: 82,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .66), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: color, size: 39),
            Positioned(
              bottom: 7,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(
                  position + 1,
                  (_) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .76),
                        shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CauseAndEffectBoard extends StatefulWidget {
  const _CauseAndEffectBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_CauseAndEffectBoard> createState() => _CauseAndEffectBoardState();
}

class _CauseAndEffectBoardState extends State<_CauseAndEffectBoard> {
  int? _selected;
  bool _submitting = false;

  @override
  void didUpdateWidget(covariant _CauseAndEffectBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _selected = null;
      _submitting = false;
    }
  }

  Future<void> _choose(List<String> options, int index) async {
    if (_submitting) return;
    setState(() {
      _selected = index;
      _submitting = true;
    });
    final solved = await _sendChoice(widget.onChoice, options[index]);
    if (!mounted || solved) return;
    setState(() {
      _selected = null;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    final options = _visibleOptions(widget.task);
    if (options.isEmpty) return const SizedBox.shrink();
    final correct = _correctIndex(widget.task, options);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractionFrame(
          color: palette.first,
          highlighted: widget.highlightTarget,
          child: SizedBox(
            height: 142,
            child: TweenAnimationBuilder<double>(
              duration: widget.task.allowMotion
                  ? const Duration(milliseconds: 900)
                  : Duration.zero,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, progress, child) => Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 38 + progress * 102,
                    top: 45 + progress * 26,
                    child: Icon(Icons.sports_baseball_rounded,
                        color: palette.first, size: 34),
                  ),
                  Positioned(
                    right: 36,
                    bottom: 22,
                    child: Transform.rotate(
                      angle: progress * .62,
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List<Widget>.generate(
                          3,
                          (index) => Container(
                            width: 19,
                            height: 36 + index * 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: palette[1 % palette.length]
                                  .withValues(alpha: .74),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      color: palette.first.withValues(alpha: .42), size: 36),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 13,
          runSpacing: 13,
          children: [
            for (var index = 0; index < options.length; index++)
              _TapTile(
                key: ValueKey('effect-choice-$index'),
                color: palette[index % palette.length],
                selected: _selected == index,
                onTap: _submitting ? null : () => _choose(options, index),
                child: _EffectOutcome(
                  kind: index == correct
                      ? _EffectOutcomeKind.fallenCups
                      : _EffectOutcomeKind.values[index % 2 + 1],
                  color: palette[index % palette.length],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _EffectOutcomeKind { fallenCups, ballStops, ballBounces }

class _EffectOutcome extends StatelessWidget {
  const _EffectOutcome({required this.kind, required this.color});

  final _EffectOutcomeKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (kind) {
        _EffectOutcomeKind.fallenCups => Transform.rotate(
            angle: .42,
            child: Icon(Icons.view_column_rounded, color: color, size: 46),
          ),
        _EffectOutcomeKind.ballStops => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_baseball_rounded, color: color, size: 31),
              const SizedBox(width: 4),
              Icon(Icons.block_rounded,
                  color: color.withValues(alpha: .62), size: 24),
            ],
          ),
        _EffectOutcomeKind.ballBounces => Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.sports_baseball_rounded, color: color, size: 34),
              Positioned(
                  bottom: 1,
                  child: Icon(Icons.keyboard_double_arrow_up_rounded,
                      color: color, size: 23)),
            ],
          ),
      };
}

class _RhythmReplayBoard extends StatefulWidget {
  const _RhythmReplayBoard({
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final _ChoiceCallback onChoice;

  @override
  State<_RhythmReplayBoard> createState() => _RhythmReplayBoardState();
}

class _RhythmReplayBoardState extends State<_RhythmReplayBoard> {
  static const List<int> _sequence = [0, 2, 1, 3];

  Timer? _demoTimer;
  Timer? _settleTimer;
  int? _flash;
  final List<int> _entered = <int>[];
  int? _lastTapped;
  bool _ready = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _showSequence();
  }

  @override
  void didUpdateWidget(covariant _RhythmReplayBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) _showSequence();
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _settleTimer?.cancel();
    super.dispose();
  }

  void _showSequence() {
    _demoTimer?.cancel();
    _settleTimer?.cancel();
    _entered.clear();
    _lastTapped = null;
    _submitting = false;
    if (!widget.task.allowMotion) {
      _flash = null;
      _ready = true;
      return;
    }
    _ready = false;
    _flash = _sequence.first;
    var tick = 1;
    _demoTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final beat = tick ~/ 2;
      if (beat >= _sequence.length) {
        timer.cancel();
        setState(() {
          _flash = null;
          _ready = true;
        });
        return;
      }
      setState(() => _flash = tick.isEven ? _sequence[beat] : null);
      tick++;
    });
  }

  Future<void> _tapPad(int index) async {
    if (!_ready || _submitting) return;
    _settleTimer?.cancel();
    setState(() {
      _lastTapped = index;
      if (_entered.length >= _sequence.length) {
        // The last beat can be changed during the settle window without
        // turning a near-complete response into an immediate failure.
        _entered[_entered.length - 1] = index;
      } else {
        _entered.add(index);
      }
    });
    if (_entered.length < _sequence.length) return;

    _settleTimer = Timer(const Duration(milliseconds: 1500), _submitSequence);
  }

  Future<void> _submitSequence() async {
    if (!mounted || _submitting || _entered.length != _sequence.length) {
      return;
    }
    final matchesSequence = List<bool>.generate(
      _sequence.length,
      (index) => _entered[index] == _sequence[index],
    ).every((matches) => matches);

    final choice = matchesSequence
        ? widget.task.correctOption
        : _wrongOption(widget.task, _visibleOptions(widget.task));
    if (choice == null) {
      setState(_showSequence);
      return;
    }
    setState(() => _submitting = true);
    final advanced = await _sendChoice(widget.onChoice, choice);
    if (!mounted || advanced) return;
    setState(_showSequence);
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.task);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InteractionFrame(
          color: palette.first,
          highlighted: widget.highlightTarget,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 46,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < _sequence.length; index++)
                      Container(
                        width: 17,
                        height: 18 + _sequence[index] * 7.0,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: palette[_sequence[index] % palette.length]
                              .withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (var index = 0; index < 4; index++)
                    _RhythmPad(
                      key: ValueKey('rhythm-pad-$index'),
                      color: palette[index % palette.length],
                      flashing: _flash == index,
                      pressed: _ready && _lastTapped == index,
                      onTap: () => _tapPad(index),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RhythmPad extends StatelessWidget {
  const _RhythmPad({
    super.key,
    required this.color,
    required this.flashing,
    required this.pressed,
    required this.onTap,
  });

  final Color color;
  final bool flashing;
  final bool pressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(
                alpha: flashing
                    ? .92
                    : pressed
                        ? .64
                        : .22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: color.withValues(alpha: .88), width: flashing ? 4 : 2),
            boxShadow: flashing
                ? [
                    BoxShadow(
                        color: color.withValues(alpha: .44),
                        blurRadius: 18,
                        spreadRadius: 3)
                  ]
                : null,
          ),
          child: Icon(Icons.circle_rounded,
              color: Colors.white.withValues(alpha: flashing ? .94 : .55),
              size: 22),
        ),
      );
}
