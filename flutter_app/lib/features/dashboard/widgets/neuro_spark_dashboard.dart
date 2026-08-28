import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdui_controller.dart';
import 'dynamic_header.dart';
import 'visual_schedule_widget.dart';
import 'emotion_hub_widget.dart';
import 'talent_growth_widget.dart';
import 'generative_ui_console.dart';
import '../providers/dashboard_controller.dart';
import 'swapped_elements.dart';
import '../../child/presentation/guardian_play_launch_card.dart';

class NeuroSparkDashboard extends ConsumerStatefulWidget {
  const NeuroSparkDashboard({super.key});

  @override
  ConsumerState<NeuroSparkDashboard> createState() => _NeuroSparkDashboardState();
}

class _NeuroSparkDashboardState extends ConsumerState<NeuroSparkDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Actively fetches fresh intake profile from database Supabase
      ref.read(sduiControllerProvider.notifier).fetchActiveProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sduiState = ref.watch(sduiControllerProvider);
    final dashboardLayout = ref.watch(dashboardControllerProvider);
    final widgetIds = dashboardLayout.widgetIds;
    final isAac = dashboardLayout.isAacMode;

    return Theme(
      data: sduiState.themeData,
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: isAac
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.secondary, size: 28),
                      ],
                    )
                  : Text(
                      'NeuroSpark',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Dynamic Adaptive SDUI Widgets Container (Scrollable)
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        // Smooth slide and fade transition when swapping profiles
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.05),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: ListView.builder(
                        key: ValueKey(sduiState.activeProfileName),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: widgetIds.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const GuardianPlayLaunchCard();
                          }
                          final componentKey = widgetIds[index - 1];
                          Widget widget;
                          switch (componentKey) {
                            case 'header':
                              widget = const DynamicHeader();
                              break;
                            case 'generative_console':
                              widget = const GenerativeUiConsole();
                              break;
                            case 'schedule':
                              widget = isAac ? const PictogramScheduleWidget() : const VisualScheduleWidget();
                              break;
                            case 'emotion':
                              widget = const EmotionHubWidget();
                              break;
                            case 'talent':
                              widget = const TalentGrowthWidget();
                              break;
                            case 'rhythm_pad':
                              widget = const KineticRhythmPadWidget();
                              break;
                            case 'breathing_ring':
                              widget = const SilentBreathingRingWidget();
                              break;
                            case 'heavy_haptics':
                              widget = const HeavyHapticButtonWidget();
                              break;
                            default:
                              widget = const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: widget,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
