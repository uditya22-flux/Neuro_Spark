import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/widgets/dashboard_screen.dart';
import '../../features/deepening/presentation/deepening_funnel_canvas.dart';
import '../../features/deepening/providers/deepening_controller.dart';
import '../auth/supabase_auth_repository.dart';

import '../../features/onboarding/widgets/neuro_spark_intake_flow.dart';

final authStatusProvider = StateProvider<AuthUserStatus>((ref) {
  return const AuthUserStatus(
    isLoggedIn: true,
    userId: 'user_guardian_101',
    hasCompletedIntake: false,
    hasCompletedAssessment: false,
  );
});

class AuthUserStatus {
  final bool isLoggedIn;
  final String userId;
  final bool hasCompletedIntake;
  final bool hasCompletedAssessment;

  const AuthUserStatus({
    required this.isLoggedIn,
    required this.userId,
    required this.hasCompletedIntake,
    required this.hasCompletedAssessment,
  });
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: !authStatus.hasCompletedIntake
        ? '/intake'
        : (!authStatus.hasCompletedAssessment ? '/assessment-canvas' : '/dashboard'),
    redirect: (BuildContext context, GoRouterState state) {
      if (!authStatus.isLoggedIn) {
        return '/login';
      }

      if (!authStatus.hasCompletedIntake && state.matchedLocation != '/intake') {
        return '/intake';
      }

      if (authStatus.hasCompletedIntake &&
          !authStatus.hasCompletedAssessment &&
          state.matchedLocation != '/assessment-canvas') {
        return '/assessment-canvas';
      }

      if (authStatus.hasCompletedAssessment && state.matchedLocation != '/dashboard') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Login Screen')),
        ),
      ),
      GoRoute(
        path: '/intake',
        builder: (context, state) => const NeuroSparkIntakeFlow(),
      ),
      GoRoute(
        path: '/assessment-canvas',
        builder: (context, state) {
          final userId = authStatus.userId;
          return DeepeningFunnelCanvas(
            userId: userId,
            onCompleted: () {
              ref.read(authStatusProvider.notifier).state = AuthUserStatus(
                isLoggedIn: true,
                userId: userId,
                hasCompletedIntake: true,
                hasCompletedAssessment: true,
              );
              context.go('/dashboard');
            },
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
