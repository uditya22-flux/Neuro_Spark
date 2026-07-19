class UserProfile {
  final String name;
  final int age;

  const UserProfile({
    required this.name,
    required this.age,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? 'Friend',
      age: json['age'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
      };
}

class VisualEnvironmentalAffinities {
  final String favoriteColor;
  final String favoritePlace;
  final String favoriteObject;

  const VisualEnvironmentalAffinities({
    required this.favoriteColor,
    required this.favoritePlace,
    required this.favoriteObject,
  });

  factory VisualEnvironmentalAffinities.fromJson(Map<String, dynamic> json) {
    return VisualEnvironmentalAffinities(
      favoriteColor: json['favorite_color'] as String? ?? 'blue',
      favoritePlace: json['favorite_place'] as String? ?? 'nature',
      favoriteObject: json['favorite_object'] as String? ?? 'blocks',
    );
  }

  Map<String, dynamic> toJson() => {
        'favorite_color': favoriteColor,
        'favorite_place': favoritePlace,
        'favorite_object': favoriteObject,
      };
}

class SensoryProfile {
  final String auditoryReaction;
  final String visualDistress;
  final String effectiveRegulationMethod;

  const SensoryProfile({
    required this.auditoryReaction,
    required this.visualDistress,
    required this.effectiveRegulationMethod,
  });

  factory SensoryProfile.fromJson(Map<String, dynamic> json) {
    return SensoryProfile(
      auditoryReaction: json['auditory_reaction'] as String? ?? 'neutral',
      visualDistress: json['visual_distress'] as String? ?? 'none',
      effectiveRegulationMethod: json['effective_regulation_method'] as String? ?? 'deep_pressure',
    );
  }

  Map<String, dynamic> toJson() => {
        'auditory_reaction': auditoryReaction,
        'visual_distress': visualDistress,
        'effective_regulation_method': effectiveRegulationMethod,
      };
}

class RoutineTransitions {
  final int transitionDifficultyScore;
  final String unexpectedChangeDistress;
  final String instructionProcessingPreference;

  const RoutineTransitions({
    required this.transitionDifficultyScore,
    required this.unexpectedChangeDistress,
    required this.instructionProcessingPreference,
  });

  factory RoutineTransitions.fromJson(Map<String, dynamic> json) {
    return RoutineTransitions(
      transitionDifficultyScore: json['transition_difficulty_score'] as int? ?? 1,
      unexpectedChangeDistress: json['unexpected_change_distress'] as String? ?? 'low',
      instructionProcessingPreference: json['instruction_processing_preference'] as String? ?? 'visual',
    );
  }

  Map<String, dynamic> toJson() => {
        'transition_difficulty_score': transitionDifficultyScore,
        'unexpected_change_distress': unexpectedChangeDistress,
        'instruction_processing_preference': instructionProcessingPreference,
      };
}

class StrengthsSpecialInterests {
  final List<String> naturalAbilities;
  final String primaryHyperFixation;
  final String problemSolvingApproach;

  const StrengthsSpecialInterests({
    required this.naturalAbilities,
    required this.primaryHyperFixation,
    required this.problemSolvingApproach,
  });

  factory StrengthsSpecialInterests.fromJson(Map<String, dynamic> json) {
    final rawAbilities = json['natural_abilities'] as List?;
    return StrengthsSpecialInterests(
      naturalAbilities: rawAbilities != null ? List<String>.from(rawAbilities) : [],
      primaryHyperFixation: json['primary_hyper_fixation'] as String? ?? 'coding',
      problemSolvingApproach: json['problem_solving_approach'] as String? ?? 'visual_mapping',
    );
  }

  Map<String, dynamic> toJson() => {
        'natural_abilities': naturalAbilities,
        'primary_hyper_fixation': primaryHyperFixation,
        'problem_solving_approach': problemSolvingApproach,
      };
}

class CommunicationEmotion {
  final String stressCommunicationStyle;
  final String emotionalInteroceptionLevel;

  const CommunicationEmotion({
    required this.stressCommunicationStyle,
    required this.emotionalInteroceptionLevel,
  });

  factory CommunicationEmotion.fromJson(Map<String, dynamic> json) {
    return CommunicationEmotion(
      stressCommunicationStyle: json['stress_communication_style'] as String? ?? 'standard_speech',
      emotionalInteroceptionLevel: json['emotional_interoception_level'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'stress_communication_style': stressCommunicationStyle,
        'emotional_interoception_level': emotionalInteroceptionLevel,
      };
}

class NeuroProfile {
  final UserProfile userProfile;
  final VisualEnvironmentalAffinities affinities;
  final SensoryProfile sensoryProfile;
  final RoutineTransitions routineTransitions;
  final StrengthsSpecialInterests interests;
  final CommunicationEmotion communicationEmotion;

  const NeuroProfile({
    required this.userProfile,
    required this.affinities,
    required this.sensoryProfile,
    required this.routineTransitions,
    required this.interests,
    required this.communicationEmotion,
  });

  factory NeuroProfile.fromJson(Map<String, dynamic> json) {
    return NeuroProfile(
      userProfile: UserProfile.fromJson(json['user_profile'] as Map<String, dynamic>? ?? {}),
      affinities: VisualEnvironmentalAffinities.fromJson(
          json['visual_environmental_affinities'] as Map<String, dynamic>? ?? {}),
      sensoryProfile: SensoryProfile.fromJson(json['sensory_profile'] as Map<String, dynamic>? ?? {}),
      routineTransitions: RoutineTransitions.fromJson(json['routine_transitions'] as Map<String, dynamic>? ?? {}),
      interests: StrengthsSpecialInterests.fromJson(json['strengths_special_interests'] as Map<String, dynamic>? ?? {}),
      communicationEmotion: CommunicationEmotion.fromJson(json['communication_emotion'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_profile': userProfile.toJson(),
        'visual_environmental_affinities': affinities.toJson(),
        'sensory_profile': sensoryProfile.toJson(),
        'routine_transitions': routineTransitions.toJson(),
        'strengths_special_interests': interests.toJson(),
        'communication_emotion': communicationEmotion.toJson(),
      };
}
