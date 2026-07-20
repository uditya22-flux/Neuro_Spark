import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_edge_service.dart';
import '../providers/sdui_controller.dart';
import 'gen_ui_parser.dart';

class GenerativeUiConsole extends ConsumerStatefulWidget {
  const GenerativeUiConsole({super.key});

  @override
  ConsumerState<GenerativeUiConsole> createState() => _GenerativeUiConsoleState();
}

class _GenerativeUiConsoleState extends ConsumerState<GenerativeUiConsole> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _generatedSchema;

  final List<String> _suggestions = [
    'I feel overwhelmed by noise',
    'I need a train junction tool',
    'Dinosaur dig-site specimens',
    'Generate logical algorithm blocks',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateUi(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedSchema = null;
    });

    final aiService = ref.read(aiEdgeServiceProvider);
    final schema = await aiService.generateUiFromPrompt(prompt);

    if (mounted) {
      setState(() {
        _generatedSchema = schema;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sduiState = ref.watch(sduiControllerProvider);
    final isAac = sduiState.isAacMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Console input card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAac)
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.secondary, size: 28),
                    ],
                  )
                else
                  Text(
                    'Gen UI Sensory Assistant',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                const SizedBox(height: 12),

                // Prompt Input TextField
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: isAac ? '🎨 🤖' : 'Describe what you need right now...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _generateUi(_promptController.text),
                    ),
                  ),
                  onSubmitted: _generateUi,
                ),
                const SizedBox(height: 12),

                // Prompt Suggestion Chips
                if (!isAac)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestions.map((suggestion) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                            onPressed: () {
                              _promptController.text = suggestion;
                              _generateUi(suggestion);
                            },
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Generated UI Area
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: _isLoading
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('AI compiling sensory interface...'),
                        ],
                      ),
                    ),
                  ),
                )
              : GenUiParser(schema: _generatedSchema ?? sduiState.dynamicGenUiSchema),
        ),
      ],
    );
  }
}
