import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/demo_config.dart';
import '../features/strength_funnel/data/strength_funnel_math.dart';
import '../features/strength_funnel/models/layer1_sector_task.dart';
import '../features/strength_funnel/models/riasec_sector.dart';
import '../features/strength_funnel/services/sector_prompt_personalizer.dart';
import '../models/intake_models.dart';
import '../providers/game_environment_provider.dart';
import '../services/modality_router.dart';

/// Remote + local fallback for multi-layer RIASEC strength funnel sessions.
class StrengthFunnelRepository {
  const StrengthFunnelRepository({
    ModalityRouter? router,
    SectorPromptPersonalizer? personalizer,
  })  : _router = router ?? const ModalityRouter(),
        _personalizer = personalizer ?? const SectorPromptPersonalizer();

  final ModalityRouter _router;
  final SectorPromptPersonalizer _personalizer;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<StrengthFunnelStartResult> startLayer(
    IntakeSessionBundle bundle, {
    required int layerNumber,
    String? sessionId,
  }) async {
    if (DemoConfig.isActive) {
      return _startLocal(bundle, layerNumber: layerNumber, sessionId: sessionId);
    }

    final client = _client;
    final childId = bundle.childId ?? 'local_child';
    final isaaPayload = _isaaPayload(bundle.clinical, bundle.parent);

    if (client != null && client.auth.currentUser != null) {
      try {
        final response = await client.functions.invoke(
          'strength-funnel-start',
          body: {
            'child_id': childId,
            'isaa': isaaPayload,
            'layer_number': layerNumber,
            if (sessionId != null) 'session_id': sessionId,
          },
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        return StrengthFunnelStartResult.fromJson(data, remote: true);
      } catch (e) {
        debugPrint('[StrengthFunnelRepository] start remote failed: $e');
      }
    }

    return _startLocal(
      bundle,
      layerNumber: layerNumber,
      sessionId: sessionId,
    );
  }

  Future<StrengthFunnelStartResult> startLayer1(IntakeSessionBundle bundle) {
    return startLayer(bundle, layerNumber: 1);
  }

  Future<StrengthFunnelSubmitResult> submitScore({
    required String sessionId,
    required String layerRunId,
    required String childId,
    required String sectorId,
    required double engagementScore,
    required String modalityUsed,
    required int layerNumber,
    required int totalSectorsInLayer,
    required int scoredCount,
    int? latencyMs,
  }) async {
    final client = _client;

    if (client != null &&
        client.auth.currentUser != null &&
        !sessionId.startsWith('local_')) {
      try {
        final response = await client.functions.invoke(
          'strength-funnel-submit-score',
          body: {
            'child_id': childId,
            'session_id': sessionId,
            'layer_run_id': layerRunId,
            'sector_id': sectorId,
            'engagement_score': engagementScore,
            'modality_used': modalityUsed,
            if (latencyMs != null) 'latency_ms': latencyMs,
          },
        );
        return StrengthFunnelSubmitResult.fromJson(
          Map<String, dynamic>.from(response.data as Map? ?? {}),
        );
      } catch (e) {
        debugPrint('[StrengthFunnelRepository] submit remote failed: $e');
      }
    }

    return StrengthFunnelSubmitResult.localFallback(
      sectorId: sectorId,
      engagementScore: engagementScore,
      scoredCount: scoredCount,
      totalSectors: totalSectorsInLayer,
      layerNumber: layerNumber,
    );
  }

  StrengthFunnelStartResult _startLocal(
    IntakeSessionBundle bundle, {
    required int layerNumber,
    String? sessionId,
    List<String>? sectorIds,
    Map<String, double> priorEngagement = const {},
  }) {
    final constraints = _router.routeFromIsaa(bundle.clinical, bundle.parent);
    final modality = _router.resolveRendererModality(constraints);
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeIds = sectorIds ??
        (DemoConfig.isActive && layerNumber == 1
            ? DemoConfig.representativeSectorIds
            : layerNumber == 1
                ? allRiasecSectorIds()
                : allRiasecSectorIds().take(sectorsAdvancingAfterLayer(1)).toList());

    final tasks = activeIds.map((id) {
      final sector = sectorById(id);
      if (sector == null) {
        throw StateError('Unknown sector $id');
      }
      final personalized = _personalizer.resolve(
        sector: sector,
        bundle: bundle,
        layer: layerNumber,
        priorEngagement: priorEngagement,
      );
      return Layer1SectorTask(
        sectorId: sector.id,
        displayName: sector.displayName,
        presentMomentPrompt: personalized.presentMomentPrompt,
        activityLabel: personalized.activityLabel,
        pictureDescription: personalized.pictureDescription,
        videoDescription: 'Silent activity loop with no background music.',
        rendererModality: modality,
        minEnjoymentLabel: 'Not fun right now',
        maxEnjoymentLabel: 'Really fun right now',
        provenanceFramework: personalized.provenanceFramework,
        personalizationReason: personalized.personalizationReason,
      );
    }).toList();

    return StrengthFunnelStartResult(
      sessionId: sessionId ?? 'local_session_$now',
      layerRunId: 'local_layer_${layerNumber}_$now',
      layerNumber: layerNumber,
      totalSectors: tasks.length,
      constraints: constraints,
      tasks: tasks,
      completedSectorIds: const [],
      remote: false,
    );
  }

  StrengthFunnelStartResult startLocalLayerFromScores({
    required IntakeSessionBundle bundle,
    required int layerNumber,
    required String sessionId,
    required List<String> advancingSectorIds,
    Map<String, double> priorEngagement = const {},
  }) {
    return _startLocal(
      bundle,
      layerNumber: layerNumber,
      sessionId: sessionId,
      sectorIds: advancingSectorIds,
      priorEngagement: priorEngagement,
    );
  }

  List<String> computeAdvancingLocally(Map<String, double> scores, int layerNumber) {
    final advanceCount = DemoConfig.isActive
        ? DemoConfig.advancingCount(scores.length)
        : sectorsAdvancingAfterLayer(layerNumber);
    return selectAdvancingSectors(scores, advanceCount);
  }

  /// Re-personalizes remote tasks using the child's intake profile and usage.
  List<Layer1SectorTask> personalizeTasks({
    required IntakeSessionBundle bundle,
    required List<Layer1SectorTask> tasks,
    required int layerNumber,
    Map<String, double> priorEngagement = const {},
  }) {
    return tasks.map((task) {
      final sector = sectorById(task.sectorId);
      if (sector == null) return task;
      final personalized = _personalizer.resolve(
        sector: sector,
        bundle: bundle,
        layer: layerNumber,
        priorEngagement: priorEngagement,
      );
      return task.copyWith(
        presentMomentPrompt: personalized.presentMomentPrompt,
        activityLabel: personalized.activityLabel,
        pictureDescription: personalized.pictureDescription,
        provenanceFramework: personalized.provenanceFramework,
        personalizationReason: personalized.personalizationReason,
      );
    }).toList();
  }

  Map<String, dynamic> _isaaPayload(
    ISAAClinicalProfile clinical,
    ParentQualitativeProfile parent,
  ) {
    return {
      'social_relationship': clinical.socialRelationship,
      'emotional_responsiveness': clinical.emotionalResponsiveness,
      'speech_communication': clinical.speechCommunication,
      'behavior_patterns': clinical.behaviorPatterns,
      'sensory_aspects': clinical.sensoryAspects,
      'cognitive_component': clinical.cognitiveComponent,
      'sound_triggers': parent.soundTriggers,
      'visual_triggers': parent.visualTriggers,
      'tactile_preference': parent.tactilePreference.name,
    };
  }
}

class StrengthFunnelStartResult {
  const StrengthFunnelStartResult({
    required this.sessionId,
    required this.layerRunId,
    required this.layerNumber,
    required this.totalSectors,
    required this.constraints,
    required this.tasks,
    required this.completedSectorIds,
    required this.remote,
  });

