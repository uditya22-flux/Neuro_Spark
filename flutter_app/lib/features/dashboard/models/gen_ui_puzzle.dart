class ChallengeData {
  final String target;
  final List<String> options;
  final List<String> correctSequence;

  const ChallengeData({
    required this.target,
    required this.options,
    required this.correctSequence,
  });

  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    return ChallengeData(
      target: json['target'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctSequence: List<String>.from(json['correct_sequence'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'target': target,
        'options': options,
        'correct_sequence': correctSequence,
      };
}

class SuccessState {
  final String visualReward;
  final String rewardText;

  const SuccessState({
    required this.visualReward,
    required this.rewardText,
  });

  factory SuccessState.fromJson(Map<String, dynamic> json) {
    return SuccessState(
      visualReward: json['visual_reward'] as String? ?? '🎉',
      rewardText: json['reward_text'] as String? ?? 'Super job!',
    );
  }

  Map<String, dynamic> toJson() => {
        'visual_reward': visualReward,
        'reward_text': rewardText,
      };
}

class GenUiPuzzle {
  final String moduleType;
  final String puzzleId;
  final String puzzleTitle;
  final String puzzleType; // 'sorting', 'sequence', 'matching'
  final String instructionText;
  final List<String> visualAssets;
  final ChallengeData challengeData;
  final SuccessState successState;

  const GenUiPuzzle({
    required this.moduleType,
    required this.puzzleId,
    required this.puzzleTitle,
    required this.puzzleType,
    required this.instructionText,
    required this.visualAssets,
    required this.challengeData,
    required this.successState,
  });

  factory GenUiPuzzle.fromJson(Map<String, dynamic> json) {
    return GenUiPuzzle(
      moduleType: json['module_type'] as String? ?? 'TalentGrowthPuzzle',
      puzzleId: json['puzzle_id'] as String? ?? '',
      puzzleTitle: json['puzzle_title'] as String? ?? 'Exciting Challenge',
      puzzleType: json['puzzle_type'] as String? ?? 'matching',
      instructionText: json['instruction_text'] as String? ?? 'Solve the puzzle!',
      visualAssets: List<String>.from(json['visual_assets'] ?? []),
      challengeData: ChallengeData.fromJson(json['challenge_data'] as Map<String, dynamic>? ?? {}),
      successState: SuccessState.fromJson(json['success_state'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'module_type': moduleType,
        'puzzle_id': puzzleId,
        'puzzle_title': puzzleTitle,
        'puzzle_type': puzzleType,
        'instruction_text': instructionText,
        'visual_assets': visualAssets,
        'challenge_data': challengeData.toJson(),
        'success_state': successState.toJson(),
      };
}
