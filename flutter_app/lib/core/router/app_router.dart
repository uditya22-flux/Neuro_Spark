import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../features/dashboard/widgets/neuro_spark_dashboard.dart';

import '../../features/deepening/presentation/deepening_funnel_canvas.dart';

import '../../features/sandbox/presentation/engine4_sandbox_screen.dart';

import '../../features/strength_funnel/presentation/layer1_sector_prompt_widget.dart';
import '../../features/strength_funnel/providers/strength_funnel_controller.dart';

import '../../providers/intake_flow_provider.dart';

import '../../screens/intake_flow_screen.dart';

import '../../services/intake_application_service.dart';

import '../../services/intake_persistence_service.dart';



final authStatusProvider = StateProvider<AuthUserStatus>((ref) {

  return const AuthUserStatus(

    isLoggedIn: true,

    userId: 'user_guardian_101',

    hasCompletedIntake: false,

    hasCompletedStrengthFunnel: false,

    hasCompletedAssessment: false,

  );

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

        return '/login';

      }



      if (!authStatus.hasCompletedIntake && state.matchedLocation != '/intake') {

        return '/intake';

      }



      if (authStatus.hasCompletedIntake &&

          !authStatus.hasCompletedStrengthFunnel &&

          state.matchedLocation != '/strength-funnel') {

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

        builder: (context, state) => const Scaffold(

          body: Center(child: Text('Login Screen')),

        ),

      ),

      GoRoute(

        path: '/intake',

        builder: (context, state) => const IntakeFlowScreen(),

      ),

      GoRoute(

        path: '/strength-funnel',

        builder: (context, state) {

          final userId = authStatus.userId;

          return StrengthFunnelScreen(

            onFunnelPhaseComplete: () async {

              await ref.read(strengthFunnelControllerProvider.notifier).clearProgress();

              await ref.read(intakePersistenceServiceProvider).markStrengthFunnelComplete();

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

