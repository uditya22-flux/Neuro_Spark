import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exploration_models.dart';
import '../models/visual_scene_spec.dart';
import '../services/synthetic_demo_scene_mapper.dart';
import 'non_audio_mechanic_board.dart';
import 'social_creative_interaction_board.dart';
import 'spatial_temporal_interaction_board.dart';

/// A deliberately word-free play surface. The top motif is the visual goal;
/// children respond by touching the matching picture below. No score, timer,
/// right/wrong marker, or written instruction is shown.
class AmbientPlayBoard extends StatefulWidget {
  const AmbientPlayBoard({
    super.key,
    required this.task,
    required this.scene,
    required this.highlightTarget,
    required this.onChoice,
    this.onInteraction,
  });

  final PuzzleSpec task;
  final VisualSceneSpec? scene;
  final bool highlightTarget;

  /// Returns `true` when the completed response advances to the next
  /// activity. A task may advance after either a correct or incorrect final
  /// response; it never waits for a hidden correct answer.
  final FutureOr<bool> Function(String choice) onChoice;

  /// Observes any touch or drag so the surrounding flow can reset its quiet
  /// inactivity timer without adding child-facing controls or text.
  final VoidCallback? onInteraction;

  @override
  State<AmbientPlayBoard> createState() => _AmbientPlayBoardState();
}

class _AmbientPlayBoardState extends State<AmbientPlayBoard> {
  static const _multiResponseMechanics = {
    PlayMechanic.visualSpatialConstruction,
    PlayMechanic.chronologicalSequencing,
    PlayMechanic.narrativeEventOrdering,
    PlayMechanic.rhythmicMotorSequencing,
    PlayMechanic.proceduralSequencing,
    PlayMechanic.multiAttributeSorting,
    PlayMechanic.creativeStorytelling,
    PlayMechanic.workingMemorySpan,
  };

  int? _selectedIndex;
  bool _submitting = false;
  Timer? _choiceSettleTimer;
  String? _draftChoice;

  static const _choiceSettleWindow = Duration(milliseconds: 1500);

  @override
  void didUpdateWidget(covariant AmbientPlayBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _choiceSettleTimer?.cancel();
      _selectedIndex = null;
      _submitting = false;
      _draftChoice = null;
    }
  }

  void _choose(List<String> options, int index) {
    if (_submitting) return;
    if (widget.task.preferHaptics) HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _stageChoice(options[index]);
  }

  void _stageChoice(String choice) {
    if (_submitting) return;
    _draftChoice = choice;
    _choiceSettleTimer?.cancel();
    _choiceSettleTimer = Timer(
      _choiceSettleWindow,
      _submitDraftChoice,
    );
  }

  /// Lets specialized one-response boards briefly settle a visual selection.
  /// Returning `false` leaves their surface ready for a revised choice while
  /// this board keeps only the latest opaque option for final submission.
  Future<bool> _stageDirectChoice(String choice) async {
    _stageChoice(choice);
    return false;
  }

  Future<void> _submitDraftChoice() async {
    final choice = _draftChoice;
    if (!mounted || _submitting || choice == null) {
      return;
    }
    setState(() => _submitting = true);
    final advanced = await widget.onChoice(choice);
    if (!mounted || advanced) return;

    // An unavailable cloud response keeps the board available for another
    // choice without exposing a failure state to the child.
    setState(() {
      _submitting = false;
      _selectedIndex = null;
      _draftChoice = null;
    });
  }

  bool _usesOwnResponseSettle(PuzzleSpec task) =>
      task.mechanics.length == 1 &&
      _multiResponseMechanics.contains(task.mechanics.single);

  @override
  void dispose() {
    _choiceSettleTimer?.cancel();
    super.dispose();
  }

  Widget _observeInteraction(Widget child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => widget.onInteraction?.call(),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final singleMechanic =
        task.mechanics.length == 1 ? task.mechanics.single : null;
    if (SpatialTemporalInteractionBoard.supports(task)) {
      return _observeInteraction(SpatialTemporalInteractionBoard(
        task: task,
        highlightTarget: widget.highlightTarget,
        onChoice:
            _usesOwnResponseSettle(task) ? widget.onChoice : _stageDirectChoice,
      ));
    }
    if (NonAudioMechanicBoard.supports(task)) {
      return _observeInteraction(NonAudioMechanicBoard(
        task: task,
        highlightTarget: widget.highlightTarget,
        onChoice:
            _usesOwnResponseSettle(task) ? widget.onChoice : _stageDirectChoice,
      ));
    }
    if (singleMechanic != null &&
        SocialCreativeInteractionBoard.supports(singleMechanic)) {
      return _observeInteraction(SocialCreativeInteractionBoard(
        key: ValueKey('social-creative-${task.id}'),
        task: task,
        highlightTarget: widget.highlightTarget,
        onChoice: widget.onChoice,
      ));
    }
    final scene = widget.scene;
    final options = _visibleOptions(task, scene?.itemCount ?? task.itemCount);
    final targetIndex = max(0, options.indexOf(task.correctOption));
    final plan = _resolvedPlan(
      task: task,
      scene: scene,
      optionCount: options.length,
      correctIndex: targetIndex,
    );
    final motif = _motifFor(task, scene);
    final animation =
        task.allowMotion ? (scene?.onTapAnimation ?? 'snap') : 'none';
    final sceneType =
        plan?.kind.wireName ?? scene?.sceneType ?? _sceneTypeFor(task);
    final tokenKind = plan?.kind ??
        visualPuzzleKindFromWire(sceneType) ??
        VisualPuzzleKind.match;
    final target = _PictureToken(
      variant: plan?.targetVariant ?? targetIndex,
      motif: motif,
      size: 94,
      style: scene?.objectStyle ?? task.visualStylePreference.name,
      repeated: task.visualRepetitionHelpful,
      kind: tokenKind,
      stimulus: plan?.stimulus ?? const [],
      rule: plan?.rule,
    );

    return _observeInteraction(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: motif.color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: motif.color
                  .withValues(alpha: widget.highlightTarget ? .95 : .32),
              width: widget.highlightTarget ? 4 : 2,
            ),
          ),
          child: _VisualStage(
            sceneType: sceneType,
            layout: scene?.layout ?? 'grid',
            motif: motif,
            target: target,
            plan: plan,
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var index = 0; index < options.length; index++)
              _GroundedPictureChoice(
                token: _PictureToken(
                  variant: plan?.choiceVariantAt(index) ?? index,
                  motif: motif,
                  size: 62,
                  style: scene?.objectStyle ?? task.visualStylePreference.name,
                  repeated: task.visualRepetitionHelpful,
                  kind: tokenKind,
                  stimulus: plan?.stimulus ?? const [],
                  rule: plan?.rule,
                ),
                color: motif.color,
                selected: _selectedIndex == index,
                animation: animation,
                interaction: task.interactionPreference,
                rule: plan?.rule,
                choiceIndex: index,
                onTap: () => _choose(options, index),
              ),
          ],
        ),
      ],
    ));
  }

  List<String> _visibleOptions(PuzzleSpec task, int requestedCount) {
    final visible = task.options
        .take(requestedCount.clamp(1, task.options.length).toInt())
        .toList();
    if (visible.isNotEmpty && !visible.contains(task.correctOption)) {
      visible[visible.length - 1] = task.correctOption;
    }
    return visible;
  }

  VisualPuzzlePlan? _resolvedPlan({
    required PuzzleSpec task,
    required VisualSceneSpec? scene,
    required int optionCount,
    required int correctIndex,
  }) {
    if (task.mechanics.length != 1) return null;
    final mechanic = task.mechanics.single;
    // Builder/offline sessions deliberately use a local, bounded plan rather
    // than falling back to one generic colour choice. Every Layer 1 mechanic
    // therefore retains its own rule, visual trace, and interaction grammar.
    final source =
        scene?.puzzlePlan ?? VisualPuzzlePlan.localForMechanic(mechanic);
    return source.resolveFor(
      sector: mechanic,
      optionCount: optionCount,
      correctIndex: correctIndex,
    );
  }

  String _sceneTypeFor(PuzzleSpec task) {
    if (task.mechanics.length != 1) return 'match';
    return visualPuzzleKindForMechanic(task.mechanics.single).wireName;
  }

  _VisualMotif _motifFor(PuzzleSpec task, VisualSceneSpec? scene) {
    final localWorld = SyntheticDemoSceneMapper.fromIntakeText(
      theme: task.visualThemeKey,
      favouriteObjects: '',
      familiarScenes: '',
    );
    final theme = (scene?.subject ?? localWorld.name).toLowerCase();
    final palette = scene?.palette.isNotEmpty == true
        ? scene!.palette.map(_colorForName).toList(growable: false)
        : task.familiarColors.isEmpty
            ? const [Color(0xff5270a2), Color(0xffd76b5e), Color(0xffe3ad45)]
            : task.familiarColors.map(_colorFor).toList(growable: false);
    final color = palette.first;
    if (theme.contains('car') ||
        theme.contains('vehicle') ||
        theme.contains('road')) {
      return _VisualMotif(Icons.directions_car_rounded, color, palette);
    }
    if (theme.contains('train') || theme.contains('rail')) {
      return _VisualMotif(Icons.train_rounded, color, palette);
    }
    if (theme.contains('space') ||
        theme.contains('planet') ||
        theme.contains('rocket')) {
      return _VisualMotif(Icons.rocket_launch_rounded, color, palette);
    }
    if (theme.contains('animal') ||
        theme.contains('dinosaur') ||
        theme.contains('pet')) {
      return _VisualMotif(Icons.pets_rounded, color, palette);
    }
    if (theme.contains('tool') ||
        theme.contains('build') ||
        theme.contains('plumb')) {
      return _VisualMotif(Icons.build_rounded, color, palette);
    }
    if (theme.contains('sea') ||
        theme.contains('water') ||
        theme.contains('ocean')) {
      return _VisualMotif(Icons.waves_rounded, color, palette);
    }
    if (theme.contains('tree') ||
        theme.contains('nature') ||
        theme.contains('garden')) {
      return _VisualMotif(Icons.park_rounded, color, palette);
    }
    return _VisualMotif(Icons.auto_awesome_rounded, color, palette);
  }

  Color _colorFor(FamiliarColor color) => switch (color) {
        FamiliarColor.red => const Color(0xffc95c54),
        FamiliarColor.orange => const Color(0xffd7873e),
        FamiliarColor.yellow => const Color(0xffc89c2e),
        FamiliarColor.green => const Color(0xff4e7a5d),
        FamiliarColor.blue => const Color(0xff5270a2),
        FamiliarColor.purple => const Color(0xff7b609c),
        FamiliarColor.pink => const Color(0xffb56483),
      };

  Color _colorForName(String color) => switch (color) {
        'red' => const Color(0xffc95c54),
        'orange' => const Color(0xffd7873e),
        'yellow' => const Color(0xffc89c2e),
        'green' => const Color(0xff4e7a5d),
        'purple' => const Color(0xff7b609c),
        'pink' => const Color(0xffb56483),
        'silver' => const Color(0xff77818c),
        _ => const Color(0xff5270a2),
      };
}

