import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_session_sync.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/safe_mode_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'models/intake_models.dart';
import 'providers/game_environment_provider.dart';
import 'core/router/app_router.dart';
import 'core/config/demo_config.dart';
import 'features/demo/presentation/demo_mode_banner.dart';
import 'features/demo/data/demo_intake_bundle.dart';
import 'features/demo/providers/demo_mode_provider.dart';
import 'services/intake_persistence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  // Firebase initialization has been skipped since FCM is charter-blocked and breaks web builds.

  // Create ProviderContainer for initializing non-widget-scoped services.
  final container = ProviderContainer();

  // Initialize Sensory Local Notification Engine
  await container.read(notificationServiceProvider).initialize();

  // Initialize Firebase and trigger token sync checks
  await container.read(firebaseServiceProvider).initializeAndRegisterToken();

  // Restore persisted intake customization + flow progress before first frame.
  await restorePersistedIntakeSession(container);
  await syncAuthSession(container);
  bindSupabaseAuthListener(container);

  if (DemoConfig.compileTimeEnabled) {
    DemoConfig.runtimeActive = true;
    container.read(demoModeProvider.notifier).state = true;
    container.read(gameEnvironmentProvider.notifier).set(buildDemoIntakeBundle());
    container.read(authStatusProvider.notifier).state = const AuthUserStatus(
      isLoggedIn: true,
      userId: 'demo_guardian',
      hasCompletedIntake: true,
      hasCompletedStrengthFunnel: false,
      hasCompletedAssessment: false,
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NeuroSparkApp(),
    ),
  );
}

class NeuroSparkApp extends ConsumerWidget {
  const NeuroSparkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeMode = ref.watch(safeModeProvider);
    final gameConfig = ref.watch(activeGameConfigProvider);
    final router = ref.watch(routerProvider);

    final preferDark = safeMode.isEnabled || gameConfig?.themePalette == ThemePalette.calmDark;

    return MaterialApp.router(
      title: 'NeuroSpark Accessibility App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => DemoModeBanner(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
