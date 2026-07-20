import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

  // Groq API Key (Configurable via environment or fallback default key)
  static const String _groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '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',
  );

  static const String _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

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

  /// Generates dynamic UI JSON layouts using Groq AI LPU (`llama-3.3-70b-versatile`).
  Future<Map<String, dynamic>> generateUiFromPrompt(String prompt) async {
    try {
      debugPrint('[AiEdgeService] Invoking Groq LPU API for prompt: "$prompt"');

      final systemPrompt = '''
You are a Generative UI Engine for neurodivergent accessibility. You MUST return ONLY a valid JSON object matching the GenUI parser schema.
Available node types:
- mascot_header: { "type": "mascot_header", "title": string, "subtitle": string, "mascot": "rocket"|"dinosaur"|"train"|"sea_turtle"|"code", "theme_label": string }
- challenge_card: { "type": "challenge_card", "title": string, "target_challenge": string, "icon": string, "strengths": string[] }
- breathing_engine: { "type": "breathing_engine", "technique": string, "location": string, "audio_anchor": string }
- tactile_sound_pad: { "type": "tactile_sound_pad", "title": string, "subtitle": string, "buttons": [{"label": string, "icon": "audio"|"music"|"check"}] }
- card, row, column, text, icon, button, glow_ring, spacer

Return a root JSON object: { "type": "column", "children": [...] } tailored to the prompt.
''';

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'response_format': {'type': 'json_object'},
          'temperature': 0.5,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Generate a personalized accessibility UI layout for: $prompt'}
          ],
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final bodyJson = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = bodyJson['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final contentStr = choices[0]['message']['content'] as String;
          final schema = jsonDecode(contentStr) as Map<String, dynamic>;
          debugPrint('[AiEdgeService] Successfully received dynamic Groq AI schema');
          return schema;
        }
      }
    } catch (e) {
      debugPrint('[AiEdgeService] Groq API call error: $e. Falling back to local rules engine.');
    }

    // Fallback schema generator if offline or network error occurs
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