/// A small set of grounded visual layouts keeps the thirty mechanic prompts
/// visually distinct without placing any text, timers, or score language in
/// the play surface. The interaction remains predictable: find the picture
/// that belongs in the highlighted scene above.
class _VisualStage extends StatelessWidget {
  const _VisualStage({
    required this.sceneType,
    required this.layout,
    required this.motif,
    required this.target,
    required this.plan,
  });

  final String sceneType;
  final String layout;
  final _VisualMotif motif;
  final Widget target;
  final VisualPuzzlePlan? plan;

  Widget _stage() {
    final accent = motif.color;
    final kind = plan?.kind ??
        visualPuzzleKindFromWire(sceneType) ??
        VisualPuzzleKind.match;
    final values = plan?.stimulus.isNotEmpty == true
        ? plan!.stimulus
        : List<int>.generate(
            3, (index) => ((plan?.variant ?? 0) + index + 1) % 16);
    final rule = plan?.rule;
    final baseStage = switch (sceneType) {
      'sequence' => _SequenceStage(target: target, accent: accent),
      'route' || 'connect' => _RouteStage(target: target, accent: accent),
      'rotate' => _RotationStage(target: target, accent: accent),
      'distance' => _DistanceStage(target: target, accent: accent),
      'pattern' => _PatternStage(target: target, colors: motif.palette),
      'sort' => _SortStage(target: target, accent: accent),
      'quantity' => _QuantityStage(target: target, colors: motif.palette),
      'shape' => _ShapeStage(target: target, accent: accent),
      'search' => _SearchStage(target: target, accent: accent),
      'memory' => _MemoryStage(target: target, accent: accent),
      'repair' => _RepairStage(target: target, accent: accent),
      'precision' => _PrecisionStage(target: target, accent: accent),
      'rhythm' => _RhythmStage(target: target, colors: motif.palette),
      'switch' => _SwitchStage(target: target, accent: accent),
      _ => Center(child: target),
    };
    final stage = rule != null && _RuleVisualStage.supports(rule)
        ? _RuleVisualStage(
            rule: rule,
            motif: motif,
            values: values,
            target: target,
          )
        : baseStage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rule == null || !_RuleVisualStage.supports(rule)) ...[
          _StageStimulusTrace(
            kind: kind,
            values: values,
            palette: motif.palette,
            accent: accent,
            rule: rule,
          ),
          const SizedBox(height: 12),
        ],
        stage,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage();
    return switch (layout) {
      'leftToRight' => Align(alignment: Alignment.centerLeft, child: stage),
      'path' => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 250,
              height: 5,
              decoration: BoxDecoration(
                color: motif.color.withValues(alpha: .24),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            stage,
          ],
        ),
      _ => Center(child: stage),
    };
  }
}

/// A fixed visual grammar for the complete 30-sector Layer 1 array. These
/// scenes remain entirely picture-based: they never expose a label, timer,
/// rank, or interpretation to the player. The themed motif is a skin only;
/// the layout is what makes a route, rhythm, sequence, matrix, memory grid,
/// or composition activity visibly different.
class _RuleVisualStage extends StatelessWidget {
  const _RuleVisualStage({
    required this.rule,
    required this.motif,
    required this.values,
    required this.target,
  });

