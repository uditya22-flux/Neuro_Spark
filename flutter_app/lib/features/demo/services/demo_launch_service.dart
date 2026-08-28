import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/game_environment_provider.dart';
import '../../strength_funnel/providers/strength_funnel_controller.dart';
import '../data/demo_intake_bundle.dart';
import '../providers/demo_mode_provider.dart';

/// Boots synthetic demo data and navigates to the shortened strength funnel.
Future<void> launchHospitalDemo(WidgetRef ref, BuildContext context) async {
  ref.read(demoModeProvider.notifier).state = true;
  DemoConfig.runtimeActive = true;
  ref.read(gameEnvironmentProvider.notifier).set(buildDemoIntakeBundle());
  await ref.read(strengthFunnelProgressServiceProvider).clearAll();

  ref.read(authStatusProvider.notifier).state = const AuthUserStatus(
    isLoggedIn: true,
    userId: 'demo_guardian',
    hasCompletedIntake: true,
    hasCompletedStrengthFunnel: false,
    hasCompletedAssessment: false,
  );

  if (context.mounted) {
    context.go('/demo-intro');
  }
}
