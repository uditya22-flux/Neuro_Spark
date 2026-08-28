/// Hospital walkthrough demo — compile-time or runtime activated.
class DemoConfig {
  /// Build with: `flutter run --dart-define=HOSPITAL_DEMO=true`
  static const compileTimeEnabled =
      bool.fromEnvironment('HOSPITAL_DEMO', defaultValue: false);

  static const funnelExitLayer = int.fromEnvironment('DEMO_FUNNEL_LAYERS', defaultValue: 3);

  /// One sector per RIASEC type — ~6 min Layer 1 instead of 30+ min.
  static const representativeSectorIds = <String>[
    'r_build_fix',
    'i_puzzles_logic',
    'a_drawing_color',
    's_helping_caring',
    'e_leading_groups',
    'c_sorting_organizing',
  ];

  static const demoChildName = 'Aarav';
  static const demoChildAge = 9;

  /// Set when guardian taps "Hospital demo" at runtime.
  static bool runtimeActive = false;

  static bool get isActive => compileTimeEnabled || runtimeActive;

  static int get exitLayer => isActive ? funnelExitLayer : 10;

  static int advancingCount(int scoredSectorCount) {
    if (scoredSectorCount <= 2) return scoredSectorCount;
    return (scoredSectorCount * 0.6).ceil().clamp(2, scoredSectorCount);
  }
}