  final VisualPuzzleRule rule;
  final _VisualMotif motif;
  final List<int> values;
  final Widget target;

  static bool supports(VisualPuzzleRule rule) => switch (rule) {
        VisualPuzzleRule.matchMentalRotation ||
        VisualPuzzleRule.completeVisualPattern ||
        VisualPuzzleRule.detectPointCloudAnomaly ||
        VisualPuzzleRule.navigateMapRoute ||
        VisualPuzzleRule.reconstructSpatialTarget ||
        VisualPuzzleRule.orderPictureCycle ||
        VisualPuzzleRule.orderStoryPanels ||
        VisualPuzzleRule.chooseEffect ||
        VisualPuzzleRule.repeatRhythm ||
        VisualPuzzleRule.orderProcedureIcons ||
        VisualPuzzleRule.completeQuantityPattern ||
        VisualPuzzleRule.discoverVisualRule ||
        VisualPuzzleRule.sortMultipleAttributes ||
        VisualPuzzleRule.findSharedProperty ||
        VisualPuzzleRule.chooseLargerDotCloud ||
        VisualPuzzleRule.matchPictureAssociation ||
        VisualPuzzleRule.matchPhonologicalPattern ||
        VisualPuzzleRule.chooseStoryNext ||
        VisualPuzzleRule.completePictureAnalogy ||
        VisualPuzzleRule.arrangeStoryPanels ||
        VisualPuzzleRule.replayCellSequence ||
        VisualPuzzleRule.findSceneChange ||
        VisualPuzzleRule.identifyTargetStream ||
        VisualPuzzleRule.replayToneSequence ||
        VisualPuzzleRule.findSelectiveTarget ||
        VisualPuzzleRule.matchEmotionIcon ||
        VisualPuzzleRule.choosePerspectiveOutcome ||
        VisualPuzzleRule.chooseTurnStrategy ||
        VisualPuzzleRule.matchMelodyPattern ||
        VisualPuzzleRule.completeVisualComposition =>
          true,
        _ => false,
      };

