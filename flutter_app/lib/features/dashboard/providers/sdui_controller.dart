import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../models/neuro_profile.dart';

class SensoryConfig {
  final bool useAudioChimes;
  final bool useRhythmicHaptics;
  final bool useHeavyHaptics;
  final bool silentVisualGlowOnly;

  const SensoryConfig({
    this.useAudioChimes = true,
    this.useRhythmicHaptics = false,
    this.useHeavyHaptics = false,
    this.silentVisualGlowOnly = false,
  });
}

class SduiState {
  final NeuroProfile profile;
  final List<String> layoutOrder;
  final ThemeData themeData;
  final SensoryConfig sensoryConfig;
  final bool isAacMode;
  final String activeProfileName;
  final Map<String, dynamic> dynamicGenUiSchema;
  final InstructionStyle instructionStyle;
  final String themeSkin;
  final List<String> blacklistedSoundTriggers;
  final List<String> blacklistedVisualTriggers;
  final bool pacingSlowed;
  final bool strictGroundingEnforced;

  const SduiState({
    required this.profile,
    required this.layoutOrder,
    required this.themeData,
    required this.sensoryConfig,
    required this.isAacMode,
    required this.activeProfileName,
    required this.dynamicGenUiSchema,
    this.instructionStyle = InstructionStyle.pictorialGuideCards,
    this.themeSkin = 'cosmic_space',
    this.blacklistedSoundTriggers = const [],
    this.blacklistedVisualTriggers = const [],
    this.pacingSlowed = false,
    this.strictGroundingEnforced = true,
  });

  SduiState copyWith({
    NeuroProfile? profile,
    List<String>? layoutOrder,
    ThemeData? themeData,
    SensoryConfig? sensoryConfig,
    bool? isAacMode,
    String? activeProfileName,
    Map<String, dynamic>? dynamicGenUiSchema,
    InstructionStyle? instructionStyle,
    String? themeSkin,
    List<String>? blacklistedSoundTriggers,
    List<String>? blacklistedVisualTriggers,
    bool? pacingSlowed,
    bool? strictGroundingEnforced,
  }) {
    return SduiState(
      profile: profile ?? this.profile,
      layoutOrder: layoutOrder ?? this.layoutOrder,
      themeData: themeData ?? this.themeData,
      sensoryConfig: sensoryConfig ?? this.sensoryConfig,
      isAacMode: isAacMode ?? this.isAacMode,
      activeProfileName: activeProfileName ?? this.activeProfileName,
      dynamicGenUiSchema: dynamicGenUiSchema ?? this.dynamicGenUiSchema,
      instructionStyle: instructionStyle ?? this.instructionStyle,
      themeSkin: themeSkin ?? this.themeSkin,
      blacklistedSoundTriggers: blacklistedSoundTriggers ?? this.blacklistedSoundTriggers,
      blacklistedVisualTriggers: blacklistedVisualTriggers ?? this.blacklistedVisualTriggers,
      pacingSlowed: pacingSlowed ?? this.pacingSlowed,
      strictGroundingEnforced: strictGroundingEnforced ?? this.strictGroundingEnforced,
    );
  }
}

class SduiController extends StateNotifier<SduiState> {
  SduiController() : super(_initialState()) {
    // Initial state setup with Profile 1
    loadProfileByName('Profile 1: Space Explorer');
  }

