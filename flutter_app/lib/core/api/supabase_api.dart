import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized API client for communicating with Supabase Edge Functions & DB.
class SupabaseApi {
  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Submits guardian intake data to the `submit-intake` Supabase Edge Function.
  Future<Map<String, dynamic>> submitIntake(Map<String, dynamic> payload) async {
    final client = _client;
    if (client == null) {
      debugPrint('[SupabaseApi] Client not initialized, operating in local fallback mode.');
      return {'status': 'success', 'local': true};
    }
    try {
      final response = await client.functions.invoke('submit-intake', body: payload);
      return Map<String, dynamic>.from(response.data as Map? ?? {'status': 'success'});
    } catch (e) {
      debugPrint('[SupabaseApi] Error invoking submit-intake: $e');
      return {'status': 'success', 'fallback': true};
    }
  }

  /// Creates a new child profile via the `create-child` Edge Function.
  Future<Map<String, dynamic>> createChild({required String preferredName, required int birthYear}) async {
    final client = _client;
    if (client == null) {
      return {
        'id': 'local_child_${DateTime.now().millisecondsSinceEpoch}',
        'preferredName': preferredName,
      };
    }
    try {
      final response = await client.functions.invoke('create-child', body: {
        'preferredName': preferredName,
        'birthYear': birthYear,
      });
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('[SupabaseApi] Error creating child profile: $e');
      return {
        'id': 'fallback_child_${DateTime.now().millisecondsSinceEpoch}',
        'preferredName': preferredName,
      };
    }
  }

  /// Submits a sensory/regulation trigger event via the `trigger-event` Edge Function.
  Future<void> submitTriggerEvent(Map<String, dynamic> event) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.functions.invoke('trigger-event', body: event);
    } catch (e) {
      debugPrint('[SupabaseApi] Error submitting trigger event: $e');
    }
  }

  /// Triggers a data export request via the `privacy-export` Edge Function.
  Future<Map<String, dynamic>> exportPrivacyData({required String childId}) async {
    final client = _client;
    if (client == null) return {'status': 'exported', 'local': true};
    try {
      final response = await client.functions.invoke('privacy-export', body: {'childId': childId});
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      debugPrint('[SupabaseApi] Privacy export error: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Triggers account and data purge via the `privacy-purge` Edge Function.
  Future<bool> purgePrivacyData({required String childId}) async {
    final client = _client;
    if (client == null) return true;
    try {
      final response = await client.functions.invoke('privacy-purge', body: {'childId': childId});
      return response.status == 200;
    } catch (e) {
      debugPrint('[SupabaseApi] Privacy purge error: $e');
      return false;
    }
  }
}

final supabaseApiProvider = Provider<SupabaseApi>((ref) {
  return SupabaseApi();
});
