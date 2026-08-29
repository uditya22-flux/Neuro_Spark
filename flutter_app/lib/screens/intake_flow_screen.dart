import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/intake_models.dart';
import '../../core/router/app_router.dart';
import '../../features/demo/presentation/demo_cheat_sheet.dart';
import '../../features/demo/providers/demo_mode_provider.dart';
import '../../providers/intake_flow_provider.dart';
import 'intake/widgets/clinical_intake_step.dart';
import 'intake/widgets/environment_preview_step.dart';
import 'intake/widgets/parent_personalization_step.dart';

/// Dual-layer clinical + parental intake that compiles a [GameEnvironmentConfig].
class IntakeFlowScreen extends ConsumerStatefulWidget {
  const IntakeFlowScreen({
    super.key,
    this.onEnvironmentConfirmed,
  });

  final void Function(GameEnvironmentConfig config)? onEnvironmentConfirmed;

  @override
  ConsumerState<IntakeFlowScreen> createState() => _IntakeFlowScreenState();
}

class _IntakeFlowScreenState extends ConsumerState<IntakeFlowScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isDemo = ref.read(demoModeProvider);
      if (isDemo) {
        ref.read(intakeFlowProvider.notifier).seedFromDemoPrefills();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncPage(int step) {
    ref.read(intakeFlowProvider.notifier).goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  bool _canAdvance(int step) {
    final notifier = ref.read(intakeFlowProvider.notifier);
    return switch (step) {
      0 => notifier.canAdvanceFromClinical(),
      1 => notifier.canAdvanceFromParent(),
      _ => true,
    };
  }

  void _next() {
    final step = ref.read(intakeFlowProvider).currentStep;
    if (!_canAdvance(step)) {
      _showValidationMessage(step);
      return;
    }
    if (step >= IntakeFlowState.totalSteps - 1) return;
    HapticFeedback.lightImpact();
    _syncPage(step + 1);
  }

  void _back() {
    final step = ref.read(intakeFlowProvider).currentStep;
    if (step <= 0) return;
    HapticFeedback.selectionClick();
    _syncPage(step - 1);
  }

  void _showValidationMessage(int step) {
    final message = step == 1
        ? 'Please enter your child\'s name and confirm age is between 7 and 12.'
        : 'Complete the required fields before continuing.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirmEnvironment() {
    HapticFeedback.mediumImpact();
    completeIntakeAndProceed(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(intakeFlowProvider.select((s) => s.currentStep));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindBridge Intake'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DemoCheatSheet(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => ref.read(intakeFlowProvider.notifier).goToStep(index),
                children: [
                  const ClinicalIntakeStep(),
                  const ParentPersonalizationStep(),
                  EnvironmentPreviewStep(onComplete: _confirmEnvironment),
                ],
              ),
            ),
            _IntakeNavigationBar(
              step: step,
              onBack: step > 0 ? _back : null,
              onNext: step < IntakeFlowState.totalSteps - 1 ? _next : null,
              nextLabel: step == IntakeFlowState.totalSteps - 2 ? 'Preview Config' : 'Continue',
            ),
          ],
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}

class _IntakeNavigationBar extends StatelessWidget {
  const _IntakeNavigationBar({
    required this.step,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Back'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          if (onNext != null)
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(nextLabel),
              ),
            ),
        ],
      ),
    );
  }
}
