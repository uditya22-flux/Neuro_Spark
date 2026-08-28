import '../../../core/config/demo_config.dart';
import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';

/// Synthetic child profile for hospital demos — moderate ISAA, picture-first routing.
IntakeSessionBundle buildDemoIntakeBundle() {
  const clinical = ISAAClinicalProfile(
    socialRelationship: 3,
    emotionalResponsiveness: 3,
    speechCommunication: 4,
    behaviorPatterns: 2,
    sensoryAspects: 3,
    cognitiveComponent: 3,
  );

  const parent = ParentQualitativeProfile(
    childName: DemoConfig.demoChildName,
    childAge: DemoConfig.demoChildAge,
    hyperFixationCategory: HyperFixationCategory.geometryPatterns,
    soundTriggers: ['loud_sudden_noise'],
    visualTriggers: ['busy_patterns'],
    tactilePreference: TactilePreference.prefersHaptics,
  );

  const config = GameEnvironmentConfig(
    themePalette: ThemePalette.softPastel,
    audioMode: AudioMode.subtleSoundEffectsOnly,
    instructionStyle: InstructionStyle.pictorialGuideCards,
    hapticEnabled: true,
    assetTheme: 'soft_pastel',
    strictGroundingEnforced: true,
    startingDifficultyTier: 1,
    pacingSlowed: false,
  );

  return const IntakeSessionBundle(
    clinical: clinical,
    parent: parent,
    config: config,
    childId: 'demo_child_local',
  );
}
