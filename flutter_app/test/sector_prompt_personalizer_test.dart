import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/strength_funnel/services/sector_prompt_personalizer.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/providers/game_environment_provider.dart';
import 'package:mindbridge_app/features/strength_funnel/models/riasec_sector.dart';

void main() {
  const personalizer = SectorPromptPersonalizer();

  group('SectorPromptPersonalizer', () {
    test('selects train variant for trainsVehicles hyperfixation', () {
      const bundle = IntakeSessionBundle(
        clinical: ISAAClinicalProfile(speechCommunication: 4),
        parent: ParentQualitativeProfile(
          childName: 'Sam',
          childAge: 9,
          hyperFixationCategory: HyperFixationCategory.trainsVehicles,
        ),
        config: GameEnvironmentConfig(
          themePalette: ThemePalette.softPastel,
          audioMode: AudioMode.subtleSoundEffectsOnly,
          instructionStyle: InstructionStyle.pictorialGuideCards,
          hapticEnabled: true,
          assetTheme: 'soft_pastel',
          strictGroundingEnforced: true,
          startingDifficultyTier: 1,
        ),
      );

      final sector = sectorById('r_vehicles_machines')!;
      final result = personalizer.resolve(sector: sector, bundle: bundle, layer: 1);

      expect(result.researchStemId, startsWith('cape_'));
      expect(result.citationShort, 'King et al., 2007');
      expect(result.personalizationReason, contains('hyperfixation'));
    });

    test('avoids loud drum for sound trigger profile', () {
      const bundle = IntakeSessionBundle(
        clinical: ISAAClinicalProfile(sensoryAspects: 4),
        parent: ParentQualitativeProfile(
          soundTriggers: ['loud_sudden_noise'],
        ),
        config: GameEnvironmentConfig(
          themePalette: ThemePalette.softPastel,
          audioMode: AudioMode.completelyMuted,
          instructionStyle: InstructionStyle.pictorialGuideCards,
          hapticEnabled: false,
          assetTheme: 'soft_pastel',
          strictGroundingEnforced: true,
          startingDifficultyTier: 1,
        ),
      );

      final sector = sectorById('a_music_rhythm')!;
      final result = personalizer.resolve(sector: sector, bundle: bundle, layer: 1);

      expect(result.presentMomentPrompt.toLowerCase(), isNot(contains('drum')));
    });

    test('boosts related RIASEC family when prior engagement high', () {
      const bundle = IntakeSessionBundle(
        clinical: const ISAAClinicalProfile(),
        parent: ParentQualitativeProfile(
          hyperFixationCategory: HyperFixationCategory.spaceAstronomy,
        ),
        config: GameEnvironmentConfig(
          themePalette: ThemePalette.softPastel,
          audioMode: AudioMode.subtleSoundEffectsOnly,
          instructionStyle: InstructionStyle.pictorialGuideCards,
          hapticEnabled: true,
          assetTheme: 'soft_pastel',
          strictGroundingEnforced: true,
          startingDifficultyTier: 1,
        ),
      );

      final sector = sectorById('i_maps_exploring')!;
      final result = personalizer.resolve(
        sector: sector,
        bundle: bundle,
        layer: 2,
        priorEngagement: {'i_puzzles_logic': 0.9},
      );

      expect(result.provenanceFramework, isNotEmpty);
      expect(result.presentMomentPrompt.endsWith('?'), isTrue);
    });
  });
}
