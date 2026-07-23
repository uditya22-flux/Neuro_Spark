import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/procedural_puzzle_generator.dart';
import '../../providers/sandbox_controller.dart';
import 'dynamic_glass_container.dart';

class ConstellationMapperSandbox extends ConsumerStatefulWidget {
  final int difficultyTier;

  const ConstellationMapperSandbox({
    super.key,
    required this.difficultyTier,
  });

  @override
  ConsumerState<ConstellationMapperSandbox> createState() => _ConstellationMapperSandboxState();
}

class _ConstellationMapperSandboxState extends ConsumerState<ConstellationMapperSandbox> {
  late List<Point3D> _points;
  final Set<int> _clearedAnomalyIds = {};
  int _correctionsCount = 0;
  late Stopwatch _solveStopwatch;
  bool _isSolved = false;
  late int _seed;

  // 3D Orbit rotation angles
  double _angleX = 0.3;
  double _angleY = 0.4;

  @override
  void initState() {
    super.initState();
    _solveStopwatch = Stopwatch();
    _loadNewPuzzle();
  }

  @override
  void didUpdateWidget(covariant ConstellationMapperSandbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.difficultyTier != widget.difficultyTier) {
      _loadNewPuzzle();
    }
  }

  void _loadNewPuzzle() {
    _seed = DateTime.now().millisecondsSinceEpoch;
    _points = ProceduralPuzzleGenerator.generateConstellationPuzzle(
      pointCount: 20,
      anomalyCount: 3,
      difficultyTier: widget.difficultyTier,
      seed: _seed,
    );
    _clearedAnomalyIds.clear();
    _correctionsCount = 0;
    _isSolved = false;
    _solveStopwatch.reset();
    _solveStopwatch.start();
    setState(() {});
  }

  void _onTapPoint(Point3D pt) {
    if (_isSolved) return;

    if (pt.isAnomaly) {
      HapticFeedback.lightImpact();
      setState(() {
        _clearedAnomalyIds.add(pt.id);
      });

      final totalAnomalies = _points.where((p) => p.isAnomaly).length;
      if (_clearedAnomalyIds.length >= totalAnomalies) {
        _solveStopwatch.stop();
        setState(() {
          _isSolved = true;
        });

        ref.read(sandboxControllerProvider.notifier).recordAttempt(
              puzzleSeed: _seed,
              timeToSolveMs: _solveStopwatch.elapsedMilliseconds,
              correctionsCount: _correctionsCount,
            );

        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            _loadNewPuzzle();
          }
        });
      }
    } else {
      // Section 4.3: Tapping non-anomaly produces no negative feedback
      _correctionsCount++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAnomalies = _points.where((p) => p.isAnomaly).length;
    final remainingAnomalies = totalAnomalies - _clearedAnomalyIds.length;

    // Glassmorphism reveal mechanic: panel blur sharpens as child clears anomalies (Section 4.3)
    final double blurPx = max(4.0, 20.0 * (remainingAnomalies / max(1, totalAnomalies)));

    return Column(
      children: [
        DynamicGlassContainer(
          blurFactorPx: blurPx,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8CAE).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF5B8CAE), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constellation workshop',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn the sky map and tap the stars that need a little care ($remainingAnomalies remaining)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _angleY += details.delta.dx * 0.01;
                _angleX += details.delta.dy * 0.01;
              });
            },
            child: DynamicGlassContainer(
              blurFactorPx: blurPx,
              padding: EdgeInsets.zero,
              child: Container(
                color: const Color(0xFF14142B),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: _ConstellationPainter(
                        points: _points,
                        clearedAnomalyIds: _clearedAnomalyIds,
                        angleX: _angleX,
                        angleY: _angleY,
                      ),
                    ),
                    // Tap detection overlay
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                        return Stack(
                          children: _points.map((pt) {
                            if (_clearedAnomalyIds.contains(pt.id)) {
                              return const SizedBox.shrink();
                            }

                            // 3D Isometric rotation projection
                            final cosX = cos(_angleX);
                            final sinX = sin(_angleX);
                            final cosY = cos(_angleY);
                            final sinY = sin(_angleY);

                            final y1 = pt.y * cosX - pt.z * sinX;
                            final z1 = pt.y * sinX + pt.z * cosX;
                            final x2 = pt.x * cosY + z1 * sinY;

                            final projX = center.dx + x2 * 0.95;
                            final projY = center.dy + y1 * 0.95;

                            return Positioned(
                              left: projX - 22,
                              top: projY - 22,
                              child: GestureDetector(
                                onTap: () => _onTapPoint(pt),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.transparent,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (_isSolved)
                      Center(
                        child: DynamicGlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, size: 64, color: Color(0xFF5B8CAE)),
                              const SizedBox(height: 12),
                              Text(
                                'The sky looks clear!',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'A new sky is forming...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<Point3D> points;
  final Set<int> clearedAnomalyIds;
  final double angleX;
  final double angleY;

  _ConstellationPainter({
    required this.points,
    required this.clearedAnomalyIds,
    required this.angleX,
    required this.angleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cosX = cos(angleX);
    final sinX = sin(angleX);
    final cosY = cos(angleY);
    final sinY = sin(angleY);

    final projected = <Offset>[];

    for (final pt in points) {
      final y1 = pt.y * cosX - pt.z * sinX;
      final z1 = pt.y * sinX + pt.z * cosX;
      final x2 = pt.x * cosY + z1 * sinY;

      final projX = center.dx + x2 * 0.95;
      final projY = center.dy + y1 * 0.95;
      projected.add(Offset(projX, projY));
    }

    // Draw connecting star lines
    final linePaint = Paint()
      ..color = const Color(0xFF5B8CAE).withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (int i = 0; i < projected.length - 1; i++) {
      if (i % 2 == 0) {
        canvas.drawLine(projected[i], projected[i + 1], linePaint);
      }
    }

    // Draw star points
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (clearedAnomalyIds.contains(pt.id)) continue;

      final offset = projected[i];
      final isAnomaly = pt.isAnomaly;

      final paint = Paint()
        ..color = isAnomaly ? const Color(0xFFFF9F1C) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, isAnomaly ? 6.5 : 4.5, paint);

      if (isAnomaly) {
        final glowPaint = Paint()
          ..color = const Color(0xFFFF9F1C).withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(offset, 12, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) => true;
}
