import '../models/exploration_models.dart';

/// Converts locally-entered fictional demo text into one of the six scene
/// families understood by the anonymous demo Edge Function. The source text
/// never leaves Flutter. A stable fallback ensures every input is accepted,
/// even if it has no familiar keywords.
class SyntheticDemoSceneMapper {
  static SyntheticDemoWorld fromIntakeText({
    required String theme,
    required String favouriteObjects,
    required String familiarScenes,
  }) {
    final source = '$theme $favouriteObjects $familiarScenes'.toLowerCase().trim();
    if (source.isEmpty) return SyntheticDemoWorld.vehicles;

    final scores = <SyntheticDemoWorld, int>{
      SyntheticDemoWorld.vehicles: _score(source, const [
        'car', 'bus', 'truck', 'vehicle', 'road', 'wheel', 'garage', 'traffic', 'racing', 'bike', 'van',
      ]),
      SyntheticDemoWorld.rail: _score(source, const [
        'train', 'rail', 'track', 'station', 'locomotive', 'metro', 'subway', 'tram', 'platform',
      ]),
      SyntheticDemoWorld.space: _score(source, const [
        'space', 'planet', 'star', 'moon', 'rocket', 'solar', 'galaxy', 'astronaut', 'constellation',
      ]),
      SyntheticDemoWorld.pipes: _score(source, const [
        'pipe', 'plumb', 'tap', 'valve', 'drain', 'water', 'tool', 'repair', 'wrench', 'machine', 'gear',
      ]),
      SyntheticDemoWorld.animals: _score(source, const [
        'animal', 'dinosaur', 'pet', 'dog', 'cat', 'bird', 'fish', 'insect', 'zoo', 'farm', 'turtle',
      ]),
      SyntheticDemoWorld.garden: _score(source, const [
        'garden', 'tree', 'flower', 'plant', 'forest', 'leaf', 'nature', 'park', 'seed', 'path', 'farm',
      ]),
    };
    final highest = scores.values.reduce((left, right) => left > right ? left : right);
    if (highest == 0) return _stableFallback(source);
    return scores.entries.firstWhere((entry) => entry.value == highest).key;
  }

  static int _score(String source, List<String> keywords) => keywords.fold(
        0,
        (score, keyword) => score + _occurrences(source, keyword),
      );

  static int _occurrences(String source, String keyword) {
    var count = 0;
    var start = 0;
    while (true) {
      final index = source.indexOf(keyword, start);
      if (index < 0) return count;
      count += 1;
      start = index + keyword.length;
    }
  }

  static SyntheticDemoWorld _stableFallback(String source) {
    var hash = 2166136261;
    for (final unit in source.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return SyntheticDemoWorld.values[hash % SyntheticDemoWorld.values.length];
  }
}
