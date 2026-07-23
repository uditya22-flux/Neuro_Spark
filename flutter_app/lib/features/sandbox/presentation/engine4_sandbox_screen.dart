import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sandbox_controller.dart';
import 'widgets/calendar_genius_sandbox.dart';
import 'widgets/constellation_mapper_sandbox.dart';
import 'widgets/dynamic_glass_container.dart';

class Engine4SandboxScreen extends ConsumerStatefulWidget {
  final String userId;
  final String initialVerticalId;

  const Engine4SandboxScreen({
    super.key,
    required this.userId,
    this.initialVerticalId = 'calendar_genius',
  });

  @override
  ConsumerState<Engine4SandboxScreen> createState() => _Engine4SandboxScreenState();
}

class _Engine4SandboxScreenState extends ConsumerState<Engine4SandboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sandboxControllerProvider.notifier).startSession(
            userId: widget.userId,
            verticalId: widget.initialVerticalId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sandboxControllerProvider);
    final controller = ref.read(sandboxControllerProvider.notifier);
    final theme = Theme.of(context);

    final isCalendarTrack = state.activeVerticalId == 'calendar_genius';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open-ended play workshop'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Top Track Selector & Difficulty Tier Bar
                    DynamicGlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'calendar_genius',
                                  label: Text('Timeline workshop'),
                                  icon: Icon(Icons.calendar_today_rounded, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'constellation_mapper',
                                  label: Text('Constellation workshop'),
                                  icon: Icon(Icons.auto_awesome_rounded, size: 18),
                                ),
                              ],
                              selected: {state.activeVerticalId},
                              onSelectionChanged: (newSelection) {
                                final newVertical = newSelection.first;
                                controller.startSession(
                                  userId: widget.userId,
                                  verticalId: newVertical,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tune_rounded, size: 16, color: Color(0xFFFF9F1C)),
                                const SizedBox(width: 4),
                                Text(
                                  'Tier ${state.currentDifficultyTier}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF9F1C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Track Canvas Mounting
                    Expanded(
                      child: isCalendarTrack
                          ? CalendarGeniusSandbox(difficultyTier: state.currentDifficultyTier)
                          : ConstellationMapperSandbox(difficultyTier: state.currentDifficultyTier),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
