import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/dashboard_layout_config.dart';

class DashboardLayoutNotifier extends StateNotifier<AsyncValue<DashboardLayoutConfig>> {
  final SupabaseService _supabaseService;
  RealtimeChannel? _channel;

  DashboardLayoutNotifier(this._supabaseService) : super(const AsyncValue.loading()) {
    fetchLayout();
    _subscribeToLayoutChanges();
  }

  Future<void> fetchLayout() async {
    state = const AsyncValue.loading();
    try {
      final client = _supabaseService.client;
      // Fetch latest layout configuration from Supabase table 'dashboard_layouts'
      final response = await client
          .from('dashboard_layouts')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final config = DashboardLayoutConfig.fromJson(response);
        state = AsyncValue.data(config);
      } else {
        // Fallback layout if database is empty
        state = const AsyncValue.data(DashboardLayoutConfig(
          moduleOrder: ['schedule', 'scanner', 'talent'],
          highAuditoryRisk: false,
          routineAnxiety: false,
          sensoryProfileName: 'Default Sensory Profile',
        ));
      }
    } catch (e) {
      // Fallback gracefully to offline mock configuration in case of connection errors or placeholders
      state = const AsyncValue.data(DashboardLayoutConfig(
        moduleOrder: ['schedule', 'scanner', 'talent'],
        highAuditoryRisk: false,
        routineAnxiety: false,
        sensoryProfileName: 'Offline Mode (Mock Config)',
      ));
    }
  }

  void _subscribeToLayoutChanges() {
    try {
      final client = _supabaseService.client;
      // Listen to real-time updates on 'dashboard_layouts' table
      _channel = client
          .channel('public:dashboard_layouts')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'dashboard_layouts',
            callback: (payload) {
              if (payload.newRecord.isNotEmpty) {
                final config = DashboardLayoutConfig.fromJson(payload.newRecord);
                state = AsyncValue.data(config);
              }
            },
          )
          .subscribe();
    } catch (e) {
      // Real-time not initialized or failed, fallback to polling if needed
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _supabaseService.client.removeChannel(_channel!);
    }
    super.dispose();
  }
}

final dashboardLayoutProvider =
    StateNotifierProvider<DashboardLayoutNotifier, AsyncValue<DashboardLayoutConfig>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return DashboardLayoutNotifier(supabaseService);
});
