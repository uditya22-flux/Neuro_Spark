import 'package:flutter_riverpod/flutter_riverpod.dart';

class SafeModeState {
  final bool isEnabled;
  final double dimmingOpacity;
  final bool soundMuted;
  final bool collapseText;

  const SafeModeState({
    required this.isEnabled,
    this.dimmingOpacity = 0.0,
    this.soundMuted = false,
    this.collapseText = false,
  });

  SafeModeState copyWith({
    bool? isEnabled,
    double? dimmingOpacity,
    bool? soundMuted,
    bool? collapseText,
  }) {
    return SafeModeState(
      isEnabled: isEnabled ?? this.isEnabled,
      dimmingOpacity: dimmingOpacity ?? this.dimmingOpacity,
      soundMuted: soundMuted ?? this.soundMuted,
      collapseText: collapseText ?? this.collapseText,
    );
  }
}

class SafeModeNotifier extends StateNotifier<SafeModeState> {
  SafeModeNotifier() : super(const SafeModeState(isEnabled: false));

  void toggle() {
    if (state.isEnabled) {
      // Revert to normal mode
      state = const SafeModeState(isEnabled: false);
    } else {
      // Activate Safe Mode: high contrast, 35% dimming, sound blocked, text auto-collapsed
      state = const SafeModeState(
        isEnabled: true,
        dimmingOpacity: 0.35,
        soundMuted: true,
        collapseText: true,
      );
    }
  }

  void setDimming(double opacity) {
    if (state.isEnabled) {
      state = state.copyWith(dimmingOpacity: opacity);
    }
  }
}

final safeModeProvider = StateNotifierProvider<SafeModeNotifier, SafeModeState>((ref) {
  return SafeModeNotifier();
});
