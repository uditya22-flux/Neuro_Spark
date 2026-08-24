import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../router/app_router.dart';
import '../../services/guardian_bootstrap_service.dart';

AuthUserStatus _authStatusFromSession(AuthUserStatus current) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  return AuthUserStatus(
    isLoggedIn: userId != null,
    userId: userId ?? current.userId,
    hasCompletedIntake: current.hasCompletedIntake,
    hasCompletedStrengthFunnel: current.hasCompletedStrengthFunnel,
    hasCompletedAssessment: current.hasCompletedAssessment,
  );
}

/// Syncs Supabase auth session into [authStatusProvider].
Future<void> syncAuthSession(ProviderContainer container) async {
  if (!SupabaseConfig.requiresAuth) return;

  final current = container.read(authStatusProvider);
  container.read(authStatusProvider.notifier).state = _authStatusFromSession(current);

  if (Supabase.instance.client.auth.currentUser != null) {
    await container.read(guardianBootstrapServiceProvider).ensureReady();
  }
}

Future<void> syncAuthSessionRef(WidgetRef ref) async {
  if (!SupabaseConfig.requiresAuth) return;

  final current = ref.read(authStatusProvider);
  ref.read(authStatusProvider.notifier).state = _authStatusFromSession(current);

  if (Supabase.instance.client.auth.currentUser != null) {
    await ref.read(guardianBootstrapServiceProvider).ensureReady();
  }
}

/// Keeps router auth flags aligned with Supabase sign-in/out events.
void bindSupabaseAuthListener(ProviderContainer container) {
  if (!SupabaseConfig.requiresAuth) return;

  Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
    await syncAuthSession(container);
  });
}
