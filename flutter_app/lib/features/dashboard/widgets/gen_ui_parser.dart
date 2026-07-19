import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenUiParser extends StatelessWidget {
  final Map<String, dynamic> schema;

  const GenUiParser({
    super.key,
    required this.schema,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'spa_rounded':
        return Icons.spa_rounded;
      case 'train_rounded':
        return Icons.train_rounded;
      case 'terrain_rounded':
        return Icons.terrain_rounded;
      case 'terminal_rounded':
        return Icons.terminal_rounded;
      case 'help_outline_rounded':
        return Icons.help_outline_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  void _handleAction(BuildContext context, String action) {
    try {
      if (action == 'trigger_vibration_tap') {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generative Haptic Feedback Triggered')),
        );
      } else if (action == 'play_chime') {
        SystemSound.play(SystemSoundType.click);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generative Audio Chime Triggered')),
        );
      }
    } catch (_) {}
  }

  Widget _buildNode(BuildContext context, Map<String, dynamic> node) {
    final type = node['type'] as String? ?? 'unknown';

    switch (type) {
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
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(opacity),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.5),
                blurRadius: 15 * scale,
                spreadRadius: 1 * scale,
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.circle_outlined, color: Colors.white70, size: 24),
          ),
        );
      },
    );
  }
}
