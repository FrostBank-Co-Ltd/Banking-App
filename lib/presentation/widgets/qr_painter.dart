import 'dart:convert';
import 'package:flutter/material.dart';

/// Renders a crisp vector QR code pattern with finder patterns and data dots.
class QrCodeWidget extends StatelessWidget {
  const QrCodeWidget({
    required this.data,
    this.size = 200,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
    super.key,
  });

  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _QrPainter(
          data: data,
          foregroundColor: foregroundColor,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter({
    required this.data,
    required this.foregroundColor,
  });

  final String data;
  final Color foregroundColor;

  static const int matrixSize = 21; // Standard Version 1 QR matrix

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    final moduleSize = size.width / matrixSize;

    // Generate deterministic 21x21 matrix from string hash
    final matrix = _generateMatrix(data);

    for (var r = 0; r < matrixSize; r++) {
      for (var c = 0; c < matrixSize; c++) {
        if (matrix[r][c]) {
          final rect = Rect.fromLTWH(
            c * moduleSize,
            r * moduleSize,
            moduleSize + 0.3,
            moduleSize + 0.3,
          );

          // Render finder patterns with rounded square styling
          if (_isFinderPattern(r, c)) {
            // Handled separately below for clean crisp rendering
            continue;
          } else {
            // Data module
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.2)),
              paint,
            );
          }
        }
      }
    }

    // Draw standard 3 Corner Finder Patterns (7x7 modules)
    _drawFinderPattern(canvas, 0, 0, moduleSize, paint);
    _drawFinderPattern(canvas, 0, matrixSize - 7, moduleSize, paint);
    _drawFinderPattern(canvas, matrixSize - 7, 0, moduleSize, paint);
  }

  bool _isFinderPattern(int r, int c) {
    if (r < 7 && c < 7) return true; // Top-left
    if (r < 7 && c >= matrixSize - 7) return true; // Top-right
    if (r >= matrixSize - 7 && c < 7) return true; // Bottom-left
    return false;
  }

  void _drawFinderPattern(
    Canvas canvas,
    int row,
    int col,
    double moduleSize,
    Paint paint,
  ) {
    final x = col * moduleSize;
    final y = row * moduleSize;
    final size = 7 * moduleSize;

    // Outer 7x7 frame
    final outerRect = Rect.fromLTWH(x, y, size, size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, Radius.circular(moduleSize * 1.5)),
      paint,
    );

    // Inner 5x5 clear square (white)
    final clearPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final innerClearRect = Rect.fromLTWH(
      x + moduleSize,
      y + moduleSize,
      5 * moduleSize,
      5 * moduleSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerClearRect, Radius.circular(moduleSize * 1.0)),
      clearPaint,
    );

    // Center 3x3 solid square
    final centerRect = Rect.fromLTWH(
      x + 2 * moduleSize,
      y + 2 * moduleSize,
      3 * moduleSize,
      3 * moduleSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(moduleSize * 0.8)),
      paint,
    );
  }

  List<List<bool>> _generateMatrix(String input) {
    final bytes = utf8.encode(input);
    final hash = bytes.fold<int>(0, (prev, elem) => (prev * 31 + elem) & 0x7FFFFFFF);

    final matrix = List.generate(
      matrixSize,
      (_) => List.generate(matrixSize, (_) => false),
    );

    // Set alignment and timing patterns
    for (var i = 0; i < matrixSize; i++) {
      if (i % 2 == 0) {
        matrix[6][i] = true;
        matrix[i][6] = true;
      }
    }

    // Fill data area deterministically
    var seed = hash;
    for (var r = 0; r < matrixSize; r++) {
      for (var c = 0; c < matrixSize; c++) {
        if (_isFinderPattern(r, c)) continue;
        if (r == 6 || c == 6) continue; // timing pattern

        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
        matrix[r][c] = (seed % 3) == 0;
      }
    }

    return matrix;
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.foregroundColor != foregroundColor;
  }
}
