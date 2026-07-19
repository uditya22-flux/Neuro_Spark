import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Foundational setup for Supabase connectivity.
  // In a production app, these would come from environment variables.
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-placeholder';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  SupabaseClient get client => Supabase.instance.client;
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});
