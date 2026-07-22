import 'dart:math';

class TimeBlock {
  final int id;
  final String label;
  final DateTime timestamp;
  final int originalIndex;

  const TimeBlock({
    required this.id,
    required this.label,
    required this.timestamp,
    required this.originalIndex,
  });
}

class Point3D {
  final int id;
  final double x;
  final double y;
  final double z;
  final bool isAnomaly;

  const Point3D({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
    required this.isAnomaly,
  });
}

class ProceduralPuzzleGenerator {
  /// Track 1: Generates chronologically ordered time blocks and scrambles positions boundedly.
  static List<TimeBlock> generateTimelinePuzzle({
    int count = 6,
    int scrambleCount = 3,
    int difficultyTier = 1,
    int? seed,
  }) {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final baseTime = DateTime(2026, 7, 21, 10, 0);

    // Duration step shrinks as difficulty rises (Days -> Hours -> Minutes -> Seconds)
    Duration stepDuration;
    switch (difficultyTier) {
      case 1:
        stepDuration = const Duration(days: 1);
        break;
      case 2:
        stepDuration = const Duration(hours: 4);
        break;
      case 3:
        stepDuration = const Duration(minutes: 30);
        break;
      case 4:
      default:
        stepDuration = const Duration(seconds: 45);
        break;
    }

    final orderedBlocks = List.generate(count, (i) {
      final dt = baseTime.add(stepDuration * i);
      String label;
      if (difficultyTier == 1) {
        label = 'Day ${i + 1} - ${dt.month}/${dt.day}';
      } else if (difficultyTier == 2) {
        label = '${dt.hour.toString().padLeft(2, '0')}:00 Window';
      } else if (difficultyTier == 3) {
        label = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} Phase';
      } else {
        label = '${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} Marker';
      }

      return TimeBlock(
        id: i,
        label: label,
        timestamp: dt,
        originalIndex: i,
      );
    });

    // Scramble bounded positions
    final scrambled = List<TimeBlock>.from(orderedBlocks);
    for (int k = 0; k < scrambleCount && k < count - 1; k++) {
      final swapIdx = rand.nextInt(count);
      final temp = scrambled[k];
      scrambled[k] = scrambled[swapIdx];
      scrambled[swapIdx] = temp;
    }

    return scrambled;
  }

  /// Track 2: Generates 3D point cluster for spatial rotation and anomaly detection.
  static List<Point3D> generateConstellationPuzzle({
    int pointCount = 20,
    int anomalyCount = 3,
    int difficultyTier = 1,
    int? seed,
  }) {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final points = <Point3D>[];

    final double radius = 100.0;
    // Anomaly deviation shrinks as difficulty rises (subtler anomalies)
    final double anomalyDev = max(15.0, 40.0 - (difficultyTier * 6.0));

    for (int i = 0; i < pointCount; i++) {
      final bool isAnomaly = i < anomalyCount;

      // Spherical coordinate generation
      final theta = rand.nextDouble() * 2 * pi;
      final phi = acos(2 * rand.nextDouble() - 1);
      final currentRadius = isAnomaly ? (radius + (rand.nextBool() ? anomalyDev : -anomalyDev)) : radius;

      final x = currentRadius * sin(phi) * cos(theta);
      final y = currentRadius * sin(phi) * sin(theta);
      final z = currentRadius * cos(phi);

      points.add(Point3D(
        id: i,
        x: x,
        y: y,
        z: z,
        isAnomaly: isAnomaly,
      ));
    }

    points.shuffle(rand);
    return points;
  }
}
