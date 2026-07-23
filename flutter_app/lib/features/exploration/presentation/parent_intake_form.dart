import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/config/prototype_mode.dart';
import '../models/exploration_models.dart';
import '../providers/intake_provider.dart';
import '../services/synthetic_demo_scene_mapper.dart';

/// Guardian-only support-preferences form. It collects presentation choices,
/// not a diagnostic, score, or predicted capability profile.
class ParentIntakeForm extends ConsumerStatefulWidget {
  const ParentIntakeForm({super.key});

  @override
  ConsumerState<ParentIntakeForm> createState() => _ParentIntakeFormState();
}

class _ParentIntakeFormState extends ConsumerState<ParentIntakeForm> {
  final _formKey = GlobalKey<FormState>();
  final _theme = TextEditingController();
  final _favouriteObjects = TextEditingController();
  final _familiarScenes = TextEditingController();
  final _childName = TextEditingController();
  final _birthYear = TextEditingController();

  double _audioLimit = 50;
  VisualClutterTolerance _clutter = VisualClutterTolerance.medium;
  AudioFeedbackPreference _audioFeedback = AudioFeedbackPreference.calm;
  SensoryTolerance _brightness = SensoryTolerance.medium;
  SensoryTolerance _motion = SensoryTolerance.medium;
  InteractionPreference _interaction = InteractionPreference.dragging;
  CommunicationPreference _communication = CommunicationPreference.visualSteps;
  SandboxPreference _sandboxPreference = SandboxPreference.calendar;
  bool _visualRepetitionHelpful = false;
  Set<KnownTrigger> _knownTriggers = <KnownTrigger>{};
  Set<FamiliarColor> _familiarColors = <FamiliarColor>{};
  VisualStylePreference _visualStyle = VisualStylePreference.illustratedObjects;
  Set<AvoidableVisualElement> _avoidableVisualElements = <AvoidableVisualElement>{};
  SyntheticDemoWorld _syntheticDemoWorld = SyntheticDemoWorld.vehicles;
  bool _creatingChild = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(intakeProvider.notifier).loadChildProfiles();
      if (mounted) _applyStoredConfiguration(ref.read(intakeProvider).configuration);
    });
  }

  @override
  void dispose() {
    _theme.dispose();
    _favouriteObjects.dispose();
    _familiarScenes.dispose();
    _childName.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  void _applyStoredConfiguration(IntakeConfiguration? configuration) {
    setState(() {
      if (configuration == null) {
        _audioLimit = 50;
        _clutter = VisualClutterTolerance.medium;
        _audioFeedback = AudioFeedbackPreference.calm;
        _brightness = SensoryTolerance.medium;
        _motion = SensoryTolerance.medium;
        _interaction = InteractionPreference.dragging;
        _communication = CommunicationPreference.visualSteps;
        _visualRepetitionHelpful = false;
        _knownTriggers = <KnownTrigger>{};
        _sandboxPreference = SandboxPreference.calendar;
        _theme.clear();
        _favouriteObjects.clear();
        _familiarScenes.clear();
        _familiarColors = <FamiliarColor>{};
        _visualStyle = VisualStylePreference.illustratedObjects;
        _avoidableVisualElements = <AvoidableVisualElement>{};
        _syntheticDemoWorld = SyntheticDemoWorld.vehicles;
        return;
      }
      _audioLimit = configuration.audioLimit.toDouble();
      _clutter = configuration.visualClutterTolerance;
      _audioFeedback = configuration.audioFeedbackPreference;
      _brightness = configuration.brightnessTolerance;
      _motion = configuration.motionTolerance;
      _interaction = configuration.interactionPreference;
      _communication = configuration.communicationPreference;
      _visualRepetitionHelpful = configuration.visualRepetitionHelpful;
      _knownTriggers = {...configuration.knownTriggers};
      _sandboxPreference = configuration.sandboxPreference;
      _theme.text = configuration.hyperFocusTheme;
      _favouriteObjects.text = configuration.favouriteObjects;
      _familiarScenes.text = configuration.familiarScenes;
      _familiarColors = {...configuration.familiarColors};
      _visualStyle = configuration.visualStylePreference;
      _avoidableVisualElements = {...configuration.avoidableVisualElements};
      _syntheticDemoWorld = configuration.syntheticDemoWorld;
    });
  }

  Future<void> _selectChild(String childId) async {
    await ref.read(intakeProvider.notifier).selectChild(childId);
    if (mounted) _applyStoredConfiguration(ref.read(intakeProvider).configuration);
  }

  void _refreshSyntheticDemoWorld() {
    if (!presentationDemoMode) return;
    final world = SyntheticDemoSceneMapper.fromIntakeText(
      theme: _theme.text,
      favouriteObjects: _favouriteObjects.text,
      familiarScenes: _familiarScenes.text,
    );
    if (world != _syntheticDemoWorld) {
      setState(() => _syntheticDemoWorld = world);
    }
  }

  Future<void> _createChildProfile() async {
    final name = _childName.text.trim();
    final birthYear = int.tryParse(_birthYear.text.trim());
    final currentYear = DateTime.now().year;
    if (name.isEmpty || birthYear == null || birthYear < currentYear - 12 || birthYear > currentYear - 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and a birth year for a child aged 7–12.')),
      );
      return;
    }
    setState(() => _creatingChild = true);
    final profile = await ref.read(intakeProvider.notifier).createChild(
          preferredName: name,
          birthYear: birthYear,
        );
    if (!mounted) return;
    setState(() => _creatingChild = false);
    if (profile != null) {
      _childName.clear();
      _birthYear.clear();
      await _selectChild(profile.id);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final demoWorld = presentationDemoMode
        ? SyntheticDemoSceneMapper.fromIntakeText(
            theme: _theme.text,
            favouriteObjects: _favouriteObjects.text,
            familiarScenes: _familiarScenes.text,
          )
        : _syntheticDemoWorld;
    final childId = ref.read(intakeProvider).selectedChildId;
    if (childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose or create a child profile first.')),
      );
      return;
    }
    final saved = await ref.read(intakeProvider.notifier).save(
          IntakeConfiguration(
            childId: childId,
            audioLimit: _audioLimit.round(),
            visualClutterTolerance: _clutter,
            audioFeedbackPreference: _audioFeedback,
            brightnessTolerance: _brightness,
            motionTolerance: _motion,
            interactionPreference: _interaction,
            visualRepetitionHelpful: _visualRepetitionHelpful,
            communicationPreference: _communication,
            knownTriggers: _knownTriggers,
            hyperFocusTheme: _theme.text.trim(),
            sandboxPreference: _sandboxPreference,
            favouriteObjects: _favouriteObjects.text.trim(),
            familiarScenes: _familiarScenes.text.trim(),
            familiarColors: _familiarColors,
            visualStylePreference: _visualStyle,
            avoidableVisualElements: _avoidableVisualElements,
            syntheticDemoWorld: demoWorld,
          ),
        );
    if (!mounted || !saved) return;
    final status = ref.read(authStatusProvider);
    ref.read(authStatusProvider.notifier).state = AuthUserStatus(
      isLoggedIn: status.isLoggedIn,
      userId: status.userId,
      activeChildId: childId,
      hasCompletedIntake: true,
      hasCompletedAssessment: false,
    );
    context.go('/assessment-canvas');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(intakeProvider);
    final busy = state.isSaving || state.isLoadingChildren || _creatingChild;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian preferences'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set up a comfortable exploration space.', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('These are guardian-stated support preferences. They are not a diagnosis or score.'),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      _MessageCard(message: state.error!),
                    ],
                    const SizedBox(height: 24),
                    if (presentationDemoMode) ...[
                      _sectionTitle(context, 'Child preferences'),
                      const Text('The preferences below set up a comfortable exploration space for this session.'),
                    ] else ...[
                    _sectionTitle(context, 'Child profile'),
                    DropdownButtonFormField<String>(
                      key: ValueKey('child-${state.selectedChildId}-${state.childProfiles.length}'),
                      initialValue: state.selectedChildId,
                      decoration: const InputDecoration(labelText: 'Choose a child profile'),
                      items: state.childProfiles
                          .map((child) => DropdownMenuItem(
                                value: child.id,
                                child: Text('${child.preferredName} (${child.birthYear})'),
                              ))
                          .toList(),
                      onChanged: busy ? null : (id) => id == null ? null : _selectChild(id),
                    ),
                    const SizedBox(height: 12),
                    Text('Or add a child aged 7–12', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _childName,
                            enabled: !busy,
                            decoration: const InputDecoration(labelText: 'Preferred name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _birthYear,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Birth year'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _createChildProfile,
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add child profile'),
                    ),
                    ],
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Sound and visuals'),
                    Text('Comfortable audio limit: ${_audioLimit.round()}%'),
                    Slider(
                      value: _audioLimit,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      onChanged: busy ? null : (value) => setState(() => _audioLimit = value),
                    ),
                    DropdownButtonFormField<AudioFeedbackPreference>(
                      key: ValueKey('audio-feedback-${_audioFeedback.name}'),
                      initialValue: _audioFeedback,
                      decoration: const InputDecoration(labelText: 'Preferred feedback'),
                      items: AudioFeedbackPreference.values
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                          .toList(),
                      onChanged: busy ? null : (value) => setState(() => _audioFeedback = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VisualClutterTolerance>(
                      key: ValueKey('visual-clutter-${_clutter.name}'),
                      initialValue: _clutter,
                      decoration: const InputDecoration(labelText: 'Visual-clutter tolerance'),
                      items: VisualClutterTolerance.values
                          .map((value) => DropdownMenuItem(value: value, child: Text('${value.name[0].toUpperCase()}${value.name.substring(1)} tolerance')))
                          .toList(),
                      onChanged: busy ? null : (value) => setState(() => _clutter = value!),
                    ),
                    const SizedBox(height: 12),
                    _toleranceField(
                      label: 'Brightness tolerance',
                      value: _brightness,
                      onChanged: busy ? null : (value) => setState(() => _brightness = value!),
                    ),
                    const SizedBox(height: 12),
                    _toleranceField(
                      label: 'Movement and animation tolerance',
                      value: _motion,
                      onChanged: busy ? null : (value) => setState(() => _motion = value!),
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Interaction and communication'),
                    const Text('Which interaction usually feels most natural?'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: InteractionPreference.values
                          .map((value) => ChoiceChip(
                                label: Text(value.label),
                                selected: _interaction == value,
                                onSelected: busy ? null : (_) => setState(() => _interaction = value),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visual repetition is calming or helpful'),
                      value: _visualRepetitionHelpful,
                      onChanged: busy ? null : (value) => setState(() => _visualRepetitionHelpful = value),
                    ),
                    DropdownButtonFormField<CommunicationPreference>(
                      key: ValueKey('communication-${_communication.name}'),
                      initialValue: _communication,
                      decoration: const InputDecoration(labelText: 'Helpful communication style'),
                      items: CommunicationPreference.values
                          .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                          .toList(),
                      onChanged: busy ? null : (value) => setState(() => _communication = value!),
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Avoidable triggers'),
                    const Text('Select anything the play experience should avoid when possible.'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: KnownTrigger.values
                          .map((trigger) => FilterChip(
                                label: Text(trigger.label),
                                selected: _knownTriggers.contains(trigger),
                                onSelected: busy
                                    ? null
                                    : (selected) => setState(() {
                                          if (selected) {
                                            _knownTriggers.add(trigger);
                                          } else {
                                            _knownTriggers.remove(trigger);
                                          }
                                        }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                    _sectionTitle(context, 'Theme and open-ended play'),
                    TextFormField(
                      controller: _theme,
                      enabled: !busy,
                      onChanged: (_) => _refreshSyntheticDemoWorld(),
                      decoration: const InputDecoration(
                        labelText: 'Favourite theme or current intense interest',
                        hintText: 'For example: trains, planets, or plumbing systems',
                      ),
                      maxLength: 80,
                      validator: (value) => presentationDemoMode || (value != null && value.trim().isNotEmpty)
                          ? null
                          : 'Enter a theme to personalise play.',
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(context, 'Familiar visual world'),
                    const Text(
                      'Optional details that help play resemble familiar, enjoyable things. Avoid names, school details, or private information.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _favouriteObjects,
                      enabled: !busy,
                      onChanged: (_) => _refreshSyntheticDemoWorld(),
                      decoration: const InputDecoration(
                        labelText: 'Favourite toys, objects, or pictures',
                        hintText: 'For example: red cars, buses, dinosaurs, building tools',
                      ),
                      maxLength: 120,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _familiarScenes,
                      enabled: !busy,
                      onChanged: (_) => _refreshSyntheticDemoWorld(),
                      decoration: const InputDecoration(
                        labelText: 'Familiar places or scenes',
                        hintText: 'For example: roads, garage, garden, night sky',
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    const Text('Colours that usually feel appealing'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FamiliarColor.values
                          .map((color) => FilterChip(
                                label: Text(color.label),
                                selected: _familiarColors.contains(color),
                                onSelected: busy
                                    ? null
                                    : (selected) => setState(() {
                                          if (selected) {
                                            _familiarColors.add(color);
                                          } else {
                                            _familiarColors.remove(color);
                                          }
                                        }),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<VisualStylePreference>(
                      key: ValueKey('visual-style-${_visualStyle.name}'),
                      initialValue: _visualStyle,
                      decoration: const InputDecoration(labelText: 'Picture style that feels most familiar'),
                      items: VisualStylePreference.values
                          .map((style) => DropdownMenuItem(value: style, child: Text(style.label)))
                          .toList(),
                      onChanged: busy ? null : (value) => setState(() => _visualStyle = value!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pictures to leave out when possible'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AvoidableVisualElement.values
                          .map((element) => FilterChip(
                                label: Text(element.label),
                                selected: _avoidableVisualElements.contains(element),
                                onSelected: busy
                                    ? null
                                    : (selected) => setState(() {
                                          if (selected) {
                                            _avoidableVisualElements.add(element);
                                          } else {
                                            _avoidableVisualElements.remove(element);
                                          }
                                        }),
                              ))
                          .toList(),
                    ),
                    DropdownButtonFormField<SandboxPreference>(
                      key: ValueKey('sandbox-${_sandboxPreference.name}'),
                      initialValue: _sandboxPreference,
                      decoration: const InputDecoration(labelText: 'Choose an open-ended sandbox'),
                      items: const [
                        DropdownMenuItem(value: SandboxPreference.calendar, child: Text('Timeline workshop')),
                        DropdownMenuItem(value: SandboxPreference.constellation, child: Text('Constellation workshop')),
                      ],
                      onChanged: busy ? null : (value) => setState(() => _sandboxPreference = value!),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : _submit,
                        child: Text(busy ? 'Saving...' : 'Save preferences and start exploration'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toleranceField({
    required String label,
    required SensoryTolerance value,
    required ValueChanged<SensoryTolerance?>? onChanged,
  }) =>
      DropdownButtonFormField<SensoryTolerance>(
        key: ValueKey('$label-${value.name}'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: SensoryTolerance.values
            .map((option) => DropdownMenuItem(value: option, child: Text(option.label)))
            .toList(),
        onChanged: onChanged,
      );

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
      );
}
