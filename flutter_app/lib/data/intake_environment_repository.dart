import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/intake_models.dart';
import '../providers/game_environment_provider.dart';
import '../services/intake_profile_mapper.dart';

/// Persists intake bundles to Supabase `profiles` and `sensory_configurations`.
class IntakeEnvironmentRepository {
  const IntakeEnvironmentRepository({IntakeProfileMapper? mapper})
      : _mapper = mapper ?? const IntakeProfileMapper();

  final IntakeProfileMapper _mapper;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated {
    final client = _client;
    return client != null && client.auth.currentUser != null;
  }

  /// Loads a previously persisted bundle from the guardian profile row.
  Future<IntakeSessionBundle?> loadRemoteBundle() async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;

    try {
      final row = await client
          .from('profiles')
          .select('generative_ui_parameters, updated_at')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      final params = row['generative_ui_parameters'];
      if (params is! Map<String, dynamic>) return null;

      final clinicalRaw = params['isaa_clinical'];
      final parentRaw = params['parent_qualitative'];
      final configRaw = params['game_environment'];

      if (clinicalRaw is! Map || parentRaw is! Map || configRaw is! Map) {
        return null;
      }

      return IntakeSessionBundle(
        clinical: ISAAClinicalProfile.fromJson(Map<String, dynamic>.from(clinicalRaw)),
        parent: ParentQualitativeProfile.fromJson(Map<String, dynamic>.from(parentRaw)),
        config: GameEnvironmentConfig.fromJson(Map<String, dynamic>.from(configRaw)),
        childId: params['child_id'] as String?,
        persistedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('[IntakeEnvironmentRepository] loadRemoteBundle: $e');
      return null;
    }
  }

  /// Saves bundle to Supabase. Returns child id when available.
  Future<String?> saveRemoteBundle(IntakeSessionBundle bundle) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return bundle.childId;

    try {
      final childId = await _ensureChild(client, bundle);
      final profile = _mapper.toNeuroProfile(
        clinical: bundle.clinical,
        parent: bundle.parent,
        config: bundle.config,
      );

      await client.from('profiles').update({
        'generative_ui_parameters': {
          'game_environment': bundle.config.toJson(),
          'isaa_clinical': bundle.clinical.toJson(),
          'parent_qualitative': bundle.parent.toJson(),
          'child_id': childId,
          'profile_json': profile.toJson(),
          'active_verticals': const ['calendar_genius', 'constellation_mapper'],
          'hyper_focus_theme': bundle.config.assetTheme,
          'layout_complexity_tier':
              bundle.config.pacingSlowed ? 'simple' : 'standard',
        },
        'sensory_control_matrix': {
          'sound_triggers': bundle.parent.soundTriggers,
          'visual_triggers': bundle.parent.visualTriggers,
          'audio_mode': bundle.config.audioMode.name,
          'haptic_enabled': bundle.config.hapticEnabled,
          'instruction_style': bundle.config.instructionStyle.name,
          'starting_difficulty_tier': bundle.config.startingDifficultyTier,
        },
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      if (childId != null) {
        await _upsertSensoryConfigurations(client, childId, bundle);
      }

      return childId;
    } catch (e) {
      debugPrint('[IntakeEnvironmentRepository] saveRemoteBundle: $e');
      return bundle.childId;
    }
  }

  Future<String?> _ensureChild(SupabaseClient client, IntakeSessionBundle bundle) async {
    if (bundle.childId != null) return bundle.childId;

    final name = bundle.parent.childName.trim().isEmpty
        ? 'Friend'
        : bundle.parent.childName.trim();
    final birthYear = DateTime.now().year - bundle.parent.childAge;

    try {
      final response = await client.functions.invoke('create-child', body: {
        'preferredName': name,
        'birthYear': birthYear,
      });
      if (response.data is Map) {
        final id = (response.data as Map)['id'];
        if (id is String) return id;
      }
    } catch (e) {
      debugPrint('[IntakeEnvironmentRepository] create-child unavailable: $e');
    }

    // Reuse most recent child for this guardian when edge function is unavailable.
    try {
      final existing = await client
          .from('children')
          .select('id')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return existing?['id'] as String?;
    } catch (e) {
      debugPrint('[IntakeEnvironmentRepository] child lookup failed: $e');
      return null;
    }
  }

  Future<void> _upsertSensoryConfigurations(
    SupabaseClient client,
    String childId,
    IntakeSessionBundle bundle,
  ) async {
    const version = 1;
    final entries = <MapEntry<String, dynamic>>[
      MapEntry('game_environment_config', bundle.config.toJson()),
      MapEntry('isaa_clinical_profile', bundle.clinical.toJson()),
      MapEntry('parent_qualitative_profile', bundle.parent.toJson()),
      MapEntry('sound_triggers_blacklist', bundle.parent.soundTriggers),
      MapEntry('visual_triggers_blacklist', bundle.parent.visualTriggers),
      MapEntry('instruction_style', bundle.config.instructionStyle.name),
      MapEntry('starting_difficulty_tier', bundle.config.startingDifficultyTier),
    ];

    final now = DateTime.now().toUtc().toIso8601String();

    for (final entry in entries) {
      await client.from('sensory_configurations').upsert(
        {
          'child_id': childId,
          'config_version': version,
          'key': entry.key,
          'proposed_value': entry.value,
          'status': 'confirmed',
          'reviewed_at': now,
          'active': true,
        },
        onConflict: 'child_id,config_version,key',
      );
    }
  }
}
