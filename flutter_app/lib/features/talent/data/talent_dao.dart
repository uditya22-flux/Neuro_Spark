import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

class RoadmapStep {
  final String id;
  final int stepNumber;
  final String title;
  final String description;
  final String status; // 'locked', 'unlocked', 'completed'
  final String sensoryNote;

  const RoadmapStep({
    required this.id,
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.sensoryNote,
  });

  bool get isCompleted => status == 'completed';
  bool get isUnlocked => status == 'unlocked' || status == 'completed';

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    return RoadmapStep(
      id: json['id'] as String? ?? '',
      stepNumber: json['step_number'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'locked',
      sensoryNote: json['sensory_note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'status': status,
      'sensory_note': sensoryNote,
    };
  }
}

class TalentDao {
  final SupabaseService _supabaseService;

  TalentDao(this._supabaseService);

  Future<List<RoadmapStep>> getRoadmapSteps(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('talent_growth')
          .select()
          .eq('user_id', userId)
          .order('step_number', ascending: true);

      return (response as List)
          .map((item) => RoadmapStep.fromJson(item))
          .toList();
    } catch (e) {
      // Fallback
    }

    // Default MVP milestones list
    return [
      const RoadmapStep(
        id: 't_1',
        stepNumber: 1,
        title: 'Core Telemetry Puzzle Complete',
        description: 'Complete the pattern identification sensory assessment.',
        status: 'completed',
        sensoryNote: 'Auditory level: None. High visual contrast.',
      ),
      const RoadmapStep(
        id: 't_2',
        stepNumber: 2,
        title: 'Logical Sorting Assessment',
        description: 'Execute nested category sorting puzzles.',
        status: 'unlocked',
        sensoryNote: 'Interactive pacing: Self-directed.',
      ),
      const RoadmapStep(
        id: 't_3',
        stepNumber: 3,
        title: 'Deep Focus Project Draft',
        description: 'Initiate a talent focus roadmap task builder.',
        status: 'locked',
        sensoryNote: 'Requires Stage 2 approval.',
      ),
    ];
  }

  Future<void> updateStepStatus(String stepId, String newStatus) async {
    try {
      await _supabaseService.client
          .from('talent_growth')
          .update({'status': newStatus})
          .eq('id', stepId);
    } catch (e) {
      // Handle or print
    }
  }
}

final talentDaoProvider = Provider<TalentDao>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return TalentDao(supabaseService);
});
