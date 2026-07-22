import 'package:flutter/material.dart';
import '../../models/deepening_task_payload.dart';

class ChoicePatternTaskWidget extends StatefulWidget {
  final DeepeningTaskPayload payload;
  final Function({
    required double accuracy,
    required String response,
    required int errorCount,
  }) onSubmit;
  final VoidCallback onHintTriggered;

  const ChoicePatternTaskWidget({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onHintTriggered,
  });

  @override
  State<ChoicePatternTaskWidget> createState() => _ChoicePatternTaskWidgetState();
}

class _ChoicePatternTaskWidgetState extends State<ChoicePatternTaskWidget> {
  String? _selected;
  final _textController = TextEditingController();

  @override
  void didUpdateWidget(ChoicePatternTaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload.taskId != widget.payload.taskId) {
      setState(() {
        _selected = null;
        _textController.clear();
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawOptions = widget.payload.taskData['options'];
    final options = rawOptions is List
        ? rawOptions.map((option) => option.toString()).toList()
        : const <String>[];
    final support = widget.payload.taskData['support'];
    final supportMessage = support is Map ? support['message'] as String? : null;
    final response = options.isEmpty ? _textController.text.trim() : _selected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.extension_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pattern Explorer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: widget.onHintTriggered,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  tooltip: 'Ask for help',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.payload.prompt, style: Theme.of(context).textTheme.bodyLarge),
            if (supportMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(supportMessage),
              ),
            ],
            const SizedBox(height: 16),
            if (options.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) => ChoiceChip(
                  label: Text(option),
                  selected: _selected == option,
                  onSelected: (_) => setState(() => _selected = option),
                )).toList(),
              )
            else
              TextField(
                controller: _textController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Your answer'),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: response == null || response.isEmpty
                    ? null
                    : () => widget.onSubmit(
                      accuracy: 0,
                      response: response,
                      errorCount: 0,
                    ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