  List<int> get _values => values.isEmpty ? const [2, 5, 8, 11] : values;
  List<Color> get _palette =>
      motif.palette.isEmpty ? const [Color(0xff5270a2)] : motif.palette;
  Color _color(int index, {double alpha = 1}) =>
      _palette[_values[index % _values.length] % _palette.length]
          .withValues(alpha: alpha);

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: ValueKey('visual-rule-${rule.name}'),
        child: SizedBox(
          height: 172,
          child: Center(child: _content()),
        ),
      );

  Widget _content() {
    switch (rule) {
      // Spatial / visual ----------------------------------------------------
      case VisualPuzzleRule.matchMentalRotation:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _color(0, alpha: .45), width: 2)),
            ),
            Transform.rotate(
              angle: .78,
              child: Icon(Icons.change_history_rounded,
                  color: _color(1, alpha: .52), size: 88),
            ),
            const Positioned(
                top: 8, child: Icon(Icons.rotate_right_rounded, size: 25)),
            _slot(),
          ],
        );
      case VisualPuzzleRule.completeVisualPattern:
        return _matrix(
          columns: 3,
          cells: List<Widget>.generate(
            9,
            (index) => index == 7
                ? _slot(size: 43)
                : _tile(index, rounded: index.isEven),
          ),
        );
      case VisualPuzzleRule.detectPointCloudAnomaly:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 206,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 13,
                runSpacing: 12,
                children: List<Widget>.generate(
                  18,
                  (index) => Icon(
                    index == 11 ? Icons.circle_outlined : Icons.circle,
                    color: _color(index, alpha: index == 11 ? .96 : .46),
                    size: index == 11 ? 22 : 12,
                  ),
                ),
              ),
            ),
            _slot(size: 48),
          ],
        );
      case VisualPuzzleRule.navigateMapRoute:
        return _routeMap();
      case VisualPuzzleRule.reconstructSpatialTarget:
        return _matrix(
          columns: 2,
          cells: [
            _puzzlePiece(0),
            _puzzlePiece(1),
            _puzzlePiece(2),
            _slot(size: 54),
          ],
        );

      // Temporal / sequential ---------------------------------------------
      case VisualPuzzleRule.orderPictureCycle:
        return _timeline([
          _panel(Icons.eco_rounded, 0),
          _panel(Icons.local_florist_rounded, 1),
          _slot(size: 52),
        ]);
      case VisualPuzzleRule.orderStoryPanels:
        return _timeline([
          _panel(Icons.directions_walk_rounded, 0),
          _panel(motif.icon, 1),
          _slot(size: 52),
        ]);
      case VisualPuzzleRule.chooseEffect:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _panel(Icons.play_arrow_rounded, 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child:
                  Icon(Icons.arrow_forward_rounded, color: _color(1), size: 34),
            ),
            _slot(size: 60),
          ],
        );
      case VisualPuzzleRule.repeatRhythm:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bars(5, outlinedAt: 3),
            const SizedBox(height: 16),
            _slot(size: 54),
          ],
        );
      case VisualPuzzleRule.orderProcedureIcons:
        return _timeline([
          _panel(Icons.water_drop_rounded, 0),
          _panel(Icons.brush_rounded, 1),
          _slot(size: 52),
        ]);

      // Numeric / logical --------------------------------------------------
      case VisualPuzzleRule.completeQuantityPattern:
        return _timeline([
          _dotGroup(1, 0),
          _dotGroup(2, 1),
          _dotGroup(3, 2),
          _slot(size: 52),
        ]);
      case VisualPuzzleRule.discoverVisualRule:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pair(0, shape: BoxShape.circle),
            const SizedBox(width: 14),
            _pair(1, shape: BoxShape.rectangle),
            const SizedBox(width: 14),
            _slot(size: 52),
          ],
        );
      case VisualPuzzleRule.sortMultipleAttributes:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bin(0, BoxShape.circle),
            const SizedBox(width: 12),
            _slot(size: 54),
            const SizedBox(width: 12),
            _bin(1, BoxShape.rectangle),
          ],
        );
      case VisualPuzzleRule.findSharedProperty:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sharedCluster(0),
            const SizedBox(width: 16),
            _sharedCluster(1),
            const SizedBox(width: 16),
            _slot(size: 52),
          ],
        );
      case VisualPuzzleRule.chooseLargerDotCloud:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dotGroup(3, 0),
            const SizedBox(width: 24),
            _dotGroup(6, 1),
            const SizedBox(width: 16),
            _slot(size: 46),
          ],
        );

      // Wordless language / meaning proxies -------------------------------
      case VisualPuzzleRule.matchPictureAssociation:
        return _linkedPanels(Icons.home_rounded, Icons.key_rounded);
      case VisualPuzzleRule.matchPhonologicalPattern:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _panel(Icons.volume_up_rounded, 0),
            const SizedBox(width: 10),
            _bars(3),
            const SizedBox(width: 12),
            _slot(size: 54),
          ],
        );
      case VisualPuzzleRule.chooseStoryNext:
        return _timeline([
          _panel(Icons.wb_sunny_rounded, 0),
          _panel(motif.icon, 1),
          _slot(size: 58),
        ]);
      case VisualPuzzleRule.completePictureAnalogy:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _panel(Icons.pets_rounded, 0),
            Icon(Icons.arrow_forward_rounded, color: _color(0), size: 26),
            _panel(Icons.home_rounded, 1),
            const SizedBox(width: 10),
            _panel(Icons.bug_report_rounded, 2),
            Icon(Icons.arrow_forward_rounded, color: _color(1), size: 26),
            _slot(size: 48),
          ],
        );
      case VisualPuzzleRule.arrangeStoryPanels:
        return _timeline([
          _panel(Icons.flag_rounded, 0),
          _slot(size: 52),
          _panel(Icons.celebration_rounded, 2),
        ]);

      // Memory / attention -------------------------------------------------
      case VisualPuzzleRule.replayCellSequence:
        return _matrix(
          columns: 3,
          cells: List<Widget>.generate(
            9,
            (index) => _tile(index,
                highlighted: const {0, 4, 7}.contains(index), rounded: true),
          )..[8] = _slot(size: 38),
        );
      case VisualPuzzleRule.findSceneChange:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scenePanel(0, changed: false),
            const SizedBox(width: 14),
            _scenePanel(1, changed: true),
            const SizedBox(width: 12),
            _slot(size: 48),
          ],
        );
      case VisualPuzzleRule.identifyTargetStream:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _movingStream(targetAt: 4),
            const SizedBox(height: 14),
            _slot(size: 50),
          ],
        );
      case VisualPuzzleRule.replayToneSequence:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up_rounded, color: _color(0), size: 28),
            const SizedBox(height: 8),
            _bars(4),
            const SizedBox(height: 12),
            _slot(size: 46),
          ],
        );
      case VisualPuzzleRule.findSelectiveTarget:
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 190,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: List<Widget>.generate(
                  15,
                  (index) => Icon(
                    index == 9
                        ? Icons.star_rounded
                        : Icons.change_history_rounded,
                    color: _color(index, alpha: index == 9 ? .95 : .34),
                    size: index == 9 ? 24 : 16,
                  ),
                ),
              ),
            ),
            _slot(size: 42),
          ],
        );

      // Social-emotional / creative play ----------------------------------
      case VisualPuzzleRule.matchEmotionIcon:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _panel(Icons.sentiment_satisfied_alt_rounded, 0),
            const SizedBox(width: 14),
            _slot(size: 58),
            const SizedBox(width: 14),
            _panel(Icons.sentiment_neutral_rounded, 1),
          ],
        );
      case VisualPuzzleRule.choosePerspectiveOutcome:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_rounded, color: _color(0), size: 44),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: _color(1), size: 28),
            const SizedBox(width: 12),
            _panel(motif.icon, 2),
            const SizedBox(width: 12),
            _slot(size: 50),
          ],
        );
      case VisualPuzzleRule.chooseTurnStrategy:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                5,
                (index) => Container(
                  width: 25,
                  height: 25,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                      color: _color(index, alpha: index.isEven ? .82 : .38),
                      shape: BoxShape.circle),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _slot(size: 50),
          ],
        );
      case VisualPuzzleRule.matchMelodyPattern:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.music_note_rounded,
                      color: _color(index), size: 18 + (index % 3) * 8),
                ),
              ),
            ),
            const SizedBox(height: 13),
            _slot(size: 50),
          ],
        );
      case VisualPuzzleRule.completeVisualComposition:
        return _matrix(
          columns: 3,
          cells: List<Widget>.generate(
            9,
            (index) => index == 4
                ? _slot(size: 40)
                : _tile(index,
                    rounded: index % 3 == 1, highlighted: index.isEven),
          ),
        );

      default:
        return _slot();
    }
  }

  Widget _slot({double size = 56}) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: motif.color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(size * .24),
          border:
              Border.all(color: motif.color.withValues(alpha: .58), width: 2),
        ),
        child: FittedBox(child: target),
      );

  Widget _tile(int index, {bool rounded = false, bool highlighted = false}) =>
      Container(
        width: 37,
        height: 37,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color(index, alpha: highlighted ? .78 : .25),
          borderRadius: BorderRadius.circular(rounded ? 18 : 5),
          border: Border.all(color: _color(index, alpha: .7)),
        ),
        child: index % 3 == 0
            ? Icon(motif.icon, color: _color(index), size: 17)
            : null,
      );

  Widget _matrix({required int columns, required List<Widget> cells}) =>
      SizedBox(
        width: columns * 51.0,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: cells,
        ),
      );

  Widget _puzzlePiece(int index) => Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color(index, alpha: .32),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(index.isEven ? 26 : 8),
            bottomRight: Radius.circular(index.isEven ? 8 : 26),
          ),
          border: Border.all(color: _color(index), width: 2),
        ),
        child: Icon(motif.icon, color: _color(index), size: 26),
      );

  Widget _timeline(List<Widget> children) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    color: _color(index, alpha: .58), size: 22),
              ),
          ],
        ],
      );

  Widget _panel(IconData icon, int index) => Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color(index, alpha: .17),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _color(index, alpha: .62)),
        ),
        child: Icon(icon, color: _color(index), size: 29),
      );

  Widget _bars(int count, {int? outlinedAt}) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(
          count,
          (index) => Container(
            width: 13,
            height: 18 + ((_values[index % _values.length] + index) % 4) * 10.0,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: outlinedAt == index
                  ? Colors.transparent
                  : _color(index, alpha: .78),
              border: Border.all(color: _color(index)),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      );

  Widget _dotGroup(int count, int index) => SizedBox(
        width: 58,
        height: 58,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: List<Widget>.generate(
            count,
            (dot) => Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                  color: _color(index + dot, alpha: .8),
                  shape: BoxShape.circle),
            ),
          ),
        ),
      );

  Widget _pair(int index, {required BoxShape shape}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          2,
          (offset) => Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
                color: _color(index + offset, alpha: .7), shape: shape),
          ),
        ),
      );

  Widget _bin(int index, BoxShape shape) => Container(
        width: 54,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color(index, alpha: .12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _color(index, alpha: .62), width: 2),
        ),
        child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: _color(index), shape: shape)),
      );

  Widget _sharedCluster(int index) => SizedBox(
        width: 58,
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in const [
              Offset(-15, -8),
              Offset(15, -8),
              Offset(0, 15)
            ])
              Transform.translate(
                offset: offset,
                child: Icon(motif.icon,
                    color: _color(index, alpha: .76), size: 24),
              ),
          ],
        ),
      );

  Widget _linkedPanels(IconData left, IconData right) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _panel(left, 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.link_rounded, color: _color(1), size: 25),
          ),
          _panel(right, 1),
          const SizedBox(width: 14),
          _slot(size: 52),
        ],
      );

  Widget _scenePanel(int index, {required bool changed}) => Container(
        width: 70,
        height: 68,
        decoration: BoxDecoration(
          color: _color(index, alpha: .10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color(index, alpha: .48)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(motif.icon, color: _color(index, alpha: .74), size: 34),
            if (changed)
              const Positioned(
                  right: 8, top: 7, child: Icon(Icons.star_rounded, size: 16)),
          ],
        ),
      );

  Widget _movingStream({required int targetAt}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          7,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index == targetAt ? Icons.star_rounded : Icons.circle,
              color: _color(index, alpha: index == targetAt ? .95 : .32),
              size: index == targetAt ? 25 : 14,
            ),
          ),
        ),
      );

  Widget _routeMap() => SizedBox(
        width: 214,
        height: 134,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
                left: 16,
                bottom: 22,
                child: Icon(motif.icon, color: _color(0), size: 32)),
            Positioned(
                right: 16,
                top: 19,
                child: Icon(Icons.flag_rounded, color: _color(2), size: 30)),
            Container(
              width: 164,
              height: 91,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _color(1, alpha: .48), width: 3),
              ),
            ),
            Positioned(
              left: 47,
              bottom: 36,
              child:
                  Container(width: 84, height: 4, color: _color(0, alpha: .64)),
            ),
            Positioned(
              right: 44,
              top: 34,
              child:
                  Container(width: 4, height: 49, color: _color(1, alpha: .64)),
            ),
            _slot(size: 46),
          ],
        ),
      );
}

