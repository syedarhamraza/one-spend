import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Samsung Health style donut: one arc per segment with small gaps, a centre label, and
/// optional emphasis on one segment (the others dim). Sweeps in on first build.
class OneUICategoryRing extends StatelessWidget {
  final List<({Color color, double value})> segments;

  /// Index of the emphasised segment, or null for none.
  final int? highlightedIndex;
  final String centerValue;
  final String centerLabel;
  final double size;
  final double strokeWidth;

  const OneUICategoryRing({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.highlightedIndex,
    this.size = 132,
    this.strokeWidth = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => CustomPaint(
          painter: _RingPainter(
            segments: segments,
            highlightedIndex: highlightedIndex,
            strokeWidth: strokeWidth,
            progress: t,
          ),
          child: child,
        ),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth + 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  centerValue,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
              Text(
                centerLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: OneUITheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<({Color color, double value})> segments;
  final int? highlightedIndex;
  final double strokeWidth;
  final double progress;

  _RingPainter({
    required this.segments,
    required this.highlightedIndex,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: (size.shortestSide - strokeWidth) / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFF2C2D30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final total = segments.fold(0.0, (sum, s) => sum + s.value);
    if (total <= 0) return;
    final gap = segments.length > 1 ? 0.035 : 0.0;
    var start = -math.pi / 2;
    final sweepTotal = math.pi * 2 * progress;
    for (final (i, s) in segments.indexed) {
      final sweep = sweepTotal * (s.value / total);
      final dimmed = highlightedIndex != null && highlightedIndex != i;
      if (sweep - gap > 0) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..color = s.color.withValues(alpha: dimmed ? 0.22 : 1.0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = highlightedIndex == i ? strokeWidth + 3 : strokeWidth,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.segments != segments || old.highlightedIndex != highlightedIndex || old.progress != progress;
}
