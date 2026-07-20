import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_state.dart';
import '../../dashboard/providers/sdui_controller.dart';
import '../../dashboard/models/neuro_profile.dart';
import '../../../core/api/supabase_api.dart';

class OnboardingController extends StateNotifier<OnboardingState> {
  final Ref ref;

  OnboardingController(this.ref) : super(const OnboardingState());

  void updateRealName(String val) => state = state.copyWith(realName: val);
  void updateAge(int val) => state = state.copyWith(age: val);
  void updateFatherName(String val) => state = state.copyWith(fatherName: val);
  void updateMotherName(String val) => state = state.copyWith(motherName: val);
  void updateSiblingNames(String val) => state = state.copyWith(siblingNames: val);

  void updateFavoriteColor(String val) => state = state.copyWith(favoriteColor: val);
  void updateFavoritePlace(String val) => state = state.copyWith(favoritePlace: val);
  void updateFavoriteObject(String val) => state = state.copyWith(favoriteObject: val);

  void updateAuditoryReaction(String val) => state = state.copyWith(auditoryReaction: val);
  void updateVisualDistress(String val) => state = state.copyWith(visualDistress: val);
  void updateEffectiveRegulationMethod(String val) => state = state.copyWith(effectiveRegulationMethod: val);

  void updateTransitionDifficultyScore(double val) => state = state.copyWith(transitionDifficultyScore: val);
  void updateUnexpectedChangeDistress(bool val) => state = state.copyWith(unexpectedChangeDistress: val);
  void updateInstructionProcessingPreference(String val) => state = state.copyWith(instructionProcessingPreference: val);

  void updateNaturalAbilities(List<String> val) => state = state.copyWith(naturalAbilities: val);
  void updatePrimaryHyperFixation(String val) => state = state.copyWith(primaryHyperFixation: val);
  void updateProblemSolvingApproach(String val) => state = state.copyWith(problemSolvingApproach: val);

  void updateStressCommunicationStyle(String val) => state = state.copyWith(stressCommunicationStyle: val);
  void updateEmotionalInteroceptionLevel(String val) => state = state.copyWith(emotionalInteroceptionLevel: val);

  Future<bool> completeSetup() async {
    final payload = state.toJson();
    final response = await ref.read(supabaseApiProvider).submitIntake(payload);
    if (response['status'] == 'success' || response['local'] == true || response['fallback'] == true) {
      final profile = NeuroProfile.fromJson(payload);
      ref.read(sduiControllerProvider.notifier).loadCustomProfile(profile);
      return true;
    }
    return false;
  }
}

final onboardingControllerProvider = StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});
