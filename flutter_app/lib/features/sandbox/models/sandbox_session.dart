class SandboxSession {
  final String sessionId;
  final String userId;
  final String verticalId; // 'calendar_genius' or 'constellation_mapper'
  final DateTime startedAt;
  final String themeBundle;
  final int currentDifficultyTier;

  const SandboxSession({
    required this.sessionId,
    required this.userId,
    required this.verticalId,
    required this.startedAt,
    required this.themeBundle,
    required this.currentDifficultyTier,
  });

  factory SandboxSession.fromJson(Map<String, dynamic> json) {
    return SandboxSession(
      sessionId: json['session_id'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? '',
      verticalId: json['vertical_id'] as String? ?? 'calendar_genius',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
      themeBundle: json['theme_bundle'] as String? ?? 'theme_astronomy_v3',
      currentDifficultyTier: json['current_difficulty_tier'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'user_id': userId,
        'vertical_id': verticalId,
        'started_at': startedAt.toIso8601String(),
        'theme_bundle': themeBundle,
        'current_difficulty_tier': currentDifficultyTier,
      };
}
