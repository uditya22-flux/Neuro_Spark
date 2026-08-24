import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/models/intake_models.dart';
import 'package:mindbridge_app/services/environment_compiler_service.dart';
import 'package:mindbridge_app/services/intake_profile_mapper.dart';

void main() {
  group('IntakeProfileMapper', () {
    const mapper = IntakeProfileMapper();
    const compiler = EnvironmentCompilerService();

    test('maps high sensory intake to highly_sensitive auditory profile', () {
      const isaa = ISAAClinicalProfile(sensoryAspects: 5, speechCommunication: 2);
      const parent = ParentQualitativeProfile(
        childName: 'Sam',
        childAge: 9,
        soundTriggers: ['Sudden loud chime'],
      );
      final config = compiler.compileEnvironment(isaa, parent);
      final profile = mapper.toNeuroProfile(clinical: isaa, parent: parent, config: config);

      expect(profile.sensoryProfile.auditoryReaction, 'highly_sensitive');
      expect(profile.sensoryProfile.visualDistress, 'high');
      expect(profile.userProfile.name, 'Sam');
    });

    test('maps wordless instruction style to visual processing preference', () {
      const isaa = ISAAClinicalProfile(speechCommunication: 5);
      const parent = ParentQualitativeProfile(
        hyperFixationCategory: HyperFixationCategory.trainsVehicles,
      );
      final config = compiler.compileEnvironment(isaa, parent);

      expect(config.instructionStyle, InstructionStyle.pureVisualGlowHints);
      expect(
        mapper.toNeuroProfile(clinical: isaa, parent: parent, config: config)
            .routineTransitions.instructionProcessingPreference,
        'visual',
      );
    });
  });
}
