import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/deepening_controller.dart';
import 'widgets/calendar_genius_task_widget.dart';
import 'widgets/constellation_mapper_task_widget.dart';
import 'widgets/choice_pattern_task_widget.dart';
import '../../dashboard/providers/sdui_controller.dart';

class DeepeningFunnelCanvas extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onCompleted;

  const DeepeningFunnelCanvas({
    super.key,
    required this.userId,
    required this.onCompleted,
  });

  @override
  ConsumerState<DeepeningFunnelCanvas> createState() => _DeepeningFunnelCanvasState();
}

class _DeepeningFunnelCanvasState extends ConsumerState<DeepeningFunnelCanvas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deepeningControllerProvider.notifier).fetchNextTask(widget.userId);
    });
  }

  Color _getSkinBackgroundColor(String skin) {
    switch (skin) {
      case 'sage_green':
        return const Color(0xFFF1F7F4);
      case 'pastel_dinosaur':
        return const Color(0xFFF0F4F8);
      case 'terracotta_train':
        return const Color(0xFFFAF5EF);
      case 'cosmic_space':
      default:
        return const Color(0xFF1E1E2C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deepeningControllerProvider);
    final sduiProfile = ref.watch(sduiControllerProvider).profile;
    final controller = ref.read(deepeningControllerProvider.notifier);

    if (state.isFunnelCompleted) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_rounded, size: 80, color: Color(0xFF4A7C59)),
                const SizedBox(height: 16),
                Text(
                  'Exploration Complete!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A7C59),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your exploration is complete. A guardian can review the recorded experience.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onCompleted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C59),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Proceed to Dashboard',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final task = state.currentTask;
    final skin = task?.themeSkin ?? sduiProfile?.themeSkin ?? 'cosmic_space';
    final bgColor = _getSkinBackgroundColor(skin);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Adaptive Deepening Funnel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: state.isLoading || task == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Adaptive engine compiling Layer task...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Layer Progress Indicator
                      LinearProgressIndicator(
                        value: task.layer / task.totalLayers,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Layer ${task.layer} of ${task.totalLayers}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          if (state.supportLadderLevel > 0)
                            Chip(
                              avatar: const Icon(Icons.help_center_rounded, size: 14),
                              label: Text('Support Ladder Lvl ${state.supportLadderLevel}'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dynamic task mounting based on vertical_id
                      if (task.verticalId == 'calendar_genius')
                        CalendarGeniusTaskWidget(
                          payload: task,
                          onSubmit: ({required accuracy, required response, required errorCount}) {
                            controller.submitResponse(
                              userId: widget.userId,
                              accuracy: accuracy,
                              responseText: response,
                              errorCount: errorCount,
                            );
                          },
                          onHintTriggered: controller.triggerSupportLadderHint,
                        )
                      else if (task.verticalId == 'constellation_mapper')
                        ConstellationMapperTaskWidget(
                          payload: task,
                          onSubmit: ({required accuracy, required response, required errorCount}) {
                            controller.submitResponse(
                              userId: widget.userId,
                              accuracy: accuracy,
                              responseText: response,
                              errorCount: errorCount,
                            );
                          },
                          onHintTriggered: controller.triggerSupportLadderHint,
                        )
                      else
                        ChoicePatternTaskWidget(
                          payload: task,
                          onSubmit: ({required accuracy, required response, required errorCount}) {
                            controller.submitResponse(
                              userId: widget.userId,
                              accuracy: accuracy,
                              responseText: response,
                              errorCount: errorCount,
                            );
                          },
                          onHintTriggered: controller.triggerSupportLadderHint,
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
