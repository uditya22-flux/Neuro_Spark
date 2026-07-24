import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guardian_demo_portal_models.dart';
import '../services/guardian_demo_portal_service.dart';

class GuardianDemoPortalState {
  const GuardianDemoPortalState({
    this.sessionCode = '',
    this.snapshot,
    this.isLoading = false,
    this.error,
    this.lastSyncedAt,
  });

  final String sessionCode;
  final GuardianDemoSessionSnapshot? snapshot;
  final bool isLoading;
  final String? error;
  final DateTime? lastSyncedAt;

  bool get isConnected => snapshot != null;

  GuardianDemoPortalState copyWith({
    String? sessionCode,
    GuardianDemoSessionSnapshot? snapshot,
    bool clearSnapshot = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? lastSyncedAt,
  }) =>
      GuardianDemoPortalState(
        sessionCode: sessionCode ?? this.sessionCode,
        snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class GuardianDemoPortalController
    extends StateNotifier<GuardianDemoPortalState> {
  GuardianDemoPortalController(this._service)
      : super(const GuardianDemoPortalState());

  final GuardianDemoPortalService _service;

  void setSessionCode(String value) {
    final code = value.trim();
    if (code == state.sessionCode) return;
    state = state.copyWith(
      sessionCode: code,
      clearSnapshot: true,
      clearError: true,
    );
  }

  Future<void> connect(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      state = state.copyWith(
        clearSnapshot: true,
        error: 'Enter the temporary session code from the activity device.',
      );
      return;
    }
    await _load(code, clearBeforeLoad: true);
  }

  Future<void> refresh() async {
    if (state.sessionCode.isEmpty || state.isLoading) return;
    await _load(state.sessionCode, clearBeforeLoad: false);
  }

  Future<void> _load(
    String code, {
    required bool clearBeforeLoad,
  }) async {
    state = state.copyWith(
      sessionCode: code,
      isLoading: true,
      clearSnapshot: clearBeforeLoad,
      clearError: true,
    );
    final result = await _service.loadSnapshot(code);
    if (result.isAvailable) {
      state = state.copyWith(
        snapshot: result.snapshot,
        isLoading: false,
        clearError: true,
        lastSyncedAt: DateTime.now(),
      );
      return;
    }
    state = state.copyWith(
      isLoading: false,
      error: result.reason ?? 'The shared demo session is unavailable.',
    );
  }
}

final guardianDemoPortalServiceProvider = Provider<GuardianDemoPortalService>(
  (ref) => GuardianDemoPortalService(),
);

final guardianDemoPortalProvider = StateNotifierProvider<
    GuardianDemoPortalController, GuardianDemoPortalState>(
  (ref) => GuardianDemoPortalController(
    ref.read(guardianDemoPortalServiceProvider),
  ),
);
