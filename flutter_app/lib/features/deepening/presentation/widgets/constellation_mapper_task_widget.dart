import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/deepening_task_payload.dart';

class ConstellationMapperTaskWidget extends StatefulWidget {
  final DeepeningTaskPayload payload;
  final Function({
    required double accuracy,
    required String response,
    required int errorCount,
  }) onSubmit;
  final VoidCallback onHintTriggered;

  const ConstellationMapperTaskWidget({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onHintTriggered,
  });

  @override
  State<ConstellationMapperTaskWidget> createState() => _ConstellationMapperTaskWidgetState();
}

class _ConstellationMapperTaskWidgetState extends State<ConstellationMapperTaskWidget> {
  final Set<int> _connectedStarIds = {};
  int _errorCount = 0;

  Color _getPrimaryThemeColor() {
    switch (widget.payload.themeSkin) {
      case 'sage_green':
        return const Color(0xFF4A7C59);
      case 'pastel_dinosaur':
        return const Color(0xFF5B8CAE);
      case 'terracotta_train':
        return const Color(0xFFB34A23);
      case 'cosmic_space':
      default:
        return const Color(0xFF5C6BC0);
    }
  }

  void _handleToggleStar(int starId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_connectedStarIds.contains(starId)) {
        _connectedStarIds.remove(starId);
      } else {
        _connectedStarIds.add(starId);
      }
    });
  }

  void _handleCheckConstellation() {
    final requiredCount = widget.payload.taskData['required_stars'] as int? ?? 4;
    final isCorrect = _connectedStarIds.length == requiredCount;

    if (!isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Constellation pattern needs $requiredCount connected stars. Try again!'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final accuracy = _errorCount == 0 ? 1.0 : (1.0 / (_errorCount + 1));
    widget.onSubmit(
      accuracy: accuracy,
      response: 'connected_stars_${_connectedStarIds.join("_")}',
      errorCount: _errorCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getPrimaryThemeColor();
    final starCount = widget.payload.taskData['total_star_nodes'] as int? ?? 6;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome_rounded, color: themeColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constellation Mapper Task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                    ),
                    Text(
                      'Layer ${widget.payload.layer} of ${widget.payload.totalLayers}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.lightbulb_outline_rounded, color: themeColor),
                onPressed: widget.onHintTriggered,
                tooltip: 'Request Support Ladder Hint',
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            widget.payload.prompt,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          // Constellation star grid
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.2)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.spaceAround,
              children: List.generate(starCount, (index) {
                final isSelected = _connectedStarIds.contains(index);
                return GestureDetector(
                  onTap: () => _handleToggleStar(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? themeColor : themeColor.withOpacity(0.15),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: themeColor.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: isSelected ? Colors.white : themeColor,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _connectedStarIds.isNotEmpty ? _handleCheckConstellation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Submit Constellation Pattern',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