  static Map<String, dynamic> generateDynamicGenUiSchema(NeuroProfile profile) {
    final name = profile.userProfile.name;
    final fixation = profile.interests.primaryHyperFixation.toLowerCase();
    final favPlace = profile.affinities.favoritePlace;
    final abilities = profile.interests.naturalAbilities;

    String mascot = 'rocket';
    String titlePrefix = 'Space Explorer';
    String challengeTitle = 'Orbital Exploration Path';
    if (fixation.contains('dinosaur') || fixation.contains('paleontology') || fixation.contains('fossil')) {
      mascot = 'dinosaur';
      titlePrefix = 'Dinosaur Excavator';
      challengeTitle = 'Fossil Dig Pattern Challenge';
    } else if (fixation.contains('train') || fixation.contains('railway') || fixation.contains('locomotive')) {
      mascot = 'train';
      titlePrefix = 'Train Conductor';
      challengeTitle = 'Metro Routing & Schedule Puzzle';
    } else if (fixation.contains('marine') || fixation.contains('ocean') || fixation.contains('aquarium')) {
      mascot = 'sea_turtle';
      titlePrefix = 'Aquarium Explorer';
      challengeTitle = 'Marine Ecosystem Explorer';
    } else if (fixation.contains('coding') || fixation.contains('microcontroller') || fixation.contains('logic')) {
      mascot = 'code';
      titlePrefix = 'Logic Coder';
      challengeTitle = 'Algorithmic Logic Challenge';
    }

    return {
      'type': 'column',
      'children': [
        {
          'type': 'mascot_header',
          'title': 'Hello, $name!',
          'subtitle': 'Personalized for your $fixation interests and $favPlace surroundings.',
          'mascot': mascot,
          'theme_label': '$titlePrefix Theme Active',
        },
        {'type': 'spacer', 'height': 16.0},
        {
          'type': 'challenge_card',
          'title': '$name\'s Talent Growth',
          'target_challenge': challengeTitle,
          'icon': mascot,
          'strengths': abilities.isNotEmpty ? abilities : ['Pattern Recognition', 'Systematic Logic'],
        },
        {'type': 'spacer', 'height': 16.0},
        {
          'type': 'breathing_engine',
          'technique': '4-4-4 Breathing Engine',
          'location': 'Calm Space at $favPlace',
          'audio_anchor': 'Soft Rain & Ambient Brown Noise (432Hz)',
        },
        {'type': 'spacer', 'height': 16.0},
        {
          'type': 'tactile_sound_pad',
          'title': 'Sensory Audio Pad',
          'subtitle': 'Designed for fidgeting & active auditory stimulation',
          'buttons': [
            {'label': 'Chime', 'icon': 'audio'},
            {'label': 'Vibrate', 'icon': 'music'},
            {'label': 'Focus', 'icon': 'check'},
          ],
        },
      ],
    };
  }

  static SduiState _initialState() {
    final defaultProfile = NeuroProfile.fromJson(mockProfiles['Profile 1: Space Explorer']!);
    return SduiState(
      profile: defaultProfile,
      layoutOrder: ['schedule', 'emotion', 'talent', 'sensory'],
      themeData: ThemeData.light(),
      sensoryConfig: const SensoryConfig(),
      isAacMode: false,
      activeProfileName: 'Profile 1: Space Explorer',
      dynamicGenUiSchema: generateDynamicGenUiSchema(defaultProfile),
    );
  }

  void loadProfileByName(String name) {
    final rawJson = mockProfiles[name];
    if (rawJson == null) return;

    final profile = NeuroProfile.fromJson(rawJson);

    // 1. Calculate Layout Order Algorithmically
    final layoutOrder = _calculateLayoutOrder(profile);

    // 2. Generate ThemeData Dynamically
    final themeData = _generateThemeData(profile);

    // 3. Configure Sensory Outputs
    final sensoryConfig = _generateSensoryConfig(profile);

    // 4. Configure Communication Preference
    final isAacMode = profile.communicationEmotion.stressCommunicationStyle == 'aac_pictograms';

    // 5. Generate Dynamic GenUI Schema
    final dynamicSchema = generateDynamicGenUiSchema(profile);

    state = SduiState(
      profile: profile,
      layoutOrder: layoutOrder,
      themeData: themeData,
      sensoryConfig: sensoryConfig,
      isAacMode: isAacMode,
      activeProfileName: name,
      dynamicGenUiSchema: dynamicSchema,
      themeSkin: profile.themeSkin,
    );
  }

  void loadCustomProfile(NeuroProfile customProfile) {
    try {
      // 1. Calculate Layout Order Algorithmically
      final layoutOrder = _calculateLayoutOrder(customProfile);

      // 2. Generate ThemeData Dynamically
      final themeData = _generateThemeData(customProfile);

      // 3. Configure Sensory Outputs
      final sensoryConfig = _generateSensoryConfig(customProfile);

      // 4. Configure Communication Preference
      final isAacMode = customProfile.communicationEmotion.stressCommunicationStyle == 'aac_pictograms' || 
                        customProfile.communicationEmotion.stressCommunicationStyle == 'uses_aac_devices';

      // 5. Generate Dynamic GenUI Schema
      final dynamicSchema = generateDynamicGenUiSchema(customProfile);

      state = SduiState(
        profile: customProfile,
        layoutOrder: layoutOrder,
        themeData: themeData,
        sensoryConfig: sensoryConfig,
        isAacMode: isAacMode,
        activeProfileName: 'Custom Profile: ${customProfile.userProfile.name}',
        dynamicGenUiSchema: dynamicSchema,
        themeSkin: customProfile.themeSkin,
      );
    } catch (e) {
      debugPrint('ERROR: Intake profile parsing or layout calculation failed: $e. Defaulting to safe baseline layout.');
      loadProfileByName('Profile 1: Space Explorer');
    }
  }

