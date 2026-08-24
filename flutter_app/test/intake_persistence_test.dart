import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/providers/game_environment_provider.dart';
import 'package:mindbridge_app/services/environment_compiler_service.dart';
import 'package:mindbridge_app/services/intake_persistence_service.dart';

void main() {
  group('IntakePersistenceService encoding', () {
    test('bundle JSON round-trip preserves clinical, parent, and config fields', () {
      const compiler = EnvironmentCompilerService();
      const isaa = ISAAClinicalProfile(
        sensoryAspects: 5,
        speechCommunication: 4,
        cognitiveComponent: 3,
      );
      const parent = ParentQualitativeProfile(
        childName: 'Riya',
        childAge: 9,
        hyperFixationCategory: HyperFixationCategory.spaceAstronomy,
        soundTriggers: ['Sudden loud chime'],
        visualTriggers: ['Rapid flashing'],
        tactilePreference: TactilePreference.prefersHaptics,
      );
      final config = compiler.compileEnvironment(isaa, parent);
      final bundle = IntakeSessionBundle(
        clinical: isaa,
        parent: parent,
        config: config,
        childId: 'child-123',
        persistedAt: DateTime.utc(2026, 8, 24, 12),
      );

      final encoded = encodePersistedBundleJson(bundle);
      final restored = decodePersistedBundleJson(encoded);

      expect(restored.childId, 'child-123');
      expect(restored.parent.childName, 'Riya');
      expect(restored.config.audioMode, AudioMode.completelyMuted);
      expect(restored.config.instructionStyle, InstructionStyle.pureVisualGlowHints);
      expect(restored.clinical.sensoryAspects, 5);
    });
  });
}
