import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../features/child/presentation/guardian_handoff_screen.dart';
import '../../features/child/presentation/child_play_launch_helper.dart';
import '../../features/child/presentation/child_play_session_screen.dart';
import '../../features/child/providers/child_play_session_controller.dart';
import '../../features/dashboard/widgets/neuro_spark_dashboard.dart';
import '../../features/guardian/presentation/guardian_settings_screen.dart';
import '../../providers/game_environment_provider.dart';

import '../../features/demo/presentation/demo_mode_banner.dart';
import '../../core/config/demo_config.dart';
import '../../features/deepening/presentation/deepening_funnel_canvas.dart';

import '../../features/sandbox/presentation/engine4_sandbox_screen.dart';

import '../../features/strength_funnel/presentation/guardian_strength_summary_screen.dart';
import '../../features/strength_funnel/presentation/layer1_sector_prompt_widget.dart';
import '../../features/strength_funnel/providers/strength_funnel_controller.dart';

import '../../providers/intake_flow_provider.dart';

import '../../screens/intake_flow_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/guardian_consent_screen.dart';
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

  if (authStatus.userId == 'demo_guardian') {
    if (!authStatus.hasCompletedIntake) {
      initialLocation = '/consent';
    } else if (!authStatus.hasCompletedStrengthFunnel) {
      initialLocation = DemoConfig.guidedFullFlow ? '/strength-funnel' : '/demo-intro';
    } else {
      initialLocation = '/dashboard';
    }
  } else if (authStatus.hasCompletedIntake) {

    if (!authStatus.hasCompletedStrengthFunnel) {

      initialLocation = '/strength-funnel';

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



      if (authStatus.isLoggedIn && state.matchedLocation == '/login') {
        if (authStatus.userId == 'demo_guardian') {
          return authStatus.hasCompletedIntake
              ? (DemoConfig.guidedFullFlow ? '/strength-funnel' : '/demo-intro')
              : '/consent';
        }
        return '/consent';
      }

      final isDemoSession = authStatus.userId == 'demo_guardian';

      if (isDemoSession) {
        const demoOpenPaths = {
          '/consent',
          '/intake',
          '/demo-intro',
          '/strength-funnel',
          '/strength-summary',
          '/guardian-handoff',
          '/child-play',
          '/dashboard',
          '/assessment-canvas',
          '/guardian-settings',
        };
        if (demoOpenPaths.contains(state.matchedLocation)) {
          return null;
        }
        if (!authStatus.hasCompletedIntake) {
          return '/consent';
        }
        if (!authStatus.hasCompletedStrengthFunnel) {
          return DemoConfig.guidedFullFlow ? '/strength-funnel' : '/demo-intro';
        }
        return '/dashboard';
      }

      const guardianOpenPaths = {
        '/consent',
        '/guardian-settings',
        '/guardian-handoff',
        '/child-play',
        '/strength-summary',
        '/dashboard',
        '/assessment-canvas',
      };

      if (guardianOpenPaths.contains(state.matchedLocation)) {
        return null;
      }



      if (!authStatus.hasCompletedIntake &&
          state.matchedLocation != '/intake' &&
          state.matchedLocation != '/consent') {

        return '/consent';

      }



      if (authStatus.hasCompletedIntake &&

          !authStatus.hasCompletedStrengthFunnel &&

          state.matchedLocation != '/strength-funnel' &&

          state.matchedLocation != '/strength-summary') {

        return '/strength-funnel';

      }


      if (authStatus.hasCompletedIntake &&

          authStatus.hasCompletedStrengthFunnel &&

          authStatus.hasCompletedAssessment &&

          state.matchedLocation != '/dashboard') {

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

        path: '/demo-intro',

        builder: (context, state) => const DemoIntroScreen(),

      ),

      GoRoute(

        path: '/consent',

        builder: (context, state) => const GuardianConsentScreen(),

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

                      await completeStrengthFunnelSession(ref, userId: userId);

                      if (context.mounted) {

                        context.push('/guardian-handoff');

                      }

                    },

                    onGoToDashboard: () async {

                      await completeStrengthFunnelSession(ref, userId: userId);

                      if (context.mounted) {

                        context.go('/dashboard');

                      }

                    },

                    onContinue: () async {

                      await completeStrengthFunnelSession(ref, userId: userId);

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

        path: '/guardian-handoff',

        builder: (context, state) {

          return Consumer(

            builder: (context, ref, _) {

              final bundle = ref.watch(gameEnvironmentProvider);

              final finalistsAsync = ref.watch(strengthFunnelFinalistsProvider);

              return finalistsAsync.when(

                loading: () => const Scaffold(

                  body: Center(child: CircularProgressIndicator()),

                ),

                error: (_, __) => const Scaffold(

                  body: Center(child: Text('Could not load play themes.')),

                ),

                data: (finalists) {

                  if (finalists == null || finalists.sectorIds.isEmpty) {

                    WidgetsBinding.instance.addPostFrameCallback((_) {

                      if (context.mounted) context.go('/strength-funnel');

                    });

                    return const SizedBox.shrink();

                  }

                  return GuardianHandoffScreen(

                    childName: bundle?.parent.childName ?? '',

                    onCancel: () => context.pop(),

                    onReady: () async {

                      final ok = await launchChildPlaySession(ref, finalists);

                      if (ok && context.mounted) {

                        context.go('/child-play');

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

          return Consumer(

            builder: (context, ref, _) {

              final playState = ref.watch(childPlaySessionControllerProvider);

              if (playState.sessionId == null && !playState.loading && !playState.completed) {

                WidgetsBinding.instance.addPostFrameCallback((_) {

                  if (context.mounted) context.go('/dashboard');

                });

                return const Scaffold(

                  body: Center(child: CircularProgressIndicator()),

                );

              }

              return ChildPlaySessionScreen(

                onSessionEnded: () async {

                  await ref.read(childPlaySessionControllerProvider.notifier).stop();

                  if (context.mounted) {

                    context.go('/dashboard');

                  }

                },

              );

            },

          );

        },

      ),

      GoRoute(

        path: '/assessment-canvas',

        builder: (context, state) {

          final userId = authStatus.userId;

          return Consumer(

            builder: (context, ref, _) {

              final childId = ref.watch(gameEnvironmentProvider)?.childId;

              if (childId == null) {

                return Scaffold(

                  appBar: AppBar(title: const Text('Strength activities')),

                  body: const Center(

                    child: Padding(

                      padding: EdgeInsets.all(24),

                      child: Text(

                        'Complete intake first to link your child profile before deeper activities.',

                        textAlign: TextAlign.center,

                      ),

                    ),

                  ),

                );

              }

              return DeepeningFunnelCanvas(

                userId: childId,

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

          );

        },

      ),

      GoRoute(

        path: '/dashboard',

        builder: (context, state) => const NeuroSparkDashboard(),

      ),

      GoRoute(

        path: '/guardian-settings',

        builder: (context, state) => const GuardianSettingsScreen(),

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



/// Marks strength funnel complete and unlocks guardian home / child play.

Future<void> completeStrengthFunnelSession(WidgetRef ref, {required String userId}) async {

  await ref.read(intakePersistenceServiceProvider).markStrengthFunnelComplete();

  ref.read(authStatusProvider.notifier).state = AuthUserStatus(

    isLoggedIn: true,

    userId: userId,

    hasCompletedIntake: true,

    hasCompletedStrengthFunnel: true,

    hasCompletedAssessment: false,

  );

}



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

/// Clears funnel progress and returns to Layer 1 (10-layer exploration).
Future<void> restartStrengthFunnelExploration(WidgetRef ref, BuildContext context) async {
  await ref.read(strengthFunnelProgressServiceProvider).clearAll();
  await ref.read(intakePersistenceServiceProvider).markStrengthFunnelIncomplete();
  ref.read(strengthFunnelControllerProvider.notifier).resetSession();

  final current = ref.read(authStatusProvider);
  ref.read(authStatusProvider.notifier).state = AuthUserStatus(
    isLoggedIn: current.isLoggedIn,
    userId: current.userId,
    hasCompletedIntake: true,
    hasCompletedStrengthFunnel: false,
    hasCompletedAssessment: current.hasCompletedAssessment,
  );

  await ref.read(strengthFunnelControllerProvider.notifier).startLayer1();

  if (context.mounted) {
    context.go('/strength-funnel');
  }
}

