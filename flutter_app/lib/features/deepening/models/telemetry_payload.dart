class TelemetryPayload {
  final String taskId;
  final String userId;
  final int layer;
  final double accuracy; // 0.0 to 1.0
  final int latencyMs; // Milliseconds from mount to submit
  final int recoveryCount; // Error corrections / retry attempts
  final double engagementScore; // Interaction frequency & focus score
  final String? userResponse;
  final bool usedHint;

  const TelemetryPayload({
    required this.taskId,
    required this.userId,
    required this.layer,
    required this.accuracy,
    required this.latencyMs,
    required this.recoveryCount,
    required this.engagementScore,
    this.userResponse,
    this.usedHint = false,
  });

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'user_id': userId,
        'layer': layer,
        'accuracy': accuracy,
        'latency_ms': latencyMs,
        'recovery_count': recoveryCount,
        'engagement_score': engagementScore,
        'user_response': userResponse,
        'used_hint': usedHint,
      };
}
