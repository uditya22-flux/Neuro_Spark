import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_environment_provider.dart';
import '../../strength_funnel/models/strength_funnel_finalists.dart';
import '../providers/child_play_session_controller.dart';

/// Starts a child play session from guardian context. Returns false on failure.
Future<bool> launchChildPlaySession(
  WidgetRef ref,
  StrengthFunnelFinalists finalists,
) async {
  final bundle = ref.read(gameEnvironmentProvider);
  if (bundle == null) return false;

  await ref.read(childPlaySessionControllerProvider.notifier).start(
        bundle: bundle,
        finalists: finalists,
      );

  return ref.read(childPlaySessionControllerProvider).error == null;
}
