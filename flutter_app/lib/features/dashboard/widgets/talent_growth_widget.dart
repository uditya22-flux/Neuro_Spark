import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gen_ui_puzzle.dart';
import '../providers/sdui_controller.dart';
import '../services/gen_ui_service.dart';

class TalentGrowthWidget extends ConsumerStatefulWidget {
  const TalentGrowthWidget({super.key});

  @override
  ConsumerState<TalentGrowthWidget> createState() => _TalentGrowthWidgetState();
}

class _TalentGrowthWidgetState extends ConsumerState<TalentGrowthWidget> {
  String? _currentPuzzleId;
  final List<String> _userSequence = [];
  final List<String> _userSelection = [];
  bool _isSolved = false;

  void _resetPuzzle(GenUiPuzzle puzzle) {
    setState(() {
      _currentPuzzleId = puzzle.puzzleId;
      _userSequence.clear();
      _userSelection.clear();
      _isSolved = false;
    });
  }

  void _verifyAnswers(GenUiPuzzle puzzle, SensoryConfig sensoryConfig) {
    final correct = puzzle.challengeData.correctSequence;
    bool matches = false;

    if (puzzle.puzzleType == 'sequence') {
      if (_userSequence.length == correct.length) {
        matches = true;
        for (int i = 0; i < correct.length; i++) {
          if (_userSequence[i] != correct[i]) {
            matches = false;
            break;
          }
        }
      }
    } else {
      // Sorting or Matching
      if (_userSelection.length == correct.length) {
        matches = _userSelection.every((item) => correct.contains(item));
      }
    }

    if (matches) {
      setState(() {
        _isSolved = true;
      });
      // Trigger sensory chime and heavy vibration feedback
      if (!sensoryConfig.silentVisualGlowOnly) {
        try {
          if (sensoryConfig.useAudioChimes) {
            SystemSound.play(SystemSoundType.click);
          }
          if (sensoryConfig.useHeavyHaptics) {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
        } catch (_) {}
      }
    } else {
      // Fail feedback
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not quite right. Try sorting again!'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _userSequence.clear();
        _userSelection.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(genUiPuzzleProvider);
    final sduiState = ref.watch(sduiControllerProvider);
    final isAac = sduiState.isAacMode;
    final sensory = sduiState.sensoryConfig;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: puzzleAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading dynamic GenUI challenge...', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading challenge: $err'),
          ),
          data: (puzzle) {
            // Auto reset if new puzzle is injected from LLM GenUI endpoint
            if (_currentPuzzleId != puzzle.puzzleId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _resetPuzzle(puzzle);
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isAac)
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Icon(Icons.emoji_events_rounded, color: Theme.of(context).colorScheme.secondary, size: 28),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            puzzle.puzzleTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            puzzle.instructionText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    
                    // Reset Button
                    if (!_isSolved)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => _resetPuzzle(puzzle),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Success State or Active Play State
                if (_isSolved) ...[
                  // Success State Visuals
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Text(
                            puzzle.successState.visualReward,
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 10),
                          if (!isAac)
                            Text(
                              puzzle.successState.rewardText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _resetPuzzle(puzzle),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Play Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Visual Assets Row
                  if (puzzle.visualAssets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: puzzle.visualAssets.map((asset) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(asset, style: const TextStyle(fontSize: 28)),
                          );
                        }).toList(),
                      ),
                    ),

                  // Native Game Interface Mapper
                  if (puzzle.puzzleType == 'sequence') ...[
                    // --- SEQUENCING INTERFACE ---
                    if (_userSequence.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _userSequence.map((item) {
                            return Chip(
                              label: Text(item),
                              onDeleted: () {
                                setState(() {
                                  _userSequence.remove(item);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Options Selector Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: puzzle.challengeData.options
                          .where((opt) => !_userSequence.contains(opt))
                          .map((opt) {
                        return ActionChip(
                          label: Text(opt),
                          onPressed: () {
                            setState(() {
                              _userSequence.add(opt);
                            });
                            if (_userSequence.length == puzzle.challengeData.options.length) {
                              _verifyAnswers(puzzle, sensory);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    // --- SORTING & MATCHING INTERFACE ---
                    Column(
                      children: puzzle.challengeData.options.map((opt) {
                        final isSelected = _userSelection.contains(opt);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                            activeColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            tileColor: Theme.of(context).colorScheme.primary.withOpacity(0.02),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _userSelection.add(opt);
                                } else {
                                  _userSelection.remove(opt);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _userSelection.isEmpty ? null : () => _verifyAnswers(puzzle, sensory),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Verify Solution'),
                      ),
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
