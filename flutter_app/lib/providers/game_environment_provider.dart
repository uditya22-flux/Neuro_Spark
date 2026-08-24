import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/intake_models.dart';

/// Full intake session: clinical baseline, parental profile, and compiled environment.
class IntakeSessionBundle {
  const IntakeSessionBundle({
    required this.clinical,
    required this.parent,
    required this.config,
    this.childId,
    this.persistedAt,
  });

  final ISAAClinicalProfile clinical;
  final ParentQualitativeProfile parent;
  final GameEnvironmentConfig config;
  final String? childId;
  final DateTime? persistedAt;

  IntakeSessionBundle copyWith({
    ISAAClinicalProfile? clinical,
    ParentQualitativeProfile? parent,
    GameEnvironmentConfig? config,
    String? childId,
    DateTime? persistedAt,
  }) {
    return IntakeSessionBundle(
      clinical: clinical ?? this.clinical,
      parent: parent ?? this.parent,
      config: config ?? this.config,
      childId: childId ?? this.childId,
      persistedAt: persistedAt ?? this.persistedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'clinical': clinical.toJson(),
        'parent': parent.toJson(),
        'config': config.toJson(),
        if (childId != null) 'child_id': childId,
        if (persistedAt != null) 'persisted_at': persistedAt!.toIso8601String(),
      };

  factory IntakeSessionBundle.fromJson(Map<String, dynamic> json) {
    return IntakeSessionBundle(
      clinical: ISAAClinicalProfile.fromJson(Map<String, dynamic>.from(json['clinical'] as Map)),
      parent: ParentQualitativeProfile.fromJson(Map<String, dynamic>.from(json['parent'] as Map)),
      config: GameEnvironmentConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map)),
      childId: json['child_id'] as String?,
      persistedAt: json['persisted_at'] != null
          ? DateTime.tryParse(json['persisted_at'] as String)
          : null,
    );
  }
}

class GameEnvironmentNotifier extends StateNotifier<IntakeSessionBundle?> {
  GameEnvironmentNotifier() : super(null);

  void set(IntakeSessionBundle bundle) => state = bundle;

  void clear() => state = null;
}

final gameEnvironmentProvider =
    StateNotifierProvider<GameEnvironmentNotifier, IntakeSessionBundle?>((ref) {
  return GameEnvironmentNotifier();
});

final activeGameConfigProvider = Provider<GameEnvironmentConfig?>((ref) {
  return ref.watch(gameEnvironmentProvider)?.config;
});

final activeInstructionStyleProvider = Provider<InstructionStyle>((ref) {
  return ref.watch(activeGameConfigProvider)?.instructionStyle ??
      InstructionStyle.pictorialGuideCards;
});

final activeThemeSkinProvider = Provider<String>((ref) {
  final asset = ref.watch(activeGameConfigProvider)?.assetTheme ?? 'cosmic_space';
  return assetThemeToSkin(asset);
});

final activeStartingTierProvider = Provider<int>((ref) {
  return ref.watch(activeGameConfigProvider)?.startingDifficultyTier ?? 1;
});

/// Maps compiler asset themes to deepening funnel skin identifiers.
String assetThemeToSkin(String assetTheme) {
  return switch (assetTheme) {
    'terracotta_train' => 'terracotta_train',
    'sage_nature' => 'sage_green',
    'geometry_lattice' => 'pastel_dinosaur',
    'calendar_chronos' => 'cosmic_space',
    _ => 'cosmic_space',
  };
}
