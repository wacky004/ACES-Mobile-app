import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 9,
    this.color,
    this.trackColor,
    this.label,
    this.labelColor,
    this.labelSize = 26,
    this.animate = true,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final String? label;
  final Color? labelColor;
  final double labelSize;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0.0, 1.0);
    final ringColor = color ?? scoreColor(percent);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = trackColor ??
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.35);
    final resolvedLabelColor = labelColor ??
        (isDark ? const Color(0xFFE8EEF8) : AppColors.ink);
    Widget ring(double animatedValue) => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              value: animatedValue,
              color: ringColor,
              trackColor: track,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Text(
                label ?? '${(animatedValue * 100).round()}%',
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  color: resolvedLabelColor,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
        );

    if (!animate) return ring(percent);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) => ring(animatedValue),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, trackPaint);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
