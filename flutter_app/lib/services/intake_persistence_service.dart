import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/router/app_router.dart';
import '../data/intake_environment_repository.dart';
import '../features/dashboard/providers/sdui_controller.dart';
import '../models/intake_models.dart';
import '../providers/game_environment_provider.dart';
import 'intake_profile_mapper.dart';

/// Local + remote persistence for intake customization and flow progress.
class IntakePersistenceService {
  IntakePersistenceService(this._remote, this._mapper);

  final IntakeEnvironmentRepository _remote;
  final IntakeProfileMapper _mapper;

  static const _bundleKey = 'mindbridge_intake_bundle_v1';
  static const _intakeCompleteKey = 'mindbridge_intake_complete';
  static const _strengthFunnelCompleteKey = 'mindbridge_strength_funnel_complete';
  static const _assessmentCompleteKey = 'mindbridge_assessment_complete';

  Future<void> saveBundle(WidgetRef ref, IntakeSessionBundle bundle) async {
    final childId = await _remote.saveRemoteBundle(bundle);
    final stamped = bundle.copyWith(
      childId: childId ?? bundle.childId,
      persistedAt: DateTime.now().toUtc(),
    );

    ref.read(gameEnvironmentProvider.notifier).set(stamped);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bundleKey, jsonEncode(stamped.toJson()));
    await prefs.setBool(_intakeCompleteKey, true);

    debugPrint('[IntakePersistence] Saved intake bundle locally${childId != null ? ' and remotely' : ''}.');
  }

  Future<void> markStrengthFunnelComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_strengthFunnelCompleteKey, true);
  }

  Future<void> markAssessmentComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_assessmentCompleteKey, true);
  }

  Future<void> clearAll(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bundleKey);
    await prefs.remove(_intakeCompleteKey);
    await prefs.remove(_strengthFunnelCompleteKey);
    await prefs.remove(_assessmentCompleteKey);
    ref.read(gameEnvironmentProvider.notifier).clear();
  }

  /// Restores customization and navigation flags on cold start.
  Future<void> restoreSession(ProviderContainer container) async {
    IntakeSessionBundle? bundle = await _loadLocalBundle();
    bundle ??= await _remote.loadRemoteBundle();

    if (bundle == null) return;

    _applyBundle(container, bundle);

    final prefs = await SharedPreferences.getInstance();
    final intakeComplete = prefs.getBool(_intakeCompleteKey) ?? false;
    final strengthFunnelComplete = prefs.getBool(_strengthFunnelCompleteKey) ?? false;
    final assessmentComplete = prefs.getBool(_assessmentCompleteKey) ?? false;

    if (intakeComplete) {
      final current = container.read(authStatusProvider);
      container.read(authStatusProvider.notifier).state = AuthUserStatus(
        isLoggedIn: current.isLoggedIn,
        userId: current.userId,
        hasCompletedIntake: true,
        hasCompletedStrengthFunnel: strengthFunnelComplete,
        hasCompletedAssessment: assessmentComplete,
      );
    }

    debugPrint(
      '[IntakePersistence] Restored intake session '
      '(strengthFunnelComplete=$strengthFunnelComplete, assessmentComplete=$assessmentComplete).',
    );
  }

  Future<IntakeSessionBundle?> _loadLocalBundle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_bundleKey);
      if (raw == null || raw.isEmpty) return null;
      return IntakeSessionBundle.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('[IntakePersistence] Local restore failed: $e');
      return null;
    }
  }

  void _applyBundle(ProviderContainer container, IntakeSessionBundle bundle) {
    container.read(gameEnvironmentProvider.notifier).set(bundle);
    container.read(sduiControllerProvider.notifier).applyGameEnvironment(
          bundle: bundle,
          profile: _mapper.toNeuroProfile(
            clinical: bundle.clinical,
            parent: bundle.parent,
            config: bundle.config,
          ),
        );
  }
}

final intakeEnvironmentRepositoryProvider = Provider<IntakeEnvironmentRepository>((ref) {
  return const IntakeEnvironmentRepository();
});

final intakePersistenceServiceProvider = Provider<IntakePersistenceService>((ref) {
  return IntakePersistenceService(
    ref.watch(intakeEnvironmentRepositoryProvider),
    ref.watch(intakeProfileMapperProvider),
  );
});

/// Startup hook — call from `main()` before `runApp`.
Future<void> restorePersistedIntakeSession(ProviderContainer container) async {
  await container.read(intakePersistenceServiceProvider).restoreSession(container);
}

/// For tests: JSON round-trip without platform storage.
IntakeSessionBundle decodePersistedBundleJson(String raw) {
  return IntakeSessionBundle.fromJson(
    Map<String, dynamic>.from(jsonDecode(raw) as Map),
  );
}

String encodePersistedBundleJson(IntakeSessionBundle bundle) {
  return jsonEncode(bundle.toJson());
}
