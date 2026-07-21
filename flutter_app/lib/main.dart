import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/safe_mode_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/widgets/neuro_spark_intake_flow.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Connectivity (from environment or default fallback)
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && anonKey.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  } else {
    await SupabaseService.initialize();
  }

  // Firebase initialization has been skipped since FCM is charter-blocked and breaks web builds.

  // Create ProviderContainer for initializing non-widget-scoped services.
  final container = ProviderContainer();

  // Initialize Sensory Local Notification Engine
  await container.read(notificationServiceProvider).initialize();

  // Initialize Firebase and trigger token sync checks
  await container.read(firebaseServiceProvider).initializeAndRegisterToken();

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
    // 1. Listen to global SafeModeProvider
    final safeMode = ref.watch(safeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'NeuroSpark Accessibility App',
      debugShowCheckedModeBanner: false,
      
      // 2. Swaps context colors instantly to dark high contrast theme if enabled
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: safeMode.isEnabled ? ThemeMode.dark : ThemeMode.light,
      
      routerConfig: router,
    );
  }
}
