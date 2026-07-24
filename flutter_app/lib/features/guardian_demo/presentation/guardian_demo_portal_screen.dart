import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exploration/models/exploration_models.dart';
import '../models/guardian_demo_portal_models.dart';
import '../providers/guardian_demo_portal_provider.dart';

/// Adult-only, read-only view of a paired synthetic demo session.
///
/// It intentionally reports session activity rather than a diagnostic,
/// prediction, or capability label. The child-facing play canvas stays
/// word-free and never shows these metrics.
class GuardianDemoPortalScreen extends ConsumerStatefulWidget {
  const GuardianDemoPortalScreen({
    super.key,
    this.initialSessionCode,
  });

  final String? initialSessionCode;

  @override
  ConsumerState<GuardianDemoPortalScreen> createState() =>
      _GuardianDemoPortalScreenState();
}

class _GuardianDemoPortalScreenState
    extends ConsumerState<GuardianDemoPortalScreen> {
  late final TextEditingController _sessionCodeController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _sessionCodeController = TextEditingController(
      text: widget.initialSessionCode ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.initialSessionCode?.trim() ?? '';
      if (initial.isNotEmpty) {
        ref.read(guardianDemoPortalProvider.notifier).connect(initial);
      }
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => ref.read(guardianDemoPortalProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _sessionCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guardianDemoPortalProvider);
    final controller = ref.read(guardianDemoPortalProvider.notifier);
    final snapshot = state.snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian activity view'),
        actions: [
          IconButton(
            tooltip: 'Refresh now',
            onPressed: state.isLoading ? null : controller.refresh,
            icon: state.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _DemoOnlyNotice(),
                const SizedBox(height: 18),
                _PairingCard(
                  controller: _sessionCodeController,
                  isLoading: state.isLoading,
                  onConnect: () =>
                      controller.connect(_sessionCodeController.text),
                  onChanged: controller.setSessionCode,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 14),
                  _ErrorCard(message: state.error!),
                ],
                if (snapshot != null) ...[
                  const SizedBox(height: 20),
                  _SessionOverview(
                    snapshot: snapshot,
                    lastSyncedAt: state.lastSyncedAt,
                  ),
                  const SizedBox(height: 20),
                  _ActivityRecord(events: snapshot.completedEvents),
                ] else if (!state.isLoading) ...[
                  const SizedBox(height: 22),
                  const _EmptyPortalState(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoOnlyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Synthetic demo activity only. This view is a live presentation of interaction records, not a diagnosis, prediction, or clinical report.',
                ),
              ),
            ],
          ),
        ),
      );
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({
    required this.controller,
    required this.isLoading,
    required this.onConnect,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onConnect;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect a child-device session',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'On the activity device, tap the guardian icon and copy its temporary session code here. The view refreshes every three seconds.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      onChanged: onChanged,
                      onSubmitted: (_) => onConnect(),
                      decoration: const InputDecoration(
                        labelText: 'Temporary demo session code',
                        hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                        prefixIcon: Icon(Icons.link_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onConnect,
                    icon: const Icon(Icons.sync),
                    label: const Text('Connect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyPortalState extends StatelessWidget {
  const _EmptyPortalState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
        child: Column(
          children: [
            Icon(
              Icons.phonelink_ring_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Waiting for a demo session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Once connected, this phone can remain with the guardian while the other phone runs the word-free activities.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _SessionOverview extends StatelessWidget {
  const _SessionOverview({
    required this.snapshot,
    required this.lastSyncedAt,
  });

  final GuardianDemoSessionSnapshot snapshot;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      snapshot.isComplete ? 'Session complete' : 'Live session',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _StatusPill(complete: snapshot.isComplete),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SummaryMetric(
                    icon: Icons.layers_outlined,
                    label: 'Current layer',
                    value: '${snapshot.currentLayer} / 10',
                  ),
                  _SummaryMetric(
                    icon: Icons.task_alt_outlined,
                    label: 'Activities recorded',
                    value: '${snapshot.completedTaskCount}',
                  ),
                  _SummaryMetric(
                    icon: Icons.schedule_outlined,
                    label: 'Expires',
                    value: _timeUntil(snapshot.expiresAt),
                  ),
                ],
              ),
              if (snapshot.activeSectors.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Activities in the current layer',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: snapshot.activeSectors
                      .map((sector) => Chip(label: Text(_sectorLabel(sector))))
                      .toList(growable: false),
                ),
              ],
              if (snapshot.isComplete) ...[
                const SizedBox(height: 18),
                _FinalTransition(snapshot: snapshot),
              ] else if (snapshot.currentLayer == 10) ...[
                const SizedBox(height: 18),
                const _LayerTenInProgress(),
              ],
              const SizedBox(height: 14),
              Text(
                lastSyncedAt == null
                    ? 'Connected'
                    : 'Synced ${_clock(lastSyncedAt!)} • refreshes every 3 seconds',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final foreground = complete
        ? Theme.of(context).colorScheme.onTertiaryContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;
    return DecoratedBox(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(50)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          complete ? 'Complete' : 'Live',
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 156,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 8),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _FinalTransition extends StatelessWidget {
  const _FinalTransition({required this.snapshot});

  final GuardianDemoSessionSnapshot snapshot;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layer 10 showcase outcome',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                snapshot.finalActivitySector == null
                    ? 'Final activity path is being prepared.'
                    : 'Final activity path: ${_sectorLabel(snapshot.finalActivitySector!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                snapshot.finalActivitySandbox == null
                    ? 'The final workshop route is not available yet.'
                    : 'Demo transition: ${snapshot.finalActivitySandbox!.label}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      );
}

class _LayerTenInProgress extends StatelessWidget {
  const _LayerTenInProgress();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Layer 10 is the final showcase activity. Its activity path and workshop transition appear here after its response is recorded.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
}

class _ActivityRecord extends StatelessWidget {
  const _ActivityRecord({required this.events});

  final List<GuardianDemoActivity> events;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interaction record',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Each card is a completed activity. Results are factual session records; they do not label the child.',
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No activity has been completed yet.'),
              ),
            )
          else
            ...events.reversed.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActivityCard(event: event),
                )),
        ],
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.event});

  final GuardianDemoActivity event;

  @override
  Widget build(BuildContext context) {
    final response = event.responseStatus;
    final responseColor = switch (response) {
      GuardianDemoResponseStatus.matched =>
        Theme.of(context).colorScheme.tertiary,
      GuardianDemoResponseStatus.nonMatching =>
        Theme.of(context).colorScheme.secondary,
      GuardianDemoResponseStatus.noResponse =>
        Theme.of(context).colorScheme.outline,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Layer ${event.layer} • ${event.sectorLabel}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(event.categoryLabel,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: responseColor.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      response.label,
                      style: TextStyle(
                          color: responseColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailPill(label: 'Time', value: _duration(event.latencyMs)),
                _DetailPill(
                    label: 'Selections', value: '${event.interactions}'),
                _DetailPill(label: 'Changes', value: '${event.misclicks}'),
                _DetailPill(
                    label: 'Recovered', value: '${event.recoveredErrors}'),
                _DetailPill(
                    label: 'Support', value: _supportLabel(event.supportLevel)),
              ],
            ),
            const SizedBox(height: 16),
            _ActivitySignals(event: event),
            const SizedBox(height: 10),
            Text(
              'Recorded ${_clock(event.completedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('$label: $value',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
}

class _ActivitySignals extends StatelessWidget {
  const _ActivitySignals({required this.event});

  final GuardianDemoActivity event;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _SignalRow(label: 'Accuracy', value: event.accuracy),
          _SignalRow(label: 'Recovery', value: event.recovery),
          _SignalRow(label: 'Engagement', value: event.engagement),
          _SignalRow(label: 'Speed', value: event.speed),
          const SizedBox(height: 4),
          _SignalRow(
            label: 'Session composite (40 / 30 / 20 / 10)',
            value: event.isolationScore,
            emphasized: true,
          ),
        ],
      );
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 196,
            child: Text(
              label,
              style: emphasized
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: .14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.end,
              style: emphasized
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

String _sectorLabel(String sector) {
  final mechanic = PlayMechanic.values.cast<PlayMechanic?>().firstWhere(
        (value) => value?.name == sector,
        orElse: () => null,
      );
  if (mechanic != null) return mechanic.label;
  return sector
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .replaceAll('_', ' ');
}

String _duration(int milliseconds) {
  final seconds = milliseconds / 1000;
  return seconds < 60
      ? '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s'
      : '${(seconds / 60).floor()}m ${(seconds % 60).round()}s';
}

String _supportLabel(int level) => switch (level) {
      0 => 'None',
      1 => 'Gentle cue',
      2 => 'Simplified',
      _ => 'Supported',
    };

String _clock(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

String _timeUntil(DateTime expiresAt) {
  final remaining = expiresAt.difference(DateTime.now());
  if (remaining.isNegative) return 'Expired';
  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
}
