import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exploration_models.dart';

/// Dedicated, word-free play interactions for the non-audio social/creative
/// Layer 1 mechanics. The board deliberately reports only a selected option
/// back to the existing telemetry pipeline; it never exposes a score or an
/// interpretation to the player.
class SocialCreativeInteractionBoard extends StatefulWidget {
  const SocialCreativeInteractionBoard({
    super.key,
    required this.task,
    required this.highlightTarget,
    required this.onChoice,
  });

  final PuzzleSpec task;
  final bool highlightTarget;
  final FutureOr<bool> Function(String choice) onChoice;

  static bool supports(PlayMechanic mechanic) => switch (mechanic) {
        PlayMechanic.emotionRecognition ||
        PlayMechanic.perspectiveTaking ||
        PlayMechanic.turnTakingStrategy ||
        PlayMechanic.visualArtisticComposition =>
          true,
        _ => false,
      };

  @override
  State<SocialCreativeInteractionBoard> createState() =>
      _SocialCreativeInteractionBoardState();
}

class _SocialCreativeInteractionBoardState
    extends State<SocialCreativeInteractionBoard> {
  bool _busy = false;
  Timer? _choiceSettleTimer;
  String? _draftChoice;
  final Set<int> _placedPieces = <int>{};
  final Set<int> _occupiedCells = <int>{};
  int _childTurns = 0;

  PlayMechanic get _mechanic => widget.task.mechanics.single;
  Color get _accent => Theme.of(context).colorScheme.primary;

  static const _choiceSettleWindow = Duration(milliseconds: 1500);

  void _choose(String option) {
    if (_busy) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _draftChoice = option);
    _choiceSettleTimer?.cancel();
    _choiceSettleTimer = Timer(_choiceSettleWindow, _submitDraftChoice);
  }

  Future<void> _submitDraftChoice() async {
    if (!mounted || _busy || _draftChoice == null) return;
    final choice = _draftChoice!;
    setState(() => _busy = true);
    final advanced = await widget.onChoice(choice);
    if (!mounted || advanced) return;
    setState(() => _busy = false);
  }

  @override
  void dispose() {
    _choiceSettleTimer?.cancel();
    super.dispose();
  }

  void _completeGentleComposition() => _choose(widget.task.correctOption);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                _accent.withValues(alpha: widget.highlightTarget ? .90 : .30),
            width: widget.highlightTarget ? 3 : 1.5,
          ),
        ),
        child: switch (_mechanic) {
          PlayMechanic.emotionRecognition => _emotionBoard(),
          PlayMechanic.perspectiveTaking => _perspectiveBoard(),
          PlayMechanic.turnTakingStrategy => _turnBoard(),
          PlayMechanic.visualArtisticComposition => _compositionBoard(),
          _ => const SizedBox.shrink(),
        },
      );

  Widget _emotionBoard() {
    const faces = [
      Icons.sentiment_very_satisfied_rounded,
      Icons.sentiment_neutral_rounded,
      Icons.sentiment_dissatisfied_rounded,
      Icons.sentiment_very_dissatisfied_rounded,
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Icon(Icons.face_rounded,
            size: 108, color: _accent.withValues(alpha: .72)),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: List<Widget>.generate(faces.length, (index) {
            final option = _optionAt(index);
            return _TouchTile(
              onTap: () => _choose(option),
              child: Icon(faces[index], size: 52, color: _tone(index)),
            );
          }),
        ),
      ],
    );
  }

  Widget _perspectiveBoard() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_rounded, size: 68, color: _accent),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward_rounded, size: 34),
              ),
              Icon(Icons.toys_rounded, size: 68, color: _tone(1)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(3, (index) {
              final icons = [
                Icons.volunteer_activism_rounded,
                Icons.sentiment_satisfied_alt_rounded,
                Icons.directions_run_rounded,
              ];
              return _TouchTile(
                onTap: () => _choose(_optionAt(index)),
                child: Icon(icons[index], size: 54, color: _tone(index)),
              );
            }),
          ),
        ],
      );

  Widget _turnBoard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _turnToken(Icons.circle_outlined, _accent),
            const SizedBox(width: 40),
            _turnToken(Icons.close_rounded, _tone(1)),
          ],
        ),
        SizedBox(
          width: 210,
          height: 210,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final occupied = _occupiedCells.contains(index);
              return GestureDetector(
                onTap: occupied || _busy ? null : () => _playTurn(index),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .56),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: .28)),
                  ),
                  child: occupied
                      ? Icon(
                          _childTurns.isOdd
                              ? Icons.circle_outlined
                              : Icons.close_rounded,
                          color: _tone(index),
                          size: 42,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playTurn(int index) {
    if (_busy) return;
    setState(() {
      _occupiedCells.add(index);
      _childTurns += 1;
      final reply = List<int>.generate(9, (cell) => cell).firstWhere(
          (cell) => !_occupiedCells.contains(cell),
          orElse: () => -1);
      if (reply >= 0 && _childTurns < 3) _occupiedCells.add(reply);
    });
    // A short turn exchange is the complete response. The final choice is
    // settled briefly before the next activity so it never waits for a hidden
    // perfect move, while still allowing a real turn-taking interaction.
    if (_childTurns >= 3 || _occupiedCells.length == 9) {
      _choose(widget.task.correctOption);
    }
  }

  Widget _compositionBoard() => Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List<Widget>.generate(4, (index) {
              final placed = _placedPieces.contains(index);
              return DragTarget<int>(
                onAcceptWithDetails: (details) {
                  if (_busy) return;
                  setState(() => _placedPieces.add(details.data));
                  if (_placedPieces.length >= 4) {
                    // This is open-ended composition. Four placed pieces make
                    // a complete response; the quiet settle window leaves a
                    // moment for the child to see and adjust the composition.
                    _completeGentleComposition();
                  }
                },
                builder: (context, accepted, rejected) => Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: index.isEven ? BoxShape.circle : BoxShape.rectangle,
                    color: placed
                        ? _tone(index).withValues(alpha: .68)
                        : _tone(index)
                            .withValues(alpha: accepted.isNotEmpty ? .35 : .12),
                    borderRadius:
                        index.isEven ? null : BorderRadius.circular(16),
                    border: Border.all(color: _tone(index), width: 2),
                  ),
                ),
              );
            }),
          ),
          Wrap(
            spacing: 14,
            alignment: WrapAlignment.center,
            children: List<Widget>.generate(4, (index) {
              if (_placedPieces.contains(index)) {
                return const SizedBox(width: 48, height: 48);
              }
              return Draggable<int>(
                data: index,
                feedback: _piece(index, elevated: true),
                childWhenDragging: const SizedBox(width: 48, height: 48),
                child: _piece(index),
              );
            }),
          ),
        ],
      );

  Widget _piece(int index, {bool elevated = false}) => Material(
        color: Colors.transparent,
        elevation: elevated ? 8 : 0,
        shape: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _tone(index),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );

  Widget _turnToken(IconData icon, Color color) => Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withValues(alpha: .16)),
        child: Icon(icon, color: color, size: 34),
      );

  String _optionAt(int index) {
    final options = widget.task.options;
    if (index < options.length) return options[index];
    return widget.task.correctOption;
  }

  Color _tone(int index) {
    const colors = [
      Color(0xff5f7fa8),
      Color(0xff7a9f88),
      Color(0xffc69358),
      Color(0xffb4778f)
    ];
    return colors[index % colors.length];
  }
}

class _TouchTile extends StatelessWidget {
  const _TouchTile({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: .66),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(width: 82, height: 82, child: Center(child: child)),
        ),
      );
}