  /// Applies the dual-layer intake bundle across theme, sensory, layout, and GenUI.
  void applyGameEnvironment({
    required IntakeSessionBundle bundle,
    required NeuroProfile profile,
  }) {
    final config = bundle.config;
    final layoutOrder = _calculateLayoutOrderFromIsaa(bundle.clinical);
    final themeData = _generateThemeFromEnvironment(config, profile, bundle.parent);
    final sensoryConfig = _generateSensoryConfigFromEnvironment(config);
    final isAacMode = config.instructionStyle == InstructionStyle.pureVisualGlowHints ||
        config.instructionStyle == InstructionStyle.pictorialGuideCards;
    final dynamicSchema = generateDynamicGenUiSchema(profile);
    final skin = assetThemeToSkin(config.assetTheme);

    state = SduiState(
      profile: profile,
      layoutOrder: layoutOrder,
      themeData: themeData,
      sensoryConfig: sensoryConfig,
      isAacMode: isAacMode,
      activeProfileName: 'Intake: ${profile.userProfile.name}',
      dynamicGenUiSchema: dynamicSchema,
      instructionStyle: config.instructionStyle,
      themeSkin: skin,
      blacklistedSoundTriggers: List<String>.from(bundle.parent.soundTriggers),
      blacklistedVisualTriggers: List<String>.from(bundle.parent.visualTriggers),
      pacingSlowed: config.pacingSlowed,
      strictGroundingEnforced: config.strictGroundingEnforced,
    );
  }

  List<String> _calculateLayoutOrderFromIsaa(ISAAClinicalProfile clinical) {
    final components = ['schedule', 'emotion', 'talent', 'sensory'];
    final scores = <String, int>{
      'schedule': clinical.behaviorPatterns * 15 + clinical.socialRelationship * 8,
      'emotion': clinical.emotionalResponsiveness * 18,
      'talent': clinical.cognitiveComponent * 16,
      'sensory': clinical.sensoryAspects * 20,
    };
    components.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
    return components;
  }

