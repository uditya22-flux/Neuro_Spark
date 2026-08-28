import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../features/child/presentation/child_play_launch_helper.dart';
import '../../features/child/presentation/child_play_session_screen.dart';
import '../../features/child/providers/child_play_session_controller.dart';
import '../../features/dashboard/widgets/neuro_spark_dashboard.dart';

import '../../features/deepening/presentation/deepening_funnel_canvas.dart';

import '../../features/sandbox/presentation/engine4_sandbox_screen.dart';

import '../../features/strength_funnel/presentation/guardian_strength_summary_screen.dart';
import '../../features/strength_funnel/presentation/layer1_sector_prompt_widget.dart';
import '../../features/strength_funnel/providers/strength_funnel_controller.dart';

import '../../providers/intake_flow_provider.dart';

import '../../screens/intake_flow_screen.dart';
import '../../screens/login_screen.dart';
import '../config/supabase_config.dart';

import '../../services/intake_application_service.dart';

import '../../services/intake_persistence_service.dart';

import '../../services/strength_funnel_progress_service.dart';

import '../auth/auth_user_id.dart';

AuthUserStatus _defaultAuthStatus() {
  final offlineBeta = !SupabaseConfig.requiresAuth;
  return AuthUserStatus(
    isLoggedIn: offlineBeta,
    userId: resolveGuardianUserId(),
    hasCompletedIntake: false,
    hasCompletedStrengthFunnel: false,
    hasCompletedAssessment: false,
  );
}

final authStatusProvider = StateProvider<AuthUserStatus>((ref) {
  return _defaultAuthStatus();
});



class AuthUserStatus {

  final bool isLoggedIn;

  final String userId;

  final bool hasCompletedIntake;

  final bool hasCompletedStrengthFunnel;

  final bool hasCompletedAssessment;



  const AuthUserStatus({

    required this.isLoggedIn,

    required this.userId,

    required this.hasCompletedIntake,

    required this.hasCompletedStrengthFunnel,

    required this.hasCompletedAssessment,

  });

}



final routerProvider = Provider<GoRouter>((ref) {

  final authStatus = ref.watch(authStatusProvider);



  String initialLocation = '/intake';

  if (authStatus.hasCompletedIntake) {

    if (!authStatus.hasCompletedStrengthFunnel) {

      initialLocation = '/strength-funnel';

    } else if (!authStatus.hasCompletedAssessment) {

      initialLocation = '/assessment-canvas';

    } else {

      initialLocation = '/dashboard';

    }

  }



  return GoRouter(

    initialLocation: initialLocation,

    redirect: (BuildContext context, GoRouterState state) {

      if (!authStatus.isLoggedIn) {
        if (state.matchedLocation != '/login') {
          return '/login';
        }
        return null;
      }



      if (state.matchedLocation == '/child-play') {
        return null;
      }



      if (!authStatus.hasCompletedIntake && state.matchedLocation != '/intake') {

        return '/intake';

      }



      if (authStatus.hasCompletedIntake &&

          !authStatus.hasCompletedStrengthFunnel &&

          state.matchedLocation != '/strength-funnel' &&

          state.matchedLocation != '/strength-summary') {

        return '/strength-funnel';

      }



      if (authStatus.hasCompletedIntake &&

          authStatus.hasCompletedStrengthFunnel &&

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

        builder: (context, state) => const LoginScreen(),

      ),

      GoRoute(

        path: '/intake',

        builder: (context, state) => const IntakeFlowScreen(),

      ),

      GoRoute(

        path: '/strength-funnel',

        builder: (context, state) {
          return StrengthFunnelScreen(

            onFunnelPhaseComplete: () async {

              final funnelState = ref.read(strengthFunnelControllerProvider);

              await ref

                  .read(strengthFunnelControllerProvider.notifier)

                  .persistFinalists(funnelState.finalistSectorIds);

              await ref.read(strengthFunnelControllerProvider.notifier).clearProgress();

              if (context.mounted) {

                context.go('/strength-summary');

              }

            },

          );

        },

      ),

      GoRoute(

        path: '/strength-summary',

        builder: (context, state) {

          final userId = authStatus.userId;

          return Consumer(

            builder: (context, ref, _) {

              final finalistsAsync = ref.watch(strengthFunnelFinalistsProvider);

              return finalistsAsync.when(

                loading: () => const Scaffold(

                  body: Center(child: CircularProgressIndicator()),

                ),

                error: (_, __) => const Scaffold(

                  body: Center(child: Text('Could not load play theme summary.')),

                ),

                data: (finalists) {

                  if (finalists == null || finalists.sectorIds.isEmpty) {

                    WidgetsBinding.instance.addPostFrameCallback((_) {

                      if (context.mounted) context.go('/strength-funnel');

                    });

                    return const SizedBox.shrink();

                  }

                  return GuardianStrengthSummaryScreen(

                    finalists: finalists,

                    onStartPlay: () async {

                      final ok = await launchChildPlaySession(ref, finalists);

                      if (ok && context.mounted) {

                        context.push('/child-play');

                      }

                    },

                    onContinue: () async {

                      await ref

                          .read(strengthFunnelProgressServiceProvider)

                          .clearFinalists();

                      await ref

                          .read(intakePersistenceServiceProvider)

                          .markStrengthFunnelComplete();

                      ref.read(authStatusProvider.notifier).state = AuthUserStatus(

                        isLoggedIn: true,

                        userId: userId,

                        hasCompletedIntake: true,

                        hasCompletedStrengthFunnel: true,

                        hasCompletedAssessment: false,

                      );

                      if (context.mounted) {

                        context.go('/assessment-canvas');

                      }

                    },

                  );

                },

              );

            },

          );

        },

      ),

      GoRoute(

        path: '/child-play',

        builder: (context, state) {

          return ChildPlaySessionScreen(

            onSessionEnded: () async {

              await ref.read(childPlaySessionControllerProvider.notifier).stop();

              if (context.mounted) {

                context.go('/dashboard');

              }

            },

          );

        },

      ),

      GoRoute(

        path: '/assessment-canvas',

        builder: (context, state) {

          final userId = authStatus.userId;

          return DeepeningFunnelCanvas(

            userId: userId,

            onCompleted: () async {

              await ref.read(intakePersistenceServiceProvider).markAssessmentComplete();

              ref.read(authStatusProvider.notifier).state = AuthUserStatus(

                isLoggedIn: true,

                userId: userId,

                hasCompletedIntake: true,

                hasCompletedStrengthFunnel: true,

                hasCompletedAssessment: true,

              );

              if (context.mounted) {

                context.go('/dashboard');

              }

            },

          );

        },

      ),

      GoRoute(

        path: '/dashboard',

        builder: (context, state) => const NeuroSparkDashboard(),

      ),

      GoRoute(

        path: '/sandbox',

        builder: (context, state) {

          final userId = authStatus.userId;

          return Engine4SandboxScreen(userId: userId);

        },

      ),

    ],

  );

});



/// Completes intake, persists customization, and advances to Layer 1 funnel.

Future<void> completeIntakeAndProceed(WidgetRef ref, BuildContext context) async {

  await ref.read(intakeApplicationServiceProvider).compileApplyAndPersist(ref);

  ref.read(intakeFlowProvider.notifier).compilePreview();



  final userId = ref.read(authStatusProvider).userId;

  ref.read(authStatusProvider.notifier).state = AuthUserStatus(

    isLoggedIn: true,

    userId: userId,

    hasCompletedIntake: true,

    hasCompletedStrengthFunnel: false,

    hasCompletedAssessment: false,

  );

  if (context.mounted) {

    context.go('/strength-funnel');

  }

}

