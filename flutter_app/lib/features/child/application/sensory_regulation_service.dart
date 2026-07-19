import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/child_experience.dart';

class RegulationState {
  const RegulationState({
    required this.configuration,
    this.isCooldownActive = false,
    this.cooldownReason,
  });

  final SensoryConfiguration configuration;
  final bool isCooldownActive;
  final String? cooldownReason;

  RegulationState copyWith({
    SensoryConfiguration? configuration,
    bool? isCooldownActive,
    String? cooldownReason,
    bool clearCooldownReason = false,
  }) {
    return RegulationState(
      configuration: configuration ?? this.configuration,
      isCooldownActive: isCooldownActive ?? this.isCooldownActive,
      cooldownReason: clearCooldownReason ? null : cooldownReason ?? this.cooldownReason,
    );
  }
}

class SensoryRegulationService extends StateNotifier<RegulationState> {
  SensoryRegulationService()
      : super(
          const RegulationState(
            configuration: SensoryConfiguration(
              reduceMotion: false,
              soundEnabled: false,
              hapticsEnabled: false,
              highContrast: false,
              themeName: 'calm',
            ),
          ),
        );

  void apply(SensoryConfiguration configuration) {
    state = state.copyWith(configuration: configuration);
  }

  /// Child-initiated pause only; it is not a performance or diagnostic signal.
  void openCooldown({String reason = 'A quiet pause is ready whenever you want it.'}) {
    state = state.copyWith(isCooldownActive: true, cooldownReason: reason);
  }

  void resume() {
    state = state.copyWith(isCooldownActive: false, clearCooldownReason: true);
  }
}

final sensoryRegulationProvider =
    StateNotifierProvider<SensoryRegulationService, RegulationState>(
  (ref) => SensoryRegulationService(),
);
