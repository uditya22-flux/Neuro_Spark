import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/safe_mode_provider.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/config/prototype_mode.dart';
import 'features/exploration/providers/intake_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local development reads public Supabase settings from flutter_app/.env.
  // Compile-time values remain available for CI and deployed builds. The
  // builder-only showcase is intentionally able to start offline because it
  // has no cloud, account, or persistence path.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    if (!builderShowcaseMode) rethrow;
  }
  const definedUrl = String.fromEnvironment('SUPABASE_URL');
  const definedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final url = definedUrl.isNotEmpty ? definedUrl : dotenv.env['SUPABASE_URL']?.trim();
  final anonKey = definedAnonKey.isNotEmpty
      ? definedAnonKey
      : dotenv.env['SUPABASE_ANON_KEY']?.trim();

  final hasSupabaseConfiguration = url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty;
  if (!hasSupabaseConfiguration && !builderShowcaseMode) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Add them to flutter_app/.env.',
    );
  }

  if (hasSupabaseConfiguration) {
    await Supabase.initialize(url: url!, publishableKey: anonKey!);
  }

  // Synthetic showcase builds use a short-lived anonymous Supabase identity
  // solely to authorize the fixed-input demo scene function. If anonymous
  // auth is unavailable, the play UI still works with its local vector scene.
  if (syntheticDemoMode && hasSupabaseConfiguration) {
    final auth = Supabase.instance.client.auth;
    try {
      // Synthetic cloud mode is deliberately authorized only by an anonymous
      // demo identity. A leftover magic-link/email session from a prior run
      // must not be reused because the server rejects non-anonymous users.
      if (auth.currentUser?.isAnonymous != true) {
        if (auth.currentSession != null) await auth.signOut();
        await auth.signInAnonymously();
      }
    } catch (error) {
      debugPrint('Synthetic demo anonymous sign-in unavailable: $error');
    }
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
    final interface = ref.watch(interfaceConfigurationProvider);

    return MaterialApp.router(
      title: 'NeuroSpark Accessibility App',
      debugShowCheckedModeBanner: false,
      
      // 2. Swaps context colors instantly to dark high contrast theme if enabled
      theme: AppTheme.lightTheme.copyWith(
        colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
          // Low visual-clutter preference deliberately reduces contrast.
          primary: Color.lerp(AppTheme.lightPrimary, AppTheme.lightSurface, 1 - interface.contrastScale)!,
        ),
      ),
      darkTheme: AppTheme.darkTheme,
      themeMode: safeMode.isEnabled ? ThemeMode.dark : ThemeMode.light,
      
      routerConfig: router,
    );
  }
}
