import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/dashboard/widgets/dashboard_screen.dart';
import '../../features/deepening/presentation/deepening_funnel_canvas.dart';
import '../../features/exploration/presentation/exploration_continuing_screen.dart';
import '../../features/guardian_demo/presentation/guardian_demo_portal_screen.dart';
import '../../features/sandbox/presentation/engine4_sandbox_screen.dart';
import '../auth/guardian_login_screen.dart';
import '../config/prototype_mode.dart';

import '../../features/exploration/presentation/parent_intake_form.dart';

final authStatusProvider = StateProvider<AuthUserStatus>((ref) {
  if (presentationDemoMode) {
    return const AuthUserStatus(
      isLoggedIn: true,
      userId: 'synthetic-demo-session',
      activeChildId: 'synthetic-demo-child',
      hasCompletedIntake: false,
      hasCompletedAssessment: false,
    );
  }
  final user = Supabase.instance.client.auth.currentUser;
  return AuthUserStatus(
    isLoggedIn: user != null,
    userId: user?.id ?? '',
    activeChildId: null,
    hasCompletedIntake: false,
    hasCompletedAssessment: false,
  );
});

class AuthUserStatus {
  final bool isLoggedIn;
  final String userId;
  final String? activeChildId;
  final bool hasCompletedIntake;
  final bool hasCompletedAssessment;

  const AuthUserStatus({
    required this.isLoggedIn,
    required this.userId,
    this.activeChildId,
    required this.hasCompletedIntake,
    required this.hasCompletedAssessment,
  });
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: !authStatus.hasCompletedIntake
        ? '/intake'
        : (!authStatus.hasCompletedAssessment
            ? '/assessment-canvas'
            : '/dashboard'),
    redirect: (BuildContext context, GoRouterState state) {
      final isGuardianDemoPortal = state.matchedLocation == '/guardian-portal';
      if (!authStatus.isLoggedIn) {
        return '/login';
      }

      // The guardian companion view can be opened on a separate demo device
      // before that device has gone through intake. It is still limited to an
      // opaque, short-lived synthetic session code by its own Edge Function.
      if (!authStatus.hasCompletedIntake &&
          state.matchedLocation != '/intake' &&
          !isGuardianDemoPortal) {
        return '/intake';
      }

      if (authStatus.hasCompletedIntake &&
          !authStatus.hasCompletedAssessment &&
          state.matchedLocation != '/assessment-canvas' &&
          !isGuardianDemoPortal) {
        return '/assessment-canvas';
      }

      if (authStatus.hasCompletedAssessment &&
          state.matchedLocation != '/dashboard' &&
          state.matchedLocation != '/sandbox' &&
          state.matchedLocation != '/exploring' &&
          !isGuardianDemoPortal) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => GuardianLoginScreen(
          onAuthenticated: (guardianId) {
            ref.read(authStatusProvider.notifier).state = AuthUserStatus(
              isLoggedIn: true,
              userId: guardianId,
              hasCompletedIntake: false,
              hasCompletedAssessment: false,
            );
          },
        ),
      ),
      GoRoute(
        path: '/intake',
        builder: (context, state) => const ParentIntakeForm(),
      ),
      GoRoute(
        path: '/guardian-portal',
        builder: (context, state) => GuardianDemoPortalScreen(
          initialSessionCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: '/assessment-canvas',
        builder: (_, __) {
          final userId = authStatus.activeChildId ?? authStatus.userId;
          return DeepeningFunnelCanvas(
            userId: userId,
            onCompleted: () {
              ref.read(authStatusProvider.notifier).state = AuthUserStatus(
                isLoggedIn: true,
                userId: authStatus.userId,
                activeChildId: authStatus.activeChildId,
                hasCompletedIntake: true,
                hasCompletedAssessment: true,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/sandbox',
        builder: (context, state) {
          final userId = authStatus.activeChildId ?? authStatus.userId;
          final vertical =
              state.uri.queryParameters['vertical'] ?? 'calendar_genius';
          return Engine4SandboxScreen(
              userId: userId, initialVerticalId: vertical);
        },
      ),
      GoRoute(
        path: '/exploring',
        builder: (context, state) => const ExplorationContinuingScreen(),
      ),
    ],
  );
});
