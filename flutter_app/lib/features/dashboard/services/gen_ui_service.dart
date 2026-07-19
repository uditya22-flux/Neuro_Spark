import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gen_ui_puzzle.dart';
import '../providers/sdui_controller.dart';

class GenUiService {
  Future<GenUiPuzzle> fetchPuzzleForProfile(String fixation, List<String> abilities) async {
    // In a production app, we would make a HTTP POST request to Groq LLM endpoint:
    // e.g., headers: { 'Authorization': 'Bearer <GROQ_API_KEY>' }
    // body: { "model": "llama3-8b-8192", "messages": [{ "role": "user", "content": prompt }] }
    //
    // For this local hybrid verification, we simulate a low-latency (500ms) LLM round-trip:
    await Future.delayed(const Duration(milliseconds: 500));

    final theme = fixation.toLowerCase();

    if (theme.contains('space')) {
      return GenUiPuzzle.fromJson({
        'module_type': 'TalentGrowthPuzzle',
        'puzzle_id': 'puzzle_space_101',
        'puzzle_title': 'Solar Sequence',
        'puzzle_type': 'sequence',
        'instruction_text': 'Arrange planets from closest to farthest.',
        'visual_assets': ['🪐', '🚀', '🌠'],
        'challenge_data': {
          'target': 'farthest',
          'options': ['Mars', 'Earth', 'Jupiter'],
          'correct_sequence': ['Earth', 'Mars', 'Jupiter'],
        },
        'success_state': {
          'visual_reward': '🌌',
          'reward_text': 'Mission Success, Captain!',
        }
      });
    } else if (theme.contains('dino')) {
      return GenUiPuzzle.fromJson({
        'module_type': 'TalentGrowthPuzzle',
        'puzzle_id': 'puzzle_dino_202',
        'puzzle_title': 'Fossil Sorter',
        'puzzle_type': 'sorting',
        'instruction_text': 'Filter fossil pieces by meat-eater type.',
        'visual_assets': ['🦖', '🦕', '🦴'],
        'challenge_data': {
          'target': 'carnivore',
          'options': ['T-Rex Tooth', 'Triceratops Horn', 'Raptor Claw', 'Stegosaurus Plate'],
          'correct_sequence': ['T-Rex Tooth', 'Raptor Claw'],
        },
        'success_state': {
          'visual_reward': '🦖',
          'reward_text': 'Fossils categorized successfully!',
        }
      });
    } else if (theme.contains('train')) {
      return GenUiPuzzle.fromJson({
        'module_type': 'TalentGrowthPuzzle',
        'puzzle_id': 'puzzle_train_303',
        'puzzle_title': 'Railway Matcher',
        'puzzle_type': 'matching',
        'instruction_text': 'Match cargo units to Engine 9.',
        'visual_assets': ['🚂', '🚃', '🛤️'],
        'challenge_data': {
          'target': 'Steam-9',
          'options': ['Freight-9', 'Cargo-9', 'Passenger-5'],
          'correct_sequence': ['Freight-9', 'Cargo-9'],
        },
        'success_state': {
          'visual_reward': '🚂',
          'reward_text': 'Carriages coupled perfectly!',
        }
      });
    } else if (theme.contains('marine')) {
      return GenUiPuzzle.fromJson({
        'module_type': 'TalentGrowthPuzzle',
        'puzzle_id': 'puzzle_marine_404',
        'puzzle_title': 'Marine Classifier',
        'puzzle_type': 'sorting',
        'instruction_text': 'Select species native to abyssal zone.',
        'visual_assets': ['🦈', '🐠', '🌊'],
        'challenge_data': {
          'target': 'Abyssal',
          'options': ['Anglerfish', 'Dolphin', 'Blobfish', 'Clownfish'],
          'correct_sequence': ['Anglerfish', 'Blobfish'],
        },
        'success_state': {
          'visual_reward': '🐙',
          'reward_text': 'Abyssal species cataloged!',
        }
      });
    } else {
      // Coding logic
      return GenUiPuzzle.fromJson({
        'module_type': 'TalentGrowthPuzzle',
        'puzzle_id': 'puzzle_code_505',
        'puzzle_title': 'Logic Compiler',
        'puzzle_type': 'sequence',
        'instruction_text': 'Arrange blocks to run the function.',
        'visual_assets': ['💻', '⚡', '🧠'],
        'challenge_data': {
          'target': 'compile',
          'options': ["void main() {", "import 'dart:io';", "print('Ready'); }"],
          'correct_sequence': ["import 'dart:io';", "void main() {", "print('Ready'); }"],
        },
        'success_state': {
          'visual_reward': '🚀',
          'reward_text': 'Compile completed: Code compiled successfully!',
        }
      });
    }
  }
}

final genUiServiceProvider = Provider<GenUiService>((ref) {
  return GenUiService();
});

// Auto-refreshing FutureProvider that fetches the puzzle whenever the active profile changes
final genUiPuzzleProvider = FutureProvider<GenUiPuzzle>((ref) async {
  final sduiState = ref.watch(sduiControllerProvider);
  final fixation = sduiState.profile.interests.primaryHyperFixation;
  final abilities = sduiState.profile.interests.naturalAbilities;

  final service = ref.read(genUiServiceProvider);
  return service.fetchPuzzleForProfile(fixation, abilities);
});
