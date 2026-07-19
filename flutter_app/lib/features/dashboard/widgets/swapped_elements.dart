import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- WIDGET 1: PictogramScheduleWidget (Rule 2: AAC Mode Textless Grid) ---
class PictogramScheduleWidget extends StatefulWidget {
  const PictogramScheduleWidget({super.key});

  @override
  State<PictogramScheduleWidget> createState() => _PictogramScheduleWidgetState();
}

class _PictogramScheduleWidgetState extends State<PictogramScheduleWidget> {
  final Map<int, bool> _checked = {0: true, 1: false, 2: false};

  final List<IconData> _pictograms = [
    Icons.settings_input_antenna_rounded, // Calibrate
    Icons.air_rounded,                   // Oxygen
    Icons.satellite_alt_rounded,           // Orbit
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.secondary, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pictograms.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, idx) {
                final isDone = _checked[idx] ?? false;
                return InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _checked[idx] = !isDone;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDone 
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.15)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone 
                            ? Theme.of(context).colorScheme.secondary 
                            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            _pictograms[idx],
                            size: 36,
                            color: isDone 
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (isDone)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.check_circle, size: 16, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 2: KineticRhythmPadWidget (Rule 3: Audio Drumming Surface) ---
class KineticRhythmPadWidget extends StatelessWidget {
  const KineticRhythmPadWidget({super.key});

  void _playDrum(BuildContext context, String name) {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🥁 $name played!'),
          duration: const Duration(milliseconds: 400),
        ),
      );
    } catch (_) {}
  }

  Widget _buildPad(BuildContext context, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _playDrum(context, label),
        child: Container(
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
              )
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kinetic Rhythm Station',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap pads to track auditory beats.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildPad(context, 'BASS', Colors.red),
                _buildPad(context, 'SNARE', Colors.blue),
                _buildPad(context, 'HI-HAT', Colors.orange),
                _buildPad(context, 'CLAP', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 3: SilentBreathingRingWidget (Rule 3: Visual-Only Breathing) ---
class SilentBreathingRingWidget extends StatefulWidget {
  const SilentBreathingRingWidget({super.key});

  @override
  State<SilentBreathingRingWidget> createState() => _SilentBreathingRingWidgetState();
}

class _SilentBreathingRingWidgetState extends State<SilentBreathingRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Silent Calming Circle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = 1.0 + (_controller.value * 0.5);
                  final opacity = 0.2 + (_controller.value * 0.6);
                  return Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.3),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.15),
                          blurRadius: 20 * scale,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _controller.value > 0.5 ? 'BREATHE OUT' : 'BREATHE IN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 4: HeavyHapticButtonWidget (Rule 3: Deep Pressure Haptic feedback) ---
class HeavyHapticButtonWidget extends StatefulWidget {
  const HeavyHapticButtonWidget({super.key});

  @override
  State<HeavyHapticButtonWidget> createState() => _HeavyHapticButtonWidgetState();
}

class _HeavyHapticButtonWidgetState extends State<HeavyHapticButtonWidget> {
  bool _pressing = false;

  void _triggerPressure() async {
    setState(() => _pressing = true);
    for (int i = 0; i < 4; i++) {
      if (!mounted || !_pressing) break;
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (mounted) {
      setState(() => _pressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deep Pressure Station',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _pressing ? null : _triggerPressure,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _pressing 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.compress_rounded),
                label: Text(
                  _pressing ? 'Applying Deep Pressure...' : 'Apply Deep Haptic Pressure',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
