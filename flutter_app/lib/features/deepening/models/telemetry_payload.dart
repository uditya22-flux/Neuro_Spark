class TelemetryPayload {
  final String taskId;
  final String? responseId;
  final String userId;
  final String sessionId;
  final int layer;
  final double accuracy; // 0.0 to 1.0
  final int latencyMs; // Milliseconds from mount to submit
  final int recoveryCount; // Error corrections / retry attempts
  final double engagementScore; // Interaction frequency & focus score
  final String? userResponse;
  final bool usedHint;
  final int supportLevelUsed;
  final int retryCount;
  final int answerChanges;
  final bool skipped;
  final String modality;

  const TelemetryPayload({
    required this.taskId,
    this.responseId,
    required this.userId,
    this.sessionId = '',
    required this.layer,
    required this.accuracy,
    required this.latencyMs,
    required this.recoveryCount,
    required this.engagementScore,
    this.userResponse,
    this.usedHint = false,
    this.supportLevelUsed = 0,
    this.retryCount = 0,
    this.answerChanges = 0,
    this.skipped = false,
    this.modality = 'visual',
  });

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        if (responseId != null) 'response_id': responseId,
        'user_id': userId,
        'session_id': sessionId,
        'layer': layer,
        'accuracy': accuracy,
        'latency_ms': latencyMs,
        'recovery_count': recoveryCount,
        'engagement_score': engagementScore,
        'user_response': userResponse,
        'used_hint': usedHint,
        'support_level_used': supportLevelUsed,
        'timing': {'latency_ms': latencyMs},
        'behavior': {
          'retry_count': retryCount,
          'hint_usage': usedHint ? 1 : 0,
          'answer_changes': answerChanges,
          'skipped': skipped,
        },
        'modality': modality,
      };
}
