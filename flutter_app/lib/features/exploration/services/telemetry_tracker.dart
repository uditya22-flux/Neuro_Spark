import '../models/exploration_models.dart';

/// Captures a single activity's aggregate interaction signals. Time spent in a
/// support pause is excluded. Builder showcase routing keeps this object only
/// in memory for the running session.
class TelemetryTracker {
  final Stopwatch _stopwatch = Stopwatch()..start();
  int _misclicks = 0;
  int _recoveredErrors = 0;
  int _interactions = 0;
  int _correctInteractions = 0;
  bool _needsRecovery = false;

  /// Active time elapsed so far, excluding any Support Ladder pause. Cloud
  /// synthetic mode sends this bounded value with each visual selection; it
  /// does not send a free-text response or pointer trace.
  int get activeLatencyMs => _stopwatch.elapsedMilliseconds;

  void recordSoftMiss() {
    _misclicks++;
    _interactions++;
    _needsRecovery = true;
  }

  void recordCorrectChoice() {
    _interactions++;
    _correctInteractions++;
    if (_needsRecovery) _recoveredErrors++;
    _needsRecovery = false;
  }

  void pause() => _stopwatch.stop();
  void resume() {
    if (!_stopwatch.isRunning) _stopwatch.start();
  }

  /// Reads the in-progress aggregate without stopping the activity. When a
  /// visual option is about to be sent to the cloud function, include that
  /// pending interaction so the bounded request describes the current tap.
  ExplorationTelemetry snapshot({bool includePendingInteraction = false}) =>
      ExplorationTelemetry(
        activeLatencyMs: activeLatencyMs,
        misclicks: _misclicks,
        recoveredErrors: _recoveredErrors,
        interactions: _interactions + (includePendingInteraction ? 1 : 0),
        correctInteractions: _correctInteractions,
      );

  ExplorationTelemetry finish() {
    _stopwatch.stop();
    return ExplorationTelemetry(
      activeLatencyMs: _stopwatch.elapsedMilliseconds,
      misclicks: _misclicks,
      recoveredErrors: _recoveredErrors,
      interactions: _interactions,
      correctInteractions: _correctInteractions,
    );
  }
}
