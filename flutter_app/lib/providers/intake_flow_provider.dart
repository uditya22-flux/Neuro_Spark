import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/intake_models.dart';
import '../services/environment_compiler_service.dart';

class IntakeFlowState {
  const IntakeFlowState({
    this.currentStep = 0,
    this.clinical = const ISAAClinicalProfile(),
    this.parent = const ParentQualitativeProfile(),
    this.compiledConfig,
  });

  final int currentStep;
  final ISAAClinicalProfile clinical;
  final ParentQualitativeProfile parent;
  final GameEnvironmentConfig? compiledConfig;

  static const int totalSteps = 3;

  IntakeFlowState copyWith({
    int? currentStep,
    ISAAClinicalProfile? clinical,
    ParentQualitativeProfile? parent,
    GameEnvironmentConfig? compiledConfig,
  }) {
    return IntakeFlowState(
      currentStep: currentStep ?? this.currentStep,
      clinical: clinical ?? this.clinical,
      parent: parent ?? this.parent,
      compiledConfig: compiledConfig ?? this.compiledConfig,
    );
  }
}

class IntakeFlowNotifier extends StateNotifier<IntakeFlowState> {
  IntakeFlowNotifier(this._compiler) : super(const IntakeFlowState());

  final EnvironmentCompilerService _compiler;

  void updateClinical(ISAAClinicalProfile clinical) {
    state = state.copyWith(clinical: clinical);
  }

  void updateClinicalField({
    int? socialRelationship,
    int? emotionalResponsiveness,
    int? speechCommunication,
    int? behaviorPatterns,
    int? sensoryAspects,
    int? cognitiveComponent,
  }) {
    state = state.copyWith(
      clinical: state.clinical.copyWith(
        socialRelationship: socialRelationship,
        emotionalResponsiveness: emotionalResponsiveness,
        speechCommunication: speechCommunication,
        behaviorPatterns: behaviorPatterns,
        sensoryAspects: sensoryAspects,
        cognitiveComponent: cognitiveComponent,
      ),
    );
  }

  void updateParent(ParentQualitativeProfile parent) {
    state = state.copyWith(parent: parent);
  }

  GameEnvironmentConfig compilePreview() {
    final config = _compiler.compileEnvironment(state.clinical, state.parent);
    state = state.copyWith(compiledConfig: config);
    return config;
  }

  bool canAdvanceFromClinical() => true;

  bool canAdvanceFromParent() {
    final age = state.parent.childAge;
    return state.parent.childName.trim().isNotEmpty && age >= 7 && age <= 12;
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, IntakeFlowState.totalSteps - 1));
    if (step >= 2) {
      compilePreview();
    }
  }

  void nextStep() {
    final next = (state.currentStep + 1).clamp(0, IntakeFlowState.totalSteps - 1);
    goToStep(next);
  }

  void previousStep() {
    goToStep(state.currentStep - 1);
  }
}

final environmentCompilerProvider = Provider<EnvironmentCompilerService>((ref) {
  return const EnvironmentCompilerService();
});

final intakeFlowProvider = StateNotifierProvider<IntakeFlowNotifier, IntakeFlowState>((ref) {
  return IntakeFlowNotifier(ref.watch(environmentCompilerProvider));
});

final compiledEnvironmentProvider = Provider<GameEnvironmentConfig>((ref) {
  final intake = ref.watch(intakeFlowProvider);
  final compiler = ref.watch(environmentCompilerProvider);
  return compiler.compileEnvironment(intake.clinical, intake.parent);
});
