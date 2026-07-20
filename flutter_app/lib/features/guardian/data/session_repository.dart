import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

class SessionResult {
  const SessionResult({required this.sessionId, required this.expiresAt});

  final String sessionId;
  final DateTime expiresAt;
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class SessionRepository {
  Future<SessionResult> issueSession(String childId);
  Future<void> revokeSession(String sessionId);
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseSessionRepository implements SessionRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Calls the issue-session Edge Function.
  /// Prerequisites (verified guardian, active consent, child ownership)
  /// are enforced server-side.
  @override
  Future<SessionResult> issueSession(String childId) async {
    final response = await _db.functions.invoke(
      'issue-session',
      body: {'childId': childId},
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['sessionId'] == null) {
      final error = data?['error'] as String? ?? 'Unknown error';
      throw Exception('Failed to issue session: $error');
    }

    return SessionResult(
      sessionId: data['sessionId'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  /// Calls the revoke-session Edge Function.
  /// Idempotent — safe to call even if already revoked.
  @override
  Future<void> revokeSession(String sessionId) async {
    await _db.functions.invoke(
      'revoke-session',
      body: {'sessionId': sessionId},
    );
  }
}
