import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the synthetic cloud showcase on a short-lived anonymous Supabase
/// identity. It is never used by the normal guardian-authenticated product
/// flow. Calling it at the point of a demo request makes a phone recover from
/// a cold start or a cleared local session instead of showing a vague error.
class SyntheticDemoAuth {
  const SyntheticDemoAuth._();

  static Future<bool> ensureAnonymousSession(SupabaseClient client) async {
    final session = client.auth.currentSession;
    if (session != null && client.auth.currentUser?.isAnonymous == true) {
      return true;
    }

    try {
      // Synthetic cloud mode is intentionally anonymous-only. A stale
      // non-anonymous demo session cannot be sent to its tightly scoped Edge
      // Functions, so replace it instead of leaving the device stuck.
      if (session != null) {
        await client.auth.signOut();
      }
      await client.auth.signInAnonymously();
      return client.auth.currentSession != null &&
          client.auth.currentUser?.isAnonymous == true;
    } catch (error) {
      // Never include a token, session ID, or telemetry in logs.
      debugPrint(
        '[SyntheticDemoAuth] anonymous session unavailable: ${error.runtimeType}',
      );
      return false;
    }
  }
}