/// The server-issued numeric stimulus appears here as a fixed visual trace.
/// It makes the goal card and its options part of a real sequence, route,
/// pattern, quantity, or repair scene instead of a generic themed backdrop.
/// No text or arbitrary server drawing commands are accepted.
class _StageStimulusTrace extends StatelessWidget {
  const _StageStimulusTrace({
    required this.kind,
    required this.values,
    required this.palette,
    required this.accent,
    required this.rule,
  });

  final VisualPuzzleKind kind;
  final List<int> values;
  final List<Color> palette;
  final Color accent;
  final VisualPuzzleRule? rule;

  List<int> get _values => values.isEmpty ? const [1, 2, 3] : values;

  Color _color(int value) =>
      palette[(value + (rule?.index ?? 0)) % palette.length];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Center(child: _trace()),
      );

  Widget _trace() {
    switch (kind) {
      case VisualPuzzleKind.sequence:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < _values.length; index++) ...[
              _TraceToken(color: _color(_values[index]), value: _values[index]),
              if (index < _values.length - 1)
                Icon(Icons.arrow_forward_rounded,
                    color: accent.withValues(alpha: .5), size: 18),
            ],
          ],
        );
      case VisualPuzzleKind.route:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _values
              .take(4)
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Transform.rotate(
                    angle: ((value % 4) * 1.57).toDouble(),
                    child: Icon(Icons.subdirectory_arrow_right_rounded,
                        color: _color(value), size: 28),
                  ),
                ),
              )
              .toList(growable: false),
        );
      case VisualPuzzleKind.rotate:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _values
              .take(4)
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Transform.rotate(
                    angle: ((value % 4) * 1.57).toDouble(),
                    child: Icon(Icons.navigation_rounded,
                        color: _color(value), size: 25),
                  ),
                ),
              )
              .toList(growable: false),
        );
      case VisualPuzzleKind.distance:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final value in _values.take(3)) ...[
              _GlyphDot(color: _color(value), size: 12),
              SizedBox(width: (8 + (value % 4) * 8).toDouble()),
            ],
          ],
        );
      case VisualPuzzleKind.pattern:
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: _values
              .take(5)
              .map(
                (value) => Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _color(value).withValues(alpha: .78),
                    borderRadius: BorderRadius.circular(value.isEven ? 10 : 3),
                  ),
                ),
              )
              .toList(growable: false),
        );
      case VisualPuzzleKind.sort:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TraceBin(color: _color(_values.first)),
            const SizedBox(width: 18),
            _TraceBin(color: _color(_values.last)),
          ],
        );
      case VisualPuzzleKind.quantity:
        {
          final count = (_values.first % 5) + 1;
          return SizedBox(
            width: 116,
            height: 42,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 5,
              children: List.generate(
                count,
                (index) => _GlyphDot(
                    color: _color(_values[index % _values.length]), size: 12),
              ),
            ),
          );
        }
      case VisualPuzzleKind.shape:
        {
          const shapes = [
            Icons.circle_outlined,
            Icons.change_history_rounded,
            Icons.square_outlined,
            Icons.hexagon_outlined,
          ];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: _values
                .take(4)
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(shapes[value % shapes.length],
                        color: _color(value), size: 25),
                  ),
                )
                .toList(growable: false),
          );
        }
      case VisualPuzzleKind.search:
        return _TraceSearch(
            color: accent, values: _values, palette: palette, reveal: true);
      case VisualPuzzleKind.memory:
        return _TraceSearch(
            color: accent, values: _values, palette: palette, reveal: false);
      case VisualPuzzleKind.repair:
        {
          final gap = _values.first % 4;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (index) => Container(
                width: 30,
                height: index == gap ? 4 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _color(_values[index % _values.length])
                      .withValues(alpha: index == gap ? .22 : .70),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }
      case VisualPuzzleKind.precision:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
                width: 112, height: 2, color: accent.withValues(alpha: .38)),
            Container(
                width: 2, height: 40, color: accent.withValues(alpha: .38)),
            Transform.translate(
              offset: Offset(((_values.first % 5 - 2) * 12).toDouble(), 0),
              child: _GlyphDot(color: _color(_values.first), size: 12),
            ),
          ],
        );
      case VisualPuzzleKind.rhythm:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _values
              .take(4)
              .map(
                (value) => Container(
                  width: 12,
                  height: (12 + (value % 4) * 8).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                      color: _color(value),
                      borderRadius: BorderRadius.circular(6)),
                ),
              )
              .toList(growable: false),
        );
      case VisualPuzzleKind.switching:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _values
              .take(4)
              .map(
                (value) => Transform.rotate(
                  angle: value.isEven ? 0 : 3.14,
                  child: Icon(Icons.swap_horiz_rounded,
                      color: _color(value), size: 28),
                ),
              )
              .toList(growable: false),
        );
      case VisualPuzzleKind.match:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: _values
              .take(3)
              .map((value) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _GlyphDot(color: _color(value), size: 16),
                  ))
              .toList(growable: false),
        );
    }
  }
}

class _TraceToken extends StatelessWidget {
  const _TraceToken({required this.color, required this.value});

  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(value.isEven ? 11 : 4),
        ),
      );
}

class _TraceBin extends StatelessWidget {
  const _TraceBin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          border: Border.all(color: color.withValues(alpha: .62), width: 2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
      );
}

class _TraceSearch extends StatelessWidget {
  const _TraceSearch({
    required this.color,
    required this.values,
    required this.palette,
    required this.reveal,
  });

  final Color color;
  final List<int> values;
  final List<Color> palette;
  final bool reveal;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 142,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Wrap(
              spacing: 11,
              runSpacing: 8,
              children: List.generate(
                8,
                (index) => _GlyphDot(
                  color: palette[(values[index % values.length] + index) %
                          palette.length]
                      .withValues(
                          alpha:
                              reveal && index == values.first % 8 ? .90 : .28),
                  size: 9,
                ),
              ),
            ),
            if (!reveal)
              Icon(Icons.visibility_rounded,
                  color: color.withValues(alpha: .66), size: 22),
          ],
        ),
      );
}

