import '../../../core/config/demo_config.dart';
import '../../../models/intake_models.dart';
import '../../../providers/game_environment_provider.dart';
import '../../../services/environment_compiler_service.dart';
import 'demo_intake_prefills.dart';

/// Synthetic child profile for hospital demos — moderate ISAA, picture-first routing.
IntakeSessionBundle buildDemoIntakeBundle() {
  const compiler = EnvironmentCompilerService();
  const clinical = DemoIntakePrefills.clinical;
  const parent = DemoIntakePrefills.parent;
  final config = compiler.compileEnvironment(clinical, parent);

  return IntakeSessionBundle(
    clinical: clinical,
    parent: parent,
    config: config,
    childId: 'demo_child_local',
  );
}
