import 'dart:math';

import '../models/exploration_models.dart';

/// Ten ambient scenes cover all 30 play mechanics in groups of three. The
/// catalog deliberately creates no score, rank, or inferred capability.
class Layer1Generator {
  static List<PuzzleSpec> generate({required IntakeConfiguration intake, int? seed}) {
    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    // Interleave the six five-sector families before compounding them into
    // scenes. A short ambient session therefore samples across domains
    // instead of presenting a block of near-identical visual tasks.
    final mechanics = _interleavedWideNet();
    final scenes = List.generate(10, (index) {
      final group = mechanics.skip(index * 3).take(3).toList();
      return _scene(index + 1, group, intake, random);
    });
    scenes.shuffle(random);
    return scenes;
  }

  /// Builds the local builder-showcase version of Layer 1.
  ///
  /// Each task represents exactly one mechanic so the showcase funnel can
  /// demonstrate its 30-to-10 narrowing without changing the regular,
  /// compound-scene experience above. Callers are responsible for keeping
  /// these in the compile-time builder mode; this generator itself never
  /// persists interaction data.
  static List<PuzzleSpec> generateBuilderShowcase({
    required IntakeConfiguration intake,
    int? seed,
  }) {
    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final tasks = PlayMechanic.values
        .map((mechanic) => _builderTask(mechanic, intake, random))
        .toList(growable: false);
    tasks.shuffle(random);
    return tasks;
  }

  static List<PlayMechanic> _interleavedWideNet() {
    final groups = PlayMechanicGroup.values
        .map(
          (group) => PlayMechanic.values
              .where((mechanic) => mechanic.group == group)
              .toList(growable: false),
        )
        .toList(growable: false);
    return List<PlayMechanic>.generate(
      PlayMechanic.values.length,
      (index) => groups[index % groups.length][index ~/ groups.length],
      growable: false,
    );
  }

  static PuzzleSpec _scene(
    int index,
    List<PlayMechanic> mechanics,
    IntakeConfiguration intake,
    Random random,
  ) {
    final theme = intake.hyperFocusTheme;
    final prompts = [
      'Connect the $theme train cars so the station lights up.',
      'Guide the $theme explorer along the clear path.',
      'Repair the $theme signal by placing its missing part.',
      'Sort the $theme supplies into their matching bays.',
      'Match the $theme cargo to its outline.',
      'Find the small change in the $theme scene.',
      'Remember where the $theme light flashed.',
      'Make the $theme machine respond in the same way.',
      'Place the $theme pieces to build a steady route.',
      'Help the $theme crew repair the last connection.',
    ];
    final options = ['Blue bay', 'Green bay', 'Gold bay', 'Silver bay', 'Rest bay']..shuffle(random);
    return PuzzleSpec(
      id: 'ambient_scene_$index',
      mechanics: mechanics,
      layer: 1,
      themedPrompt: prompts[index - 1],
      options: options,
      correctOption: 'Gold bay',
      itemCount: 5,
      visualThemeKey: intake.visualThemeKey,
      familiarColors: intake.familiarColors.toList(growable: false),
      visualStylePreference: intake.visualStylePreference,
      interactionPreference: intake.interface.preferredInteraction,
      allowMotion: intake.interface.allowMotion,
      visualRepetitionHelpful: intake.visualRepetitionHelpful,
      preferHaptics: intake.interface.preferHaptics,
      communicationPreference: intake.interface.communicationPreference,
    );
  }

  static PuzzleSpec _builderTask(
    PlayMechanic mechanic,
    IntakeConfiguration intake,
    Random random,
  ) {
    final options = ['Blue bay', 'Green bay', 'Gold bay', 'Silver bay', 'Rest bay']
      ..shuffle(random);
    final theme = _themeLabel(intake);
    return PuzzleSpec(
      id: 'builder_layer_1_${mechanic.name}',
      mechanics: [mechanic],
      layer: 1,
      themedPrompt: _builderPrompt(mechanic, theme),
      options: options,
      correctOption: 'Gold bay',
      // The wide-net baseline starts with three visual choices. Later layers
      // add choices, hidden complexity, and optional distractors.
      itemCount: 3,
      visualThemeKey: intake.visualThemeKey,
      familiarColors: intake.familiarColors.toList(growable: false),
      visualStylePreference: intake.visualStylePreference,
      interactionPreference: intake.interface.preferredInteraction,
      allowMotion: intake.interface.allowMotion,
      visualRepetitionHelpful: intake.visualRepetitionHelpful,
      preferHaptics: intake.interface.preferHaptics,
      communicationPreference: intake.interface.communicationPreference,
      expectedInteractions: 1,
      speedBudgetMs: _layer1SpeedBudget(intake),
      difficulty: 1,
    );
  }

  static int _layer1SpeedBudget(IntakeConfiguration intake) {
    // The timing budget is telemetry-only; no timer is shown in the play UI.
    // A guardian preference that avoids time pressure relaxes it further.
    return intake.interface.showTimePressure ? 12000 : 18000;
  }

  static String _themeLabel(IntakeConfiguration intake) {
    final theme = intake.hyperFocusTheme.trim();
    return theme.isEmpty ? 'play world' : theme;
  }

  /// This string is developer metadata only. The child board draws the
  /// corresponding non-verbal scene from the mechanic/visual-plan contract.
  static String _builderPrompt(PlayMechanic mechanic, String theme) =>
      'Word-free $theme scene: ${mechanic.label}.';
}
