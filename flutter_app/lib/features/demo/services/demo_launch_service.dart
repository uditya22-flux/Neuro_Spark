import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../providers/intake_flow_provider.dart';
import '../../../services/intake_persistence_service.dart';
import '../../strength_funnel/providers/strength_funnel_controller.dart';
import '../data/demo_intake_bundle.dart';
import '../providers/demo_mode_provider.dart';
import '../providers/demo_session_providers.dart';

Future<void> _bootstrapDemoSession(WidgetRef ref) async {
  ref.read(demoModeProvider.notifier).state = true;
  DemoConfig.runtimeActive = true;
  ref.read(demoConsentAcceptedProvider.notifier).state = false;
  ref.read(gameEnvironmentProvider.notifier).clear();
  ref.read(intakeFlowProvider.notifier).seedFromDemoPrefills();
  await ref.read(strengthFunnelProgressServiceProvider).clearAll();
  await ref.read(intakePersistenceServiceProvider).clearAll(ref);
}

/// Full hospital walkthrough: consent → intake (pre-filled) → shortened funnel.
Future<void> launchHospitalDemoGuided(WidgetRef ref, BuildContext context) async {
  DemoConfig.guidedFullFlow = true;
  await _bootstrapDemoSession(ref);

  ref.read(authStatusProvider.notifier).state = const AuthUserStatus(
    isLoggedIn: true,
    userId: 'demo_guardian',
    hasCompletedIntake: false,
    hasCompletedStrengthFunnel: false,
    hasCompletedAssessment: false,
  );

  if (context.mounted) {
    context.go('/consent');
  }
}

/// Quick pitch: skip intake, synthetic bundle, demo intro → funnel.
Future<void> launchHospitalDemoQuick(WidgetRef ref, BuildContext context) async {
  DemoConfig.guidedFullFlow = false;
  await _bootstrapDemoSession(ref);
  ref.read(gameEnvironmentProvider.notifier).set(buildDemoIntakeBundle());

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

/// Default hospital demo entry — guided full flow.
Future<void> launchHospitalDemo(WidgetRef ref, BuildContext context) {
  return launchHospitalDemoGuided(ref, context);
}
