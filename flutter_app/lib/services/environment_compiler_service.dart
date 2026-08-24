import '../models/intake_models.dart';

/// Deterministic merger of clinical ISAA baseline and parental qualitative intake.
class EnvironmentCompilerService {
  const EnvironmentCompilerService();

  GameEnvironmentConfig compileEnvironment(
    ISAAClinicalProfile isaa,
    ParentQualitativeProfile parent,
  ) {
    final hasVisualTriggers = parent.visualTriggers.isNotEmpty;
    final hasSoundTriggers = parent.soundTriggers.isNotEmpty;
    final highSensoryLoad = isaa.sensoryAspects >= 4;

    final themePalette = _resolveThemePalette(
      sensoryAspects: isaa.sensoryAspects,
      hasVisualTriggers: hasVisualTriggers,
    );
    final pacingSlowed = highSensoryLoad || hasVisualTriggers;

    final audioMode = _resolveAudioMode(
      sensoryAspects: isaa.sensoryAspects,
      hasSoundTriggers: hasSoundTriggers,
    );

    final hapticEnabled = _resolveHapticEnabled(
      audioMode: audioMode,
      tactilePreference: parent.tactilePreference,
    );

    final instructionStyle = _resolveInstructionStyle(isaa.speechCommunication);
    final assetTheme = _mapHyperFixationToAssetTheme(parent.hyperFixationCategory);
    final startingDifficultyTier = _resolveStartingDifficultyTier(isaa.cognitiveComponent);

    return GameEnvironmentConfig(
      themePalette: themePalette,
      audioMode: audioMode,
      hapticEnabled: hapticEnabled,
      instructionStyle: instructionStyle,
      assetTheme: assetTheme,
      strictGroundingEnforced: true,
      startingDifficultyTier: startingDifficultyTier,
      pacingSlowed: pacingSlowed,
    );
  }

  ThemePalette _resolveThemePalette({
    required int sensoryAspects,
    required bool hasVisualTriggers,
  }) {
    if (sensoryAspects >= 4 || hasVisualTriggers) {
      return ThemePalette.calmDark;
    }
    return ThemePalette.softPastel;
  }

  AudioMode _resolveAudioMode({
    required int sensoryAspects,
    required bool hasSoundTriggers,
  }) {
    if (sensoryAspects >= 4 || hasSoundTriggers) {
      return AudioMode.completelyMuted;
    }
    if (sensoryAspects <= 2) {
      return AudioMode.subtleSoundEffectsOnly;
    }
    return AudioMode.ambientBinauralSoft;
  }

  bool _resolveHapticEnabled({
    required AudioMode audioMode,
    required TactilePreference tactilePreference,
  }) {
    if (tactilePreference == TactilePreference.noVibrations) {
      return false;
    }
    if (tactilePreference == TactilePreference.prefersHaptics) {
      return true;
    }
    // Neutral: route confirmations to haptics only when audio is fully muted.
    return audioMode == AudioMode.completelyMuted;
  }

  InstructionStyle _resolveInstructionStyle(int speechCommunication) {
    if (speechCommunication >= 4) {
      return InstructionStyle.pureVisualGlowHints;
    }
    if (speechCommunication == 2 || speechCommunication == 3) {
      return InstructionStyle.pictorialGuideCards;
    }
    return InstructionStyle.simpleText;
  }

  String _mapHyperFixationToAssetTheme(HyperFixationCategory category) {
    return switch (category) {
      HyperFixationCategory.trainsVehicles => 'terracotta_train',
      HyperFixationCategory.spaceAstronomy => 'cosmic_space',
      HyperFixationCategory.geometryPatterns => 'geometry_lattice',
      HyperFixationCategory.animalsNature => 'sage_nature',
      HyperFixationCategory.clocksNumbers => 'calendar_chronos',
    };
  }

  int _resolveStartingDifficultyTier(int cognitiveComponent) {
    if (cognitiveComponent <= 2) return 1;
    if (cognitiveComponent == 3) return 2;
    return 3;
  }
}
