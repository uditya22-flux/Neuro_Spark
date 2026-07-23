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
      throw StateError('Supabase is not initialized. Check flutter_app/.env.');
    }
    try {
      final response = await client.functions.invoke('submit-intake', body: payload);
      final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
      if (response.status >= 400 || data.containsKey('error')) {
        throw StateError(data['error'] as String? ?? 'Preferences could not be saved.');
      }
      return data;
    } catch (e) {
      debugPrint('[SupabaseApi] Error invoking submit-intake: $e');
      throw StateError(_safeFunctionMessage(e, 'Preferences could not be saved.'));
    }
  }

  /// Creates a new child profile via the `create-child` Edge Function.
  Future<Map<String, dynamic>> createChild({required String preferredName, required int birthYear}) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized. Check flutter_app/.env.');
    }
    try {
      final response = await client.functions.invoke('create-child', body: {
        'preferredName': preferredName,
        'birthYear': birthYear,
      });
      final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
      if (response.status >= 400 || data.containsKey('error')) {
        throw StateError(data['error'] as String? ?? 'Child profile could not be created.');
      }
      return data;
    } catch (e) {
      debugPrint('[SupabaseApi] Error creating child profile: $e');
      throw StateError(_safeFunctionMessage(e, 'Child profile could not be created.'));
    }
  }

  /// Lists only child records owned by the authenticated guardian (enforced by RLS).
  Future<List<Map<String, dynamic>>> loadChildren() async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized. Check flutter_app/.env.');
    }
    final rows = await client
        .from('children')
        .select('id, preferred_name, birth_year')
        .order('created_at');
    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  /// Loads the latest structured preferences for an owned child record.
  Future<Map<String, dynamic>?> loadExplorationPreferences(String childId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized. Check flutter_app/.env.');
    }
    final row = await client
        .from('guardian_exploration_preferences')
        .select('configuration')
        .eq('child_id', childId)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row['configuration'] as Map);
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

  String _safeFunctionMessage(Object error, String fallback) {
    if (error is StateError) return error.message.toString();
    if (error is FunctionException) {
      final dynamic exception = error;
      final details = exception.details;
      if (details is Map && details['error'] is String) {
        return details['error'] as String;
      }
      if (details is String && details.isNotEmpty) return details;
      final reason = exception.reason;
      if (reason is String && reason.isNotEmpty) return reason;
    }
    return fallback;
  }
}

final supabaseApiProvider = Provider<SupabaseApi>((ref) {
  return SupabaseApi();
});
