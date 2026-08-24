import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/modality_router.dart';
import '../data/strength_funnel_math.dart';
import '../models/layer1_sector_task.dart';
import '../models/riasec_sector.dart';
import '../providers/strength_funnel_controller.dart';

/// Layer 1 sector prompt renderer — modality chosen by ISAA routing engine.
class Layer1SectorPromptWidget extends StatefulWidget {
  const Layer1SectorPromptWidget({
    super.key,
    required this.task,
    required this.constraints,
    this.onEnjoymentSelected,
  });

  final Layer1SectorTask task;
  final ModalityConstraints constraints;
  final ValueChanged<double>? onEnjoymentSelected;

  @override
  State<Layer1SectorPromptWidget> createState() => _Layer1SectorPromptWidgetState();
}

class _Layer1SectorPromptWidgetState extends State<Layer1SectorPromptWidget> {
  double _enjoyment = 0.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modality = widget.task.rendererModality;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_modalityIcon(modality), color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.task.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text('Layer 1 · ${_modalityLabel(modality)}'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (modality == 'text' && widget.constraints.allowText)
              _TextModalityView(task: widget.task)
            else if (modality == 'video' && widget.constraints.allowVideo)
              _VideoModalityView(task: widget.task)
            else if (modality == 'haptic' && widget.constraints.allowHaptics)
              _HapticModalityView(task: widget.task)
            else
              _PictureModalityView(task: widget.task, constraints: widget.constraints),
            const SizedBox(height: 20),
            Text(
              widget.task.minEnjoymentLabel,
              style: theme.textTheme.labelMedium,
            ),
            Slider(
              value: _enjoyment,
              onChanged: (value) {
                setState(() => _enjoyment = value);
                if (widget.constraints.allowHaptics) {
                  HapticFeedback.selectionClick();
                }
                widget.onEnjoymentSelected?.call(value);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.task.maxEnjoymentLabel,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _modalityIcon(String modality) {
    return switch (modality) {
      'text' => Icons.text_fields_rounded,
      'video' => Icons.play_circle_outline_rounded,
      'haptic' => Icons.vibration_rounded,
      _ => Icons.image_outlined,
    };
  }

  String _modalityLabel(String modality) {
    return switch (modality) {
      'text' => 'Text prompt',
      'video' => 'Silent video',
      'haptic' => 'Touch & glow',
      _ => 'Picture card',
    };
  }
}

class _PictureModalityView extends StatelessWidget {
  const _PictureModalityView({required this.task, required this.constraints});

  final Layer1SectorTask task;
  final ModalityConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction_rounded, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(task.activityLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  task.pictureDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        if (constraints.useSimpleConcreteDrawings) ...[
          const SizedBox(height: 8),
          Text(
            'Simple concrete drawing — no faces, no clutter.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
        if (!constraints.allowText) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.visibility_rounded, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  task.presentMomentPrompt,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TextModalityView extends StatelessWidget {
  const _TextModalityView({required this.task});

  final Layer1SectorTask task;

  @override
  Widget build(BuildContext context) {
    return Text(
      task.presentMomentPrompt,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _VideoModalityView extends StatelessWidget {
  const _VideoModalityView({required this.task});

  final Layer1SectorTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(task.activityLabel, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.videoDescription ?? 'Silent activity loop'),
          const SizedBox(height: 8),
          Text(task.presentMomentPrompt),
        ],
      ),
    );
  }
}

class _HapticModalityView extends StatelessWidget {
  const _HapticModalityView({required this.task});

  final Layer1SectorTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: task.presentMomentPrompt,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.touch_app_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              task.activityLabel,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(task.presentMomentPrompt, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Multi-layer RIASEC strength funnel with ISAA modality routing.
class StrengthFunnelScreen extends ConsumerStatefulWidget {
  const StrengthFunnelScreen({
    super.key,
    required this.onFunnelPhaseComplete,
  });

  final VoidCallback onFunnelPhaseComplete;

  @override
  ConsumerState<StrengthFunnelScreen> createState() => _StrengthFunnelScreenState();
}

class _StrengthFunnelScreenState extends ConsumerState<StrengthFunnelScreen> {
  double _enjoyment = 0.5;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        ref.read(strengthFunnelControllerProvider.notifier).initializeFunnel();
      }
    });
  }

  Future<void> _submitAndAdvance() async {
    final controller = ref.read(strengthFunnelControllerProvider.notifier);
    final funnelDone = await controller.submitCurrentScore(_enjoyment);
    if (!mounted) return;

    if (funnelDone) {
      widget.onFunnelPhaseComplete();
      return;
    }

    setState(() => _enjoyment = 0.5);
  }

  Future<void> _continueToNextLayer() async {
    await ref.read(strengthFunnelControllerProvider.notifier).startNextLayer();
    if (mounted) setState(() => _enjoyment = 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final funnel = ref.watch(strengthFunnelControllerProvider);
    final task = funnel.currentTask;
    final constraints = funnel.constraints;
    final layer = funnel.layerNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDeepDiveLayer(layer)
              ? 'Deep dive · Layer $layer'
              : 'Layer $layer · Strength Exploration',
        ),
        bottom: funnel.totalTasks > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(value: funnel.progress.clamp(0.0, 1.0)),
              )
            : null,
      ),
      body: funnel.loading && task == null
          ? const Center(child: CircularProgressIndicator())
          : funnel.error != null && task == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(funnel.error!, textAlign: TextAlign.center),
                  ),
                )
              : funnel.layerComplete && funnel.canStartNextLayer
                  ? _LayerCompleteView(
                      completedLayer: layer,
                      advancingCount: funnel.advancingSectorIds?.length ??
                          sectorsAdvancingDisplayCount(layer),
                      onContinue: _continueToNextLayer,
                    )
                  : funnel.layerComplete && funnel.readyForAssessment
                      ? _FunnelPhaseCompleteView(
                          finalistIds: funnel.finalistSectorIds,
                          onContinue: widget.onFunnelPhaseComplete,
                        )
                      : task == null || constraints == null
                          ? const Center(child: Text('No sectors available.'))
                          : ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                Text(
                                  'Layer $layer · ${sectorsAtLayerStart(layer)} play themes · '
                                  'sector ${funnel.scoredCount + 1} of ${funnel.totalTasks}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'How much fun is this activity right now?',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                _RoutingDebugCard(
                                  constraints: constraints,
                                  modality: task.rendererModality,
                                ),
                                const SizedBox(height: 16),
                                Layer1SectorPromptWidget(
                                  task: task,
                                  constraints: constraints,
                                  onEnjoymentSelected: (value) => _enjoyment = value,
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: funnel.loading ? null : _submitAndAdvance,
                                  child: Text(
                                    funnel.scoredCount + 1 >= funnel.totalTasks
                                        ? 'Finish Layer $layer'
                                        : 'Next sector',
                                  ),
                                ),
                              ],
                            ),
    );
  }
}

