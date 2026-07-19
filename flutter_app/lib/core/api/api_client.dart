import 'package:supabase_flutter/supabase_flutter.dart';

/// One authenticated Supabase boundary. Feature repositories own table and function details.
class ApiClient {
  ApiClient({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  SupabaseClient get supabase => _client;

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<User?> currentUser() async {
    final response = await _client.auth.getUser();
    return response.user;
  }
}
