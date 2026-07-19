import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdui_controller.dart';

class VisualScheduleWidget extends ConsumerStatefulWidget {
  const VisualScheduleWidget({super.key});

  @override
  ConsumerState<VisualScheduleWidget> createState() => _VisualScheduleWidgetState();
}

class _VisualScheduleWidgetState extends ConsumerState<VisualScheduleWidget> {
  final List<bool> _completions = [true, false, false];

  @override
  Widget build(BuildContext context) {
    final sduiState = ref.watch(sduiControllerProvider);
    final profile = sduiState.profile;
    final interest = profile.interests.primaryHyperFixation.toLowerCase();
    final isAac = sduiState.isAacMode;
    final score = profile.routineTransitions.transitionDifficultyScore;

    // Define schedule tasks based on primary hyper-fixation theme
    List<Map<String, dynamic>> tasks;
    if (interest.contains('space')) {
      tasks = [
        {'title': 'Calibrate Deep Space Telescope', 'time': '08:00 AM', 'icon': Icons.settings_input_antenna_rounded},
        {'title': 'Verify Oxygen Flow Meters', 'time': '10:15 AM', 'icon': Icons.air_rounded},
        {'title': 'Compute Rocket Orbit Coordinates', 'time': '02:30 PM', 'icon': Icons.satellite_alt_rounded},
      ];
    } else if (interest.contains('dino')) {
      tasks = [
        {'title': 'Fossil Dusting & Inspection', 'time': '08:00 AM', 'icon': Icons.brush_rounded},
        {'title': 'Excavation Grid Soil Mapping', 'time': '10:15 AM', 'icon': Icons.map_rounded},
        {'title': 'Dinosaur Skeleton Sorting', 'time': '02:30 PM', 'icon': Icons.grid_view_rounded},
      ];
    } else if (interest.contains('train')) {
      tasks = [
        {'title': 'Locomotive Engine Warm-Up', 'time': '08:00 AM', 'icon': Icons.local_fire_department_rounded},
        {'title': 'Railway Signal Inspections', 'time': '10:15 AM', 'icon': Icons.traffic_rounded},
        {'title': 'Steam Valve Depressurization', 'time': '02:30 PM', 'icon': Icons.plumbing_rounded},
      ];
    } else if (interest.contains('marine')) {
      tasks = [
        {'title': 'Hydrophone Audio Calibration', 'time': '08:00 AM', 'icon': Icons.hearing_rounded},
        {'title': 'Coral Reef Acidity Measurements', 'time': '10:15 AM', 'icon': Icons.science_rounded},
        {'title': 'Submersible Deep Trench Dive', 'time': '02:30 PM', 'icon': Icons.waves_rounded},
      ];
    } else {
      tasks = [
        {'title': 'Define Main Coding Function', 'time': '08:00 AM', 'icon': Icons.code_rounded},
        {'title': 'Array Logic Debugging Session', 'time': '10:15 AM', 'icon': Icons.bug_report_rounded},
        {'title': 'Compile Block Code Script', 'time': '02:30 PM', 'icon': Icons.integration_instructions_rounded},
      ];
    }

    final isExpanded = score >= 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: isAac
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary, size: 28),
                          ],
                        )
                      : Text(
                          'Visual Routine',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                ),
                if (isExpanded && !isAac) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Structure Priority Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // If AAC Mode, render pictogram horizontal boxes with large clickable items
            if (isAac)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isDone = _completions[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _completions[index] = !_completions[index];
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDone ? Theme.of(context).colorScheme.primary : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clock symbol
                            Icon(Icons.schedule, size: 16, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                            const SizedBox(height: 6),
                            // Action symbol
                            Icon(task['icon'] as IconData, size: 36, color: isDone ? Theme.of(context).colorScheme.primary : Colors.white),
                            const SizedBox(height: 8),
                            // Checked symbol
                            Icon(
                              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 20,
                              color: isDone ? Theme.of(context).colorScheme.primary : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              // Standard visual list
              Column(
                children: List.generate(tasks.length, (index) {
                  final task = tasks[index];
                  final isDone = _completions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(
                          task['icon'] as IconData,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        task['title'] as String,
                        style: TextStyle(
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5)
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        task['time'] as String,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isDone,
                        activeColor: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        onChanged: (val) {
                          setState(() {
                            _completions[index] = val ?? false;
                          });
                        },
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
