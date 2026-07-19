class OnboardingState {
  final String realName;
  final int age;
  final String fatherName;
  final String motherName;
  final String siblingNames;

  final String favoriteColor;
  final String favoritePlace;
  final String favoriteObject;

  final String auditoryReaction; // "Seeks out noise", "Neutral", "Easily overwhelmed"
  final String visualDistress;   // "Yes frequently", "Sometimes", "Rarely"
  final String effectiveRegulationMethod; // "Deep pressure", "Ambient sounds", "Dim lighting", "Fidgeting"

  final double transitionDifficultyScore; // 1.0 - 5.0
  final bool unexpectedChangeDistress;
  final String instructionProcessingPreference; // "Step-by-step visual pictograms", "Short direct verbal cues", "Written checklists"

  final List<String> naturalAbilities; // Multi-select (max 3)
  final String primaryHyperFixation;
  final String problemSolvingApproach; // "Trial and error", "Observing first", "Categorizing and sorting"

  final String stressCommunicationStyle; // "Highly verbal", "Non-verbal", "Uses AAC devices", "Scripting/Echolalia"
  final String emotionalInteroceptionLevel; // "Usually", "Sometimes", "Rarely"

  const OnboardingState({
    this.realName = '',
    this.age = 8,
    this.fatherName = '',
    this.motherName = '',
    this.siblingNames = '',
    this.favoriteColor = '',
    this.favoritePlace = '',
    this.favoriteObject = '',
    this.auditoryReaction = 'Neutral',
    this.visualDistress = 'Rarely',
    this.effectiveRegulationMethod = 'Deep pressure',
    this.transitionDifficultyScore = 3.0,
    this.unexpectedChangeDistress = false,
    this.instructionProcessingPreference = 'Written checklists',
    this.naturalAbilities = const [],
    this.primaryHyperFixation = '',
    this.problemSolvingApproach = 'Observing first',
    this.stressCommunicationStyle = 'Highly verbal',
    this.emotionalInteroceptionLevel = 'Sometimes',
  });

  OnboardingState copyWith({
    String? realName,
    int? age,
    String? fatherName,
    String? motherName,
    String? siblingNames,
    String? favoriteColor,
    String? favoritePlace,
    String? favoriteObject,
    String? auditoryReaction,
    String? visualDistress,
    String? effectiveRegulationMethod,
    double? transitionDifficultyScore,
    bool? unexpectedChangeDistress,
    String? instructionProcessingPreference,
    List<String>? naturalAbilities,
    String? primaryHyperFixation,
    String? problemSolvingApproach,
    String? stressCommunicationStyle,
    String? emotionalInteroceptionLevel,
  }) {
    return OnboardingState(
      realName: realName ?? this.realName,
      age: age ?? this.age,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      siblingNames: siblingNames ?? this.siblingNames,
      favoriteColor: favoriteColor ?? this.favoriteColor,
      favoritePlace: favoritePlace ?? this.favoritePlace,
      favoriteObject: favoriteObject ?? this.favoriteObject,
      auditoryReaction: auditoryReaction ?? this.auditoryReaction,
      visualDistress: visualDistress ?? this.visualDistress,
      effectiveRegulationMethod: effectiveRegulationMethod ?? this.effectiveRegulationMethod,
      transitionDifficultyScore: transitionDifficultyScore ?? this.transitionDifficultyScore,
      unexpectedChangeDistress: unexpectedChangeDistress ?? this.unexpectedChangeDistress,
      instructionProcessingPreference: instructionProcessingPreference ?? this.instructionProcessingPreference,
      naturalAbilities: naturalAbilities ?? this.naturalAbilities,
      primaryHyperFixation: primaryHyperFixation ?? this.primaryHyperFixation,
      problemSolvingApproach: problemSolvingApproach ?? this.problemSolvingApproach,
      stressCommunicationStyle: stressCommunicationStyle ?? this.stressCommunicationStyle,
      emotionalInteroceptionLevel: emotionalInteroceptionLevel ?? this.emotionalInteroceptionLevel,
    );
  }

  Map<String, dynamic> toJson() {
    // Map text reactions/selections to corresponding lowercase engine parameters
    String mapAuditory(String val) {
      if (val == 'Seeks out noise') return 'seeks_out_noise';
      if (val == 'Easily overwhelmed') return 'easily_overwhelmed';
      return 'neutral';
    }

    String mapVisual(String val) {
      if (val == 'Yes frequently') return 'high';
      if (val == 'Sometimes') return 'sometimes';
      return 'rarely';
    }

    String mapReg(String val) {
      if (val == 'Ambient sounds') return 'ambient_sounds';
      if (val == 'Dim lighting') return 'dim_lighting';
      if (val == 'Fidgeting') return 'rhythmic_tapping'; // maps to tapping pad!
      return 'deep_pressure';
    }

    String mapInstr(String val) {
      if (val == 'Step-by-step visual pictograms') return 'pictograms';
      if (val == 'Short direct verbal cues') return 'verbal_cues';
      return 'written_checklists';
    }

    String mapProblemSolving(String val) {
      if (val == 'Trial and error') return 'trial_and_error';
      if (val == 'Categorizing and sorting') return 'categorizing_sorting';
      return 'observing_first';
    }

    String mapComm(String val) {
      if (val == 'Non-verbal') return 'non_verbal';
      if (val == 'Uses AAC devices') return 'uses_aac_devices';
      if (val == 'Scripting/Echolalia') return 'scripting_echolalia';
      return 'highly_verbal';
    }

    String mapInteroception(String val) {
      if (val == 'Usually') return 'high'; // maps to 'high'
      if (val == 'Rarely') return 'low';  // maps to 'low'
      return 'medium'; // maps to 'medium'
    }

    return {
      'user_profile': {
        'name': realName.isEmpty ? 'Friend' : realName,
        'age': age,
        'father_name': fatherName,
        'mother_name': motherName,
        'sibling_names': siblingNames,
      },
      'visual_environmental_affinities': {
        'favorite_color': favoriteColor.toLowerCase().contains('green')
            ? 'space_sage_green'
            : (favoriteColor.toLowerCase().contains('blue')
                ? 'muted_pastel_blue'
                : (favoriteColor.toLowerCase().contains('terracotta') || favoriteColor.toLowerCase().contains('red') || favoriteColor.toLowerCase().contains('orange')
                    ? 'terracotta'
                    : (favoriteColor.toLowerCase().contains('indigo') || favoriteColor.toLowerCase().contains('dark') || favoriteColor.toLowerCase().contains('purple')
                        ? 'deep_sea_indigo'
                        : 'sunflower_yellow'))),
        'favorite_place': favoritePlace.isEmpty ? 'Home' : favoritePlace,
        'favorite_object': favoriteObject.isEmpty ? 'Toy' : favoriteObject,
      },
      'sensory_profile': {
        'auditory_reaction': mapAuditory(auditoryReaction),
        'visual_distress': mapVisual(visualDistress),
        'effective_regulation_method': mapReg(effectiveRegulationMethod),
      },
      'routine_transitions': {
        'transition_difficulty_score': transitionDifficultyScore.toInt(),
        'unexpected_change_distress': unexpectedChangeDistress ? 'high' : 'low',
        'instruction_processing_preference': mapInstr(instructionProcessingPreference),
      },
      'strengths_special_interests': {
        'natural_abilities': naturalAbilities,
        'primary_hyper_fixation': primaryHyperFixation.isEmpty ? 'General' : primaryHyperFixation,
        'problem_solving_approach': mapProblemSolving(problemSolvingApproach),
      },
      'communication_emotion': {
        'stress_communication_style': mapComm(stressCommunicationStyle),
        'emotional_interoception_level': mapInteroception(emotionalInteroceptionLevel),
      },
    };
  }
}
