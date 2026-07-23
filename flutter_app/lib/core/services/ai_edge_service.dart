import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StrengthProfile {
  final String primaryStrength;
  final List<String> cognitiveMarkers;
  final Map<String, dynamic> telemetrySummary;
  final String recommendedGrowthPath;

  const StrengthProfile({
    required this.primaryStrength,
    required this.cognitiveMarkers,
    required this.telemetrySummary,
    required this.recommendedGrowthPath,
  });

  factory StrengthProfile.fromJson(Map<String, dynamic> json) {
    return StrengthProfile(
      primaryStrength: json['primary_strength'] as String? ?? 'Analytical Reasoning',
      cognitiveMarkers: List<String>.from(json['cognitive_markers'] ?? []),
      telemetrySummary: json['telemetry_summary'] as Map<String, dynamic>? ?? {},
      recommendedGrowthPath: json['recommended_growth_path'] as String? ?? 'Pattern Analytics Program',
    );
  }
}

class AiEdgeService {
  final SupabaseService _supabaseService;

  AiEdgeService(this._supabaseService);

  /// Invokes 'onboarding-ai' Edge Function.
  Future<Map<String, dynamic>> getOnboardingLayout({
    required Map<String, dynamic> questionnaireAnswers,
  }) async {
    try {
      final FunctionResponse response = await _supabaseService.client.functions.invoke(
        'onboarding-ai',
        body: {
          'questionnaire': questionnaireAnswers,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Invalid response type from onboarding-ai: ${data.runtimeType}');
      } else {
        throw Exception('onboarding-ai function error status: ${response.status}');
      }
    } catch (e) {
      return {
        'module_order': ['schedule', 'scanner', 'talent'],
        'high_auditory_risk': false,
        'routine_anxiety': true,
        'sensory_profile_name': 'Standard Sensory Layout (Offline Fallback)',
      };
    }
  }

  /// Invokes 'talent-ai' Edge Function.
  Future<StrengthProfile> analyzeGameTelemetry({
    required List<Map<String, dynamic>> telemetryVectors,
  }) async {
    try {
      final FunctionResponse response = await _supabaseService.client.functions.invoke(
        'talent-ai',
        body: {
          'telemetry_vectors': telemetryVectors,
          'device_timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return StrengthProfile.fromJson(data);
        }
        throw Exception('Invalid response format from talent-ai');
      } else {
        throw Exception('talent-ai function error status: ${response.status}');
      }
    } catch (e) {
      return const StrengthProfile(
        primaryStrength: 'Visual Pattern Recognition (Offline Demo)',
        cognitiveMarkers: ['High Visual Persistence', 'Rapid Spatial Sorting', 'Attention to Micro-details'],
        telemetrySummary: {'accuracy': 0.94, 'completion_seconds': 48},
        recommendedGrowthPath: 'Advanced Visual Interface Design & Coding',
      );
    }
  }

  /// Generates a local Gen-UI fallback. Raw prompt text must never be sent to
  /// an LLM from Flutter; cloud generation belongs in a scoped Edge Function.
  Future<Map<String, dynamic>> generateUiFromPrompt(String prompt) async {
    debugPrint('[AiEdgeService] Using local Gen-UI schema.');
    return _getLocalFallbackSchema(prompt);
  }

  Map<String, dynamic> _getLocalFallbackSchema(String prompt) {
    final lowercasePrompt = prompt.toLowerCase();

    if (lowercasePrompt.contains('noise') || 
        lowercasePrompt.contains('overwhelm') || 
        lowercasePrompt.contains('calm') || 
        lowercasePrompt.contains('breathe')) {
      return {
        'type': 'column',
        'children': [
          {
            'type': 'mascot_header',
            'title': 'AI Calm Sanctuary',
            'subtitle': 'Deep visual breathing cycle configured to lower sensory over-activation.',
            'mascot': 'sea_turtle',
            'theme_label': 'Calm Corner Mode',
          },
          {'type': 'spacer', 'height': 16.0},
          {
            'type': 'breathing_engine',
            'technique': '4-4-4 Visual Breathing Engine',
            'location': 'Marayoor Sandalwood Forest',
            'audio_anchor': 'Soft Rain & Ambient Brown Noise (432Hz)',
          },
        ]
      };
    } else if (lowercasePrompt.contains('train') || lowercasePrompt.contains('railway')) {
      return {
        'type': 'column',
        'children': [
          {
            'type': 'mascot_header',
            'title': 'AI Train Conductor Station',
            'subtitle': 'Route steam locomotive coupling and track switches.',
            'mascot': 'train',
            'theme_label': 'Train Conductor Mode',
          },
          {'type': 'spacer', 'height': 16.0},
          {
            'type': 'tactile_sound_pad',
            'title': 'Train Engine Status & Whistle Pad',
            'subtitle': 'Tap for locomotive audio chimes and haptic feedback',
            'buttons': [
              {'label': 'Horn', 'icon': 'audio'},
              {'label': 'Whistle', 'icon': 'music'},
              {'label': 'Engine', 'icon': 'check'},
            ],
          },
        ]
      };
    } else {
      return {
        'type': 'column',
        'children': [
          {
            'type': 'mascot_header',
            'title': 'AI Sensory Assistant',
            'subtitle': 'Custom regulation interface generated for: "$prompt"',
            'mascot': 'rocket',
            'theme_label': 'Sensory Assistant Mode',
          },
          {'type': 'spacer', 'height': 16.0},
          {
            'type': 'challenge_card',
            'title': 'Personalized Focus Node',
            'target_challenge': 'Adaptive Learning Task for $prompt',
            'icon': 'rocket',
            'strengths': ['Pattern Recognition', 'System Logic'],
          },
        ]
      };
    }
  }
}

final aiEdgeServiceProvider = Provider<AiEdgeService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AiEdgeService(supabaseService);
});
