import 'package:flutter/material.dart';

/// Draws a subtle, crisp grid pattern background for light mode promotional cards/screens.
class GridPatternPainter extends CustomPainter {
  const GridPatternPainter({
    required this.lineColor,
    this.gridSize = 32.0,
    this.strokeWidth = 1.0,
  });

  final Color lineColor;
  final double gridSize;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPatternPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