  final String sessionId;
  final String layerRunId;
  final int layerNumber;
  final int totalSectors;
  final ModalityConstraints constraints;
  final List<Layer1SectorTask> tasks;
  final List<String> completedSectorIds;
  final bool remote;

  factory StrengthFunnelStartResult.fromJson(Map<String, dynamic> json, {required bool remote}) {
    final rawConstraints = Map<String, dynamic>.from(
      json['modality_constraints'] as Map? ?? {},
    );
    final tasksRaw = json['tasks'] as List? ?? [];
    return StrengthFunnelStartResult(
      sessionId: json['session_id'] as String? ?? '',
      layerRunId: json['layer_run_id'] as String? ?? '',
      layerNumber: (json['layer_number'] as num?)?.toInt() ?? 1,
      totalSectors: (json['total_sectors'] as num?)?.toInt() ?? tasksRaw.length,
      constraints: ModalityConstraints.fromJson(rawConstraints),
      tasks: tasksRaw
          .map((t) => Layer1SectorTask.fromJson(Map<String, dynamic>.from(t as Map)))
          .toList(),
      completedSectorIds: List<String>.from(json['completed_sector_ids'] as List? ?? []),
      remote: remote,
    );
  }
}

class StrengthFunnelSubmitResult {
  const StrengthFunnelSubmitResult({
    required this.sectorId,
    required this.engagementScore,
    required this.scoredCount,
    required this.totalSectors,
    required this.layerComplete,
    this.advancingSectorIds,
    this.nextLayer,
  });

  final String sectorId;
  final double engagementScore;
  final int scoredCount;
  final int totalSectors;
  final bool layerComplete;
  final List<String>? advancingSectorIds;
  final int? nextLayer;

  factory StrengthFunnelSubmitResult.fromJson(Map<String, dynamic> json) {
    return StrengthFunnelSubmitResult(
      sectorId: json['sector_id'] as String? ?? '',
      engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0,
      scoredCount: (json['scored_count'] as num?)?.toInt() ?? 0,
      totalSectors: (json['total_sectors'] as num?)?.toInt() ?? 30,
      layerComplete: json['layer_complete'] as bool? ?? false,
      advancingSectorIds: json['advancing_sector_ids'] != null
          ? List<String>.from(json['advancing_sector_ids'] as List)
          : null,
      nextLayer: (json['next_layer'] as num?)?.toInt(),
    );
  }

  factory StrengthFunnelSubmitResult.localFallback({
    required String sectorId,
    required double engagementScore,
    required int scoredCount,
    required int totalSectors,
    required int layerNumber,
  }) {
    return StrengthFunnelSubmitResult(
      sectorId: sectorId,
      engagementScore: engagementScore,
      scoredCount: scoredCount,
      totalSectors: totalSectors,
      layerComplete: scoredCount >= totalSectors,
      nextLayer: scoredCount >= totalSectors ? layerNumber + 1 : null,
    );
  }
}