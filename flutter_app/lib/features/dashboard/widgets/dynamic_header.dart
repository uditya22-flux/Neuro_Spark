import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sdui_controller.dart';

class DynamicHeader extends ConsumerWidget {
  const DynamicHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sduiState = ref.watch(sduiControllerProvider);
    final profile = sduiState.profile;
    final interest = profile.interests.primaryHyperFixation.toLowerCase();
    final isAac = sduiState.isAacMode;

    String greeting = "Welcome back, ${profile.userProfile.name}!";
    String subtitle = "Let's explore today.";
    IconData interestIcon = Icons.star;
    Color iconColor = Theme.of(context).colorScheme.primary;
    
    // Customize based on hyper-fixation
    if (interest.contains('space')) {
      greeting = "Greetings Space Captain ${profile.userProfile.name}!";
      subtitle = "Mission Specialization: Space Exploration";
      interestIcon = Icons.rocket_launch_rounded;
      iconColor = const Color(0xFF6E8B7E);
    } else if (interest.contains('dino')) {
      greeting = "Hello Paleontologist ${profile.userProfile.name}!";
      subtitle = "Current Excavation Site active";
      interestIcon = Icons.grass_rounded;
      iconColor = const Color(0xFF5B8CAE);
    } else if (interest.contains('train')) {
      greeting = "Welcome aboard Chief Conductor ${profile.userProfile.name}!";
      subtitle = "Departing Platform 3: Trains & Railways";
      interestIcon = Icons.train_rounded;
      iconColor = const Color(0xFFC85A32);
    } else if (interest.contains('marine')) {
      greeting = "Ahoy Marine Biologist ${profile.userProfile.name}!";
      subtitle = "Exploring the Deep Indigo Trench";
      interestIcon = Icons.water_rounded;
      iconColor = const Color(0xFF5C6BC0);
    } else if (interest.contains('logic') || interest.contains('coding')) {
      greeting = "Terminal: Input verified (User: ${profile.userProfile.name})";
      subtitle = "System: Logic Block Coding compiler ready";
      interestIcon = Icons.terminal_rounded;
      iconColor = const Color(0xFFFBBF24);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Adaptive Icon Avatar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.15),
              border: Border.all(
                color: iconColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              interestIcon,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 20),
          // Adaptive Narrative Header
          Expanded(
            child: isAac
                ? Row(
                    children: [
                      _buildPictogram(Icons.face_rounded, "User Profile"),
                      const SizedBox(width: 8),
                      _buildPictogram(Icons.waving_hand_rounded, "Waving Welcome"),
                      const SizedBox(width: 8),
                      _buildPictogram(interestIcon, "Hyper-fixation Theme"),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPictogram(IconData icon, String semanticLabel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Icon(
        icon,
        size: 30,
        color: Colors.white,
      ),
    );
  }
}
