import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenUiParser extends StatelessWidget {
  final Map<String, dynamic> schema;

  const GenUiParser({
    super.key,
    required this.schema,
  });

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'rocket':
      case 'space':
      case 'space_exploration':
        return Icons.rocket_launch_rounded;
      case 'dinosaur':
      case 'egg':
      case 'fossil':
        return Icons.egg_rounded;
      case 'train':
      case 'trains':
      case 'locomotive':
        return Icons.train_rounded;
      case 'sea_turtle':
      case 'turtle':
      case 'ocean':
      case 'marine_biology':
        return Icons.water_rounded;
      case 'telescope':
        return Icons.search_rounded;
      case 'code':
      case 'logic_coding':
      case 'microcontroller':
        return Icons.terminal_rounded;
      case 'spa_rounded':
      case 'nature':
        return Icons.spa_rounded;
      case 'terrain_rounded':
        return Icons.terrain_rounded;
      case 'help_outline_rounded':
        return Icons.help_outline_rounded;
      case 'music':
      case 'audio':
        return Icons.graphic_eq_rounded;
      case 'volume':
        return Icons.volume_up_rounded;
      case 'check':
        return Icons.check_circle_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  void _handleAction(BuildContext context, String action) {
    try {
      if (action == 'trigger_vibration_tap' || action.contains('haptic')) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generative Haptic Feedback Triggered'),
            duration: Duration(seconds: 1),
          ),
        );
      } else if (action == 'play_chime' || action.contains('audio')) {
        SystemSound.play(SystemSoundType.click);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generative Audio Anchor Triggered'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  Widget _buildNode(BuildContext context, Map<String, dynamic> node) {
    final type = node['type'] as String? ?? 'unknown';

    switch (type) {
      case 'mascot_header':
        final title = node['title'] as String? ?? 'Welcome!';
        final subtitle = node['subtitle'] as String? ?? '';
        final mascot = node['mascot'] as String? ?? 'rocket';
        final themeLabel = node['theme_label'] as String? ?? '';
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.15),
                primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconData(mascot), size: 48, color: primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blueGrey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (themeLabel.isNotEmpty) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(Icons.palette_outlined, size: 16, color: primaryColor),
                  label: Text(themeLabel, style: TextStyle(fontSize: 12, color: primaryColor)),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              ],
            ],
          ),
        );

      case 'breathing_engine':
        final location = node['location'] as String? ?? 'Calm Sanctuary';
        final technique = node['technique'] as String? ?? '4-4-4 Breathing Engine';
        final audioAnchor = node['audio_anchor'] as String? ?? 'Soft Brown Noise (432Hz)';
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  technique,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                const PulsingGlowRing(),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audio Anchor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(audioAnchor, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.play_circle_fill_rounded, color: primaryColor, size: 32),
                        onPressed: () => _handleAction(context, 'play_chime'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case 'tactile_sound_pad':
        final title = node['title'] as String? ?? 'Sensory Audio Pad';
        final subtitle = node['subtitle'] as String? ?? 'Tap for rhythmic stimulation';
        final buttons = node['buttons'] as List? ?? [];
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: buttons.map((btn) {
                    final bMap = Map<String, dynamic>.from(btn);
                    final bLabel = bMap['label'] as String? ?? 'Tap';
                    final bIcon = bMap['icon'] as String? ?? 'audio';
                    return InkWell(
                      onTap: () => _handleAction(context, 'trigger_vibration_tap'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(_getIconData(bIcon), color: primaryColor, size: 28),
                            const SizedBox(height: 6),
                            Text(bLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );

      case 'challenge_card':
        final title = node['title'] as String? ?? 'Personalized Challenge';
        final targetChallenge = node['target_challenge'] as String? ?? 'Exploration Task';
        final strengths = (node['strengths'] as List?)?.cast<String>() ?? [];
        final iconName = node['icon'] as String? ?? 'rocket';
        final primaryColor = Theme.of(context).colorScheme.primary;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIconData(iconName), color: primaryColor, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Target Challenge:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(targetChallenge, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                if (strengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Focus Point Strengths:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ...strengths.map((str) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(child: Text(str, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        );

      case 'card':
        final childrenList = node['children'] as List? ?? [];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: childrenList
                  .map((child) => _buildNode(context, Map<String, dynamic>.from(child)))
                  .toList(),
            ),
          ),
        );

      case 'row':
        final childrenList = node['children'] as List? ?? [];
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: childrenList
              .map((child) => _buildNode(context, Map<String, dynamic>.from(child)))
              .toList(),
        );

      case 'column':
        final childrenList = node['children'] as List? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: childrenList
              .map((child) => _buildNode(context, Map<String, dynamic>.from(child)))
              .toList(),
        );

      case 'spacer':
        final height = (node['height'] as num?)?.toDouble() ?? 0.0;
        final width = (node['width'] as num?)?.toDouble() ?? 0.0;
        return SizedBox(height: height, width: width);

      case 'text':
        final value = node['value'] as String? ?? '';
        final isHeader = node['is_header'] as bool? ?? false;
        return Text(
          value,
          style: isHeader
              ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyMedium,
        );

      case 'icon':
        final iconName = node['icon'] as String? ?? 'help';
        return Icon(
          _getIconData(iconName),
          color: Theme.of(context).colorScheme.primary,
        );

      case 'button':
        final label = node['label'] as String? ?? 'Tap';
        final action = node['action'] as String? ?? '';
        return ElevatedButton(
          onPressed: () => _handleAction(context, action),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label),
        );

      case 'glow_ring':
        return const Center(
          child: PulsingGlowRing(),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildNode(context, schema);
  }
}

// Custom internal widget for rendering a pulsing glowing visual ring for Gen UI breathing guide
class PulsingGlowRing extends StatefulWidget {
  const PulsingGlowRing({super.key});

  @override
  State<PulsingGlowRing> createState() => _PulsingGlowRingState();
}

class _PulsingGlowRingState extends State<PulsingGlowRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.3);
        final opacity = 0.2 + (_controller.value * 0.6);
        return Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.3),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.5),
                blurRadius: 20 * scale,
                spreadRadius: 2 * scale,
              )
            ],
          ),
          child: Center(
            child: Icon(Icons.circle_outlined, color: Theme.of(context).colorScheme.primary, size: 36),
          ),
        );
      },
    );
  }
}
