enum HyperFixationCategory {
  trainsVehicles,
  spaceAstronomy,
  geometryPatterns,
  animalsNature,
  clocksNumbers,
}

enum TactilePreference {
  prefersHaptics,
  noVibrations,
  neutral,
}

enum ThemePalette {
  calmDark,
  softPastel,
  mutedMonochrome,
}

enum AudioMode {
  completelyMuted,
  ambientBinauralSoft,
  subtleSoundEffectsOnly,
}

enum InstructionStyle {
  pureVisualGlowHints,
  pictorialGuideCards,
  simpleText,
  gentleAudioGuide,
}

class ISAAClinicalProfile {
  const ISAAClinicalProfile({
    this.socialRelationship = 3,
    this.emotionalResponsiveness = 3,
    this.speechCommunication = 3,
    this.behaviorPatterns = 3,
    this.sensoryAspects = 3,
    this.cognitiveComponent = 3,
  });

  final int socialRelationship;
  final int emotionalResponsiveness;
  final int speechCommunication;
  final int behaviorPatterns;
  final int sensoryAspects;
  final int cognitiveComponent;

  ISAAClinicalProfile copyWith({
    int? socialRelationship,
    int? emotionalResponsiveness,
    int? speechCommunication,
    int? behaviorPatterns,
    int? sensoryAspects,
    int? cognitiveComponent,
  }) {
    return ISAAClinicalProfile(
      socialRelationship: socialRelationship ?? this.socialRelationship,
      emotionalResponsiveness: emotionalResponsiveness ?? this.emotionalResponsiveness,
      speechCommunication: speechCommunication ?? this.speechCommunication,
      behaviorPatterns: behaviorPatterns ?? this.behaviorPatterns,
      sensoryAspects: sensoryAspects ?? this.sensoryAspects,
      cognitiveComponent: cognitiveComponent ?? this.cognitiveComponent,
    );
  }

  Map<String, dynamic> toJson() => {
        'social_relationship': socialRelationship,
        'emotional_responsiveness': emotionalResponsiveness,
        'speech_communication': speechCommunication,
        'behavior_patterns': behaviorPatterns,
        'sensory_aspects': sensoryAspects,
        'cognitive_component': cognitiveComponent,
      };

  factory ISAAClinicalProfile.fromJson(Map<String, dynamic> json) {
    int score(dynamic value, {int fallback = 3}) {
      final parsed = value is int ? value : int.tryParse('$value');
      if (parsed == null) return fallback;
      return parsed.clamp(1, 5);
    }

    return ISAAClinicalProfile(
      socialRelationship: score(json['social_relationship']),
      emotionalResponsiveness: score(json['emotional_responsiveness']),
      speechCommunication: score(json['speech_communication']),
      behaviorPatterns: score(json['behavior_patterns']),
      sensoryAspects: score(json['sensory_aspects']),
      cognitiveComponent: score(json['cognitive_component']),
    );
  }
}

class ParentQualitativeProfile {
  const ParentQualitativeProfile({
    this.childName = '',
    this.childAge = 8,
    this.hyperFixationCategory = HyperFixationCategory.spaceAstronomy,
    this.soundTriggers = const [],
    this.visualTriggers = const [],
    this.tactilePreference = TactilePreference.neutral,
  });

  final String childName;
  final int childAge;
  final HyperFixationCategory hyperFixationCategory;
  final List<String> soundTriggers;
  final List<String> visualTriggers;
  final TactilePreference tactilePreference;

  ParentQualitativeProfile copyWith({
    String? childName,
    int? childAge,
    HyperFixationCategory? hyperFixationCategory,
    List<String>? soundTriggers,
    List<String>? visualTriggers,
    TactilePreference? tactilePreference,
  }) {
    return ParentQualitativeProfile(
      childName: childName ?? this.childName,
      childAge: childAge ?? this.childAge,
      hyperFixationCategory: hyperFixationCategory ?? this.hyperFixationCategory,
      soundTriggers: soundTriggers ?? List<String>.from(this.soundTriggers),
      visualTriggers: visualTriggers ?? List<String>.from(this.visualTriggers),
      tactilePreference: tactilePreference ?? this.tactilePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        'child_name': childName,
        'child_age': childAge,
        'hyper_fixation_category': hyperFixationCategory.name,
        'sound_triggers': soundTriggers,
        'visual_triggers': visualTriggers,
        'tactile_preference': tactilePreference.name,
      };

  factory ParentQualitativeProfile.fromJson(Map<String, dynamic> json) {
    return ParentQualitativeProfile(
      childName: json['child_name'] as String? ?? '',
      childAge: (json['child_age'] as num?)?.toInt().clamp(7, 12) ?? 8,
      hyperFixationCategory: _enumByName(
        HyperFixationCategory.values,
        json['hyper_fixation_category'] as String?,
        HyperFixationCategory.spaceAstronomy,
      ),
      soundTriggers: List<String>.from(json['sound_triggers'] as List? ?? []),
      visualTriggers: List<String>.from(json['visual_triggers'] as List? ?? []),
      tactilePreference: _enumByName(
        TactilePreference.values,
        json['tactile_preference'] as String?,
        TactilePreference.neutral,
      ),
    );
  }
}

class GameEnvironmentConfig {
  const GameEnvironmentConfig({
    required this.themePalette,
    required this.audioMode,
    required this.hapticEnabled,
    required this.instructionStyle,
    required this.assetTheme,
    required this.strictGroundingEnforced,
    required this.startingDifficultyTier,
    this.pacingSlowed = false,
  });

