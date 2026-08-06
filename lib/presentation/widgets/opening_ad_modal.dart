import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/providers.dart';
import 'brand.dart';
import 'grid_pattern_painter.dart';
import 'pressable.dart';

/// Rotates available ad assets randomly with a rare chance (10%) for `ad_uma.webp`.
String selectRandomAdAsset({Random? rng}) {
  final random = rng ?? Random();

  // 10% rare chance for ad_uma.webp
  if (random.nextDouble() < 0.10) {
    return 'assets/images/ad_uma.webp';
  }

  // 90% chance to rotate between standard ads
  const standardAds = [
    'assets/images/ad_light.png',
    'assets/images/ad_dark.png',
  ];

  return standardAds[random.nextInt(standardAds.length)];
}

/// Shows the opening advertisement modal if it has not been dismissed yet.
Future<void> showOpeningAdModal(
  BuildContext context,
  WidgetRef ref, {
  String? overrideAssetPath,
}) async {
  final isDismissed = ref.read(openingAdDismissedProvider);
  if (isDismissed) return;

  final selectedAssetPath = overrideAssetPath ?? selectRandomAdAsset();

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (dialogContext) => OpeningAdModal(
      assetPath: selectedAssetPath,
      onDismiss: () {
        ref.read(openingAdDismissedProvider.notifier).dismiss();
        if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        }
      },
    ),
  );
}

/// Rotating Opening Advertisement modal dialog with theme matching and rare ad support.
class OpeningAdModal extends StatelessWidget {
  const OpeningAdModal({
    required this.onDismiss,
    this.assetPath,
    super.key,
  });

  final VoidCallback onDismiss;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeAsset = assetPath ?? selectRandomAdAsset();

    // Determine card theme based on the selected ad content rather than system mode alone.
    final isDarkCard = activeAsset.contains('ad_dark') || activeAsset.contains('ad_uma');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x6,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 420,
            maxHeight: 620,
          ),
          decoration: BoxDecoration(
            color: isDarkCard ? Palette.darkBackground : tokens.background,
            borderRadius: AppRadius.all(AppRadius.xl),
            border: Border.all(
              color: isDarkCard ? Palette.darkBorder : Palette.border.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkCard ? 0.65 : 0.2),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.all(AppRadius.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.x5, Space.x4, Space.x4, Space.x3),
                  child: Row(
                    children: [
                      const FrostMark(size: 26),
                      const SizedBox(width: Space.x2),
                      Text(
                        'FrostBank',
                        style: AppType.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkCard ? Palette.darkTextPrimary : tokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      // Integrated Skip / Close Pill Button
                      Pressable(
                        onTap: onDismiss,
                        semanticLabel: 'Skip advertisement',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x3,
                            vertical: Space.x1,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkCard
                                ? Colors.white.withValues(alpha: 0.12)
                                : Palette.surface,
                            borderRadius: AppRadius.all(AppRadius.pill),
                            border: Border.all(
                              color: isDarkCard
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Palette.border.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skip',
                                style: AppType.labelMedium.copyWith(
                                  color: isDarkCard ? Palette.darkTextPrimary : tokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isDarkCard ? Palette.darkTextSecondary : tokens.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Image Poster Display
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                    child: ClipRRect(
                      borderRadius: AppRadius.all(AppRadius.lg),
                      child: Image.asset(
                        activeAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return isDarkCard
                              ? _DarkAdFallback(onDismiss: onDismiss)
                              : _LightAdFallback(onDismiss: onDismiss);
                        },
                      ),
                    ),
                  ),
                ),

                // Bottom Action Pill Button Bar
                Padding(
                  padding: const EdgeInsets.all(Space.x4),
                  child: Pressable(
                    onTap: onDismiss,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.all(AppRadius.pill),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkCard
                              ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
                              : const [Palette.primaryPurple, Palette.vibrantBlue],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.vibrantBlue.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isDarkCard ? 'Get Started Now' : 'Experience Smarter Banking',
                                style: AppType.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.x2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback Light Mode layout if image asset is missing.
class _LightAdFallback extends StatelessWidget {
  const _LightAdFallback({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      color: Palette.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(
                lineColor: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                gridSize: 28,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'The Future of Banking is Digital.',
                  style: AppType.displayMedium.copyWith(
                    color: Palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Space.x3),
                Text(
                  'Banking is no longer just transactions. It is speed, security, and smart financial control.',
                  style: AppType.bodyMedium.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback Dark Mode layout if image asset is missing.
class _DarkAdFallback extends StatelessWidget {
  const _DarkAdFallback({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.darkBackground,
      padding: const EdgeInsets.all(Space.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pay Your Way,\nAnytime',
            style: AppType.displayMedium.copyWith(
              color: const Color(0xFF60A5FA),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Space.x3),
          Text(
            'Send, receive, and manage money effortlessly',
            style: AppType.bodyMedium.copyWith(
              color: Palette.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
