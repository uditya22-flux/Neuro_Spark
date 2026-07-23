import 'dart:math';

import '../models/exploration_models.dart';

/// Produces a varied, themed play scene for each layer. Mechanics are rotated
/// for variety, never removed because of a child's interaction data.
class DeepeningTaskFactory {
  static PuzzleSpec build({
    required IntakeConfiguration intake,
    required int layer,
    int itemCount = 5,
    bool simplified = false,
  }) {
    final start = ((layer - 2) * 3) % PlayMechanic.values.length;
    final mechanics = List.generate(3, (offset) => PlayMechanic.values[(start + offset) % PlayMechanic.values.length]);
    const options = ['Anchor', 'Bridge', 'Signal', 'Station', 'Rest'];
    final effectiveItemCount = itemCount.clamp(3, options.length).toInt();
    final theme = intake.hyperFocusTheme;
    final scenario = switch (layer) {
      2 => 'a fresh $theme route',
      3 => 'a mirrored $theme layout',
      4 => 'a moving $theme scene',
      5 => 'a joined $theme build',
      6 => 'a calm $theme station',
      7 => 'a wider $theme map',
      8 => 'a new $theme setting',
      9 => 'a connected $theme world',
      _ => 'a final $theme repair',
    };
    return PuzzleSpec(
      id: 'ambient_layer_$layer',
      mechanics: mechanics,
      layer: layer,
      themedPrompt: 'Place the right piece to complete $scenario.',
      options: options.take(effectiveItemCount).toList(),
      correctOption: 'Signal',
      itemCount: effectiveItemCount,
      showsDistractors: layer >= 6 && intake.interface.allowDistractors && !simplified,
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

  /// Creates one local builder-showcase task for each surviving mechanic.
  ///
  /// The caller owns the funnel selection. This factory only makes the next
  /// layer more complex: more visible pieces, a tighter telemetry budget when
  /// time pressure is allowed, and optional distractors from Layer 6 onward.
  static List<PuzzleSpec> buildBuilderLayer({
    required IntakeConfiguration intake,
    required int layer,
    required List<PlayMechanic> activeMechanics,
    int? seed,
  }) {
    if (layer < 2 || layer > 10) {
      throw RangeError.range(layer, 2, 10, 'layer');
    }

    final mechanics = <PlayMechanic>[];
    for (final mechanic in activeMechanics) {
      if (!mechanics.contains(mechanic)) mechanics.add(mechanic);
    }

    final random = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final tasks = mechanics
        .map((mechanic) => _builderTask(
              intake: intake,
              layer: layer,
              mechanic: mechanic,
              random: random,
            ))
        .toList(growable: false);
    tasks.shuffle(random);
    return tasks;
  }

  static PuzzleSpec _builderTask({
    required IntakeConfiguration intake,
    required int layer,
    required PlayMechanic mechanic,
    required Random random,
  }) {
    final options = ['Anchor', 'Bridge', 'Signal', 'Station', 'Rest']..shuffle(random);
    final theme = intake.hyperFocusTheme.trim().isEmpty ? 'play world' : intake.hyperFocusTheme.trim();
    return PuzzleSpec(
      id: 'builder_layer_${layer}_${mechanic.name}',
      mechanics: [mechanic],
      layer: layer,
      themedPrompt: _builderPrompt(mechanic, theme, layer),
      options: options,
      correctOption: 'Signal',
      itemCount: _itemCountFor(layer),
      showsDistractors: layer >= 6 && intake.interface.allowDistractors,
      visualThemeKey: intake.visualThemeKey,
      familiarColors: intake.familiarColors.toList(growable: false),
      visualStylePreference: intake.visualStylePreference,
      interactionPreference: intake.interface.preferredInteraction,
      allowMotion: intake.interface.allowMotion,
      visualRepetitionHelpful: intake.visualRepetitionHelpful,
      preferHaptics: intake.interface.preferHaptics,
      communicationPreference: intake.interface.communicationPreference,
      // The current word-free surface resolves a task in one completed move.
      // More demanding layers are represented by choices, distractors and the
      // telemetry budget until multi-step renderers are introduced.
      expectedInteractions: 1,
      speedBudgetMs: _speedBudgetFor(intake, layer),
      difficulty: layer,
    );
  }

  static int _itemCountFor(int layer) => switch (layer) {
        2 || 3 => 4,
        _ => 5,
      };

  static int _speedBudgetFor(IntakeConfiguration intake, int layer) {
    final compressedBudget = switch (layer) {
      2 => 12000,
      3 => 10500,
      4 => 9000,
      5 => 8000,
      6 => 7000,
      7 => 6200,
      8 => 5500,
      9 => 4800,
      _ => 4200,
    };
    if (!intake.interface.showTimePressure) {
      // Respect a timer trigger by retaining a comfortable, invisible budget.
      return max(14000, compressedBudget).toInt();
    }
    if (!intake.interface.allowDistractors) {
      // A visually simplified experience has a modestly gentler baseline.
      return compressedBudget + 1500;
    }
    return compressedBudget;
  }

  static String _builderPrompt(PlayMechanic mechanic, String theme, int layer) {
    final complexity = switch (layer) {
      2 || 3 => 'a new',
      4 || 5 => 'a busier',
      6 || 7 => 'a wider',
      8 || 9 => 'a different',
      _ => 'the richest',
    };
    // Developer metadata only: the child-facing board remains fully visual.
    return 'Complete $complexity $theme ${mechanic.label} scene.';
  }
}
