import '../models/exploration_models.dart';

class CapstoneRouter {
  const CapstoneRouter._();

  /// The guardian chooses the open-ended sandbox; this does not infer a path
  /// from child play telemetry.
  static String verticalIdFor(SandboxPreference preference) => switch (preference) {
        SandboxPreference.calendar => 'calendar_genius',
        SandboxPreference.constellation => 'constellation_mapper',
      };

  /// Returns a sandbox only for mechanics with a direct, pre-defined
  /// correspondence to one of the two available builder-showcase sandboxes.
  ///
  /// This is intentionally a narrow presentation mapping. It is not used to
  /// infer a profile, and callers should use the neutral exploration route
  /// when it returns `null`.
  static String? verticalIdForPlayMechanic(PlayMechanic mechanic) {
    switch (mechanic) {
      // Only the two explicitly built capstone mechanics map to a sandbox.
      // Every other finalist stays on the neutral exploration route until a
      // corresponding workshop exists.
      case PlayMechanic.chronologicalSequencing:
        return 'calendar_genius';

      case PlayMechanic.mapRouteNavigation:
        return 'constellation_mapper';

      default:
        return null;
    }
  }
}
