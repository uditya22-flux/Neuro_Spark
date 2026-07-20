import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApi {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> createChild({required String preferredName, required int birthYear}) async {
    final response = await _client.functions.invoke('create-child', body: {'preferredName': preferredName, 'birthYear': birthYear});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> submitTriggerEvent(Map<String, dynamic> event) async {
    await _client.functions.invoke('trigger-event', body: event);
  }
}
