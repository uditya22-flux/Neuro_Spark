import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/synthetic_demo_auth.dart';
import '../../../core/config/prototype_mode.dart';
import '../models/guardian_demo_portal_models.dart';

/// Read-only client for a paired synthetic showcase session.
///
/// The code is the existing short-lived opaque synthetic session UUID. This
/// service deliberately never sends guardian intake text, a child identifier,
/// task content, or a free-text response. It is only enabled in the explicit
/// synthetic cloud demo build mode; production guardian access remains a
/// different, verified-authorisation flow.
class GuardianDemoPortalService {
  static const _functionName = 'synthetic-engine2-guardian-portal';

  bool get isAvailable =>
      syntheticCloudDemoMode && !builderShowcaseMode && !localPrototypeMode;

  Future<GuardianDemoPortalResult> loadSnapshot(String sessionCode) async {
    if (!isAvailable) {
      return GuardianDemoPortalResult.unavailable(
        'Live pairing is available only in the synthetic cloud demo build.',
      );
    }
    if (!_isOpaqueSessionId(sessionCode)) {
      return GuardianDemoPortalResult.unavailable(
        'Enter the temporary session code shown on the activity device.',
      );
    }

    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return GuardianDemoPortalResult.unavailable(
        'Supabase is not initialized on this device.',
      );
    }
    if (!await SyntheticDemoAuth.ensureAnonymousSession(client)) {
      return GuardianDemoPortalResult.unavailable(
        'The demo could not start its anonymous Supabase session. Check that Anonymous Sign-Ins are enabled, then reopen the app.',
      );
    }

    try {
      final response = await client.functions.invoke(
        _functionName,
        body: <String, dynamic>{
          'action': 'snapshot',
          'session_id': sessionCode.trim(),
        },
      );
      if (response.status >= 400 || response.data is! Map) {
        return GuardianDemoPortalResult.unavailable(
          'The shared demo session could not be opened. Check the code and try again.',
        );
      }
      return GuardianDemoPortalResult.snapshot(
        GuardianDemoSessionSnapshot.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
    } on FunctionException {
      return GuardianDemoPortalResult.unavailable(
        'The shared demo session could not be opened. Check the code and try again.',
      );
    } on FormatException {
      return GuardianDemoPortalResult.unavailable(
        'The shared demo session returned an unexpected activity record.',
      );
    } catch (error) {
      // Do not log a session code or activity values. The runtime type alone
      // helps local debugging without exposing even synthetic demo data.
      debugPrint(
          '[GuardianDemoPortalService] snapshot unavailable: ${error.runtimeType}');
      return GuardianDemoPortalResult.unavailable(
        'The shared demo session is temporarily unavailable.',
      );
    }
  }
}

class GuardianDemoPortalResult {
  const GuardianDemoPortalResult._({this.snapshot, this.reason});

  final GuardianDemoSessionSnapshot? snapshot;
  final String? reason;

  bool get isAvailable => snapshot != null;

  factory GuardianDemoPortalResult.snapshot(
          GuardianDemoSessionSnapshot snapshot) =>
      GuardianDemoPortalResult._(snapshot: snapshot);

  factory GuardianDemoPortalResult.unavailable(String reason) =>
      GuardianDemoPortalResult._(reason: reason);
}

bool _isOpaqueSessionId(String value) => RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value.trim());