class _SequenceStage extends StatelessWidget {
  const _SequenceStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageDot(color: accent.withValues(alpha: .38)),
              _StageRail(color: accent),
              _StageDot(color: accent.withValues(alpha: .62)),
              _StageRail(color: accent),
              _StageDot(color: accent),
            ],
          ),
          const SizedBox(height: 14),
          target,
        ],
      );
}

class _RouteStage extends StatelessWidget {
  const _RouteStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 210,
            height: 118,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StageDot(color: accent.withValues(alpha: .30)),
                  _StageRail(color: accent),
                  const SizedBox(width: 18),
                  _StageRail(color: accent),
                  _StageDot(color: accent.withValues(alpha: .72)),
                ],
              ),
            ),
          ),
          target,
        ],
      );
}

class _RotationStage extends StatelessWidget {
  const _RotationStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: accent.withValues(alpha: .45), width: 2),
            ),
          ),
          Positioned(
              top: 2,
              child: Icon(Icons.refresh_rounded, color: accent, size: 22)),
          target,
        ],
      );
}

class _DistanceStage extends StatelessWidget {
  const _DistanceStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StageDot(color: accent),
              const SizedBox(width: 40),
              _StageDot(color: accent.withValues(alpha: .38)),
              const SizedBox(width: 18),
              _StageDot(color: accent.withValues(alpha: .72)),
            ],
          ),
          const SizedBox(height: 10),
          target,
        ],
      );
}

class _PatternStage extends StatelessWidget {
  const _PatternStage({required this.target, required this.colors});

  final Widget target;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: colors[index % colors.length]
                      .withValues(alpha: index == 4 ? .18 : .70),
                  borderRadius: BorderRadius.circular(index.isEven ? 10 : 3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          target,
        ],
      );
}

class _SortStage extends StatelessWidget {
  const _SortStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StageBay(color: accent.withValues(alpha: .25)),
          const SizedBox(width: 16),
          target,
          const SizedBox(width: 16),
          _StageBay(color: accent.withValues(alpha: .48)),
        ],
      );
}

class _QuantityStage extends StatelessWidget {
  const _QuantityStage({required this.target, required this.colors});

  final Widget target;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DotCluster(count: 2, color: colors.first),
              const SizedBox(width: 20),
              _DotCluster(count: 3, color: colors[colors.length > 1 ? 1 : 0]),
            ],
          ),
          const SizedBox(height: 8),
          target,
        ],
      );
}

class _ShapeStage extends StatelessWidget {
  const _ShapeStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 112,
            decoration: BoxDecoration(
              border:
                  Border.all(color: accent.withValues(alpha: .38), width: 3),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          target,
        ],
      );
}

class _SearchStage extends StatelessWidget {
  const _SearchStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 196,
            height: 118,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 14,
              children: List.generate(
                8,
                (index) => _StageDot(
                    color: accent.withValues(alpha: index == 5 ? .70 : .20)),
              ),
            ),
          ),
          target,
        ],
      );
}

class _MemoryStage extends StatelessWidget {
  const _MemoryStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 146,
            height: 120,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          target,
          Positioned(
            right: 14,
            top: 10,
            child: Icon(Icons.visibility_rounded,
                color: accent.withValues(alpha: .55), size: 20),
          ),
        ],
      );
}

class _RepairStage extends StatelessWidget {
  const _RepairStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
              left: 10,
              child: _StageRail(color: accent.withValues(alpha: .38))),
          Positioned(
              right: 10,
              child: _StageRail(color: accent.withValues(alpha: .38))),
          target,
        ],
      );
}

class _PrecisionStage extends StatelessWidget {
  const _PrecisionStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
              width: 150, height: 2, color: accent.withValues(alpha: .32)),
          Container(
              width: 2, height: 120, color: accent.withValues(alpha: .32)),
          target,
        ],
      );
}

class _RhythmStage extends StatelessWidget {
  const _RhythmStage({required this.target, required this.colors});

  final Widget target;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              4,
              (index) => Container(
                width: 14,
                height: 22 + index * 12.0,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: colors[index % colors.length].withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          target,
        ],
      );
}

class _SwitchStage extends StatelessWidget {
  const _SwitchStage({required this.target, required this.accent});

  final Widget target;
  final Color accent;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded, color: accent, size: 32),
          const SizedBox(height: 6),
          target,
        ],
      );
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _StageRail extends StatelessWidget {
  const _StageRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 5,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .56),
            borderRadius: BorderRadius.circular(4)),
      );
}

class _StageBay extends StatelessWidget {
  const _StageBay({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 74,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
      );
}

class _DotCluster extends StatelessWidget {
  const _DotCluster({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        height: 36,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: List.generate(
              count, (_) => _StageDot(color: color.withValues(alpha: .7))),
        ),
      );
}

class _VisualMotif {
  const _VisualMotif(this.icon, this.color, this.palette);

  final IconData icon;
  final Color color;
  final List<Color> palette;
}

class _PictureToken extends StatelessWidget {
  const _PictureToken({
    required this.variant,
    required this.motif,
    required this.size,
    required this.style,
    required this.repeated,
    required this.kind,
    required this.stimulus,
    required this.rule,
  });

  final int variant;
  final _VisualMotif motif;
  final double size;
  final String style;
  final bool repeated;
  final VisualPuzzleKind kind;
  final List<int> stimulus;
  final VisualPuzzleRule? rule;

