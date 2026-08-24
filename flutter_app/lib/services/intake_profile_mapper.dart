import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/intake_models.dart';
import '../features/dashboard/models/neuro_profile.dart';

/// Converts dual-layer intake into the legacy [NeuroProfile] shape used by GenUI.
class IntakeProfileMapper {
  const IntakeProfileMapper();

  NeuroProfile toNeuroProfile({
    required ISAAClinicalProfile clinical,
    required ParentQualitativeProfile parent,
    required GameEnvironmentConfig config,
  }) {
    return NeuroProfile.fromJson(toProfileJson(
      clinical: clinical,
      parent: parent,
      config: config,
    ));
  }

  Map<String, dynamic> toProfileJson({
    required ISAAClinicalProfile clinical,
    required ParentQualitativeProfile parent,
    required GameEnvironmentConfig config,
  }) {
    final highSensory = clinical.sensoryAspects >= 4 || parent.visualTriggers.isNotEmpty;
    final soundSensitive =
        clinical.sensoryAspects >= 4 || parent.soundTriggers.isNotEmpty;

    return {
      'user_profile': {
        'name': parent.childName.isEmpty ? 'Friend' : parent.childName,
        'age': parent.childAge,
      },
      'visual_environmental_affinities': {
        'favorite_color': _favoriteColor(config),
        'favorite_place': _favoritePlace(parent.hyperFixationCategory),
        'favorite_object': _favoriteObject(parent.hyperFixationCategory),
      },
      'sensory_profile': {
        'auditory_reaction': soundSensitive ? 'highly_sensitive' : 'neutral',
        'visual_distress': highSensory ? 'high' : 'none',
        'effective_regulation_method': _regulationMethod(parent, config),
      },
      'routine_transitions': {
        'transition_difficulty_score': clinical.behaviorPatterns.clamp(1, 5),
        'unexpected_change_distress': clinical.behaviorPatterns >= 4 ? 'high' : 'low',
        'instruction_processing_preference': _instructionPreference(config.instructionStyle),
      },
      'strengths_special_interests': {
        'natural_abilities': _naturalAbilities(clinical),
        'primary_hyper_fixation': _hyperFixationText(parent.hyperFixationCategory),
        'problem_solving_approach': clinical.cognitiveComponent >= 4
            ? 'algorithmic'
            : 'visual_mapping',
      },
      'communication_emotion': {
        'stress_communication_style': _communicationStyle(clinical.speechCommunication),
        'emotional_interoception_level':
            clinical.emotionalResponsiveness >= 4 ? 'low' : 'medium',
      },
    };
  }

  String _favoriteColor(GameEnvironmentConfig config) {
    return switch (config.themePalette) {
      ThemePalette.calmDark => 'deep_sea_indigo',
      ThemePalette.mutedMonochrome => 'pastel_blue',
      ThemePalette.softPastel => switch (config.assetTheme) {
          'terracotta_train' => 'terracotta',
          'sage_nature' => 'sage_green',
          _ => 'pastel_blue',
        },
    };
  }

  String _favoritePlace(HyperFixationCategory category) {
    return switch (category) {
      HyperFixationCategory.trainsVehicles => 'railway_station',
      HyperFixationCategory.spaceAstronomy => 'space_station',
      HyperFixationCategory.geometryPatterns => 'pattern_studio',
      HyperFixationCategory.animalsNature => 'nature_trail',
      HyperFixationCategory.clocksNumbers => 'clock_tower',
    };
  }

  String _favoriteObject(HyperFixationCategory category) {
    return switch (category) {
      HyperFixationCategory.trainsVehicles => 'locomotive',
      HyperFixationCategory.spaceAstronomy => 'telescope',
      HyperFixationCategory.geometryPatterns => 'puzzle_tiles',
      HyperFixationCategory.animalsNature => 'fossil',
      HyperFixationCategory.clocksNumbers => 'calendar',
    };
  }

  String _regulationMethod(ParentQualitativeProfile parent, GameEnvironmentConfig config) {
    if (config.audioMode == AudioMode.completelyMuted) {
      if (config.hapticEnabled) {
        return parent.tactilePreference == TactilePreference.prefersHaptics
            ? 'rhythmic_tapping'
            : 'deep_pressure';
      }
      return 'visual_glow';
    }
    if (parent.tactilePreference == TactilePreference.prefersHaptics) {
      return 'rhythmic_tapping';
    }
    return 'audio_scanner';
  }

  String _instructionPreference(InstructionStyle style) {
    return switch (style) {
      InstructionStyle.pureVisualGlowHints => 'visual',
      InstructionStyle.pictorialGuideCards => 'pictograms',
      InstructionStyle.gentleAudioGuide => 'auditory',
      InstructionStyle.simpleText => 'textual',
    };
  }

  List<String> _naturalAbilities(ISAAClinicalProfile clinical) {
    final abilities = <String>[];
    if (clinical.cognitiveComponent >= 4) abilities.add('pattern_recognition');
    if (clinical.sensoryAspects <= 2) abilities.add('sensory_tolerance');
    if (clinical.socialRelationship <= 2) abilities.add('independent_play');
    if (abilities.isEmpty) abilities.add('exploration');
    return abilities;
  }

  String _hyperFixationText(HyperFixationCategory category) {
    return switch (category) {
      HyperFixationCategory.trainsVehicles => 'trains',
      HyperFixationCategory.spaceAstronomy => 'space_exploration',
      HyperFixationCategory.geometryPatterns => 'geometry_patterns',
      HyperFixationCategory.animalsNature => 'dinosaurs',
      HyperFixationCategory.clocksNumbers => 'clocks_numbers',
    };
  }

  String _communicationStyle(int speech) {
    if (speech >= 4) return 'aac_pictograms';
    if (speech <= 2) return 'written_text';
    return 'standard_speech';
  }
}

final intakeProfileMapperProvider = Provider<IntakeProfileMapper>((ref) {
  return const IntakeProfileMapper();
});
