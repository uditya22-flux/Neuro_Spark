import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/prototype_mode.dart';
import '../../../core/api/supabase_api.dart';
import '../models/exploration_models.dart';

class IntakeState {
  final IntakeConfiguration? configuration;
  final List<ChildProfile> childProfiles;
  final String? selectedChildId;
  final bool isLoadingChildren;
  final bool isSaving;
  final String? error;

  const IntakeState({
    this.configuration,
    this.childProfiles = const [],
    this.selectedChildId,
    this.isLoadingChildren = false,
    this.isSaving = false,
    this.error,
  });

  IntakeState copyWith({
    IntakeConfiguration? configuration,
    bool clearConfiguration = false,
    List<ChildProfile>? childProfiles,
    String? selectedChildId,
    bool clearSelectedChild = false,
    bool? isLoadingChildren,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      IntakeState(
        configuration: clearConfiguration ? null : configuration ?? this.configuration,
        childProfiles: childProfiles ?? this.childProfiles,
        selectedChildId:
            clearSelectedChild ? null : selectedChildId ?? this.selectedChildId,
        isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : error ?? this.error,
      );
}

/// Engine 1 source of truth. It stores guardian-stated presentation
/// preferences; it does not create a diagnostic or predictive child profile.
class IntakeController extends StateNotifier<IntakeState> {
  IntakeController(this._api) : super(const IntakeState());

  final SupabaseApi _api;

  Future<void> loadChildProfiles() async {
    if (presentationDemoMode) {
      final profile = ChildProfile(
        id: 'synthetic-demo-child',
        preferredName: 'Demo explorer',
        birthYear: DateTime.now().year - 9,
      );
      state = state.copyWith(
        childProfiles: [profile],
        selectedChildId: profile.id,
        isLoadingChildren: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(isLoadingChildren: true, clearError: true);
    try {
      final profiles = (await _api.loadChildren())
          .map(ChildProfile.fromJson)
          .toList(growable: false);
      state = state.copyWith(
        childProfiles: profiles,
        isLoadingChildren: false,
        clearError: true,
      );
      if (profiles.length == 1) {
        await selectChild(profiles.single.id);
      }
    } catch (error) {
      state = state.copyWith(
        isLoadingChildren: false,
        error: _errorMessage(error),
      );
    }
  }

  Future<void> selectChild(String childId) async {
    if (presentationDemoMode) {
      state = state.copyWith(
        selectedChildId: childId,
        isLoadingChildren: false,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(
      selectedChildId: childId,
      isLoadingChildren: true,
      clearError: true,
    );
    try {
      final stored = await _api.loadExplorationPreferences(childId);
      final configuration = stored == null
          ? null
          : IntakeConfiguration.fromJson(childId: childId, json: stored);
      state = state.copyWith(
        configuration: configuration,
        clearConfiguration: configuration == null,
        selectedChildId: childId,
        isLoadingChildren: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        selectedChildId: childId,
        isLoadingChildren: false,
        error: _errorMessage(error),
      );
    }
  }

  Future<ChildProfile?> createChild({
    required String preferredName,
    required int birthYear,
  }) async {
    if (presentationDemoMode) {
      final profile = ChildProfile(
        id: 'local-prototype-child',
        preferredName: preferredName,
        birthYear: birthYear,
      );
      state = state.copyWith(
        childProfiles: [profile],
        selectedChildId: profile.id,
        isSaving: false,
        clearError: true,
      );
      return profile;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final response = await _api.createChild(
        preferredName: preferredName,
        birthYear: birthYear,
      );
      final profile = ChildProfile.fromJson(response);
      final profiles = [...state.childProfiles, profile];
      state = state.copyWith(
        childProfiles: profiles,
        selectedChildId: profile.id,
        isSaving: false,
        clearError: true,
      );
      return profile;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: _errorMessage(error));
      return null;
    }
  }

  Future<bool> save(IntakeConfiguration configuration) async {
    if (presentationDemoMode) {
      state = state.copyWith(
        configuration: configuration,
        selectedChildId: configuration.childId,
        isSaving: false,
        clearError: true,
      );
      return true;
    }
    state = state.copyWith(
      configuration: configuration,
      selectedChildId: configuration.childId,
      isSaving: true,
      clearError: true,
    );
    try {
      await _api.submitIntake({
        'childId': configuration.childId,
        'explorationPreferences': configuration.toJson(),
      });
      state = state.copyWith(
        configuration: configuration,
        selectedChildId: configuration.childId,
        isSaving: false,
        clearError: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        configuration: configuration,
        selectedChildId: configuration.childId,
        isSaving: false,
        error: _errorMessage(error),
      );
      return false;
    }
  }

  void setForLocalPreview(IntakeConfiguration configuration) {
    state = state.copyWith(
      configuration: configuration,
      selectedChildId: configuration.childId,
      clearError: true,
    );
  }

  String _errorMessage(Object error) {
    if (error is StateError) return error.message.toString();
    return 'We could not save these preferences. Please check the connection and try again.';
  }
}

final intakeProvider = StateNotifierProvider<IntakeController, IntakeState>((ref) {
  return IntakeController(ref.read(supabaseApiProvider));
});

final interfaceConfigurationProvider = Provider<InterfaceConfiguration>((ref) {
  return ref.watch(intakeProvider).configuration?.interface ??
      const InterfaceConfiguration(
        glassBlur: 16,
        glassOpacity: .14,
        contrastScale: .9,
        allowDistractors: true,
        allowAudioFeedback: true,
        preferHaptics: false,
        allowMotion: true,
        showTimePressure: true,
        preferredInteraction: InteractionPreference.dragging,
        communicationPreference: CommunicationPreference.visualSteps,
      );
});