  @override
  Widget build(BuildContext context) {
    final shapes = [
      BoxShape.circle,
      BoxShape.rectangle,
      BoxShape.circle,
      BoxShape.rectangle,
      BoxShape.circle
    ];
    final rotations = [-.18, .13, .0, -.08, .18];
    final colors = motif.palette;
    final safeVariant = variant.clamp(0, 15).toInt();
    final safeIndex = safeVariant % colors.length;
    final shapeIndex =
        (safeVariant + kind.index + (rule?.index ?? 0)) % shapes.length;
    final rotation = kind == VisualPuzzleKind.rotate
        ? [0.0, .25, .5, .75][safeVariant % 4]
        : rotations[shapeIndex];
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors[safeIndex].withValues(alpha: .20),
              shape: kind == VisualPuzzleKind.rotate
                  ? BoxShape.circle
                  : shapes[shapeIndex],
              borderRadius: kind == VisualPuzzleKind.rotate ||
                      shapes[shapeIndex] == BoxShape.circle
                  ? null
                  : BorderRadius.circular(20),
              border: Border.all(color: colors[safeIndex], width: 3),
            ),
            child: style == VisualStylePreference.simpleShapes.name &&
                    kind == VisualPuzzleKind.match &&
                    rule == null
                ? null
                : _TokenGlyph(
                    kind: kind,
                    motif: motif.icon,
                    color: colors[safeIndex],
                    palette: colors,
                    variant: safeVariant,
                    stimulus: stimulus,
                    rule: rule,
                    size: size,
                  ),
          ),
          if (repeated)
            Positioned(
              bottom: -8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                        color: colors[safeIndex], shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws a meaningful, word-free visual value for each choice. The themed
/// motif remains familiar (for example, vehicles), while the glyph changes
/// with the cognitive sector so a "car" world is not thirty copies of one
/// matching card.
class _TokenGlyph extends StatelessWidget {
  const _TokenGlyph({
    required this.kind,
    required this.motif,
    required this.color,
    required this.palette,
    required this.variant,
    required this.stimulus,
    required this.rule,
    required this.size,
  });

  final VisualPuzzleKind kind;
  final IconData motif;
  final Color color;
  final List<Color> palette;
  final int variant;
  final List<int> stimulus;
  final VisualPuzzleRule? rule;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * .50;
    final semanticIcon = _iconForRule(rule);
    if (semanticIcon != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(semanticIcon, color: color, size: iconSize),
          if (_usesMotifBadge(rule))
            Positioned(
              right: size * .08,
              bottom: size * .08,
              child: Icon(motif,
                  color: color.withValues(alpha: .62), size: iconSize * .38),
            ),
        ],
      );
    }
    switch (kind) {
      case VisualPuzzleKind.sequence:
        return _SequenceGlyph(color: color, variant: variant, size: size);
      case VisualPuzzleKind.route:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(motif, color: color, size: iconSize),
            Positioned(
              right: size * .10,
              top: size * .12,
              child: Transform.rotate(
                angle: ((variant % 4) * 1.57).toDouble(),
                child: Icon(Icons.arrow_upward_rounded,
                    color: color, size: size * .25),
              ),
            ),
          ],
        );
      case VisualPuzzleKind.rotate:
        return Icon(motif, color: color, size: iconSize);
      case VisualPuzzleKind.distance:
        return _DistanceGlyph(color: color, variant: variant, size: size);
      case VisualPuzzleKind.pattern:
        return _PatternGlyph(
          palette: palette,
          variant: variant,
          stimulus: stimulus,
          size: size,
        );
      case VisualPuzzleKind.sort:
        return _SortGlyph(palette: palette, variant: variant, size: size);
      case VisualPuzzleKind.quantity:
        return _QuantityGlyph(
          motif: motif,
          color: color,
          count: (variant % 5) + 1,
          size: size,
        );
      case VisualPuzzleKind.shape:
        return Icon(
          [
            Icons.circle_outlined,
            Icons.change_history_rounded,
            Icons.square_outlined,
            Icons.hexagon_outlined
          ][variant % 4],
          color: color,
          size: iconSize,
        );
      case VisualPuzzleKind.search:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(motif,
                color: color.withValues(alpha: .55), size: iconSize * .74),
            Icon(Icons.search_rounded, color: color, size: iconSize),
          ],
        );
      case VisualPuzzleKind.memory:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.visibility_rounded, color: color, size: iconSize),
            Positioned(
                bottom: size * .14,
                child: _GlyphDot(color: color, size: size * .10)),
          ],
        );
      case VisualPuzzleKind.repair:
        return Icon(Icons.build_circle_rounded, color: color, size: iconSize);
      case VisualPuzzleKind.precision:
        return Icon(Icons.gps_fixed_rounded, color: color, size: iconSize);
      case VisualPuzzleKind.rhythm:
        return _RhythmGlyph(color: color, variant: variant, size: size);
      case VisualPuzzleKind.switching:
        return Icon(Icons.swap_horiz_rounded, color: color, size: iconSize);
      case VisualPuzzleKind.match:
        return Icon(motif, color: color, size: iconSize);
    }
  }

  /// The word-free glyph is chosen from a fixed rule vocabulary. This makes
  /// a train/space/animal world a visual *skin*, rather than the mechanic
  /// itself: the same world can show a maze, dot cloud, panel sequence,
  /// musical pattern, or composition task.
  IconData? _iconForRule(VisualPuzzleRule? value) {
    switch (value) {
      case VisualPuzzleRule.matchMentalRotation:
        return Icons.rotate_right_rounded;
      case VisualPuzzleRule.completeVisualPattern:
      case VisualPuzzleRule.completeQuantityPattern:
        return Icons.grid_view_rounded;
      case VisualPuzzleRule.detectPointCloudAnomaly:
        return Icons.hub_rounded;
      case VisualPuzzleRule.navigateMapRoute:
        return Icons.alt_route_rounded;
      case VisualPuzzleRule.reconstructSpatialTarget:
        return Icons.extension_rounded;
      case VisualPuzzleRule.orderPictureCycle:
        return Icons.timeline_rounded;
      case VisualPuzzleRule.orderStoryPanels:
      case VisualPuzzleRule.chooseStoryNext:
      case VisualPuzzleRule.arrangeStoryPanels:
        return Icons.view_carousel_rounded;
      case VisualPuzzleRule.chooseEffect:
        return Icons.arrow_forward_rounded;
      case VisualPuzzleRule.repeatRhythm:
      case VisualPuzzleRule.matchPhonologicalPattern:
      case VisualPuzzleRule.replayToneSequence:
      case VisualPuzzleRule.matchMelodyPattern:
        return Icons.graphic_eq_rounded;
      case VisualPuzzleRule.orderProcedureIcons:
        return Icons.account_tree_rounded;
      case VisualPuzzleRule.discoverVisualRule:
        return Icons.rule_rounded;
      case VisualPuzzleRule.sortMultipleAttributes:
        return Icons.category_rounded;
      case VisualPuzzleRule.findSharedProperty:
        return Icons.hub_rounded;
      case VisualPuzzleRule.chooseLargerDotCloud:
        return Icons.bubble_chart_rounded;
      case VisualPuzzleRule.matchPictureAssociation:
        return Icons.link_rounded;
      case VisualPuzzleRule.completePictureAnalogy:
        return Icons.compare_arrows_rounded;
      case VisualPuzzleRule.replayCellSequence:
        return Icons.apps_rounded;
      case VisualPuzzleRule.findSceneChange:
        return Icons.visibility_rounded;
      case VisualPuzzleRule.identifyTargetStream:
      case VisualPuzzleRule.findSelectiveTarget:
        return Icons.center_focus_strong_rounded;
      case VisualPuzzleRule.matchEmotionIcon:
        return Icons.sentiment_satisfied_alt_rounded;
      case VisualPuzzleRule.choosePerspectiveOutcome:
        return Icons.remove_red_eye_rounded;
      case VisualPuzzleRule.chooseTurnStrategy:
        return Icons.shuffle_rounded;
      case VisualPuzzleRule.completeVisualComposition:
        return Icons.palette_rounded;
      case null:
      case VisualPuzzleRule.ascending:
      case VisualPuzzleRule.matchDuration:
      case VisualPuzzleRule.nextEvent:
      case VisualPuzzleRule.followRoute:
      case VisualPuzzleRule.matchRotation:
      case VisualPuzzleRule.matchDistance:
      case VisualPuzzleRule.repeatNext:
      case VisualPuzzleRule.completePattern:
      case VisualPuzzleRule.matchGroup:
      case VisualPuzzleRule.sortAttribute:
      case VisualPuzzleRule.matchQuantity:
      case VisualPuzzleRule.completePairs:
      case VisualPuzzleRule.matchShape:
      case VisualPuzzleRule.findHidden:
      case VisualPuzzleRule.findTarget:
      case VisualPuzzleRule.findChange:
      case VisualPuzzleRule.recallToken:
      case VisualPuzzleRule.followPath:
      case VisualPuzzleRule.triggerEffect:
      case VisualPuzzleRule.selectTool:
      case VisualPuzzleRule.dropTarget:
      case VisualPuzzleRule.tapTarget:
      case VisualPuzzleRule.pairSides:
      case VisualPuzzleRule.waitForTurn:
      case VisualPuzzleRule.repeatBeat:
      case VisualPuzzleRule.matchSignal:
      case VisualPuzzleRule.viewFromSide:
      case VisualPuzzleRule.switchRule:
      case VisualPuzzleRule.completeBuild:
      case VisualPuzzleRule.repairMismatch:
        return null;
    }
  }

  bool _usesMotifBadge(VisualPuzzleRule? value) => switch (value) {
        VisualPuzzleRule.navigateMapRoute ||
        VisualPuzzleRule.reconstructSpatialTarget ||
        VisualPuzzleRule.orderPictureCycle ||
        VisualPuzzleRule.orderStoryPanels ||
        VisualPuzzleRule.chooseEffect ||
        VisualPuzzleRule.orderProcedureIcons ||
        VisualPuzzleRule.chooseStoryNext ||
        VisualPuzzleRule.arrangeStoryPanels ||
        VisualPuzzleRule.choosePerspectiveOutcome ||
        VisualPuzzleRule.completeVisualComposition =>
          true,
        _ => false,
      };
}

