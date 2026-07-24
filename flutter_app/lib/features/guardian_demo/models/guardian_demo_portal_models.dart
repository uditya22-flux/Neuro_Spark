import '../../exploration/models/exploration_models.dart';

/// A guardian-facing view of one short-lived, synthetic showcase session.
///
/// This contains only the fixed, aggregate interaction record produced by the
/// fictional demo. It deliberately has no child identifier, guardian input,
/// task payload, image prompt, or free-text answer.
class GuardianDemoSessionSnapshot {
  const GuardianDemoSessionSnapshot({
    required this.sessionId,
    required this.status,
    required this.currentLayer,
    required this.activeSectors,
    required this.completedTaskCount,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.completedEvents,
    this.finalSector,
    this.finalSandbox,
  });

  final String sessionId;
  final GuardianDemoSessionStatus status;
  final int currentLayer;
  final List<String> activeSectors;
  final int completedTaskCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GuardianDemoActivity> completedEvents;
  final String? finalSector;
  final GuardianDemoSandbox? finalSandbox;

  bool get isComplete => status == GuardianDemoSessionStatus.complete;
  bool get isInProgress => status == GuardianDemoSessionStatus.inProgress;

  /// Supports a short-lived demo session created by an earlier function
  /// revision: if its completion row exists but final fields were not written,
  /// the final Layer 10 activity still gives the guardian portal a factual
  /// showcase outcome to display.
  String? get finalActivitySector {
    if (finalSector != null && finalSector!.isNotEmpty) return finalSector;
    for (final activity in completedEvents.reversed) {
      if (activity.layer == 10) return activity.sectorId;
    }
    return null;
  }

  GuardianDemoSandbox? get finalActivitySandbox =>
      finalSandbox ?? GuardianDemoSandbox.fromSector(finalActivitySector);

  factory GuardianDemoSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    final rawEvents = json['completed_events'];
    if (rawSession is! Map || rawEvents is! List) {
      throw const FormatException('The guardian snapshot is incomplete.');
    }
    final session = Map<String, dynamic>.from(rawSession);
    final id = session['session_id'];
    final rawStatus = session['status'];
    final layer =
        _boundedInt(session['current_layer'], minimum: 1, maximum: 10);
    final expiresAt = _date(session['expires_at']);
    final createdAt = _date(session['created_at']);
    final updatedAt = _date(session['updated_at']);
    if (id is! String ||
        id.isEmpty ||
        rawStatus is! String ||
        layer == null ||
        expiresAt == null ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException(
          'The guardian snapshot has invalid session data.');
    }

    return GuardianDemoSessionSnapshot(
      sessionId: id,
      status: GuardianDemoSessionStatus.fromWire(rawStatus),
      currentLayer: layer,
      activeSectors: _strings(session['active_sectors']),
      completedTaskCount: _boundedInt(
            session['completed_task_count'],
            minimum: 0,
            maximum: 100,
          ) ??
          0,
      expiresAt: expiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      finalSector: session['final_sector'] is String
          ? session['final_sector'] as String
          : null,
      finalSandbox:
          GuardianDemoSandbox.fromWireOrNull(session['final_sandbox']),
      completedEvents: rawEvents
          .whereType<Map>()
          .map((event) => GuardianDemoActivity.fromJson(
                Map<String, dynamic>.from(event),
              ))
          .toList(growable: false),
    );
  }
}

enum GuardianDemoSessionStatus {
  inProgress,
  complete;

  static GuardianDemoSessionStatus fromWire(String value) => switch (value) {
        'complete' => GuardianDemoSessionStatus.complete,
        _ => GuardianDemoSessionStatus.inProgress,
      };
}

enum GuardianDemoSandbox {
  calendar,
  constellation,
  exploring;

  static GuardianDemoSandbox? fromWireOrNull(Object? value) => switch (value) {
        'calendar' => GuardianDemoSandbox.calendar,
        'constellation' => GuardianDemoSandbox.constellation,
        'exploring' => GuardianDemoSandbox.exploring,
        _ => null,
      };

