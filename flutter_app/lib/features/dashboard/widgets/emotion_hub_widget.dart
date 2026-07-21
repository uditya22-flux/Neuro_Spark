import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdui_controller.dart';

class EmotionHubWidget extends ConsumerStatefulWidget {
  const EmotionHubWidget({super.key});

  @override
  ConsumerState<EmotionHubWidget> createState() => _EmotionHubWidgetState();
}

class _EmotionHubWidgetState extends ConsumerState<EmotionHubWidget> {
  double _energy = 0.5;
  double _comfort = 0.8;
  String _selectedStateSymbol = '';

  @override
  Widget build(BuildContext context) {
    final sduiState = ref.watch(sduiControllerProvider);
    final profile = sduiState.profile;
    final isAac = sduiState.isAacMode;
    final interoception = profile.communicationEmotion.emotionalInteroceptionLevel.toLowerCase();

    // Determine low interoception mode
    final isLowInteroception = interoception == 'low';

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
                  Icon(Icons.face_retouching_natural_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
                ],
              )
            else
              Text(
                'Self-Regulation Check-in',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            const SizedBox(height: 14),

            if (isLowInteroception) ...[
              // AAC / Pictorial mood cards for low interoception
              if (!isAac)
                Text(
                  'Tap the card matching your current body feeling:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double cardWidth = (constraints.maxWidth - 24) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeelingTile('☀️', 'Calm / Sunny', const Color(0xFF68A357), cardWidth),
                      _buildFeelingTile('⛈️', 'Stormy / Chaotic', const Color(0xFFFF9F1C), cardWidth),
                      _buildFeelingTile('⚡', 'Sensory Overload', const Color(0xFFFBBF24), cardWidth),
                      _buildFeelingTile('☁️', 'Tired / Foggy', const Color(0xFF5B8CAE), cardWidth),
                    ],
                  );
                },
              ),
            ] else ...[
              // Standard sliders for higher interoception
              if (!isAac)
                Text(
                  'Adjust sliders to reflect your sensory capacity:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 16),
              
              // Slider 1
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAac)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Energy Level', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${(_energy * 100).toInt()}%'),
                      ],
                    ),
                  Slider(
                    value: _energy,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _energy = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Slider 2
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAac)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sensory Comfort', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${(_comfort * 100).toInt()}%'),
                      ],
                    ),
                  Slider(
                    value: _comfort,
                    activeColor: Theme.of(context).colorScheme.secondary,
                    onChanged: (val) {
                      setState(() {
                        _comfort = val;
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingTile(String emoji, String description, Color baseColor, double width) {
    final sduiState = ref.read(sduiControllerProvider);
    final isSelected = _selectedStateSymbol == emoji;
    final isAac = sduiState.isAacMode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStateSymbol = emoji;
        });

        // Trigger haptics/audio if applicable
        final sensory = sduiState.sensoryConfig;
        if (sensory.useRhythmicHaptics) {
          // Rhythmic taps
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.2) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? baseColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: baseColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            if (!isAac)
              Text(
                description,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? baseColor : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
