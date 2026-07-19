import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/safe_mode_provider.dart';
import '../../../core/widgets/dashed_container.dart';
import '../../../core/widgets/sensory_text.dart';
import '../../../core/widgets/safe_mode_dimmer.dart';
import '../../../core/services/ai_edge_service.dart';
import '../../../core/services/notification_service.dart';
import '../../schedule/data/schedule_dao.dart';
import '../../talent/data/talent_dao.dart';
import '../providers/dashboard_layout_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutAsync = ref.watch(dashboardLayoutProvider);
    final safeMode = ref.watch(safeModeProvider);

    return SafeModeDimmer(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'NeuroSpark',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Global Safe Mode Toggle Switch
            Row(
              children: [
                Icon(
                  safeMode.isEnabled
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  color: safeMode.isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'Safe Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: safeMode.isEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                Switch(
                  value: safeMode.isEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    ref.read(safeModeProvider.notifier).toggle();
                    
                    // Trigger a soft announcement notification
                    ref.read(notificationServiceProvider).showSensoryNotification(
                          id: 100,
                          title: val ? "Safe Mode Enabled" : "Safe Mode Disabled",
                          body: val 
                              ? "Sensory filters applied: dimming active, muted interfaces."
                              : "Returning to normal sensory environment.",
                        );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
        body: layoutAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text('Error loading layout: $err'),
          ),
          data: (config) {
            // Server-Driven UI Module Ordering Logic
            List<String> modules = List.from(config.moduleOrder);

            // Conditional Priority Rules:
            // 1. High Auditory Risk: Push Scanner to top
            if (config.highAuditoryRisk) {
              modules.remove('scanner');
              modules.insert(0, 'scanner');
            }

            // Render modules dynamically
            return RefreshIndicator(
              onRefresh: () => ref.read(dashboardLayoutProvider.notifier).fetchLayout(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemCount: modules.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Header sensory intro text
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sensory Profile: ${config.sensoryProfileName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const SensoryText(
                            text: 'Welcome to your tailored sensory dashboard. This interface dynamically configures itself based on your auditory, visual, and routine needs. Safe Mode can be activated at any time via the top-right toggle to instantly scale down stimulation, mute notifications, and dim light levels.',
                          ),
                        ],
                      ),
                    );
                  }

                  final moduleType = modules[index - 1];

                  switch (moduleType) {
                    case 'schedule':
                      return VisualScheduleCard(isExpanded: config.routineAnxiety);
                    case 'scanner':
                      return ScannerCard(isPromoted: config.highAuditoryRisk);
                    case 'talent':
                      return const TalentGrowthCard();
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 1. VISUAL SCHEDULE CARD (WITH CIRCULAR CHECKBOXES)
// ----------------------------------------------------
class VisualScheduleCard extends ConsumerWidget {
  final bool isExpanded;

  const VisualScheduleCard({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Visual schedules checklist with circular checkbox selectors
    final scheduleDao = ref.watch(scheduleDaoProvider);
    
    return FutureBuilder<List<VisualScheduleItem>>(
      future: scheduleDao.getScheduleItems('demo_user_123'),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16.0),
          height: isExpanded ? 340 : 220,
          child: DashedContainer(
            borderColor: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).cardTheme.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visual Routine',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Primary Routine Focus Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ),
                          child: Icon(
                            _getIconForType(item.iconKey),
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(item.timeLabel),
                        trailing: InkWell(
                          onTap: () async {
                            await scheduleDao.updateItemCompletion(item.id, !item.isCompleted);
                            ref.invalidate(scheduleDaoProvider); // Refresh
                            
                            // Emit soft tap notification feedback if safe mode is off
                            final safeMode = ref.read(safeModeProvider);
                            if (!safeMode.isEnabled) {
                              ref.read(notificationServiceProvider).showSensoryNotification(
                                    id: 200 + index,
                                    title: "Task Updated",
                                    body: "${item.title} completed status toggled.",
                                  );
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: item.isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: item.isCompleted
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: item.isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String key) {
    switch (key) {
      case 'breath':
        return Icons.spa_rounded;
      case 'puzzle':
        return Icons.extension_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}

// ----------------------------------------------------
// 2. SCANNER / PUZZLE CARD (AI GAME TELEMETRY INTERACTION)
// ----------------------------------------------------
class ScannerCard extends ConsumerStatefulWidget {
  final bool isPromoted;

  const ScannerCard({
    super.key,
    required this.isPromoted,
  });

  @override
  ConsumerState<ScannerCard> createState() => _ScannerCardState();
}

class _ScannerCardState extends ConsumerState<ScannerCard> {
  bool _isAnalyzing = false;
  StrengthProfile? _resultProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: DashedContainer(
        borderColor: widget.isPromoted 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300,
        borderWidth: widget.isPromoted ? 2.5 : 1.5,
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.extension_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pattern Discovery Puzzle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const SensoryText(
              text: 'Tap puzzle items to match layout rules. This card tracks tactile latency, visual correction cycles, and spatial mapping telemetry to feed our AI assessment model.',
            ),
            const SizedBox(height: 12),
            if (_resultProfile != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Insight Strength: ${_resultProfile!.primaryStrength}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Recommended Path: ${_resultProfile!.recommendedGrowthPath}'),
                    const SizedBox(height: 6),
                    Text('Telemetry Markers: ${_resultProfile!.cognitiveMarkers.join(", ")}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _simulateTelemetryGame,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(_isAnalyzing ? 'Processing Game Vectors...' : 'Complete Challenge & Analyze'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simulateTelemetryGame() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Capture telemetry patterns
    final mockTelemetry = [
      {'action': 'click_start', 'ms_offset': 120, 'coordinate': 'X:32, Y:12'},
      {'action': 'pattern_match_correct', 'ms_offset': 1400, 'coordinate': 'X:45, Y:22'},
      {'action': 'drag_latency', 'ms_offset': 450, 'coordinate': 'X:10, Y:15'},
    ];

    // Call Supabase Edge Function talent-ai
    final aiService = ref.read(aiEdgeServiceProvider);
    final profile = await aiService.analyzeGameTelemetry(telemetryVectors: mockTelemetry);

    if (mounted) {
      setState(() {
        _resultProfile = profile;
        _isAnalyzing = false;
      });

      // Show notification details
      ref.read(notificationServiceProvider).showSensoryNotification(
            id: 300,
            title: "Talent Discovery Complete",
            body: "Your profile has been analyzed. Strength: ${profile.primaryStrength}.",
          );
    }
  }
}

// ----------------------------------------------------
// 3. TALENT GROWTH CARD (ROADMAP TREE STEPS)
// ----------------------------------------------------
class TalentGrowthCard extends ConsumerWidget {
  const TalentGrowthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talentDao = ref.watch(talentDaoProvider);

    return FutureBuilder<List<RoadmapStep>>(
      future: talentDao.getRoadmapSteps('demo_user_123'),
      builder: (context, snapshot) {
        final steps = snapshot.data ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: DashedContainer(
            borderColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            backgroundColor: Theme.of(context).cardTheme.color,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Talent Growth Roadmap',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    final step = steps[index];
                    final isCompleted = step.isCompleted;
                    final isUnlocked = step.isUnlocked;

                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          // Left stepper line indicators
                          Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : (isUnlocked
                                          ? Theme.of(context).colorScheme.secondary
                                          : Colors.grey.shade400),
                                ),
                                child: isCompleted
                                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                                    : Center(
                                        child: Text(
                                          '${step.stepNumber}',
                                          style: const TextStyle(fontSize: 10, color: Colors.white),
                                        ),
                                      ),
                              ),
                              if (index < steps.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isCompleted
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Content Card details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isUnlocked
                                          ? Theme.of(context).textTheme.bodyLarge?.color
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  Text(
                                    step.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isUnlocked
                                          ? Theme.of(context).textTheme.bodyMedium?.color
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  if (step.sensoryNote.isNotEmpty && isUnlocked) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sensory Note: ${step.sensoryNote}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
