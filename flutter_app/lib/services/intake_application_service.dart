import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_environment_provider.dart';
import '../providers/intake_flow_provider.dart';
import '../features/dashboard/providers/sdui_controller.dart';
import 'environment_compiler_service.dart';
import 'intake_persistence_service.dart';
import 'intake_profile_mapper.dart';

/// Applies a completed intake session across app-wide customization surfaces.
class IntakeApplicationService {
  const IntakeApplicationService({
    required this.compiler,
    required this.mapper,
    required this.persistence,
  });

  final EnvironmentCompilerService compiler;
  final IntakeProfileMapper mapper;
  final IntakePersistenceService persistence;

  Future<IntakeSessionBundle> compileApplyAndPersist(WidgetRef ref) async {
    final intake = ref.read(intakeFlowProvider);
    final config = compiler.compileEnvironment(intake.clinical, intake.parent);
    final bundle = IntakeSessionBundle(
      clinical: intake.clinical,
      parent: intake.parent,
      config: config,
    );
    applyBundle(ref, bundle);
    await persistence.saveBundle(ref, bundle);
    return ref.read(gameEnvironmentProvider)!;
  }

  void applyBundle(WidgetRef ref, IntakeSessionBundle bundle) {
    ref.read(gameEnvironmentProvider.notifier).set(bundle);
    ref.read(sduiControllerProvider.notifier).applyGameEnvironment(
          bundle: bundle,
          profile: mapper.toNeuroProfile(
            clinical: bundle.clinical,
            parent: bundle.parent,
            config: bundle.config,
          ),
        );
  }
}

final intakeApplicationServiceProvider = Provider<IntakeApplicationService>((ref) {
  return IntakeApplicationService(
    compiler: ref.watch(environmentCompilerProvider),
    mapper: ref.watch(intakeProfileMapperProvider),
    persistence: ref.watch(intakePersistenceServiceProvider),
  );
});