  static GuardianDemoSandbox? fromSector(String? sector) {
    if (sector == null) return null;
    if (const {
      'chronologicalSequencing',
      'narrativeEventOrdering',
      'causeAndEffectChains',
      'proceduralSequencing',
    }.contains(sector)) {
      return GuardianDemoSandbox.calendar;
    }
    if (const {
      'mentalRotation',
      'pointCloudAnomalyDetection',
      'mapRouteNavigation',
      'visualSpatialConstruction',
    }.contains(sector)) {
      return GuardianDemoSandbox.constellation;
    }
    return GuardianDemoSandbox.exploring;
  }

  String get label => switch (this) {
        GuardianDemoSandbox.calendar => 'Timeline workshop',
        GuardianDemoSandbox.constellation => 'Constellation workshop',
        GuardianDemoSandbox.exploring => 'Exploration continues',
      };
}

/// One completed, word-free play activity shown only in the adult demo view.
class GuardianDemoActivity {
  const GuardianDemoActivity({
    required this.layer,
    required this.sectorId,
    required this.matched,
    required this.skipped,
    required this.latencyMs,
    required this.misclicks,
    required this.recoveredErrors,
    required this.interactions,
    required this.supportLevel,
    required this.accuracy,
    required this.recovery,
    required this.engagement,
    required this.speed,
    required this.isolationScore,
    required this.completedAt,
  });

  final int layer;
  final String sectorId;
  final bool matched;
  final bool skipped;
  final int latencyMs;
  final int misclicks;
  final int recoveredErrors;
  final int interactions;
  final int supportLevel;
  final double accuracy;
  final double recovery;
  final double engagement;
  final double speed;
  final double isolationScore;
  final DateTime completedAt;

  PlayMechanic? get mechanic =>
      PlayMechanic.values.cast<PlayMechanic?>().firstWhere(
            (value) => value?.name == sectorId,
            orElse: () => null,
          );

  String get sectorLabel => mechanic?.label ?? _humanize(sectorId);
  String get categoryLabel => mechanic?.group.label ?? 'word-free activity';

  GuardianDemoResponseStatus get responseStatus {
    if (skipped) return GuardianDemoResponseStatus.noResponse;
    return matched
        ? GuardianDemoResponseStatus.matched
        : GuardianDemoResponseStatus.nonMatching;
  }

  factory GuardianDemoActivity.fromJson(Map<String, dynamic> json) {
    final layer = _boundedInt(json['layer'], minimum: 1, maximum: 10);
    final sector = json['sector'];
    final completedAt = _date(json['created_at']);
    if (layer == null ||
        sector is! String ||
        sector.isEmpty ||
        completedAt == null) {
      throw const FormatException('The guardian activity record is invalid.');
    }
    return GuardianDemoActivity(
      layer: layer,
      sectorId: sector,
      matched: json['correct'] == true,
      skipped: json['skipped'] == true,
      latencyMs:
          _boundedInt(json['latency_ms'], minimum: 0, maximum: 600000) ?? 0,
      misclicks: _boundedInt(json['misclicks'], minimum: 0, maximum: 50) ?? 0,
      recoveredErrors:
          _boundedInt(json['recovered_errors'], minimum: 0, maximum: 50) ?? 0,
      interactions:
          _boundedInt(json['interactions'], minimum: 0, maximum: 100) ?? 0,
      supportLevel:
          _boundedInt(json['support_level'], minimum: 0, maximum: 3) ?? 0,
      accuracy: _unit(json['accuracy']),
      recovery: _unit(json['recovery']),
      engagement: _unit(json['engagement']),
      speed: _unit(json['speed']),
      isolationScore: _unit(json['isolation_score']),
      completedAt: completedAt,
    );
  }
}

enum GuardianDemoResponseStatus {
  matched,
  nonMatching,
  noResponse;

  String get label => switch (this) {
        GuardianDemoResponseStatus.matched => 'Matched response',
        GuardianDemoResponseStatus.nonMatching => 'Non-matching response',
        GuardianDemoResponseStatus.noResponse => 'No response — moved on',
      };
}

int? _boundedInt(Object? value, {required int minimum, required int maximum}) {
  if (value is! num || !value.isFinite) return null;
  final integer = value.toInt();
  if (integer < minimum || integer > maximum) return null;
  return integer;
}

double _unit(Object? value) {
  if (value is! num || !value.isFinite) return 0;
  return value.clamp(0, 1).toDouble();
}

DateTime? _date(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().take(30).toList(growable: false);
}

String _humanize(String value) => value
    .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
    .replaceAll('_', ' ');
