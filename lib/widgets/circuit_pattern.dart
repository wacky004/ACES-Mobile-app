import 'package:flutter/material.dart';

class CircuitPattern extends StatelessWidget {
  const CircuitPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.11,
  });

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CircuitPainter(color: color.withValues(alpha: opacity)),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CircuitPainter extends CustomPainter {
  const _CircuitPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final node = Paint()..color = color;
    final step = size.width < 500 ? 54.0 : 72.0;
    for (var x = -20.0; x < size.width + 40; x += step) {
      for (var y = 10.0; y < size.height + 30; y += step) {
        final path = Path()
          ..moveTo(x, y)
          ..lineTo(x + step * 0.42, y)
          ..lineTo(x + step * 0.62, y + step * 0.28)
          ..lineTo(x + step * 0.62, y + step * 0.62);
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x + step * 0.62, y + step * 0.62), 2.2, node);
      }
    }
    final circuit = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.21);
      final path = Path()
        ..moveTo(0, y)
        ..lineTo(size.width * 0.28, y)
        ..lineTo(size.width * 0.38, y - 22)
        ..lineTo(size.width * 0.74, y - 22)
        ..lineTo(size.width * 0.84, y + 8)
        ..lineTo(size.width, y + 8);
      canvas.drawPath(path, circuit);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) => false;
}
