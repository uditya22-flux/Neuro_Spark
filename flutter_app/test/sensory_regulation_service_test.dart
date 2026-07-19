import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/child/application/sensory_regulation_service.dart';
import 'package:mindbridge_app/features/child/domain/child_experience.dart';

void main() {
  test('cooldown can be opened and resumed without changing sensory settings', () {
    final service = SensoryRegulationService();
    const configuration = SensoryConfiguration(
      reduceMotion: true,
      soundEnabled: false,
      hapticsEnabled: false,
      highContrast: true,
      themeName: 'night',
    );

    service.apply(configuration);
    service.openCooldown();

    expect(service.state.isCooldownActive, isTrue);
    expect(service.state.configuration, same(configuration));

    service.resume();

    expect(service.state.isCooldownActive, isFalse);
    expect(service.state.cooldownReason, isNull);
    expect(service.state.configuration, same(configuration));
  });
}
