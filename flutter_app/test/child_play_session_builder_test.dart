import 'package:flutter_test/flutter_test.dart';

import 'package:mindbridge_app/features/child/data/child_play_session_builder.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/providers/game_environment_provider.dart';
import 'package:mindbridge_app/features/strength_funnel/models/strength_funnel_finalists.dart';

void main() {
  test('buildChildPlayActivities uses picture modality for low verbal ISAA', () {
    final bundle = IntakeSessionBundle(
      clinical: const ISAAClinicalProfile(speechCommunication: 5),
      parent: const ParentQualitativeProfile(childName: 'Sam', childAge: 9),
      config: const GameEnvironmentConfig(
        themePalette: ThemePalette.softPastel,
        audioMode: AudioMode.completelyMuted,
        hapticEnabled: false,
        instructionStyle: InstructionStyle.pictorialGuideCards,
        assetTheme: 'cosmic_space',
        strictGroundingEnforced: true,
        startingDifficultyTier: 1,
        pacingSlowed: true,
      ),
    );

    const finalists = StrengthFunnelFinalists(
      sectorIds: ['r_build_fix', 'i_puzzles_logic'],
    );

    final activities = buildChildPlayActivities(finalists: finalists, bundle: bundle);

    expect(activities.length, 2);
    expect(activities.first.sectorId, 'r_build_fix');
    expect(activities.first.modality, isNot('text'));
    expect(
      activities.first.presentMomentPrompt,
      contains('right now'),
    );
  });

  test('buildChildPlayActivities maps all finalist sectors', () {
    final bundle = IntakeSessionBundle(
      clinical: const ISAAClinicalProfile(speechCommunication: 2),
      parent: const ParentQualitativeProfile(childName: 'Riya', childAge: 10),
      config: const GameEnvironmentConfig(
        themePalette: ThemePalette.calmDark,
        audioMode: AudioMode.subtleSoundEffectsOnly,
        hapticEnabled: true,
        instructionStyle: InstructionStyle.simpleText,
        assetTheme: 'cosmic_space',
        strictGroundingEnforced: true,
        startingDifficultyTier: 2,
      ),
    );

    const finalists = StrengthFunnelFinalists(
      sectorIds: ['a_drawing_color', 'c_patterns_order', 'r_vehicles_machines'],
    );

    final activities = buildChildPlayActivities(finalists: finalists, bundle: bundle);

    expect(activities.length, 3);
    expect(activities.map((a) => a.displayName), contains('Drawing & Color'));
  });
}
