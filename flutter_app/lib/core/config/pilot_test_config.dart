/// Shared pilot guardian for private field testing (not for production release).
class PilotTestConfig {
  PilotTestConfig._();

  static const email = 'mindbridge.pilot.test@gmail.com';
  static const password = 'MindBridge2026!';

  static const enabled = bool.fromEnvironment('PILOT_LOGIN', defaultValue: true);
}
