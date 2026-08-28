import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/game_environment_provider.dart';
import '../../guardian/data/session_repository.dart';
import '../../strength_funnel/models/strength_funnel_finalists.dart';
import '../data/child_play_session_builder.dart';
import '../models/child_play_activity.dart';
import 'child_play_telemetry_service.dart';

class ChildPlayLaunchResult {
  const ChildPlayLaunchResult({
    required this.sessionId,
    required this.activities,
    required this.remoteSession,
  });

  final String sessionId;
  final List<ChildPlayActivity> activities;
  final bool remoteSession;
}

class ChildPlaySessionService {
  ChildPlaySessionService({
    SessionRepository? sessions,
    ChildPlayTelemetryService? telemetry,
  })  : _sessions = sessions ?? SupabaseSessionRepository(),
        _telemetry = telemetry ?? ChildPlayTelemetryService();

  final SessionRepository _sessions;
  final ChildPlayTelemetryService _telemetry;

  bool get _canIssueRemote {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<ChildPlayLaunchResult> launch({
    required IntakeSessionBundle bundle,
    required StrengthFunnelFinalists finalists,
  }) async {
    final activities = buildChildPlayActivities(
      finalists: finalists,
      bundle: bundle,
    );

    if (activities.isEmpty) {
      throw StateError('No play activities to launch.');
    }

    var sessionId = 'local_play_${DateTime.now().millisecondsSinceEpoch}';
    var remote = false;

    final childId = bundle.childId;
    if (_canIssueRemote && childId != null) {
      try {
        final issued = await _sessions.issueSession(childId);
        sessionId = issued.sessionId;
        remote = true;
        debugPrint('[ChildPlaySession] Remote session $sessionId issued.');
      } catch (e) {
        debugPrint('[ChildPlaySession] issue-session fallback: $e');
      }
    }

    return ChildPlayLaunchResult(
      sessionId: sessionId,
      activities: activities,
      remoteSession: remote,
    );
  }

  Future<void> endSession(String sessionId) async {
    if (sessionId.startsWith('local_play_')) return;
    try {
      await _sessions.revokeSession(sessionId);
    } catch (e) {
      debugPrint('[ChildPlaySession] revoke-session: $e');
    }
  }

  Future<void> recordEnjoyment({
    required String sessionId,
    required String childId,
    required String sectorId,
    bool skipped = false,
  }) {
    return _telemetry.recordResponse(
      sessionId: sessionId,
      childId: childId,
      sectorId: sectorId,
      enjoyed: !skipped,
      skipped: skipped,
    );
  }
}

final childPlaySessionServiceProvider = Provider<ChildPlaySessionService>((ref) {
  return ChildPlaySessionService();
});
