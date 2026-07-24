import '../models/exploration_models.dart';

/// Ephemeral result used only by the builder-showcase state machine. It is not
/// persisted, rendered as a child score, or presented as a diagnostic result.
class PlayRoutingResult {
  const PlayRoutingResult({
    required this.mechanic,
    required this.score,
    required this.accuracy,
    required this.recovery,
    required this.engagement,
    required this.speed,
    required this.supportLevelUsed,
  });

  final PlayMechanic mechanic;
  final double score;
  final double accuracy;
  final double recovery;
  final double engagement;
  final double speed;
  final int supportLevelUsed;
}

/// Uses the agreed fixed routing formula:
/// 40% accuracy, 30% recovery, 20% engagement, and 10% speed.
class PlayRoutingScoreCalculator {
  const PlayRoutingScoreCalculator._();

  static PlayRoutingResult fromObservation(PlayObservation observation) {
    final telemetry = observation.telemetry;
    final interactions = telemetry.interactions.clamp(1, 1 << 30).toDouble();
    final expected =
        observation.expectedInteractions.clamp(1, 1 << 30).toDouble();
    final accuracy = _unit(telemetry.correctInteractions / interactions);
    // A completed interaction with no error is fully recovered by definition.
    // An entirely unanswered item is different: it has no correction signal,
    // so it receives no recovery credit when auto-advanced after inactivity.
    final noResponse =
        telemetry.interactions == 0 && telemetry.correctInteractions == 0;
    final recovery = noResponse
        ? 0.0
        : telemetry.misclicks == 0
            ? 1.0
            : _unit(telemetry.recoveredErrors / telemetry.misclicks);
    final engagement = _unit(telemetry.interactions / expected);
    final speed = _unit(1 -
        telemetry.activeLatencyMs /
            observation.speedBudgetMs.clamp(1, 1 << 30));
    final score =
        (0.40 * accuracy + 0.30 * recovery + 0.20 * engagement + 0.10 * speed) *
            100;
    return PlayRoutingResult(
      mechanic: observation.mechanics.single,
      score: score,
      accuracy: accuracy,
      recovery: recovery,
      engagement: engagement,
      speed: speed,
      supportLevelUsed: observation.supportLevelUsed,
    );
  }

  static List<PlayRoutingResult> rank(Iterable<PlayObservation> observations) {
    final grouped = <PlayMechanic, List<PlayObservation>>{};
    for (final observation in observations) {
      if (observation.mechanics.length != 1) continue;
      grouped
          .putIfAbsent(observation.mechanics.single, () => [])
          .add(observation);
    }
    final results = grouped.entries.map((entry) {
      final samples = entry.value.map(fromObservation).toList(growable: false);
      double average(double Function(PlayRoutingResult result) select) =>
          samples.map(select).reduce((left, right) => left + right) /
          samples.length;
      return PlayRoutingResult(
        mechanic: entry.key,
        score: average((result) => result.score),
        accuracy: average((result) => result.accuracy),
        recovery: average((result) => result.recovery),
        engagement: average((result) => result.engagement),
        speed: average((result) => result.speed),
        supportLevelUsed:
            samples.map((result) => result.supportLevelUsed).reduce(
                  (left, right) => left > right ? left : right,
                ),
      );
    }).toList();
    results.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      if (scoreOrder != 0) return scoreOrder;
      final supportOrder =
          left.supportLevelUsed.compareTo(right.supportLevelUsed);
      if (supportOrder != 0) return supportOrder;
      return left.mechanic.index.compareTo(right.mechanic.index);
    });
    return results;
  }

  static double _unit(num value) => value.clamp(0, 1).toDouble();
}

/// Chooses the next builder-showcase pool from the most recent layer only.
///
/// This is deliberately deterministic and session-local. It does not make a
/// clinical interpretation: it simply lets the showcase demonstrate that the
/// next visual layer changes in response to the interactions just completed.
/// The score itself remains the agreed 40/30/20/10 aggregate above.
class BuilderSurvivorSelector {
  const BuilderSurvivorSelector._();

  /// Every non-capstone layer uses this same explicit continuation threshold.
  /// It deliberately replaces a fixed 30→10→… count schedule.
  static const double continuationScoreThreshold = 60;

  static List<PlayMechanic> selectForNextLayer({
    required int completedLayer,
    required Iterable<PlayRoutingResult> latestLayerResults,
  }) {
    final ranked = List<PlayRoutingResult>.of(latestLayerResults)
      ..sort((left, right) {
        final scoreOrder = right.score.compareTo(left.score);
        if (scoreOrder != 0) return scoreOrder;
        final supportOrder =
            left.supportLevelUsed.compareTo(right.supportLevelUsed);
        if (supportOrder != 0) return supportOrder;
        return left.mechanic.index.compareTo(right.mechanic.index);
      });
    if (ranked.isEmpty) return const [];

    // The one final Layer 10 task is the capstone. It is always the strongest
    // mechanic from the immediately preceding layer, never a pre-set sector.
    if (completedLayer >= 9) return [ranked.first.mechanic];

    final currentStrengths = ranked
        .where((result) => result.score >= continuationScoreThreshold)
        .map((result) => result.mechanic)
        .toList(growable: false);
    return currentStrengths.isEmpty
        ? [ranked.first.mechanic]
        : currentStrengths;
  }
}
