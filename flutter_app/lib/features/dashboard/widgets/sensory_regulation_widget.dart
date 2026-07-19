import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdui_controller.dart';

class SensoryRegulationWidget extends ConsumerStatefulWidget {
  const SensoryRegulationWidget({super.key});

  @override
  ConsumerState<SensoryRegulationWidget> createState() => _SensoryRegulationWidgetState();
}

class _SensoryRegulationWidgetState extends ConsumerState<SensoryRegulationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  int _tapCount = 0;
  bool _isHoldingPressure = false;
  bool _isAudioPlaying = false;
  Timer? _hapticTimer;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _triggerHapticFeedback(HapticFeedbackType type, SensoryConfig config) {
    if (config.silentVisualGlowOnly) return; // Silent visual glow only
    try {
      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.vibrate:
          HapticFeedback.vibrate();
          break;
      }
    } catch (_) {}
  }

  void _playMockSound(SensoryConfig config) {
    if (config.silentVisualGlowOnly || !config.useAudioChimes) return;
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sduiState = ref.watch(sduiControllerProvider);
    final profile = sduiState.profile;
    final isAac = sduiState.isAacMode;
    final method = profile.sensoryProfile.effectiveRegulationMethod.toLowerCase();
    final sensoryConfig = sduiState.sensoryConfig;

    String toolTitle = "Calm Station";
    Widget toolInterface = const SizedBox.shrink();

    // Renders different layout depending on sensory regulation preference
    if (method.contains('audio_scanner')) {
      toolTitle = isAac ? "" : "Audio Calm Scanner";
      toolInterface = Column(
        children: [
          if (!isAac)
            const Text(
              'Listen to low-frequency soothing soundwaves to ease sensory over-stimulation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 48,
                onPressed: () {
                  setState(() {
                    _isAudioPlaying = !_isAudioPlaying;
                  });
                  _triggerHapticFeedback(HapticFeedbackType.medium, sensoryConfig);
                  if (_isAudioPlaying) {
                    _playMockSound(sensoryConfig);
                  }
                },
                icon: Icon(_isAudioPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated sound waves
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isAudioPlaying
                ? SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(8, (index) {
                        return AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            final val = (_glowController.value * (index % 3 + 1) * 30).clamp(5, 30).toDouble();
                            return Container(
                              width: 6,
                              height: val,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  )
                : const SizedBox(height: 40),
          ),
        ],
      );
    } else if (method.contains('rhythmic_tapping')) {
      toolTitle = isAac ? "" : "Kinetic Rhythmic Tap Pad";
      toolInterface = Column(
        children: [
          if (!isAac)
            const Text(
              'Tap the pad rhythmically to ground your focus and regulate pacing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _tapCount++;
              });
              _triggerHapticFeedback(HapticFeedbackType.light, sensoryConfig);
              _playMockSound(sensoryConfig);
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    if (!isAac)
                      Text(
                        'Total Grounding Taps: $_tapCount',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (method.contains('deep_pressure')) {
      toolTitle = isAac ? "" : "Deep Pressure Haptic Station";
      toolInterface = Column(
        children: [
          if (!isAac)
            const Text(
              'Press and hold the button below to receive constant regulating vibration feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) {
              setState(() {
                _isHoldingPressure = true;
              });
              _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
                _triggerHapticFeedback(HapticFeedbackType.heavy, sensoryConfig);
              });
            },
            onTapUp: (_) {
              setState(() {
                _isHoldingPressure = false;
              });
              _hapticTimer?.cancel();
            },
            onTapCancel: () {
              setState(() {
                _isHoldingPressure = false;
              });
              _hapticTimer?.cancel();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHoldingPressure
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
                boxShadow: _isHoldingPressure
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  Icons.compress_rounded,
                  size: 38,
                  color: _isHoldingPressure ? Colors.white : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isAac)
            Text(
              _isHoldingPressure ? 'Deep Haptics active...' : 'Hold for pressure',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
        ],
      );
    } else {
      // Visual Glow (Profile 5 - Logic Coder)
      toolTitle = isAac ? "" : "Silent Visual Glow Pad";
      toolInterface = Column(
        children: [
          if (!isAac)
            const Text(
              'Hold your finger on the circle and take deep, slow breaths matching the glow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final double scale = 1.0 + (_glowController.value * 0.4);
              final double opacity = 0.2 + (_glowController.value * 0.5);
              return Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.6),
                      blurRadius: 20 * scale,
                      spreadRadius: 2 * scale,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.lens_blur_rounded,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            if (isAac)
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  const Icon(Icons.spa_rounded, color: Colors.greenAccent, size: 28),
                ],
              )
            else
              Text(
                toolTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            const SizedBox(height: 16),
            toolInterface,
          ],
        ),
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, heavy, vibrate }
