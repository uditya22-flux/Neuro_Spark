class SandboxAttempt {
  final String attemptId;
  final String sessionId;
  final int puzzleSeed;
  final int timeToSolveMs;
  final int correctionsCount;
  final int difficultyTier;
  final bool completed;
  final DateTime occurredAt;

  const SandboxAttempt({
    required this.attemptId,
    required this.sessionId,
    required this.puzzleSeed,
    required this.timeToSolveMs,
    required this.correctionsCount,
    required this.difficultyTier,
    required this.completed,
    required this.occurredAt,
  });

  factory SandboxAttempt.fromJson(Map<String, dynamic> json) {
    return SandboxAttempt(
      attemptId: json['attempt_id'] as String? ?? 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: json['session_id'] as String? ?? '',
      puzzleSeed: json['puzzle_seed'] as int? ?? 1001,
      timeToSolveMs: json['time_to_solve_ms'] as int? ?? 0,
      correctionsCount: json['corrections_count'] as int? ?? 0,
      difficultyTier: json['difficulty_tier'] as int? ?? 1,
      completed: json['completed'] as bool? ?? true,
      occurredAt: json['occurred_at'] != null ? DateTime.parse(json['occurred_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'attempt_id': attemptId,
        'session_id': sessionId,
        'puzzle_seed': puzzleSeed,
        'time_to_solve_ms': timeToSolveMs,
        'corrections_count': correctionsCount,
        'difficulty_tier': difficultyTier,
        'completed': completed,
        'occurred_at': occurredAt.toIso8601String(),
      };
}
