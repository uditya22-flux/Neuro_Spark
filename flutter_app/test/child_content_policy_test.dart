import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/core/safety/child_content_policy.dart';
import 'package:mindbridge_app/features/child/domain/child_experience.dart';

void main() {
  test('child copy accepts neutral encouragement and rejects restricted concepts', () {
    expect(isSafeChildCopy('Thanks for exploring the star map.'), isTrue);
    expect(isSafeChildCopy('This helps with a future job.'), isFalse);
  });

  test('child experience only packages sensory, puzzle, and celebration content', () {
    const experience = ChildExperience(
      sessionId: 'session-1',
      sensory: SensoryConfiguration(
        reduceMotion: true,
        soundEnabled: false,
        hapticsEnabled: false,
        highContrast: false,
        themeName: 'calm',
      ),
      puzzle: TimelinePuzzlePayload(
        id: 'timeline-1',
        seed: 4,
        items: <TimelineItem>[],
      ),
      celebration: ChildCelebration(message: 'Thanks for exploring.'),
    );

    expect(experience.sessionId, 'session-1');
    expect(experience.puzzle, isA<TimelinePuzzlePayload>());
    expect(isSafeChildCopy(experience.celebration.message), isTrue);
  });
}
