class DashboardLayoutConfig {
  final List<String> moduleOrder;
  final bool highAuditoryRisk;
  final bool routineAnxiety;
  final String sensoryProfileName;

  const DashboardLayoutConfig({
    required this.moduleOrder,
    required this.highAuditoryRisk,
    required this.routineAnxiety,
    required this.sensoryProfileName,
  });

  DashboardLayoutConfig copyWith({
    List<String>? moduleOrder,
    bool? highAuditoryRisk,
    bool? routineAnxiety,
    String? sensoryProfileName,
  }) {
    return DashboardLayoutConfig(
      moduleOrder: moduleOrder ?? this.moduleOrder,
      highAuditoryRisk: highAuditoryRisk ?? this.highAuditoryRisk,
      routineAnxiety: routineAnxiety ?? this.routineAnxiety,
      sensoryProfileName: sensoryProfileName ?? this.sensoryProfileName,
    );
  }

  factory DashboardLayoutConfig.fromJson(Map<String, dynamic> json) {
    return DashboardLayoutConfig(
      moduleOrder: List<String>.from(json['module_order'] ?? ['schedule', 'scanner', 'talent']),
      highAuditoryRisk: json['high_auditory_risk'] as bool? ?? false,
      routineAnxiety: json['routine_anxiety'] as bool? ?? false,
      sensoryProfileName: json['sensory_profile_name'] as String? ?? 'Default Profile',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_order': moduleOrder,
      'high_auditory_risk': highAuditoryRisk,
      'routine_anxiety': routineAnxiety,
      'sensory_profile_name': sensoryProfileName,
    };
  }
}
