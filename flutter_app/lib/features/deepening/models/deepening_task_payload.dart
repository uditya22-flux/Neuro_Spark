class DeepeningTaskPayload {
  final String taskId;
  final String userId;
  final String sessionId;
  final int layer;
  final int totalLayers;
  final String verticalId; // 'calendar_genius' or 'constellation_mapper'
  final String themeSkin; // 'cosmic_space', 'sage_green', 'pastel_dinosaur', 'terracotta_train'
  final String prompt;
  final Map<String, dynamic> taskData;
  final String sourceType;
  final String modality;
  final int supportLevel;
  final int timingVariant;
  final int requiredExecutions;
  final String status;
  final bool isCompleted;

  const DeepeningTaskPayload({
    required this.taskId,
    required this.userId,
    this.sessionId = '',
    required this.layer,
    this.totalLayers = 10,
    required this.verticalId,
    required this.themeSkin,
    required this.prompt,
    required this.taskData,
    this.sourceType = 'created',
    this.modality = 'visual',
    this.supportLevel = 0,
    this.timingVariant = 1,
    this.requiredExecutions = 1,
    this.status = 'in_progress',
    this.isCompleted = false,
  });

  factory DeepeningTaskPayload.fromJson(Map<String, dynamic> json) {
    return DeepeningTaskPayload(
      taskId: json['task_id'] as String? ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      layer: json['layer'] as int? ?? 1,
      totalLayers: json['total_layers'] as int? ?? 10,
      verticalId: json['vertical_id'] as String? ?? 'calendar_genius',
      themeSkin: json['theme_skin'] as String? ?? 'cosmic_space',
      prompt: json['prompt'] as String? ?? 'Solve the adaptive puzzle below',
      taskData: json['task_data'] as Map<String, dynamic>? ?? {},
      sourceType: json['source_type'] as String? ?? 'created',
      modality: json['modality'] as String? ?? 'visual',
      supportLevel: json['support_level'] as int? ?? 0,
      timingVariant: json['timing_variant'] as int? ?? 1,
      requiredExecutions: json['required_executions'] as int? ?? 1,
      status: json['status'] as String? ?? 'in_progress',
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'user_id': userId,
        'session_id': sessionId,
        'layer': layer,
        'total_layers': totalLayers,
        'vertical_id': verticalId,
        'theme_skin': themeSkin,
        'prompt': prompt,
        'task_data': taskData,
        'source_type': sourceType,
        'modality': modality,
        'support_level': supportLevel,
        'timing_variant': timingVariant,
        'required_executions': requiredExecutions,
        'status': status,
        'is_completed': isCompleted,
      };
}
