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
  /// Sends parent questionnaire map responses and returns the custom dashboard layout JSON.
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
      // Return a fallback sensory layout config in case of connection issues
      return {
        'module_order': ['schedule', 'scanner', 'talent'],
        'high_auditory_risk': false,
        'routine_anxiety': true,
        'sensory_profile_name': 'Standard Sensory Layout (Offline Fallback)',
      };
    }
  }

  /// Invokes 'talent-ai' Edge Function.
  /// Sends puzzle game telemetry vectors (e.g. click counts, completion speed, correct/incorrect match cycles)
  /// and returns a formal StrengthProfile payload.
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
      // Fallback StrengthProfile for design demonstration
      return const StrengthProfile(
        primaryStrength: 'Visual Pattern Recognition (Offline Demo)',
        cognitiveMarkers: ['High Visual Persistence', 'Rapid Spatial Sorting', 'Attention to Micro-details'],
        telemetrySummary: {'accuracy': 0.94, 'completion_seconds': 48},
        recommendedGrowthPath: 'Advanced Visual Interface Design & Coding',
      );
    }
  }

  /// Generates dynamic UI JSON layouts matching natural language user prompts.
  Future<Map<String, dynamic>> generateUiFromPrompt(String prompt) async {
    // In a production app, we would invoke an AI edge function passing the prompt
    // to dynamic widget compilers. For this implementation, we parse keys locally.
    final lowercasePrompt = prompt.toLowerCase();
    
    // Simulate short latency
    await Future.delayed(const Duration(milliseconds: 600));

    if (lowercasePrompt.contains('noise') || 
        lowercasePrompt.contains('overwhelm') || 
        lowercasePrompt.contains('calm') || 
        lowercasePrompt.contains('breathe')) {
      return {
        'type': 'card',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'icon', 'icon': 'spa_rounded'},
              {'type': 'spacer', 'width': 8.0},
              {'type': 'text', 'value': 'AI Calm Space: Breathe Guide', 'is_header': true}
            ]
          },
          {'type': 'spacer', 'height': 12.0},
          {'type': 'text', 'value': 'Let\'s do a quiet visual breathing cycle. Match your breaths to the pulsing circle below to lower sensory activation.', 'is_header': false},
          {'type': 'spacer', 'height': 16.0},
          {'type': 'glow_ring'},
          {'type': 'spacer', 'height': 16.0},
          {'type': 'button', 'label': 'Start Silent Vibration', 'action': 'trigger_vibration_tap'}
        ]
      };
    } else if (lowercasePrompt.contains('train') || 
               lowercasePrompt.contains('railway') || 
               lowercasePrompt.contains('track')) {
      return {
        'type': 'card',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'icon', 'icon': 'train_rounded'},
              {'type': 'spacer', 'width': 8.0},
              {'type': 'text', 'value': 'AI Train Junction Tool', 'is_header': true}
            ]
          },
          {'type': 'spacer', 'height': 12.0},
          {'type': 'text', 'value': 'Route 9 Express steam locomotive coupling is verified. Connect track switches to start passenger simulation.', 'is_header': false},
          {'type': 'spacer', 'height': 16.0},
          {
            'type': 'row',
            'children': [
              {'type': 'button', 'label': 'Play Horn Chime', 'action': 'play_chime'},
              {'type': 'spacer', 'width': 12.0},
              {'type': 'button', 'label': 'Engage Haptics', 'action': 'trigger_vibration_tap'}
            ]
          }
        ]
      };
    } else if (lowercasePrompt.contains('dino') || 
               lowercasePrompt.contains('fossil') || 
               lowercasePrompt.contains('dig')) {
      return {
        'type': 'card',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'icon', 'icon': 'terrain_rounded'},
              {'type': 'spacer', 'width': 8.0},
              {'type': 'text', 'value': 'AI Fossil Dig Site Specimen', 'is_header': true}
            ]
          },
          {'type': 'spacer', 'height': 12.0},
          {'type': 'text', 'value': 'Stratum layer 4 fossils cataloged: Triceratops rib fragment found. Tap brush to clean specimen.', 'is_header': false},
          {'type': 'spacer', 'height': 16.0},
          {'type': 'button', 'label': 'Clean Specimen with Soft Haptics', 'action': 'trigger_vibration_tap'}
        ]
      };
    } else if (lowercasePrompt.contains('code') || 
               lowercasePrompt.contains('logic') || 
               lowercasePrompt.contains('program')) {
      return {
        'type': 'card',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'icon', 'icon': 'terminal_rounded'},
              {'type': 'spacer', 'width': 8.0},
              {'type': 'text', 'value': 'AI Logic Compiler Node', 'is_header': true}
            ]
          },
          {'type': 'spacer', 'height': 12.0},
          {'type': 'text', 'value': 'Define conditional flow: If safeMode active, set volume limit to 0 decibels.', 'is_header': false},
          {'type': 'spacer', 'height': 16.0},
          {'type': 'button', 'label': 'Compile & Run Logic Block', 'action': 'play_chime'}
        ]
      };
    } else {
      // General sensory assistance fallback
      return {
        'type': 'card',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'icon', 'icon': 'help_outline_rounded'},
              {'type': 'spacer', 'width': 8.0},
              {'type': 'text', 'value': 'AI Sensory Assistant Helper', 'is_header': true}
            ]
          },
          {'type': 'spacer', 'height': 12.0},
          {'type': 'text', 'value': 'I can construct custom regulation widgets for you. Try asking for a "quiet breathing space", a "train challenge", "dinosaur fossil tool", or a "coding loop".', 'is_header': false}
        ]
      };
    }
  }
}

final aiEdgeServiceProvider = Provider<AiEdgeService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AiEdgeService(supabaseService);
});
