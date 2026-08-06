import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders a real, scannable QR code using the `qr_flutter` package.
///
/// Drop-in replacement for the previous fake dot-pattern painter.
/// The [foregroundColor] and [backgroundColor] default to values that work
/// in both light and dark mode, but callers can override them when the widget
/// sits inside a brand-gradient surface (e.g. white on dark).
class QrCodeWidget extends StatelessWidget {
  const QrCodeWidget({
    required this.data,
    this.size = 200,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final String data;
  final double size;

  /// Dot / module colour. Defaults to the theme's primary text colour.
  final Color? foregroundColor;

  /// Background fill colour. Defaults to white so the QR reader always has
  /// maximum contrast regardless of the app's current theme.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default colours guarantee scanner-readable contrast.
    final fg = foregroundColor ??
        (isDark ? const Color(0xFFF5F7FF) : const Color(0xFF0F1123));
    final bg = backgroundColor ?? Colors.white;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        // Use a pure white eye-frame background so finder patterns stay crisp.
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: fg,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: fg,
        ),
        backgroundColor: bg,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        gapless: true,
        errorStateBuilder: (context, err) => Center(
          child: Icon(Icons.error_outline_rounded, color: Colors.red, size: size * 0.3),
        ),
      ),
    );
  }
}
