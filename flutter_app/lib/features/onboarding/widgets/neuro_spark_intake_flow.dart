import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_state.dart';
import '../providers/onboarding_controller.dart';
import '../../dashboard/widgets/neuro_spark_dashboard.dart';

import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class NeuroSparkIntakeFlow extends ConsumerStatefulWidget {
  const NeuroSparkIntakeFlow({super.key});

  @override
  ConsumerState<NeuroSparkIntakeFlow> createState() => _NeuroSparkIntakeFlowState();
}

class _NeuroSparkIntakeFlowState extends ConsumerState<NeuroSparkIntakeFlow> {
  final PageController _pageController = PageController();
  int _activePage = 0;
  bool _isSubmitting = false;

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey5 = GlobalKey<FormState>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate required inputs on Page 1
    if (_activePage == 0) {
      if (!_formKey1.currentState!.validate()) return;
    }
    // Validate required inputs on Page 2
    if (_activePage == 1) {
      if (!_formKey2.currentState!.validate()) return;
    }
    // Validate required inputs on Page 5
    if (_activePage == 4) {
      if (!_formKey5.currentState!.validate()) return;
    }

    if (_activePage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_activePage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isSubmitting = true);

    final controller = ref.read(onboardingControllerProvider.notifier);
    final success = await controller.completeSetup();

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ref.read(authStatusProvider.notifier).state = const AuthUserStatus(
          isLoggedIn: true,
          userId: 'user_guardian_101',
          hasCompletedIntake: true,
          hasCompletedStrengthFunnel: false,
          hasCompletedAssessment: false,
        );
        context.go('/strength-funnel');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize theme. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intake Onboarding'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_activePage + 1) / 6,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Page Indicator Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_activePage + 1} of 6',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _getPageTitle(_activePage),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) {
                      setState(() {
                        _activePage = page;
                      });
                    },
                    children: [
                      _buildPage1(onboardingState),
                      _buildPage2(onboardingState),
                      _buildPage3(onboardingState),
                      _buildPage4(onboardingState),
                      _buildPage5(onboardingState),
                      _buildPage6(onboardingState),
                    ],
                  ),
                ),

                // Navigation Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      OutlinedButton(
                        onPressed: _activePage == 0 ? null : _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Back'),
                      ),

                      // Next or Complete Setup Button
                      ElevatedButton(
                        onPressed: _activePage == 5 ? _completeSetup : _nextPage,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_activePage == 5 ? 'Complete Setup' : 'Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Initializing Child\'s Custom Theme...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Core Identity';
      case 1:
        return 'Environmental Affinities';
      case 2:
        return 'Sensory Profile';
      case 3:
        return 'Transitions & Routines';
      case 4:
        return 'Interests & Strengths';
      case 5:
        return 'Communication & Emotion';
      default:
        return '';
    }
  }

  // PAGE 1: Identity Form View
  Widget _buildPage1(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your family',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.realName,
              decoration: const InputDecoration(
                labelText: 'Child\'s Name *',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter child\'s name' : null,
              onChanged: notifier.updateRealName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.age.toString(),
              decoration: const InputDecoration(
                labelText: 'Child\'s Age *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter child\'s age';
                final parsed = int.tryParse(val);
                if (parsed == null || parsed <= 0) return 'Please enter a valid age number';
                return null;
              },
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 8;
                notifier.updateAge(parsed);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.fatherName,
              decoration: const InputDecoration(
                labelText: 'Father\'s Name',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.updateFatherName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.motherName,
              decoration: const InputDecoration(
                labelText: 'Mother\'s Name',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.updateMotherName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.siblingNames,
              decoration: const InputDecoration(
                labelText: 'Sibling(s) Names',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.updateSiblingNames,
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 2: Environmental Affinities Form View
  Widget _buildPage2(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environmental Interests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.favoriteColor,
              decoration: const InputDecoration(
                labelText: 'Favorite Color (e.g. Sage Green, Blue, Indigo, Yellow) *',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a color preference' : null,
              onChanged: notifier.updateFavoriteColor,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.favoritePlace,
              decoration: const InputDecoration(
                labelText: 'Favorite Place (e.g. Outer Space, Dig site) *',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a place preference' : null,
              onChanged: notifier.updateFavoritePlace,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.favoriteObject,
              decoration: const InputDecoration(
                labelText: 'Favorite Object (e.g. Telescope, Train) *',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter an object preference' : null,
              onChanged: notifier.updateFavoriteObject,
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 3: Sensory Profile Form View
  Widget _buildPage3(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final auditoryOptions = ['Seeks out noise', 'Neutral', 'Easily overwhelmed'];
    final visualOptions = ['Yes frequently', 'Sometimes', 'Rarely'];
    final regulationOptions = ['Deep pressure', 'Ambient sounds', 'Dim lighting', 'Fidgeting'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensory Environment Preferences',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Auditory Reaction
          const Text('Reaction to auditory environments:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: auditoryOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.auditoryReaction == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateAuditoryReaction(opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Visual Distress
          const Text('Bright lights/visual distress:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: visualOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.visualDistress == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateVisualDistress(opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Regulation Method
          const Text('Most effective regulation method:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: regulationOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.effectiveRegulationMethod == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateEffectiveRegulationMethod(opt);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // PAGE 4: Routine & Transitions Form View
  Widget _buildPage4(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final instructionOptions = [
      'Step-by-step visual pictograms',
      'Short direct verbal cues',
      'Written checklists'
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Routines & Task Transitions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Slider Task Difficulty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Difficulty switching to new tasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${state.transitionDifficultyScore.toInt()}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: state.transitionDifficultyScore,
            min: 1.0,
            max: 5.0,
            divisions: 4,
            label: state.transitionDifficultyScore.toInt().toString(),
            onChanged: notifier.updateTransitionDifficultyScore,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Very Easy', style: TextStyle(fontSize: 11)),
                Text('Very Difficult', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Boolean distress toggle
          SwitchListTile(
            title: const Text('Unexpected changes cause significant distress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            value: state.unexpectedChangeDistress,
            onChanged: notifier.updateUnexpectedChangeDistress,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),

          // Instruction processing preference
          const Text('Best way to process instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: instructionOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.instructionProcessingPreference == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateInstructionProcessingPreference(opt);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // PAGE 5: Strengths & Hyper-Fixations View
  Widget _buildPage5(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final abilitiesOptions = [
      'Exceptional memory',
      'Pattern recognition',
      'High attention to detail',
      'Logical reasoning',
      'Music/Rhythm',
      '3D Spatial Reasoning',
      'Visual Thinking',
      'Systems Thinking',
      'Numerical Intuition',
      'Deep Hyper-focus',
      'Divergent Problem Solving',
      'Kinesthetic Learning',
    ];
    final approachOptions = ['Trial and error', 'Observing first', 'Categorizing and sorting'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Strengths & Hyper-Fixations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Abilities Multi-select
            const Text('Natural abilities (Max 3):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: abilitiesOptions.map((opt) {
                final isSelected = state.naturalAbilities.contains(opt);
                final maxReached = state.naturalAbilities.length >= 3;
                return FilterChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (!isSelected && maxReached)
                      ? null
                      : (selected) {
                          final list = List<String>.from(state.naturalAbilities);
                          if (selected) {
                            if (list.length < 3) {
                              list.add(opt);
                              notifier.updateNaturalAbilities(list);
                            }
                          } else {
                            list.remove(opt);
                            notifier.updateNaturalAbilities(list);
                          }
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Hyper fixation text input
            TextFormField(
              initialValue: state.primaryHyperFixation,
              decoration: const InputDecoration(
                labelText: 'Primary Hyper-Fixation/Special Interest *',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter primary interest' : null,
              onChanged: notifier.updatePrimaryHyperFixation,
            ),
            const SizedBox(height: 20),

            // Problem solving
            const Text('Problem-solving approach:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: approachOptions.map((opt) {
                return ChoiceChip(
                  label: Text(opt),
                  selected: state.problemSolvingApproach == opt,
                  onSelected: (selected) {
                    if (selected) notifier.updateProblemSolvingApproach(opt);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // PAGE 6: Communication & Emotion View
  Widget _buildPage6(OnboardingState state) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final communicationOptions = ['Highly verbal', 'Non-verbal', 'Uses AAC devices', 'Scripting/Echolalia'];
    final interoceptionOptions = ['Usually', 'Sometimes', 'Rarely'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Communication & Emotion',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Communication style
          const Text('Communication when stressed:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: communicationOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.stressCommunicationStyle == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateStressCommunicationStyle(opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Interoception level
          const Text('Emotional interoception/Recognizing frustration:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: interoceptionOptions.map((opt) {
              return ChoiceChip(
                label: Text(opt),
                selected: state.emotionalInteroceptionLevel == opt,
                onSelected: (selected) {
                  if (selected) notifier.updateEmotionalInteroceptionLevel(opt);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