  ThemeData _generateThemeFromEnvironment(
    GameEnvironmentConfig config,
    NeuroProfile profile,
    ParentQualitativeProfile parent,
  ) {
    final reduceMotion = config.pacingSlowed ||
        parent.visualTriggers.contains('Rapid flashing') ||
        parent.visualTriggers.contains('Parallax scrolling');
    final baseTheme = config.themePalette == ThemePalette.calmDark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
    final profileTheme = _generateThemeData(profile);
    final flatCards = config.strictGroundingEnforced ||
        parent.visualTriggers.contains('Floating UI elements');

    return profileTheme.copyWith(
      brightness: baseTheme.brightness,
      scaffoldBackgroundColor: baseTheme.scaffoldBackgroundColor,
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            })
          : profileTheme.pageTransitionsTheme,
      cardTheme: profileTheme.cardTheme?.copyWith(
        elevation: flatCards ? 0 : profileTheme.cardTheme?.elevation,
      ),
    );
  }

  SensoryConfig _generateSensoryConfigFromEnvironment(GameEnvironmentConfig config) {
    final muted = config.audioMode == AudioMode.completelyMuted;
    if (muted && config.instructionStyle == InstructionStyle.pureVisualGlowHints) {
      return SensoryConfig(
        useAudioChimes: false,
        useRhythmicHaptics: config.hapticEnabled,
        useHeavyHaptics: config.hapticEnabled,
        silentVisualGlowOnly: true,
      );
    }
    if (muted) {
      return SensoryConfig(
        useAudioChimes: false,
        useRhythmicHaptics: config.hapticEnabled,
        useHeavyHaptics: config.hapticEnabled,
        silentVisualGlowOnly: false,
      );
    }
    return SensoryConfig(
      useAudioChimes: config.audioMode == AudioMode.subtleSoundEffectsOnly,
      useRhythmicHaptics: config.hapticEnabled,
      useHeavyHaptics: false,
      silentVisualGlowOnly: false,
    );
  }

  Future<void> fetchActiveProfile() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await client
          .from('profiles')
          .select('generative_ui_parameters, updated_at')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return;

      final params = response['generative_ui_parameters'];
      if (params is Map<String, dynamic>) {
        final clinicalRaw = params['isaa_clinical'];
        final parentRaw = params['parent_qualitative'];
        final configRaw = params['game_environment'];

        if (clinicalRaw is Map && parentRaw is Map && configRaw is Map) {
          final bundle = IntakeSessionBundle(
            clinical: ISAAClinicalProfile.fromJson(Map<String, dynamic>.from(clinicalRaw)),
            parent: ParentQualitativeProfile.fromJson(Map<String, dynamic>.from(parentRaw)),
            config: GameEnvironmentConfig.fromJson(Map<String, dynamic>.from(configRaw)),
            childId: params['child_id'] as String?,
            persistedAt: response['updated_at'] != null
                ? DateTime.tryParse(response['updated_at'] as String)
                : null,
          );
          applyGameEnvironment(
            bundle: bundle,
            profile: toNeuroProfileFromBundle(bundle),
          );
          debugPrint('Loaded persisted intake profile for ${bundle.parent.childName}.');
          return;
        }

        final legacyProfile = params['profile_json'];
        if (legacyProfile is Map<String, dynamic>) {
          loadCustomProfile(NeuroProfile.fromJson(legacyProfile));
          return;
        }
      }

      debugPrint('No customized profile payload found in database. Relying on default.');
    } catch (e) {
      debugPrint('WARNING: Database profile fetch failed: $e. Fallback to default in-memory configs.');
    }
  }

  NeuroProfile toNeuroProfileFromBundle(IntakeSessionBundle bundle) {
    return NeuroProfile.fromJson({
      'user_profile': {
        'name': bundle.parent.childName.isEmpty ? 'Friend' : bundle.parent.childName,
        'age': bundle.parent.childAge,
      },
      'visual_environmental_affinities': {
        'favorite_color': bundle.config.themePalette == ThemePalette.calmDark
            ? 'deep_sea_indigo'
            : 'sage_green',
        'favorite_place': 'home',
        'favorite_object': bundle.config.assetTheme,
      },
      'sensory_profile': {
        'auditory_reaction': bundle.config.audioMode == AudioMode.completelyMuted
            ? 'highly_sensitive'
            : 'neutral',
        'visual_distress': bundle.config.themePalette == ThemePalette.calmDark ? 'high' : 'none',
        'effective_regulation_method': bundle.config.hapticEnabled
            ? 'rhythmic_tapping'
            : 'visual_glow',
      },
      'routine_transitions': {
        'transition_difficulty_score': bundle.clinical.behaviorPatterns,
        'unexpected_change_distress': 'low',
        'instruction_processing_preference': 'visual',
      },
      'strengths_special_interests': {
        'natural_abilities': ['exploration'],
        'primary_hyper_fixation': bundle.config.assetTheme,
        'problem_solving_approach': 'visual_mapping',
      },
      'communication_emotion': {
        'stress_communication_style': 'standard_speech',
        'emotional_interoception_level': 'medium',
      },
    });
  }

  List<String> _calculateLayoutOrder(NeuroProfile profile) {
    // Dynamic score-based priority ordering:
    // Base components
    final components = ['schedule', 'emotion', 'talent', 'sensory'];

    final scores = <String, int>{};

    // Score calculation rules
    // 1. Transition Difficulty pushes Schedule up
    scores['schedule'] = profile.routineTransitions.transitionDifficultyScore * 15;

    // 2. Low Emotional Interoception pushes Emotion Hub up
    scores['emotion'] = profile.communicationEmotion.emotionalInteroceptionLevel == 'low' ? 80 : 20;

    // 3. High Visual Distress pushes Talent Growth up
    scores['talent'] = profile.sensoryProfile.visualDistress == 'high' ? 90 : 30;

    // 4. Sensory regulation method preferences
    scores['sensory'] = profile.sensoryProfile.effectiveRegulationMethod == 'rhythmic_tapping' ? 50 : 25;

    // Sort descending by calculated scores
    components.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));

    return components;
  }

  ThemeData _generateThemeData(NeuroProfile profile) {
    final favoriteColor = profile.affinities.favoriteColor.toLowerCase();
    final hasHighVisualDistress = profile.sensoryProfile.visualDistress == 'high';

    ColorScheme colorScheme;
    bool isDark = false;

    if (favoriteColor.contains('sage_green')) {
      // Soft Sage Green (Profile 1)
      colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E8B7E),
        primary: const Color(0xFF4A7C59),
        secondary: const Color(0xFF68A357),
        background: const Color(0xFFF1F7F4),
        brightness: Brightness.light,
      );
    } else if (favoriteColor.contains('pastel_blue')) {
      // Minimalist Muted Pastel Blue (Profile 2)
      colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF7BAFD4),
        primary: const Color(0xFF5B8CAE),
        secondary: const Color(0xFF90B4CE),
        background: const Color(0xFFF0F4F8),
        brightness: Brightness.light,
      );
    } else if (favoriteColor.contains('terracotta') || favoriteColor.contains('orange')) {
      // Warm Vibrant Orange (#FF9F1C) (Profile 3)
      colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF9F1C),
        primary: const Color(0xFFFF9F1C),
        secondary: const Color(0xFFFFB703),
        background: const Color(0xFFFFF9F2),
        brightness: Brightness.light,
      );
    } else if (favoriteColor.contains('deep_sea_indigo')) {
      // Deep Sea Indigo Glassmorphic Dark Mode (Profile 4)
      isDark = true;
      colorScheme = const ColorScheme.dark(
        primary: Color(0xFF5C6BC0),
        secondary: Color(0xFF3F51B5),
        surface: Color(0xFF1E293B),
      );
    } else if (favoriteColor.contains('sunflower_yellow')) {
      // High Contrast Vibrant Sunflower Yellow Dark Mode (Profile 5)
      isDark = true;
      colorScheme = const ColorScheme.dark(
        primary: Color(0xFFFBBF24),
        secondary: Color(0xFFF59E0B),
        surface: Color(0xFF111827),
      );
    } else {
      // Fallback Default Blue
      colorScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      );
    }

    final theme = isDark ? ThemeData.dark() : ThemeData.light();

    // Disable all transition animations if visual distress is high (Profile 2)
    PageTransitionsTheme pageTheme = hasHighVisualDistress
        ? const PageTransitionsTheme(builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          })
        : theme.pageTransitionsTheme;

    return theme.copyWith(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: hasHighVisualDistress ? 0 : 2, // remove elevation (flat cards) for visual distress
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: hasHighVisualDistress
              ? BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1.5)
              : (favoriteColor.contains('sunflower_yellow')
                  ? const BorderSide(color: Color(0xFFFBBF24), width: 2.0)
                  : (favoriteColor.contains('deep_sea_indigo')
                      ? const BorderSide(color: Color(0x665C6BC0), width: 1.5)
                      : BorderSide.none)),
        ),
      ),
      pageTransitionsTheme: pageTheme,
      textTheme: theme.textTheme.apply(
        fontFamily: 'Outfit',
        bodyColor: isDark ? Colors.white : Colors.blueGrey[900],
        displayColor: isDark ? Colors.white : Colors.blueGrey[900],
      ),
    );
  }

  SensoryConfig _generateSensoryConfig(NeuroProfile profile) {
    final method = profile.sensoryProfile.effectiveRegulationMethod.toLowerCase();
    final reaction = profile.sensoryProfile.auditoryReaction.toLowerCase();

    if (reaction.contains('highly_sensitive') || method.contains('visual_glow')) {
      // Permanent silent glowing visual-only mode
      return const SensoryConfig(
        useAudioChimes: false,
        useRhythmicHaptics: false,
        useHeavyHaptics: false,
        silentVisualGlowOnly: true,
      );
    } else if (method.contains('rhythmic_tapping')) {
      return const SensoryConfig(
        useAudioChimes: true,
        useRhythmicHaptics: true,
        useHeavyHaptics: false,
        silentVisualGlowOnly: false,
      );
    } else if (method.contains('deep_pressure')) {
      // Profile 4 prefers deep pressure vibration instead of audio chimes
      return const SensoryConfig(
        useAudioChimes: false,
        useRhythmicHaptics: false,
        useHeavyHaptics: true,
        silentVisualGlowOnly: false,
      );
    } else {
      // Default: Standard low audio chimes
      return const SensoryConfig(
        useAudioChimes: true,
        useRhythmicHaptics: false,
        useHeavyHaptics: false,
        silentVisualGlowOnly: false,
      );
    }
  }

  static const Map<String, Map<String, dynamic>> mockProfiles = {
    'Profile 1: Space Explorer': {
      'user_profile': {'name': 'Leo', 'age': 8},
      'visual_environmental_affinities': {
        'favorite_color': 'sage_green',
        'favorite_place': 'space_station',
        'favorite_object': 'telescope'
      },
      'sensory_profile': {
        'auditory_reaction': 'neutral',
        'visual_distress': 'none',
        'effective_regulation_method': 'audio_scanner'
      },
      'routine_transitions': {
        'transition_difficulty_score': 5,
        'unexpected_change_distress': 'high',
        'instruction_processing_preference': 'visual'
      },
      'strengths_special_interests': {
        'natural_abilities': ['spatial_reasoning', 'astronomy'],
        'primary_hyper_fixation': 'space_exploration',
        'problem_solving_approach': 'visual_mapping'
      },
      'communication_emotion': {
        'stress_communication_style': 'standard_speech',
        'emotional_interoception_level': 'high'
      }
    },
    'Profile 2: Dinosaur Paleontology': {
      'user_profile': {'name': 'Emily', 'age': 12},
      'visual_environmental_affinities': {
        'favorite_color': 'pastel_blue',
        'favorite_place': 'dig_site',
        'favorite_object': 'fossil'
      },
      'sensory_profile': {
        'auditory_reaction': 'neutral',
        'visual_distress': 'high',
        'effective_regulation_method': 'deep_pressure'
      },
      'routine_transitions': {
        'transition_difficulty_score': 2,
        'unexpected_change_distress': 'medium',
        'instruction_processing_preference': 'textual'
      },
      'strengths_special_interests': {
        'natural_abilities': ['categorization', 'historical_memory'],
        'primary_hyper_fixation': 'dinosaurs',
        'problem_solving_approach': 'systematic_analysis'
      },
      'communication_emotion': {
        'stress_communication_style': 'written_text',
        'emotional_interoception_level': 'medium'
      }
    },
    'Profile 3: Train Conductor': {
      'user_profile': {'name': 'Toby', 'age': 9},
      'visual_environmental_affinities': {
        'favorite_color': 'terracotta',
        'favorite_place': 'railway_station',
        'favorite_object': 'locomotive'
      },
      'sensory_profile': {
        'auditory_reaction': 'seeker',
        'visual_distress': 'none',
        'effective_regulation_method': 'rhythmic_tapping'
      },
      'routine_transitions': {
        'transition_difficulty_score': 2,
        'unexpected_change_distress': 'low',
        'instruction_processing_preference': 'auditory'
      },
      'strengths_special_interests': {
        'natural_abilities': ['rhythm_tracking', 'sequencing'],
        'primary_hyper_fixation': 'trains',
        'problem_solving_approach': 'trial_and_error'
      },
      'communication_emotion': {
        'stress_communication_style': 'vocalizations',
        'emotional_interoception_level': 'low'
      }
    },
    'Profile 4: Marine Biologist': {
      'user_profile': {'name': 'Kai', 'age': 11},
      'visual_environmental_affinities': {
        'favorite_color': 'deep_sea_indigo',
        'favorite_place': 'coral_reef',
        'favorite_object': 'submarine'
      },
      'sensory_profile': {
        'auditory_reaction': 'sensitive',
        'visual_distress': 'none',
        'effective_regulation_method': 'deep_pressure'
      },
      'routine_transitions': {
        'transition_difficulty_score': 3,
        'unexpected_change_distress': 'high',
        'instruction_processing_preference': 'pictograms'
      },
      'strengths_special_interests': {
        'natural_abilities': ['visual_sorting', 'pattern_recognition'],
        'primary_hyper_fixation': 'marine_biology',
        'problem_solving_approach': 'visual_sorting'
      },
      'communication_emotion': {
        'stress_communication_style': 'aac_pictograms',
        'emotional_interoception_level': 'medium'
      }
    },
    'Profile 5: Logic Coder': {
      'user_profile': {'name': 'Zane', 'age': 13},
      'visual_environmental_affinities': {
        'favorite_color': 'sunflower_yellow',
        'favorite_place': 'code_lab',
        'favorite_object': 'microcontroller'
      },
      'sensory_profile': {
        'auditory_reaction': 'highly_sensitive',
        'visual_distress': 'none',
        'effective_regulation_method': 'visual_glow'
      },
      'routine_transitions': {
        'transition_difficulty_score': 1,
        'unexpected_change_distress': 'low',
        'instruction_processing_preference': 'textual'
      },
      'strengths_special_interests': {
        'natural_abilities': ['logical_deduction', 'nested_loops'],
        'primary_hyper_fixation': 'logic_coding',
        'problem_solving_approach': 'algorithmic'
      },
      'communication_emotion': {
        'stress_communication_style': 'written_text',
        'emotional_interoception_level': 'high'
      }
    }
  };
}

final sduiControllerProvider = StateNotifierProvider<SduiController, SduiState>((ref) {
  return SduiController();
});
