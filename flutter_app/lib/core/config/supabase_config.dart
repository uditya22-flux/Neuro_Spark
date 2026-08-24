import 'package:flutter/foundation.dart';

/// Resolves Supabase URL and anon key for hosted (all devices) or local dev.
class SupabaseConfig {
  /// Mind_Bridge hosted project — reachable from any device on the internet.
  static const hostedUrl = 'https://zkskozozwjjzwvnkmeqb.supabase.co';
  static const hostedAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inprc2tvem96d2pqend2bmttZXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1NTMzNTYsImV4cCI6MjEwMDEyOTM1Nn0.lK-IX9NQhNybWqBNfBGss_aGUJVHLnIGM94CWB5U-xo';

  /// Standard local Supabase anon key (dev only).
  static const localAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static const _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _useLocalSupabase =
      bool.fromEnvironment('USE_LOCAL_SUPABASE', defaultValue: false);

  static String get url {
    if (_defineUrl.isNotEmpty) return _defineUrl;
    if (_useLocalSupabase) return _localApiUrl;
    return hostedUrl;
  }

  static String get anonKey {
    if (_defineAnonKey.isNotEmpty) return _defineAnonKey;
    if (_useLocalSupabase) return localAnonKey;
    return hostedAnonKey;
  }

  static bool get isLocalDev => _useLocalSupabase && _defineUrl.isEmpty;

  /// True when pointing at a real Supabase stack (local or hosted).
  static bool get isLiveBackend {
    final resolved = url.trim();
    if (resolved.isEmpty) return false;
    if (resolved.contains('your-project.supabase.co')) return false;
    return true;
  }

  /// When live, guardians must sign in before intake/funnel API calls work.
  static bool get requiresAuth => isLiveBackend;

  static String get _localApiUrl {
    const port = 64321;
    if (kIsWeb) return 'http://127.0.0.1:$port';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$port';
      default:
        return 'http://127.0.0.1:$port';
    }
  }
}
