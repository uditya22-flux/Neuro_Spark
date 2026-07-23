import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/prototype_mode.dart';
import '../../exploration/models/exploration_models.dart';
import '../../exploration/presentation/ambient_play_board.dart';
import '../../exploration/presentation/sensory_glass_surface.dart';
import '../../exploration/providers/exploration_funnel_provider.dart';
import '../../exploration/providers/intake_provider.dart';
import '../../exploration/services/capstone_router.dart';
import '../../exploration/services/telemetry_tracker.dart';
import '../../exploration/services/visual_scene_service.dart';

class DeepeningFunnelCanvas extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onCompleted;

  const DeepeningFunnelCanvas({super.key, required this.userId, required this.onCompleted});

  @override
  ConsumerState<DeepeningFunnelCanvas> createState() => _DeepeningFunnelCanvasState();
}

class _DeepeningFunnelCanvasState extends ConsumerState<DeepeningFunnelCanvas> {
  TelemetryTracker? _tracker;
  String? _taskId;
  bool _reportedCapstone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(explorationFunnelProvider.notifier).start());
  }

  void _syncTracker(PuzzleSpec task) {
    if (_taskId == task.id) return;
    _taskId = task.id;
    _tracker = TelemetryTracker();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explorationFunnelProvider);
    final controller = ref.read(explorationFunnelProvider.notifier);
    final task = state.currentTask;

    if (state.phase == ExplorationPhase.complete) {
      if (!_reportedCapstone) {
        _reportedCapstone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final preference = ref.read(intakeProvider).configuration?.sandboxPreference ?? SandboxPreference.calendar;
          final vertical = adaptiveFunnelDemoMode
              ? state.finalMechanic == null
                  ? null
                  : CapstoneRouter.verticalIdForPlayMechanic(state.finalMechanic!)
              : CapstoneRouter.verticalIdFor(preference);
          widget.onCompleted();
          context.go(vertical == null ? '/exploring' : '/sandbox?vertical=$vertical');
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (task == null) return Scaffold(body: Center(child: Text(state.error ?? 'Preparing play...')));

    _syncTracker(task);
    if (state.support.timerPaused) _tracker?.pause();
    final intake = ref.watch(intakeProvider).configuration;
    final visualScene = state.usesSyntheticCloud
        ? state.syntheticCloudScene
        : intake == null
            ? null
            : ref.watch(
                visualSceneProvider(
                  VisualSceneRequest(
                    childId: intake.childId,
                    layer: task.layer,
                    taskId: task.id,
                    syntheticDemoWorld: intake.syntheticDemoWorld,
                    familiarColors: intake.familiarColors.toList(growable: false),
                    visualStylePreference: intake.visualStylePreference,
                    motionAllowed: intake.interface.allowMotion,
                  ),
                ),
              ).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SensoryGlassSurface(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showcaseDebugOverlay)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _ShowcaseDebugReadout(
                          task: task,
                          activeMechanics: state.activeMechanics,
                        ),
                      ),
                    if (task.showsDistractors) const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: _QuietDistractorMarkers(),
                    ),
                    AmbientPlayBoard(
                      task: task,
                      scene: visualScene,
                      highlightTarget: state.support.highlightTarget,
                      onChoice: (option) async {
                        _tracker!.resume();
                        controller.recordChildInteraction();
                        if (state.usesSyntheticCloud) {
                          final outcome = await controller.submitSyntheticCloudSelection(
                            optionId: option,
                            telemetry: _tracker!.snapshot(includePendingInteraction: true),
                          );
                          if (outcome == SyntheticCloudChoiceResult.unavailable) {
                            return false;
                          }
                          if (outcome == SyntheticCloudChoiceResult.softMiss) {
                            _tracker!.recordSoftMiss();
                            return false;
                          }
                          _tracker!.recordCorrectChoice();
                          return true;
                        }
                        if (option != task.correctOption) {
                          _tracker!.recordSoftMiss();
                          return false;
                        }

                        _tracker!.recordCorrectChoice();
                        controller.completeCurrentTask(_tracker!.finish());
                        return true;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietDistractorMarkers extends StatelessWidget {
  const _QuietDistractorMarkers();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Marker(color: Color(0x335270A2)),
          SizedBox(width: 16),
          _Marker(color: Color(0x33D76B5E)),
          SizedBox(width: 16),
          _Marker(color: Color(0x33E3AD45)),
        ],
      );
}

class _Marker extends StatelessWidget {
  const _Marker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// This is intentionally available only behind a compile-time developer flag.
/// It lets a demo reviewer verify the 30-sector funnel without adding words,
/// labels, or score language to the child-facing experience.
class _ShowcaseDebugReadout extends StatelessWidget {
  const _ShowcaseDebugReadout({
    required this.task,
    required this.activeMechanics,
  });

  final PuzzleSpec task;
  final List<PlayMechanic> activeMechanics;

  @override
  Widget build(BuildContext context) {
    final mechanic = task.mechanics.isEmpty ? null : task.mechanics.single;
    final rawIndex = mechanic == null ? -1 : activeMechanics.indexOf(mechanic);
    final position = rawIndex < 0 ? 1 : rawIndex + 1;
    final total = activeMechanics.isEmpty ? 1 : activeMechanics.length;
    final label = mechanic?.label ?? 'visual play';
    final group = mechanic?.group.label ?? 'word-free play';
    return Semantics(
      label: 'Showcase debug: Layer ${task.layer}, sector $position of $total, $group, $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff1c2b3d).withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            'DEMO INSPECTOR | LAYER ${task.layer} | $position / $total | ${group.toUpperCase()} | ${label.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .45,
            ),
          ),
        ),
      ),
    );
  }
}
