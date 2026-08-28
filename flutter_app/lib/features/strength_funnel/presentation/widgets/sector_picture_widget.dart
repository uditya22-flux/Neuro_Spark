import 'package:flutter/material.dart';

import '../../models/riasec_sector.dart';

/// Sensory-safe concrete-activity drawing — no faces, minimal clutter.
/// Used in strength funnel and child play when picture modality is active.
class SectorPictureWidget extends StatelessWidget {
  const SectorPictureWidget({
    super.key,
    required this.sectorId,
    this.activityLabel,
    this.height = 160,
  });

  final String sectorId;
  final String? activityLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sector = sectorById(sectorId);
    final palette = _paletteForType(sector?.riasecType ?? 'realistic');

    return Semantics(
      label: activityLabel ?? sector?.displayName ?? 'Play activity picture',
      image: true,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.accent.withValues(alpha: 0.35)),
        ),
        child: CustomPaint(
          painter: _SectorPicturePainter(
            sectorId: sectorId,
            accent: palette.accent,
            secondary: palette.secondary,
          ),
          child: activityLabel != null
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    ),
                    child: Text(
                      activityLabel!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _SectorPalette {
  const _SectorPalette({
    required this.background,
    required this.accent,
    required this.secondary,
  });

  final Color background;
  final Color accent;
  final Color secondary;
}

_SectorPalette _paletteForType(String riasecType) {
  return switch (riasecType) {
    'investigative' => const _SectorPalette(
        background: Color(0xFFE8F4FD),
        accent: Color(0xFF1565C0),
        secondary: Color(0xFF64B5F6),
      ),
    'artistic' => const _SectorPalette(
        background: Color(0xFFF3E8FD),
        accent: Color(0xFF7B1FA2),
        secondary: Color(0xFFBA68C8),
      ),
    'social' => const _SectorPalette(
        background: Color(0xFFE8F5E9),
        accent: Color(0xFF2E7D32),
        secondary: Color(0xFF81C784),
      ),
    'enterprising' => const _SectorPalette(
        background: Color(0xFFFFF3E0),
        accent: Color(0xFFE65100),
        secondary: Color(0xFFFFB74D),
      ),
    'conventional' => const _SectorPalette(
        background: Color(0xFFECEFF1),
        accent: Color(0xFF455A64),
        secondary: Color(0xFF90A4AE),
      ),
    _ => const _SectorPalette(
        background: Color(0xFFFBE9E7),
        accent: Color(0xFFC62828),
        secondary: Color(0xFFE57373),
      ),
  };
}

class _SectorPicturePainter extends CustomPainter {
  _SectorPicturePainter({
    required this.sectorId,
    required this.accent,
    required this.secondary,
  });

  final String sectorId;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = accent;

    final cx = size.width / 2;
    final cy = size.height * 0.42;

    switch (sectorId) {
      case 'r_build_fix':
        _drawBlocks(canvas, cx, cy, paint, stroke);
      case 'r_nature_outdoors':
        _drawTree(canvas, cx, cy, paint, stroke);
      case 'r_sports_movement':
        _drawBall(canvas, cx, cy, paint, stroke);
      case 'r_crafts_making':
        _drawScissors(canvas, cx, cy, paint, stroke);
      case 'r_vehicles_machines':
        _drawTrain(canvas, cx, cy, paint, stroke);
      case 'i_puzzles_logic':
        _drawPuzzle(canvas, cx, cy, paint, stroke);
      case 'i_nature_science':
        _drawLeaf(canvas, cx, cy, paint, stroke);
      case 'i_numbers_patterns':
        _drawGrid(canvas, cx, cy, paint, stroke);
      case 'i_maps_exploring':
        _drawMap(canvas, cx, cy, paint, stroke);
      case 'i_experiments_trying':
        _drawBeaker(canvas, cx, cy, paint, stroke);
      case 'a_drawing_color':
        _drawPalette(canvas, cx, cy, paint, stroke);
      case 'a_music_rhythm':
        _drawNotes(canvas, cx, cy, paint, stroke);
      case 'a_story_imagine':
        _drawBook(canvas, cx, cy, paint, stroke);
      case 'a_build_design':
        _drawShapes(canvas, cx, cy, paint, stroke);
      case 'a_performance_show':
        _drawStage(canvas, cx, cy, paint, stroke);
      case 's_helping_caring':
        _drawHeart(canvas, cx, cy, paint, stroke);
      case 's_teaching_showing':
        _drawPointer(canvas, cx, cy, paint, stroke);
      case 's_team_play':
        _drawCircles(canvas, cx, cy, paint, stroke);
      case 's_community_events':
        _drawFlag(canvas, cx, cy, paint, stroke);
      case 's_friend_connections':
        _drawLink(canvas, cx, cy, paint, stroke);
      case 'e_leading_groups':
        _drawMegaphone(canvas, cx, cy, paint, stroke);
      case 'e_selling_trading':
        _drawSwap(canvas, cx, cy, paint, stroke);
      case 'e_planning_events':
        _drawCalendar(canvas, cx, cy, paint, stroke);
      case 'e_persuading_sharing':
        _drawBulb(canvas, cx, cy, paint, stroke);
      case 'e_starting_projects':
        _drawRocket(canvas, cx, cy, paint, stroke);
      case 'c_sorting_organizing':
        _drawBins(canvas, cx, cy, paint, stroke);
      case 'c_schedules_routines':
        _drawTimeline(canvas, cx, cy, paint, stroke);
      case 'c_lists_checklists':
        _drawChecklist(canvas, cx, cy, paint, stroke);
      case 'c_collecting_sets':
        _drawStack(canvas, cx, cy, paint, stroke);
      case 'c_patterns_order':
        _drawPattern(canvas, cx, cy, paint, stroke);
      default:
        _drawGeneric(canvas, cx, cy, paint, stroke);
    }
  }

  void _drawBlocks(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    for (var i = 0; i < 3; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - 20 + i * 22, cy + 10 - i * 18), width: 36, height: 36),
          const Radius.circular(4),
        ),
        fill,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 28), width: 80, height: 8), const Radius.circular(2)),
      fill..color = secondary,
    );
  }

  void _drawTree(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 18), width: 56, height: 44), fill);
    fill.color = accent;
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 22), width: 10, height: 36), fill);
  }

  void _drawBall(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawCircle(Offset(cx, cy), 28, fill);
    c.drawArc(Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 56), 0.5, 2, false, stroke..color = secondary);
  }

  void _drawScissors(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    c.drawCircle(Offset(cx - 14, cy - 10), 10, stroke);
    c.drawCircle(Offset(cx + 14, cy - 10), 10, stroke);
    c.drawLine(Offset(cx - 14, cy), Offset(cx + 8, cy + 28), stroke);
    c.drawLine(Offset(cx + 14, cy), Offset(cx - 8, cy + 28), stroke);
  }

  void _drawTrain(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 72, height: 32), const Radius.circular(6)),
      fill,
    );
    fill.color = secondary;
    for (var i = -1; i <= 1; i++) {
      c.drawCircle(Offset(cx + i * 22, cy + 22), 8, fill);
    }
  }

  void _drawPuzzle(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawRect(Rect.fromCenter(center: Offset(cx - 16, cy - 16), width: 32, height: 32), fill);
    fill.color = secondary;
    c.drawRect(Rect.fromCenter(center: Offset(cx + 16, cy - 16), width: 32, height: 32), fill);
    c.drawRect(Rect.fromCenter(center: Offset(cx - 16, cy + 16), width: 32, height: 32), fill);
    c.drawRect(Rect.fromCenter(center: Offset(cx + 16, cy + 16), width: 32, height: 32), fill);
  }

  void _drawLeaf(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 48), fill);
    c.drawLine(Offset(cx, cy - 24), Offset(cx, cy + 24), stroke);
  }

  void _drawGrid(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        fill.color = (row + col).isEven ? accent : secondary;
        c.drawRect(
          Rect.fromLTWH(cx - 36 + col * 24, cy - 36 + row * 24, 22, 22),
          fill,
        );
      }
    }
  }

  void _drawMap(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary.withValues(alpha: 0.4);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 72, height: 52), const Radius.circular(8)),
      fill,
    );
    c.drawLine(Offset(cx - 30, cy), Offset(cx + 30, cy), stroke);
    c.drawLine(Offset(cx, cy - 22), Offset(cx, cy + 22), stroke);
    fill.color = accent;
    c.drawCircle(Offset(cx + 12, cy - 8), 6, fill);
  }

  void _drawBeaker(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(cx - 18, cy - 28)
      ..lineTo(cx + 18, cy - 28)
      ..lineTo(cx + 12, cy + 28)
      ..lineTo(cx - 12, cy + 28)
      ..close();
    c.drawPath(path, stroke);
    fill.color = secondary.withValues(alpha: 0.5);
    c.drawRect(Rect.fromLTWH(cx - 10, cy + 4, 20, 18), fill);
  }

  void _drawPalette(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawCircle(Offset(cx, cy), 30, fill);
    for (var i = 0; i < 4; i++) {
      fill.color = [secondary, accent, const Color(0xFFFFEB3B), const Color(0xFF4CAF50)][i];
      c.drawCircle(Offset(cx - 20 + i * 14, cy - 18), 6, fill);
    }
  }

  void _drawNotes(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawOval(Rect.fromCenter(center: Offset(cx - 16, cy + 8), width: 14, height: 10), fill);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 8, cy - 8), width: 14, height: 10), fill);
    c.drawLine(Offset(cx - 9, cy + 4), Offset(cx - 9, cy - 20), stroke);
    c.drawLine(Offset(cx + 15, cy - 12), Offset(cx + 15, cy + 16), stroke);
  }

  void _drawBook(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawRect(Rect.fromCenter(center: Offset(cx - 18, cy), width: 36, height: 48), fill);
    fill.color = secondary;
    c.drawRect(Rect.fromCenter(center: Offset(cx + 18, cy), width: 36, height: 48), fill);
    c.drawLine(Offset(cx, cy - 24), Offset(cx, cy + 24), stroke..strokeWidth = 3);
  }

  void _drawShapes(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawCircle(Offset(cx - 20, cy), 16, fill);
    fill.color = secondary;
    c.drawRect(Rect.fromCenter(center: Offset(cx + 20, cy), width: 32, height: 32), fill);
  }

  void _drawStage(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary;
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 18), width: 80, height: 12), fill);
    c.drawLine(Offset(cx - 40, cy + 12), Offset(cx - 30, cy - 28), stroke);
    c.drawLine(Offset(cx + 40, cy + 12), Offset(cx + 30, cy - 28), stroke);
    c.drawLine(Offset(cx - 30, cy - 28), Offset(cx + 30, cy - 28), stroke);
  }

  void _drawHeart(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    final path = Path()
      ..moveTo(cx, cy + 16)
      ..cubicTo(cx - 36, cy - 8, cx - 20, cy - 32, cx, cy - 12)
      ..cubicTo(cx + 20, cy - 32, cx + 36, cy - 8, cx, cy + 16)
      ..close();
    c.drawPath(path, fill);
  }

  void _drawPointer(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawRect(Rect.fromCenter(center: Offset(cx + 10, cy - 10), width: 48, height: 32), fill..color = secondary.withValues(alpha: 0.5));
    final path = Path()
      ..moveTo(cx - 28, cy + 20)
      ..lineTo(cx - 8, cy - 20)
      ..lineTo(cx + 4, cy - 8)
      ..close();
    c.drawPath(path, fill..color = accent);
  }

  void _drawCircles(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    for (var i = -1; i <= 1; i++) {
      c.drawCircle(Offset(cx + i * 28, cy), 14, fill);
    }
  }

  void _drawFlag(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    c.drawLine(Offset(cx - 24, cy - 28), Offset(cx - 24, cy + 28), stroke);
    fill.color = accent;
    c.drawRect(Rect.fromLTWH(cx - 24, cy - 28, 48, 28), fill);
  }

  void _drawLink(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawCircle(Offset(cx - 20, cy), 16, fill);
    c.drawCircle(Offset(cx + 20, cy), 16, fill);
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 10), fill);
  }

  void _drawMegaphone(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    final path = Path()
      ..moveTo(cx - 30, cy)
      ..lineTo(cx + 10, cy - 24)
      ..lineTo(cx + 10, cy + 24)
      ..close();
    c.drawPath(path, fill);
    c.drawRect(Rect.fromCenter(center: Offset(cx - 36, cy), width: 12, height: 20), fill..color = secondary);
  }

  void _drawSwap(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    c.drawLine(Offset(cx - 28, cy - 8), Offset(cx + 28, cy - 8), stroke);
    c.drawLine(Offset(cx - 28, cy + 8), Offset(cx + 28, cy + 8), stroke);
    fill.color = accent;
    c.drawCircle(Offset(cx - 28, cy - 8), 6, fill);
    c.drawCircle(Offset(cx + 28, cy + 8), 6, fill);
  }

  void _drawCalendar(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary.withValues(alpha: 0.4);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 48), const Radius.circular(6)),
      fill,
    );
    fill.color = accent;
    c.drawRect(Rect.fromLTWH(cx - 28, cy - 18, 56, 10), fill);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(cx - 14 + i * 14, cy + 8), 4, fill);
    }
  }

  void _drawBulb(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = const Color(0xFFFFF59D);
    c.drawCircle(Offset(cx, cy - 8), 22, fill);
    fill.color = secondary;
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 20), width: 20, height: 12), fill);
    c.drawLine(Offset(cx, cy - 30), Offset(cx, cy - 38), stroke);
  }

  void _drawRocket(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    final path = Path()
      ..moveTo(cx, cy - 32)
      ..lineTo(cx + 16, cy + 20)
      ..lineTo(cx - 16, cy + 20)
      ..close();
    c.drawPath(path, fill);
    fill.color = secondary;
    c.drawCircle(Offset(cx, cy - 4), 8, fill);
  }

  void _drawBins(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    for (var i = -1; i <= 1; i++) {
      fill.color = [accent, secondary, accent][i + 1];
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + i * 26, cy), width: 22, height: 36), const Radius.circular(4)),
        fill,
      );
    }
  }

  void _drawTimeline(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    c.drawLine(Offset(cx - 36, cy), Offset(cx + 36, cy), stroke);
    for (var i = -1; i <= 1; i++) {
      fill.color = accent;
      c.drawCircle(Offset(cx + i * 28, cy), 8, fill);
    }
  }

  void _drawChecklist(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = secondary.withValues(alpha: 0.3);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 48, height: 56), const Radius.circular(4)),
      fill,
    );
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(cx - 16, cy - 16 + i * 16), Offset(cx + 16, cy - 16 + i * 16), stroke..strokeWidth = 2);
      if (i < 2) {
        c.drawLine(Offset(cx - 12, cy - 16 + i * 16), Offset(cx - 8, cy - 12 + i * 16), stroke..color = accent);
        c.drawLine(Offset(cx - 8, cy - 12 + i * 16), Offset(cx - 2, cy - 18 + i * 16), stroke..color = accent);
      }
    }
  }

  void _drawStack(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    for (var i = 0; i < 3; i++) {
      fill.color = i.isEven ? accent : secondary;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 8 + i * 10), width: 48, height: 16),
          const Radius.circular(3),
        ),
        fill,
      );
    }
  }

  void _drawPattern(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    for (var i = 0; i < 4; i++) {
      fill.color = i.isEven ? accent : secondary;
      c.drawRect(Rect.fromLTWH(cx - 36 + i * 18, cy - 18, 16, 16), fill);
      c.drawRect(Rect.fromLTWH(cx - 36 + i * 18, cy + 2, 16, 16), fill);
    }
  }

  void _drawGeneric(Canvas c, double cx, double cy, Paint fill, Paint stroke) {
    fill.color = accent;
    c.drawCircle(Offset(cx, cy), 24, fill);
    c.drawCircle(Offset(cx, cy), 24, stroke);
  }

  @override
  bool shouldRepaint(covariant _SectorPicturePainter oldDelegate) =>
      oldDelegate.sectorId != sectorId;
}
