import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';

class SensoryMetrics {
  final String userId;
  final double auditorySensitivity; // 0.0 to 1.0
  final double visualSensitivity;   // 0.0 to 1.0
  final double tactileSensitivity;  // 0.0 to 1.0
  final String cognitiveNotes;

  const SensoryMetrics({
    required this.userId,
    required this.auditorySensitivity,
    required this.visualSensitivity,
    required this.tactileSensitivity,
    required this.cognitiveNotes,
  });

  factory SensoryMetrics.fromJson(Map<String, dynamic> json) {
    return SensoryMetrics(
      userId: json['user_id'] as String? ?? '',
      auditorySensitivity: (json['auditory_sensitivity'] as num?)?.toDouble() ?? 0.5,
      visualSensitivity: (json['visual_sensitivity'] as num?)?.toDouble() ?? 0.5,
      tactileSensitivity: (json['tactile_sensitivity'] as num?)?.toDouble() ?? 0.5,
      cognitiveNotes: json['cognitive_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'auditory_sensitivity': auditorySensitivity,
      'visual_sensitivity': visualSensitivity,
      'tactile_sensitivity': tactileSensitivity,
      'cognitive_notes': cognitiveNotes,
    };
  }
}

class ProfileDao {
  final SupabaseService _supabaseService;

  ProfileDao(this._supabaseService);

  Future<SensoryMetrics?> getSensoryMetrics(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('profiles')
          .select('user_id, auditory_sensitivity, visual_sensitivity, tactile_sensitivity, cognitive_notes')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return SensoryMetrics.fromJson(response);
      }
    } catch (e) {
      // Fallback or logger
    }
    return null;
  }

  Future<void> saveSensoryMetrics(SensoryMetrics metrics) async {
    try {
      await _supabaseService.client.from('profiles').upsert(metrics.toJson());
    } catch (e) {
      // Offline fallback
    }
  }
}

final profileDaoProvider = Provider<ProfileDao>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ProfileDao(supabaseService);
});