class _SequenceGlyph extends StatelessWidget {
  const _SequenceGlyph(
      {required this.color, required this.variant, required this.size});

  final Color color;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: size * .025),
            child: _GlyphDot(
              color: color.withValues(alpha: index == variant % 3 ? 1 : .35),
              size: size * .14,
            ),
          ),
        ),
      );
}

class _DistanceGlyph extends StatelessWidget {
  const _DistanceGlyph(
      {required this.color, required this.variant, required this.size});

  final Color color;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlyphDot(color: color, size: size * .12),
          SizedBox(width: size * (.08 + (variant % 4) * .055)),
          _GlyphDot(color: color.withValues(alpha: .62), size: size * .12),
        ],
      );
}

class _PatternGlyph extends StatelessWidget {
  const _PatternGlyph({
    required this.palette,
    required this.variant,
    required this.stimulus,
    required this.size,
  });

  final List<Color> palette;
  final int variant;
  final List<int> stimulus;
  final double size;

  @override
  Widget build(BuildContext context) {
    final values = stimulus.isEmpty
        ? [variant, variant + 1, variant + 2, variant]
        : stimulus;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: size * .055,
      runSpacing: size * .055,
      children: values.take(4).map((value) {
        final color = palette[value % palette.length];
        return Container(
          width: size * .17,
          height: size * .17,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .78),
            borderRadius:
                BorderRadius.circular(value.isEven ? size * .09 : size * .025),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _SortGlyph extends StatelessWidget {
  const _SortGlyph(
      {required this.palette, required this.variant, required this.size});

  final List<Color> palette;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlyphDot(color: palette[variant % palette.length], size: size * .18),
          SizedBox(width: size * .08),
          _GlyphDot(
              color: palette[(variant + 1) % palette.length], size: size * .18),
        ],
      );
}

class _QuantityGlyph extends StatelessWidget {
  const _QuantityGlyph({
    required this.motif,
    required this.color,
    required this.count,
    required this.size,
  });

  final IconData motif;
  final Color color;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * .64,
        height: size * .56,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: size * .025,
          runSpacing: size * .015,
          children: List.generate(
            count,
            (_) => Icon(motif, color: color, size: size * .18),
          ),
        ),
      );
}

class _RhythmGlyph extends StatelessWidget {
  const _RhythmGlyph(
      {required this.color, required this.variant, required this.size});

  final Color color;
  final int variant;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (index) => Container(
            width: size * .10,
            height: size * (.16 + ((variant + index) % 4) * .09),
            margin: EdgeInsets.symmetric(horizontal: size * .025),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(size * .06)),
          ),
        ),
      );
}

class _GlyphDot extends StatelessWidget {
  const _GlyphDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _GroundedPictureChoice extends StatelessWidget {
  const _GroundedPictureChoice({
    required this.token,
    required this.color,
    required this.selected,
    required this.animation,
    required this.interaction,
    required this.rule,
    required this.choiceIndex,
    required this.onTap,
  });

  final Widget token;
  final Color color;
  final bool selected;
  final String animation;
  final InteractionPreference interaction;
  final VisualPuzzleRule? rule;
  final int choiceIndex;
  final VoidCallback onTap;

  bool get _isPanelChoice => switch (rule) {
        VisualPuzzleRule.orderPictureCycle ||
        VisualPuzzleRule.orderStoryPanels ||
        VisualPuzzleRule.chooseEffect ||
        VisualPuzzleRule.orderProcedureIcons ||
        VisualPuzzleRule.chooseStoryNext ||
        VisualPuzzleRule.completePictureAnalogy ||
        VisualPuzzleRule.arrangeStoryPanels ||
        VisualPuzzleRule.findSceneChange ||
        VisualPuzzleRule.matchEmotionIcon ||
        VisualPuzzleRule.choosePerspectiveOutcome =>
          true,
        _ => false,
      };

  bool get _isRoundChoice => switch (rule) {
        VisualPuzzleRule.matchMentalRotation ||
        VisualPuzzleRule.detectPointCloudAnomaly ||
        VisualPuzzleRule.chooseLargerDotCloud ||
        VisualPuzzleRule.matchPhonologicalPattern ||
        VisualPuzzleRule.replayToneSequence ||
        VisualPuzzleRule.matchMelodyPattern =>
          true,
        _ => false,
      };

  bool get _isBinChoice => switch (rule) {
        VisualPuzzleRule.sortMultipleAttributes ||
        VisualPuzzleRule.discoverVisualRule ||
        VisualPuzzleRule.findSharedProperty =>
          true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final width = _isPanelChoice
        ? 124.0
        : _isRoundChoice
            ? 96.0
            : _isBinChoice
                ? 102.0
                : 108.0;
    final height = _isPanelChoice
        ? 92.0
        : _isRoundChoice
            ? 96.0
            : _isBinChoice
                ? 108.0
                : 116.0;
    final radius = _isRoundChoice
        ? BorderRadius.circular(56)
        : _isBinChoice
            ? const BorderRadius.vertical(
                top: Radius.circular(26), bottom: Radius.circular(12))
            : BorderRadius.circular(_isPanelChoice ? 12 : 22);
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey('visual-choice-${rule?.name ?? 'generic'}-$choiceIndex'),
        onTap: onTap,
        onHorizontalDragEnd: interaction == InteractionPreference.swiping
            ? (_) => onTap()
            : null,
        onPanEnd: interaction == InteractionPreference.dragging
            ? (_) => onTap()
            : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          scale: selected && animation == 'snap' ? .84 : 1,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 280),
            turns: selected && (animation == 'roll' || animation == 'rotate')
                ? .25
                : 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              offset: selected && animation == 'slide'
                  ? const Offset(.35, 0)
                  : Offset.zero,
              child: Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .72),
                  borderRadius: radius,
                  border: Border.all(color: color.withValues(alpha: .22)),
                ),
                child: token,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
