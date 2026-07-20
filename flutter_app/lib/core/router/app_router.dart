import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/widgets/dashboard_screen.dart';
import '../../features/deepening/presentation/deepening_funnel_canvas.dart';
import '../../features/deepening/providers/deepening_controller.dart';
import '../auth/supabase_auth_repository.dart';

final authStatusProvider = StateProvider<AuthUserStatus>((ref) {
  return const AuthUserStatus(
    isLoggedIn: true, // Mock authenticated user state
    userId: 'user_guardian_101',
    hasCompletedAssessment: false, // Set to false to trigger assessment route post-login
  );
});

class AuthUserStatus {
  final bool isLoggedIn;
  final String userId;
  final bool hasCompletedAssessment;

  const AuthUserStatus({
    required this.isLoggedIn,
    required this.userId,
    required this.hasCompletedAssessment,
  });
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: authStatus.hasCompletedAssessment ? '/dashboard' : '/assessment-canvas',
    redirect: (BuildContext context, GoRouterState state) {
      if (!authStatus.isLoggedIn) {
        return '/login';
      }

      final isNavigatingToAssessment = state.matchedLocation == '/assessment-canvas';

      // If user has not completed assessment, force routing to assessment canvas
      if (!authStatus.hasCompletedAssessment && !isNavigatingToAssessment) {
        return '/assessment-canvas';
      }

      // If user has already completed assessment and tries to go to assessment, route to dashboard
      if (authStatus.hasCompletedAssessment && isNavigatingToAssessment) {
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
        path: '/assessment-canvas',
        builder: (context, state) {
          final userId = authStatus.userId;
          return DeepeningFunnelCanvas(
            userId: userId,
            onCompleted: () {
              // Mark assessment as completed and navigate to dashboard
              ref.read(authStatusProvider.notifier).state = AuthUserStatus(
                isLoggedIn: true,
                userId: userId,
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
