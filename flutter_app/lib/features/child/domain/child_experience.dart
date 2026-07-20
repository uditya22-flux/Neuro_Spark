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
