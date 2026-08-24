import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/deepening_task_payload.dart';
import '../../../../models/intake_models.dart';
import '../../../dashboard/providers/sdui_controller.dart';
import 'task_instruction_widgets.dart';

class CalendarGeniusTaskWidget extends ConsumerStatefulWidget {
  final DeepeningTaskPayload payload;
  final Function({
    required double accuracy,
    required String response,
    required int errorCount,
  }) onSubmit;
  final VoidCallback onHintTriggered;

  const CalendarGeniusTaskWidget({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onHintTriggered,
  });

  @override
  ConsumerState<CalendarGeniusTaskWidget> createState() => _CalendarGeniusTaskWidgetState();
}

class _CalendarGeniusTaskWidgetState extends ConsumerState<CalendarGeniusTaskWidget> {
  String? _selectedDay;
  int _errorCount = 0;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Color _getPrimaryThemeColor() {
    switch (widget.payload.themeSkin) {
      case 'sage_green':
        return const Color(0xFF4A7C59);
      case 'pastel_dinosaur':
        return const Color(0xFF5B8CAE);
      case 'terracotta_train':
        return const Color(0xFFFF9F1C);
      case 'cosmic_space':
      default:
        return const Color(0xFF5C6BC0);
    }
  }

  void _handleSelectDay(String day) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = day;
    });
  }

  void _handleCheckAnswer() {
    if (_selectedDay == null) return;

    final instructionStyle = ref.read(sduiControllerProvider).instructionStyle;

    // The server deliberately withholds the answer key. Derive the visible
    // calendar answer locally for feedback; the server remains authoritative
    // when the response is submitted.
    final targetDate = widget.payload.taskData['target_date'] as String?;
    final correctAnswer = targetDate == null ? 'Monday' : _dayForDate(targetDate);
    final isCorrect = _selectedDay!.toLowerCase() == correctAnswer.toLowerCase();

    HapticFeedback.mediumImpact();

    final double accuracy;
    if (isCorrect) {
      accuracy = _errorCount == 0 ? 1.0 : (1.0 / (_errorCount + 1));
      showTaskFeedback(context, instructionStyle, advanced: true);
    } else {
      accuracy = 0.2;
      showTaskFeedback(context, instructionStyle, advanced: false);
    }

    widget.onSubmit(
      accuracy: accuracy,
      response: _selectedDay!,
      errorCount: _errorCount,
    );
  }

  String _dayForDate(String value) {
    try {
      final date = DateTime.parse(value).toUtc();
      const days = <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } catch (_) {
      return 'Monday';
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructionStyle = ref.watch(sduiControllerProvider.select((s) => s.instructionStyle));
    final themeColor = _getPrimaryThemeColor();
    final targetDate = widget.payload.taskData['target_date'] as String? ?? '2026-07-20';
    final visibleDays = widget.payload.taskData['visible_options'] is List
        ? (widget.payload.taskData['visible_options'] as List).map((value) => value.toString()).toList()
        : _daysOfWeek;
    final support = widget.payload.taskData['support'];
    final supportMessage = support is Map ? support['message'] as String? : null;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_month_rounded, color: themeColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendar Genius Puzzle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                    ),
                    Text(
                      'Layer ${widget.payload.layer} of ${widget.payload.totalLayers}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.lightbulb_outline_rounded, color: themeColor),
                onPressed: widget.onHintTriggered,
                tooltip: 'Request Support Ladder Hint',
              ),
            ],
          ),
          const Divider(height: 24),
          TaskInstructionPrompt(
            style: instructionStyle,
            prompt: widget.payload.prompt,
            icon: Icons.calendar_month_rounded,
            accentColor: themeColor,
          ),
          if (supportMessage != null) ...[
            const SizedBox(height: 12),
            Text(supportMessage, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_rounded, color: themeColor),
                const SizedBox(width: 8),
                Text(
                  'Target Date: $targetDate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleDays.map((day) {
              final isSelected = _selectedDay == day;
              return ChoiceChip(
                label: Text(day),
                selected: isSelected,
                selectedColor: themeColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : themeColor,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: themeColor.withOpacity(0.08),
                onSelected: (_) => _handleSelectDay(day),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TaskContinueButton(
            style: instructionStyle,
            onPressed: _selectedDay != null ? _handleCheckAnswer : null,
            accentColor: themeColor,
            textLabel: instructionStyle == InstructionStyle.simpleText
                ? 'Submit Task Answer'
                : 'Continue',
          ),
        ],
      ),
    );
  }
}