  final ThemePalette themePalette;
  final AudioMode audioMode;
  final bool hapticEnabled;
  final InstructionStyle instructionStyle;
  final String assetTheme;
  final bool strictGroundingEnforced;
  final int startingDifficultyTier;
  final bool pacingSlowed;

  GameEnvironmentConfig copyWith({
    ThemePalette? themePalette,
    AudioMode? audioMode,
    bool? hapticEnabled,
    InstructionStyle? instructionStyle,
    String? assetTheme,
    bool? strictGroundingEnforced,
    int? startingDifficultyTier,
    bool? pacingSlowed,
  }) {
    return GameEnvironmentConfig(
      themePalette: themePalette ?? this.themePalette,
      audioMode: audioMode ?? this.audioMode,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      instructionStyle: instructionStyle ?? this.instructionStyle,
      assetTheme: assetTheme ?? this.assetTheme,
      strictGroundingEnforced: strictGroundingEnforced ?? this.strictGroundingEnforced,
      startingDifficultyTier: startingDifficultyTier ?? this.startingDifficultyTier,
      pacingSlowed: pacingSlowed ?? this.pacingSlowed,
    );
  }

  Map<String, dynamic> toJson() => {
        'theme_palette': themePalette.name,
        'audio_mode': audioMode.name,
        'haptic_enabled': hapticEnabled,
        'instruction_style': instructionStyle.name,
        'asset_theme': assetTheme,
        'strict_grounding_enforced': strictGroundingEnforced,
        'starting_difficulty_tier': startingDifficultyTier,
        'pacing_slowed': pacingSlowed,
      };

  factory GameEnvironmentConfig.fromJson(Map<String, dynamic> json) {
    return GameEnvironmentConfig(
      themePalette: _enumByName(
        ThemePalette.values,
        json['theme_palette'] as String?,
        ThemePalette.softPastel,
      ),
      audioMode: _enumByName(
        AudioMode.values,
        json['audio_mode'] as String?,
        AudioMode.subtleSoundEffectsOnly,
      ),
      hapticEnabled: json['haptic_enabled'] as bool? ?? false,
      instructionStyle: _enumByName(
        InstructionStyle.values,
        json['instruction_style'] as String?,
        InstructionStyle.pictorialGuideCards,
      ),
      assetTheme: json['asset_theme'] as String? ?? 'cosmic_space',
      strictGroundingEnforced: json['strict_grounding_enforced'] as bool? ?? true,
      startingDifficultyTier: (json['starting_difficulty_tier'] as num?)?.toInt().clamp(1, 3) ?? 2,
      pacingSlowed: json['pacing_slowed'] as bool? ?? false,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

String labelForHyperFixation(HyperFixationCategory category) {
  return switch (category) {
    HyperFixationCategory.trainsVehicles => 'Trains & Vehicles',
    HyperFixationCategory.spaceAstronomy => 'Space & Astronomy',
    HyperFixationCategory.geometryPatterns => 'Geometry & Patterns',
    HyperFixationCategory.animalsNature => 'Animals & Nature',
    HyperFixationCategory.clocksNumbers => 'Clocks & Numbers',
  };
}

String labelForThemePalette(ThemePalette palette) {
  return switch (palette) {
    ThemePalette.calmDark => 'Calm Dark',
    ThemePalette.softPastel => 'Soft Pastel',
    ThemePalette.mutedMonochrome => 'Muted Monochrome',
  };
}

String labelForAudioMode(AudioMode mode) {
  return switch (mode) {
    AudioMode.completelyMuted => 'Completely Muted',
    AudioMode.ambientBinauralSoft => 'Ambient Binaural (Soft)',
    AudioMode.subtleSoundEffectsOnly => 'Subtle Sound Effects Only',
  };
}

String labelForInstructionStyle(InstructionStyle style) {
  return switch (style) {
    InstructionStyle.pureVisualGlowHints => 'Pure Visual Glow Hints',
    InstructionStyle.pictorialGuideCards => 'Pictorial Guide Cards',
    InstructionStyle.simpleText => 'Simple Text',
    InstructionStyle.gentleAudioGuide => 'Gentle Audio Guide',
  };
}

const List<String> kSoundTriggerOptions = [
  'High-frequency beeps',
  'Sudden loud chime',
  'Background music loops',
  'Voice-over narration',
  'Applause or cheering',
];

const List<String> kVisualTriggerOptions = [
  'Rapid flashing',
  'High contrast red/yellow',
  'Parallax scrolling',
  'Floating UI elements',
  'Busy animated backgrounds',
];
