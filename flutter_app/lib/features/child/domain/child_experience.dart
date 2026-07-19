/// The complete child-facing contract. It deliberately cannot carry adult notes.
class ChildExperience {
  const ChildExperience({
    required this.sessionId,
    required this.sensory,
    required this.puzzle,
    required this.celebration,
  });

  final String sessionId;
  final SensoryConfiguration sensory;
  final ChildPuzzlePayload puzzle;
  final ChildCelebration celebration;

  factory ChildExperience.fromSupabase({
    required String sessionId,
    required Map<String, Object?> payload,
  }) {
    final sensory = Map<String, Object?>.from(payload['sensory'] as Map? ?? const <String, Object?>{});
    final puzzle = Map<String, Object?>.from(payload['puzzle'] as Map? ?? const <String, Object?>{});
    final celebration = Map<String, Object?>.from(payload['celebration'] as Map? ?? const <String, Object?>{});
    return ChildExperience(
      sessionId: sessionId,
      sensory: SensoryConfiguration(
        reduceMotion: sensory['reduceMotion'] as bool? ?? false,
        soundEnabled: sensory['soundEnabled'] as bool? ?? false,
        hapticsEnabled: sensory['hapticsEnabled'] as bool? ?? false,
        highContrast: sensory['highContrast'] as bool? ?? false,
        themeName: sensory['themeName']?.toString() ?? 'calm',
      ),
      puzzle: _buildPuzzle(sessionId: sessionId, puzzle: puzzle),
      celebration: ChildCelebration(
        message: celebration['message']?.toString() ?? 'Thanks for exploring in your own way.',
      ),
    );
  }

  static ChildPuzzlePayload _buildPuzzle({
    required String sessionId,
    required Map<String, Object?> puzzle,
  }) {
    final seed = (puzzle['seed'] as num?)?.toInt() ?? 0;
    final type = puzzle['type']?.toString() ?? 'timeline';
    if (type == 'constellation') {
      final stars = (puzzle['stars'] as List? ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (entry) => ConstellationStar(
              id: entry['id']?.toString() ?? '',
              x: (entry['x'] as num?)?.toDouble() ?? 0,
              y: (entry['y'] as num?)?.toDouble() ?? 0,
              isDifferent: entry['isDifferent'] as bool? ?? false,
            ),
          )
          .toList(growable: false);
      return ConstellationPuzzlePayload(id: '$sessionId-constellation', seed: seed, stars: stars);
    }

    final items = (puzzle['items'] as List? ?? const <Object?>[])
        .whereType<Map>()
        .map(
          (entry) => TimelineItem(
            id: entry['id']?.toString() ?? '',
            label: entry['label']?.toString() ?? 'Task',
            order: (entry['order'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
    return TimelinePuzzlePayload(id: '$sessionId-timeline', seed: seed, items: items);
  }
}

class SensoryConfiguration {
  const SensoryConfiguration({
    required this.reduceMotion,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.highContrast,
    required this.themeName,
  });

  final bool reduceMotion;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool highContrast;
  final String themeName;
}

sealed class ChildPuzzlePayload {
  const ChildPuzzlePayload({required this.id, required this.seed});

  final String id;
  final int seed;
}

class TimelinePuzzlePayload extends ChildPuzzlePayload {
  const TimelinePuzzlePayload({
    required super.id,
    required super.seed,
    required this.items,
  });

  final List<TimelineItem> items;
}

class TimelineItem {
  const TimelineItem({required this.id, required this.label, required this.order});

  final String id;
  final String label;
  final int order;
}

class ConstellationPuzzlePayload extends ChildPuzzlePayload {
  const ConstellationPuzzlePayload({
    required super.id,
    required super.seed,
    required this.stars,
  });

  final List<ConstellationStar> stars;
}

class ConstellationStar {
  const ConstellationStar({
    required this.id,
    required this.x,
    required this.y,
    required this.isDifferent,
  });

  final String id;
  final double x;
  final double y;
  final bool isDifferent;
}

class ChildCelebration {
  const ChildCelebration({required this.message});

  final String message;
}
