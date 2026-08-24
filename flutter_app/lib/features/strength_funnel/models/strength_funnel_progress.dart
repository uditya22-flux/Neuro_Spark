/// Saved in-progress strength funnel state for resume between layers.
class StrengthFunnelProgress {
  const StrengthFunnelProgress({
    required this.sessionId,
    required this.layerNumber,
    this.layerRunId,
    this.awaitingNextLayer = false,
    this.advancingSectorIds = const [],
    this.finalistSectorIds = const [],
    this.completedSectorIds = const [],
    this.layerScores = const {},
  });

  final String sessionId;
  final int layerNumber;
  final String? layerRunId;
  final bool awaitingNextLayer;
  final List<String> advancingSectorIds;
  final List<String> finalistSectorIds;
  final List<String> completedSectorIds;
  final Map<String, double> layerScores;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'layer_number': layerNumber,
        if (layerRunId != null) 'layer_run_id': layerRunId,
        'awaiting_next_layer': awaitingNextLayer,
        'advancing_sector_ids': advancingSectorIds,
        'finalist_sector_ids': finalistSectorIds,
        'completed_sector_ids': completedSectorIds,
        'layer_scores': layerScores,
      };

  factory StrengthFunnelProgress.fromJson(Map<String, dynamic> json) {
    return StrengthFunnelProgress(
      sessionId: json['session_id'] as String? ?? '',
      layerNumber: (json['layer_number'] as num?)?.toInt() ?? 1,
      layerRunId: json['layer_run_id'] as String?,
      awaitingNextLayer: json['awaiting_next_layer'] as bool? ?? false,
      advancingSectorIds: List<String>.from(json['advancing_sector_ids'] as List? ?? []),
      finalistSectorIds: List<String>.from(json['finalist_sector_ids'] as List? ?? []),
      completedSectorIds: List<String>.from(json['completed_sector_ids'] as List? ?? []),
      layerScores: (json['layer_scores'] as Map? ?? {}).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    );
  }

  StrengthFunnelProgress copyWith({
    String? sessionId,
    int? layerNumber,
    String? layerRunId,
    bool? awaitingNextLayer,
    List<String>? advancingSectorIds,
    List<String>? finalistSectorIds,
    List<String>? completedSectorIds,
    Map<String, double>? layerScores,
  }) {
    return StrengthFunnelProgress(
      sessionId: sessionId ?? this.sessionId,
      layerNumber: layerNumber ?? this.layerNumber,
      layerRunId: layerRunId ?? this.layerRunId,
      awaitingNextLayer: awaitingNextLayer ?? this.awaitingNextLayer,
      advancingSectorIds: advancingSectorIds ?? this.advancingSectorIds,
      finalistSectorIds: finalistSectorIds ?? this.finalistSectorIds,
      completedSectorIds: completedSectorIds ?? this.completedSectorIds,
      layerScores: layerScores ?? this.layerScores,
    );
  }
}
