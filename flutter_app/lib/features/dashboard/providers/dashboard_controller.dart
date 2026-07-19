import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sdui_controller.dart';

class DashboardLayoutState {
  final List<String> widgetIds;
  final bool isAacMode;

  const DashboardLayoutState({
    required this.widgetIds,
    required this.isAacMode,
  });
}

class DashboardController extends StateNotifier<DashboardLayoutState> {
  final Ref ref;

  DashboardController(this.ref) : super(const DashboardLayoutState(widgetIds: [], isAacMode: false)) {
    _calculateLayout();
    // Re-calculate layout whenever the core SDUI profile changes
    ref.listen(sduiControllerProvider, (previous, next) {
      _calculateLayout();
    });
  }

  void _calculateLayout() {
    final sduiState = ref.read(sduiControllerProvider);
    final profile = sduiState.profile;

    final difficulty = profile.routineTransitions.transitionDifficultyScore;
    final interoception = profile.communicationEmotion.emotionalInteroceptionLevel.toLowerCase();
    final auditoryReaction = profile.sensoryProfile.auditoryReaction.toLowerCase();
    final regulationMethod = profile.sensoryProfile.effectiveRegulationMethod.toLowerCase();

    final isAac = sduiState.isAacMode;

    // Build the dynamic layout list top-to-bottom
    final List<String> layout = [];

    // Always put dynamic greeting header at index 0 of base components
    layout.add('header');

    // Add GenUI interactive console
    layout.add('generative_console');

    // Rule 3: Functional Element Swapping
    if (auditoryReaction.contains('seek') || auditoryReaction.contains('noise')) {
      layout.add('rhythm_pad');
    } else if (auditoryReaction.contains('overwhelm') || auditoryReaction.contains('sensitive')) {
      layout.add('breathing_ring');
    }

    if (regulationMethod.contains('pressure') || regulationMethod.contains('deep')) {
      layout.add('heavy_haptics');
    }

    // Base widget blocks
    layout.add('talent');
    layout.add('schedule');
    layout.add('emotion');

    // Rule 1: Structural Re-ordering (Priority Injection)
    // If transition difficulty is 4 or 5, inject the schedule widget at index 0 (or index 1 if keeping header at absolute top).
    // Let's inject it at the top of the body blocks (which means index 0 if we ignore header, or index 1).
    // Let's place it at index 0 of the scrollable tree to match the prompt instructions:
    // "inject the VisualScheduleWidget at index 0 (the very top of the screen)"
    if (difficulty == 4 || difficulty == 5) {
      layout.remove('schedule');
      layout.insert(0, 'schedule');
    }

    // If interoception level is "Rarely" (represented as "low"), inject EmotionHubWidget at index 0 instead.
    if (interoception == 'low' || interoception.contains('rare')) {
      layout.remove('emotion');
      layout.insert(0, 'emotion');
    }

    state = DashboardLayoutState(
      widgetIds: layout,
      isAacMode: isAac,
    );
  }
}

final dashboardControllerProvider = StateNotifierProvider.autoDispose<DashboardController, DashboardLayoutState>((ref) {
  return DashboardController(ref);
});
