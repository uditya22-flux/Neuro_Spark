import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/safe_mode_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/widgets/neuro_spark_intake_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Connectivity
  await SupabaseService.initialize();

  // Initialize Firebase with placeholder options for startup configuration
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDummyApiKeyPlaceholder12345",
        appId: "1:1234567890:android:abc123dummyapp",
        messagingSenderId: "1234567890",
        projectId: "neurospark-dummy-project",
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

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

    return MaterialApp(
      title: 'NeuroSpark Accessibility App',
      debugShowCheckedModeBanner: false,
      
      // 2. Swaps context colors instantly to dark high contrast theme if enabled
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: safeMode.isEnabled ? ThemeMode.dark : ThemeMode.light,
      
      home: const NeuroSparkIntakeFlow(),
    );
  }
}
