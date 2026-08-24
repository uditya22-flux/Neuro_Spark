import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/services/environment_compiler_service.dart';

void main() {
  const compiler = EnvironmentCompilerService();

  group('EnvironmentCompilerService', () {
    test('high sensory ISAA score selects calmDark theme and muted audio', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 5, speechCommunication: 3, cognitiveComponent: 3);
      const parent = ParentQualitativeProfile();

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.themePalette, ThemePalette.calmDark);
      expect(config.audioMode, AudioMode.completelyMuted);
      expect(config.pacingSlowed, isTrue);
    });

    test('parent visual triggers force calmDark even when sensory score is low', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 2, speechCommunication: 3);
      const parent = ParentQualitativeProfile(
        visualTriggers: ['Rapid flashing'],
      );

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.themePalette, ThemePalette.calmDark);
      expect(config.pacingSlowed, isTrue);
    });

    test('low sensory profile with no triggers selects softPastel theme', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 3, speechCommunication: 3);
      const parent = ParentQualitativeProfile();

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.themePalette, ThemePalette.softPastel);
      expect(config.audioMode, isNot(AudioMode.completelyMuted));
      expect(config.pacingSlowed, isFalse);
    });

    test('parent sound triggers force completelyMuted audio', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 2);
      const parent = ParentQualitativeProfile(
        soundTriggers: ['Sudden loud chime'],
      );

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.audioMode, AudioMode.completelyMuted);
    });

    test('prefersHaptics enables haptic confirmations when audio is muted', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 5);
      const parent = ParentQualitativeProfile(
        tactilePreference: TactilePreference.prefersHaptics,
      );

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.hapticEnabled, isTrue);
    });

    test('noVibrations disables haptics even when audio is muted', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 5);
      const parent = ParentQualitativeProfile(
        tactilePreference: TactilePreference.noVibrations,
      );

      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.hapticEnabled, isFalse);
    });

    test('speech communication maps to instruction styles deterministically', () {
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(speechCommunication: 5),
          const ParentQualitativeProfile(),
        ).instructionStyle,
        InstructionStyle.pureVisualGlowHints,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(speechCommunication: 4),
          const ParentQualitativeProfile(),
        ).instructionStyle,
        InstructionStyle.pureVisualGlowHints,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(speechCommunication: 3),
          const ParentQualitativeProfile(),
        ).instructionStyle,
        InstructionStyle.pictorialGuideCards,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(speechCommunication: 2),
          const ParentQualitativeProfile(),
        ).instructionStyle,
        InstructionStyle.pictorialGuideCards,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(speechCommunication: 1),
          const ParentQualitativeProfile(),
        ).instructionStyle,
        InstructionStyle.simpleText,
      );
    });

    test('hyper-fixation category maps to asset theme strings', () {
      final themes = {
        HyperFixationCategory.trainsVehicles: 'terracotta_train',
        HyperFixationCategory.spaceAstronomy: 'cosmic_space',
        HyperFixationCategory.geometryPatterns: 'geometry_lattice',
        HyperFixationCategory.animalsNature: 'sage_nature',
        HyperFixationCategory.clocksNumbers: 'calendar_chronos',
      };

      for (final entry in themes.entries) {
        final config = compiler.compileEnvironment(
          const ISAAClinicalProfile(),
          ParentQualitativeProfile(hyperFixationCategory: entry.key),
        );
        expect(config.assetTheme, entry.value);
      }
    });

    test('strictGroundingEnforced is always true', () {
      final config = compiler.compileEnvironment(
        const ISAAClinicalProfile(),
        const ParentQualitativeProfile(),
      );
      expect(config.strictGroundingEnforced, isTrue);
    });

    test('cognitive component calibrates starting difficulty tier 1-3', () {
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(cognitiveComponent: 1),
          const ParentQualitativeProfile(),
        ).startingDifficultyTier,
        1,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(cognitiveComponent: 2),
          const ParentQualitativeProfile(),
        ).startingDifficultyTier,
        1,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(cognitiveComponent: 3),
          const ParentQualitativeProfile(),
        ).startingDifficultyTier,
        2,
      );
      expect(
        compiler.compileEnvironment(
          const ISAAClinicalProfile(cognitiveComponent: 5),
          const ParentQualitativeProfile(),
        ).startingDifficultyTier,
        3,
      );
    });

    test('GameEnvironmentConfig round-trips through JSON', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 4, speechCommunication: 2, cognitiveComponent: 4);
      const parent = ParentQualitativeProfile(
        childName: 'Riya',
        childAge: 9,
        hyperFixationCategory: HyperFixationCategory.trainsVehicles,
        soundTriggers: ['High-frequency beeps'],
        visualTriggers: ['Floating UI elements'],
        tactilePreference: TactilePreference.prefersHaptics,
      );

      final compiled = compiler.compileEnvironment(isaa, parent);
      final restored = GameEnvironmentConfig.fromJson(compiled.toJson());

      expect(restored.toJson(), compiled.toJson());
    });

    test('ISAAClinicalProfile and ParentQualitativeProfile round-trip JSON', () {
      const isaa = ISAAClinicalProfile(
        socialRelationship: 2,
        emotionalResponsiveness: 4,
        speechCommunication: 3,
        behaviorPatterns: 1,
        sensoryAspects: 5,
        cognitiveComponent: 4,
      );
      const parent = ParentQualitativeProfile(
        childName: 'Alex',
        childAge: 10,
        hyperFixationCategory: HyperFixationCategory.geometryPatterns,
        soundTriggers: ['Background music loops'],
        visualTriggers: ['Parallax scrolling'],
        tactilePreference: TactilePreference.neutral,
      );

      expect(ISAAClinicalProfile.fromJson(isaa.toJson()).toJson(), isaa.toJson());
      expect(ParentQualitativeProfile.fromJson(parent.toJson()).toJson(), parent.toJson());
    });
  });
}
