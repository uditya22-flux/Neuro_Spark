import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/procedural_puzzle_generator.dart';
import '../../providers/sandbox_controller.dart';
import 'dynamic_glass_container.dart';

class CalendarGeniusSandbox extends ConsumerStatefulWidget {
  final int difficultyTier;

  const CalendarGeniusSandbox({
    super.key,
    required this.difficultyTier,
  });

  @override
  ConsumerState<CalendarGeniusSandbox> createState() => _CalendarGeniusSandboxState();
}

class _CalendarGeniusSandboxState extends ConsumerState<CalendarGeniusSandbox> {
  late List<TimeBlock> _blocks;
  int _correctionsCount = 0;
  late Stopwatch _solveStopwatch;
  bool _isSolved = false;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _solveStopwatch = Stopwatch();
    _loadNewPuzzle();
  }

  @override
  void didUpdateWidget(covariant CalendarGeniusSandbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.difficultyTier != widget.difficultyTier) {
      _loadNewPuzzle();
    }
  }

  void _loadNewPuzzle() {
    _seed = DateTime.now().millisecondsSinceEpoch;
    _blocks = ProceduralPuzzleGenerator.generateTimelinePuzzle(
      count: 5,
      scrambleCount: 3,
      difficultyTier: widget.difficultyTier,
      seed: _seed,
    );
    _correctionsCount = 0;
    _isSolved = false;
    _solveStopwatch.reset();
    _solveStopwatch.start();
    setState(() {});
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isSolved) return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });

    _checkPuzzleState();
  }

  void _checkPuzzleState() {
    bool isChronological = true;
    for (int i = 0; i < _blocks.length - 1; i++) {
      if (_blocks[i].timestamp.isAfter(_blocks[i + 1].timestamp)) {
        isChronological = false;
        break;
      }
    }

    if (isChronological) {
      _solveStopwatch.stop();
      HapticFeedback.lightImpact();

      setState(() {
        _isSolved = true;
      });

      ref.read(sandboxControllerProvider.notifier).recordAttempt(
            puzzleSeed: _seed,
            timeToSolveMs: _solveStopwatch.elapsedMilliseconds,
            correctionsCount: _correctionsCount,
          );

      // Auto generate next puzzle after brief celebratory pause
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          _loadNewPuzzle();
        }
      });
    } else {
      _correctionsCount++;
      // No punitive feedback: gentle haptic feedback on move
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        DynamicGlassContainer(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF9F1C), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline workshop',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Drag the story blocks into an order that feels right',
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
          child: DynamicGlassContainer(
            padding: const EdgeInsets.all(12),
            child: _isSolved
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFFFF9F1C)),
                        const SizedBox(height: 12),
                        Text(
                          'The timeline is flowing!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF9F1C),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A new story is arriving...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _blocks.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final block = _blocks[index];
                      return Container(
                        key: ValueKey(block.id),
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                block.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.schedule_rounded,
                              size: 20,
                              color: theme.colorScheme.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
