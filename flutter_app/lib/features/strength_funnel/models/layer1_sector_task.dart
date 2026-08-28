/// A Layer 1 RIASEC sector activity prompt (generated from JSON template).
class Layer1SectorTask {
  const Layer1SectorTask({
    required this.sectorId,
    required this.displayName,
    required this.presentMomentPrompt,
    required this.activityLabel,
    required this.pictureDescription,
    this.videoDescription,
    required this.rendererModality,
    required this.minEnjoymentLabel,
    required this.maxEnjoymentLabel,
    this.provenanceFramework,
    this.personalizationReason,
  });

  final String sectorId;
  final String displayName;
  final String presentMomentPrompt;
  final String activityLabel;
  final String pictureDescription;
  final String? videoDescription;
  final String rendererModality;
  final String minEnjoymentLabel;
  final String maxEnjoymentLabel;
  final String? provenanceFramework;
  final String? personalizationReason;

  Layer1SectorTask copyWith({
    String? presentMomentPrompt,
    String? activityLabel,
    String? pictureDescription,
    String? provenanceFramework,
    String? personalizationReason,
  }) {
    return Layer1SectorTask(
      sectorId: sectorId,
      displayName: displayName,
      presentMomentPrompt: presentMomentPrompt ?? this.presentMomentPrompt,
      activityLabel: activityLabel ?? this.activityLabel,
      pictureDescription: pictureDescription ?? this.pictureDescription,
      videoDescription: videoDescription,
      rendererModality: rendererModality,
      minEnjoymentLabel: minEnjoymentLabel,
      maxEnjoymentLabel: maxEnjoymentLabel,
      provenanceFramework: provenanceFramework ?? this.provenanceFramework,
      personalizationReason: personalizationReason ?? this.personalizationReason,
    );
  }

  factory Layer1SectorTask.sampleRealistic({
    required String rendererModality,
  }) {
    return Layer1SectorTask(
      sectorId: 'r_build_fix',
      displayName: 'Build & Fix',
      presentMomentPrompt: 'Is snapping blocks together fun for you right now?',
      activityLabel: 'Building a small tower',
      pictureDescription:
          'Simple drawing: two hands stacking three blocks. No faces. Neutral colors.',
      videoDescription: 'Silent 3-second loop of blocks clicking together.',
      rendererModality: rendererModality,
      minEnjoymentLabel: 'Not fun right now',
      maxEnjoymentLabel: 'Really fun right now',
    );
  }

  factory Layer1SectorTask.fromJson(Map<String, dynamic> json) {
    return Layer1SectorTask(
      sectorId: json['sector_id'] as String? ?? json['sectorId'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? '',
      presentMomentPrompt: json['present_moment_prompt'] as String? ??
          json['presentMomentPrompt'] as String? ??
          '',
      activityLabel: json['activity_label'] as String? ?? json['activityLabel'] as String? ?? '',
      pictureDescription: json['picture_description'] as String? ??
          json['pictureDescription'] as String? ??
          '',
      videoDescription: json['video_description'] as String? ?? json['videoDescription'] as String?,
      rendererModality: json['renderer_modality'] as String? ??
          json['rendererModality'] as String? ??
          'picture',
      minEnjoymentLabel: json['min_enjoyment_label'] as String? ??
          json['minEnjoymentLabel'] as String? ??
          'Not fun right now',
      maxEnjoymentLabel: json['max_enjoyment_label'] as String? ??
          json['maxEnjoymentLabel'] as String? ??
          'Really fun right now',
    );
  }

  Map<String, dynamic> toJson() => {
        'sector_id': sectorId,
        'display_name': displayName,
        'present_moment_prompt': presentMomentPrompt,
        'activity_label': activityLabel,
        'picture_description': pictureDescription,
        if (videoDescription != null) 'video_description': videoDescription,
        'renderer_modality': rendererModality,
        'min_enjoyment_label': minEnjoymentLabel,
        'max_enjoyment_label': maxEnjoymentLabel,
      };
}
