import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/prototype_mode.dart';
import '../models/exploration_models.dart';
import '../models/visual_scene_spec.dart';

class VisualSceneRequest {
  const VisualSceneRequest({
    required this.childId,
    required this.layer,
    required this.taskId,
    required this.mechanic,
    required this.itemCount,
    this.syntheticDemoWorld,
    this.familiarColors = const [],
    this.visualStylePreference = VisualStylePreference.illustratedObjects,
    this.motionAllowed = true,
  });

  final String childId;
  final int layer;
  final String taskId;
  final PlayMechanic mechanic;
  final int itemCount;
  final SyntheticDemoWorld? syntheticDemoWorld;
  final List<FamiliarColor> familiarColors;
  final VisualStylePreference visualStylePreference;
  final bool motionAllowed;

  /// The only payload permitted in synthetic demo mode. In particular it has
  /// no child ID, task ID, name, age, theme text, or guardian-entered text.
  Map<String, dynamic> get syntheticDemoPayload {
    final palette = familiarColors.map((color) => color.name).toSet().take(3).toList();
    return {
      'scenarioId': (syntheticDemoWorld ?? SyntheticDemoWorld.vehicles).name,
      'palette': palette.isEmpty ? const ['blue'] : palette,
      'objectStyle': visualStylePreference.name,
      'motionAllowed': motionAllowed,
      'layer': layer,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is VisualSceneRequest &&
      other.childId == childId &&
      other.layer == layer &&
      other.taskId == taskId &&
      other.mechanic == mechanic &&
      other.itemCount == itemCount &&
      other.syntheticDemoWorld == syntheticDemoWorld &&
      listEquals(other.familiarColors, familiarColors) &&
      other.visualStylePreference == visualStylePreference &&
      other.motionAllowed == motionAllowed;

  @override
  int get hashCode => Object.hash(
        childId,
        layer,
        taskId,
        mechanic,
        itemCount,
        syntheticDemoWorld,
        Object.hashAll(familiarColors),
        visualStylePreference,
        motionAllowed,
      );
}

class VisualSceneService {
  Future<VisualSceneSpec?> load(VisualSceneRequest request) async {
    // Offline and builder builds never make an AI request, but they still
    // return the same rule-specific scene shape as cloud builds. This avoids
    // a generic colour-match fallback for the 30-sector showcase.
    if (localPrototypeMode || builderShowcaseMode) {
      return VisualSceneSpec.localForMechanic(
        mechanic: request.mechanic,
        itemCount: request.itemCount,
        subject: (request.syntheticDemoWorld ?? SyntheticDemoWorld.vehicles).name,
        palette: request.familiarColors.map((color) => color.name).toList(growable: false),
        objectStyle: request.visualStylePreference.name,
        motionAllowed: request.motionAllowed,
      );
    }
    try {
      if (syntheticDemoMode) {
        if (Supabase.instance.client.auth.currentSession == null) return null;
        final response = await Supabase.instance.client.functions.invoke(
          'generate-demo-visual-scene',
          body: request.syntheticDemoPayload,
        );
        return _parseScene(response.data);
      }

      // Production requests carry only an opaque child ID. The guardian-only
      // Edge Function reads the stored preferences after authorization.
      final response = await Supabase.instance.client.functions.invoke(
        'generate-visual-scene',
        body: {'childId': request.childId, 'layer': request.layer},
      );
      return _parseScene(response.data);
    } on FunctionException {
      // A local, non-verbal fallback remains available if cloud generation is
      // unavailable or is not consented to.
      return null;
    } catch (_) {
      return null;
    }
  }

  VisualSceneSpec? _parseScene(dynamic data) {
    if (data is! Map || data['scene'] is! Map) return null;
    return VisualSceneSpec.fromJson(Map<String, dynamic>.from(data['scene'] as Map));
  }
}

final visualSceneServiceProvider = Provider((ref) => VisualSceneService());

final visualSceneProvider = FutureProvider.autoDispose
    .family<VisualSceneSpec?, VisualSceneRequest>((ref, request) {
  return ref.read(visualSceneServiceProvider).load(request);
});
