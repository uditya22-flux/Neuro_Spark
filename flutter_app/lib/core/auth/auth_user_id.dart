import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the authenticated Supabase user id when available.
String? activeSupabaseUserId() {
  try {
    return Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

/// Local beta fallback when Supabase auth is not configured.
String resolveGuardianUserId({String fallback = 'user_guardian_101'}) {
  return activeSupabaseUserId() ?? fallback;
}