/// Back-compat alias — router and tests may still reference this name.
typedef Layer1FunnelScreen = StrengthFunnelScreen;

class _LayerCompleteView extends StatelessWidget {
  const _LayerCompleteView({
    required this.completedLayer,
    required this.advancingCount,
    required this.onContinue,
  });

  final int completedLayer;
  final int advancingCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Layer $completedLayer complete',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isEliminationLayer(completedLayer)
                ? 'Top $advancingCount play themes carry forward to Layer ${completedLayer + 1}.'
                : 'Layer ${completedLayer + 1} goes deeper into what feels most fun right now.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onContinue,
            child: Text('Continue to Layer ${completedLayer + 1}'),
          ),
        ],
      ),
    );
  }
}

class _FunnelPhaseCompleteView extends StatelessWidget {
  const _FunnelPhaseCompleteView({
    required this.finalistIds,
    required this.onContinue,
  });

  final List<String> finalistIds;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = finalistIds
        .map((id) => sectorById(id)?.displayName ?? id)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'All 10 layers complete',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Top ${labels.length} play themes are your deepest sparks. '
            'Next up: strength activities.',
            textAlign: TextAlign.center,
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...labels.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Chip(label: Text(name)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: onContinue, child: const Text('Continue to activities')),
        ],
      ),
    );
  }
}

class _RoutingDebugCard extends StatelessWidget {
  const _RoutingDebugCard({required this.constraints, required this.modality});

  final ModalityConstraints constraints;
  final String modality;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ISAA routing decision', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Primary modality: $modality'),
            Text('requiresVisualItems: ${constraints.requiresVisualItems}'),
            Text('allowText: ${constraints.allowText}'),
            Text('allowVideo: ${constraints.allowVideo}'),
            Text('allowHaptics: ${constraints.allowHaptics}'),
            Text('disableAnimations: ${constraints.disableAnimations}'),
          ],
        ),
      ),
    );
  }
}
