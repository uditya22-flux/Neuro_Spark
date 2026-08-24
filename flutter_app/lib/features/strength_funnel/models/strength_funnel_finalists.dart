/// Persisted finalist play themes after the 10-layer strength funnel.
class StrengthFunnelFinalists {
  const StrengthFunnelFinalists({
    required this.sectorIds,
    this.completedAt,
    this.layerScores = const {},
  });

  final List<String> sectorIds;
  final DateTime? completedAt;
  final Map<String, double> layerScores;

  Map<String, dynamic> toJson() => {
        'sector_ids': sectorIds,
        if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
        'layer_scores': layerScores,
      };

  factory StrengthFunnelFinalists.fromJson(Map<String, dynamic> json) {
    return StrengthFunnelFinalists(
      sectorIds: List<String>.from(json['sector_ids'] as List? ?? []),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      layerScores: (json['layer_scores'] as Map? ?? {}).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    );
  }
}
