import '../models/intake_models.dart';

/// UI constraints produced by the ISAA Modality Routing Engine.
/// Mirrors `supabase/functions/_shared/modality_router.ts`.
class ModalityConstraints {
  const ModalityConstraints({
    required this.requiresVisualItems,
    required this.allowText,
    required this.allowVideo,
    required this.allowHaptics,
    required this.disableAnimations,
    required this.useSimpleConcreteDrawings,
    required this.primaryModality,
    required this.fallbackModalities,
    required this.pacingMultiplier,
  });

  factory ModalityConstraints.fromJson(Map<String, dynamic> json) {
    return ModalityConstraints(
      requiresVisualItems: json['requiresVisualItems'] as bool? ?? true,
      allowText: json['allowText'] as bool? ?? false,
      allowVideo: json['allowVideo'] as bool? ?? false,
      allowHaptics: json['allowHaptics'] as bool? ?? false,
      disableAnimations: json['disableAnimations'] as bool? ?? false,
      useSimpleConcreteDrawings: json['useSimpleConcreteDrawings'] as bool? ?? true,
      primaryModality: json['primaryModality'] as String? ?? 'picture',
      fallbackModalities: List<String>.from(json['fallbackModalities'] as List? ?? []),
      pacingMultiplier: (json['pacingMultiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  final bool requiresVisualItems;
  final bool allowText;
  final bool allowVideo;
  final bool allowHaptics;
  final bool disableAnimations;
  final bool useSimpleConcreteDrawings;
  final String primaryModality;
  final List<String> fallbackModalities;
  final double pacingMultiplier;
}

class ModalityRouter {
  const ModalityRouter();

  ModalityConstraints routeFromIsaa(ISAAClinicalProfile clinical, ParentQualitativeProfile parent) {
    final lowVerbal = clinical.speechCommunication >= 4;
    final moderateVerbal = clinical.speechCommunication == 3;
    final highSensory = clinical.sensoryAspects >= 4 || parent.visualTriggers.isNotEmpty;
    final soundSensitive = clinical.sensoryAspects >= 4 || parent.soundTriggers.isNotEmpty;
    final prefersHaptics = parent.tactilePreference == TactilePreference.prefersHaptics;
    final noVibrations = parent.tactilePreference == TactilePreference.noVibrations;

    final requiresVisualItems = lowVerbal || highSensory || moderateVerbal;
    final allowText = !lowVerbal && clinical.speechCommunication <= 2;
    final allowVideo = !highSensory && !soundSensitive && clinical.sensoryAspects <= 3;
    final allowHaptics = !noVibrations && (prefersHaptics || soundSensitive);
    final disableAnimations = highSensory ||
        parent.visualTriggers.any((t) =>
            RegExp(r'flash|parallax|floating|busy', caseSensitive: false).hasMatch(t));

    String primaryModality = 'picture';
    final fallbacks = <String>[];

    if (lowVerbal) {
      primaryModality = allowHaptics ? 'haptic' : 'picture';
      fallbacks.add('picture');
      if (allowHaptics) fallbacks.add('haptic');
    } else if (allowText) {
      primaryModality = 'text';
      fallbacks.add('picture');
    } else if (allowVideo) {
      primaryModality = 'video';
      fallbacks.addAll(['picture', 'text']);
    } else {
      primaryModality = 'picture';
      if (allowHaptics) fallbacks.add('haptic');
    }

    final pacingMultiplier = highSensory
        ? 1.35
        : clinical.behaviorPatterns >= 4
            ? 1.15
            : 1.0;

    return ModalityConstraints(
      requiresVisualItems: requiresVisualItems,
      allowText: allowText,
      allowVideo: allowVideo,
      allowHaptics: allowHaptics,
      disableAnimations: disableAnimations,
      useSimpleConcreteDrawings: true,
      primaryModality: primaryModality,
      fallbackModalities: fallbacks,
      pacingMultiplier: pacingMultiplier,
    );
  }

  /// Resolves which Layer 1 renderer to use for a sector prompt.
  String resolveRendererModality(ModalityConstraints constraints) {
    if (constraints.primaryModality == 'text' && constraints.allowText) {
      return 'text';
    }
    if (constraints.primaryModality == 'video' && constraints.allowVideo) {
      return 'video';
    }
    if (constraints.primaryModality == 'haptic' && constraints.allowHaptics) {
      return 'haptic';
    }
    return 'picture';
  }

  void assertPresentMomentFraming(String text) {
    const forbidden = [
      'career',
      'job',
      'employ',
      'salary',
      'when you grow up',
      'become a',
      'profession',
      'industry',
    ];
    final lower = text.toLowerCase();
    for (final term in forbidden) {
      if (lower.contains(term)) {
        throw StateError('Golden rule violation: forbidden term "$term"');
      }
    }
  }
}
