import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/child/presentation/constellation_puzzle_screen.dart';
import 'features/child/presentation/cooldown_screen.dart';
import 'features/child/presentation/timeline_puzzle_screen.dart';
import 'features/guardian/presentation/consent_screen.dart';
import 'features/guardian/presentation/intake_review_screen.dart';
import 'features/guardian/presentation/guardian_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;
  return GoRouter(
    initialLocation: '/guardian/consent',
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = client.auth.currentSession;
      final atConsent = state.matchedLocation == '/guardian/consent';
      if (session == null) {
        return atConsent ? null : '/guardian/consent';
      }
      return atConsent ? '/guardian/home' : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/guardian/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/guardian/review',
        builder: (context, state) => const IntakeReviewScreen(),
      ),
      GoRoute(
        path: '/guardian/home',
        builder: (context, state) => const GuardianHomeScreen(),
      ),
      GoRoute(
        path: '/play/timeline',
        builder: (context, state) => const TimelinePuzzleScreen(),
      ),
      GoRoute(
        path: '/play/constellation',
        builder: (context, state) => const ConstellationPuzzleScreen(),
      ),
      GoRoute(
        path: '/play/cooldown',
        builder: (context, state) => const CooldownScreen(),
      ),
    ],
  );
});

class MindBridgeApp extends ConsumerWidget {
  const MindBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MindBridge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3458a5)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
