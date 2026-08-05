import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models.dart';
import 'brand.dart';

/// The payment card face.
///
/// Portrait, the way the physical card is held. One vertical fall from ice to
/// ink carries the brand colour in the top third, the bare mark sits centred on
/// the dark half, and the four pieces of real information sit in the corners:
/// the last four digits, the scheme mark, and the product type.
class CardFace extends StatelessWidget {
  const CardFace({
    required this.card,
    this.sheen = 0,
    this.lift = 1,
    this.radius = AppRadius.lg,
    super.key,
  });

  /// Height as a share of width, taken from the physical card proportion.
  static const double aspectRatio = 0.66;

  /// Height for a given available width.
  static double heightFor(double width) => width / aspectRatio;

  final BankCard card;

  /// Where the specular highlight sits, from -1 to 1. The carousel drives this
  /// from the swipe offset so light travels across the face as it turns.
  final double sheen;

  /// How much elevation the face carries, from 0 to 1. Off centre cards sit
  /// lower, so the active card reads as the one in hand.
  final double lift;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(radius);
    final frozen = card.status == CardStatus.frozen;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Palette.frostInk.withValues(alpha: 0.34 * lift),
            blurRadius: 34 * lift,
            spreadRadius: -4,
            offset: Offset(0, 18 * lift),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border,
        child: CustomPaint(
          painter: _CardFacePainter(sheen: sheen, frozen: frozen),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              // Inner hairline. Reads as the milled edge of the card.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: border,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Padding(
                  padding: EdgeInsets.all(constraints.maxWidth * 0.075),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '\u2022\u2022\u2022\u2022 ${card.last4}',
                              style: AppType.numericSmall.copyWith(
                                color: Palette.frostInk.withValues(alpha: 0.72),
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          if (frozen) const _FrozenTag(),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: FrostGlyph(
                            width: constraints.maxWidth * 0.56,
                            excludeSemantics: true,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Align, not a bare Expanded child: Expanded hands
                          // down a tight width, which would stretch the mark
                          // and pull the two Mastercard circles apart.
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: NetworkMark(
                                network: card.network,
                                width: constraints.maxWidth * 0.21,
                              ),
                            ),
                          ),
                          Text(
                            card.kind.label,
                            style: AppType.titleSmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frozen marker. Only drawn when the card is actually frozen, so the face
/// stays at four elements in its normal state.
class _FrozenTag extends StatelessWidget {
  const _FrozenTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: 3),
    decoration: BoxDecoration(
      color: Palette.frostInk.withValues(alpha: 0.16),
      borderRadius: AppRadius.all(AppRadius.pill),
      border: Border.all(color: Palette.frostInk.withValues(alpha: 0.28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.ac_unit_rounded,
          size: 11,
          color: Palette.frostInk.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          'FROZEN',
          style: AppType.labelSmall.copyWith(
            color: Palette.frostInk.withValues(alpha: 0.8),
            fontSize: 9,
          ),
        ),
      ],
    ),
  );
}

/// Scheme colours. Third party marks, kept out of [Palette] because that file
/// is the FrostBank brand sheet and these belong to the card schemes.
abstract final class _Scheme {
  static const Color mastercardRed = Color(0xFFEB001B);
  static const Color mastercardYellow = Color(0xFFF79E1B);

  /// The colour of the region where the two circles meet.
  static const Color mastercardOverlap = Color(0xFFFF5F00);

  static const Color visaBlue = Color(0xFF1A1F71);
}

/// Scheme mark on the card face, in scheme colour.
///
/// These are drawn approximations of third party marks, not the licensed
/// artwork: the geometry and colours follow each scheme's published symbol, and
/// the Visa word mark is set in the interface font rather than Visa's own.
///
/// Visa sits on a white plate. Visa blue is near black in value, so on the dark
/// half of the card face it would disappear, and a white plate is how the mark
/// is placed on dark cards in practice. Mastercard needs no plate, because its
/// two circles already carry their own contrast.
class NetworkMark extends StatelessWidget {
  const NetworkMark({required this.network, required this.width, super.key});

  final CardNetwork network;

  /// Width of the mark. Height follows the scheme's own proportion, so both
  /// marks take the same footprint on the card.
  final double width;

  /// Width to height of the Mastercard symbol, and of the Visa plate that has
  /// to sit beside it.
  static const double _aspect = 1.55;

  @override
  Widget build(BuildContext context) => Semantics(
    label: network.label,
    child: ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: width / _aspect,
        child: switch (network) {
          CardNetwork.mastercard => CustomPaint(
            painter: const _MastercardPainter(),
          ),
          CardNetwork.visa => DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(width * 0.08),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.09),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'VISA',
                    style: AppType.titleSmall.copyWith(
                      color: _Scheme.visaBlue,
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                      letterSpacing: 0.5,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        },
      ),
    ),
  );
}

/// The Mastercard symbol: two circles of equal diameter, overlapping, with the
/// intersection filled in the third colour.
class _MastercardPainter extends CustomPainter {
  const _MastercardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Circle diameter is the full height, so the published width to height
    // proportion sets how far the two circles overlap.
    final r = size.height / 2;
    final left = Rect.fromCircle(center: Offset(r, r), radius: r);
    final right = Rect.fromCircle(
      center: Offset(size.width - r, r),
      radius: r,
    );

    canvas
      ..drawOval(left, Paint()..color = _Scheme.mastercardRed)
      ..drawOval(right, Paint()..color = _Scheme.mastercardYellow)
      ..drawPath(
        Path.combine(
          PathOperation.intersect,
          Path()..addOval(left),
          Path()..addOval(right),
        ),
        Paint()..color = _Scheme.mastercardOverlap,
      );
  }

  @override
  bool shouldRepaint(covariant _MastercardPainter oldDelegate) => false;
}

class _CardFacePainter extends CustomPainter {
  const _CardFacePainter({required this.sheen, required this.frozen});

  final double sheen;
  final bool frozen;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // The fall. Colour in the top third, near black below the mark.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Palette.gradientCardFace,
          stops: Palette.cardFaceStops,
        ).createShader(rect),
    );

    // Ice bloom off the top left corner, so the colour band is not a flat ramp.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.16, -size.height * 0.04),
          size.width * 1.05,
          [
            Palette.frostIceWhite.withValues(alpha: 0.52),
            Palette.frostIcePale.withValues(alpha: 0.16),
            Palette.frostIcePale.withValues(alpha: 0),
          ],
          const [0, 0.42, 1],
        ),
    );

    // Cool light entering from the right, held inside the colour band.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 1.02, size.height * 0.16),
          size.width * 0.8,
          [
            Palette.cardAzure.withValues(alpha: 0.55),
            Palette.cardOcean.withValues(alpha: 0.2),
            Palette.cardOcean.withValues(alpha: 0),
          ],
          const [0, 0.5, 1],
        ),
    );

    // Bottom vignette. Pulls the lower half further down so the mark holds.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.bottomCenter,
          colors: [
            Palette.cardVoid.withValues(alpha: 0),
            Palette.cardVoid.withValues(alpha: 0.55),
          ],
        ).createShader(rect),
    );

    // Specular sheen. Travels with the swipe, so the face reads as a hard
    // surface catching light rather than a printed gradient.
    final x = sheen * 0.9;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(x - 1.4, -1),
          end: Alignment(x + 0.6, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.34, 0.5, 0.66],
        ).createShader(rect),
    );

    if (!frozen) return;

    // Frozen veil. Cools and flattens the whole face.
    canvas.drawRect(
      rect,
      Paint()..color = Palette.frostIcePale.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant _CardFacePainter oldDelegate) =>
      oldDelegate.sheen != sheen || oldDelegate.frozen != frozen;
}

/// Small portrait card used in strips and lists, where the full face would not
/// have room to breathe. Same material, fewer elements.
class MiniCardFace extends StatelessWidget {
  const MiniCardFace({required this.card, this.width = 96, super.key});

  final BankCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final border = BorderRadius.circular(AppRadius.sm);

    return SizedBox(
      width: width,
      height: CardFace.heightFor(width),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: border,
          boxShadow: [
            BoxShadow(
              color: Palette.frostInk.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: border,
          child: CustomPaint(
            painter: _CardFacePainter(
              sheen: 0,
              frozen: card.status == CardStatus.frozen,
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.last4,
                    style: AppType.numericSmall.copyWith(
                      color: Palette.frostInk.withValues(alpha: 0.72),
                      fontSize: width * 0.11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FrostGlyph(
                        width: width * 0.5,
                        excludeSemantics: true,
                      ),
                    ),
                  ),
                  Text(
                    card.kind.label.toUpperCase(),
                    style: AppType.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: width * 0.09,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty slot in a strip of cards. Reads as a place a card could go rather than
/// as a card. Wrap it in a [Pressable] to make it actionable.
class AddCardTile extends StatelessWidget {
  const AddCardTile({this.width = 96, this.onBrand = false, super.key});

  final double width;

  /// True when the tile sits on the brand backdrop instead of the light sheet.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final line = onBrand
        ? Colors.white.withValues(alpha: 0.26)
        : tokens.border;
    final ink = onBrand ? Colors.white : tokens.interactivePrimary;

    return SizedBox(
      width: width,
      height: CardFace.heightFor(width),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: onBrand
              ? Colors.white.withValues(alpha: 0.07)
              : tokens.surface,
          borderRadius: AppRadius.all(AppRadius.sm),
          border: Border.all(color: line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: ink, size: width * 0.24),
            SizedBox(height: width * 0.06),
            Text(
              'ADD',
              style: AppType.labelSmall.copyWith(
                color: ink,
                fontSize: width * 0.095,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated page dots for the card carousel. The active dot stretches into a
/// bar, so position reads without counting.
class CardPageDots extends StatelessWidget {
  const CardPageDots({
    required this.count,
    required this.page,
    this.color,
    this.trackColor,
    super.key,
  });

  final int count;

  /// Fractional page position, so the dots track the finger rather than
  /// snapping after the gesture ends.
  final double page;

  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final active = color ?? tokens.accent;
    final track = trackColor ?? tokens.border;
    final index = page.round().clamp(0, count - 1);

    return Semantics(
      label: 'Card ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              _Dot(
                // Nearness is continuous, so the bar grows and shrinks with the
                // swipe instead of after it.
                weight: (1 - (page - i).abs()).clamp(0.0, 1.0),
                active: active,
                track: track,
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.weight,
    required this.active,
    required this.track,
  });

  final double weight;
  final Color active;
  final Color track;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    width: 7 + 15 * weight,
    height: 7,
    decoration: BoxDecoration(
      color: Color.lerp(track, active, weight),
      borderRadius: AppRadius.all(AppRadius.pill),
    ),
  );
}

/// Skeleton shaped like the card face, so the carousel does not resize when the
/// real cards arrive.
class CardFaceSkeleton extends StatelessWidget {
  const CardFaceSkeleton({required this.width, super.key});

  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: CardFace.heightFor(width),
    decoration: BoxDecoration(
      color: context.tokens.skeletonHighlight,
      borderRadius: AppRadius.all(AppRadius.lg),
    ),
  );
}

/// Cross fades the trailing edge of a value that changes with the active card.
class CardValueSwap extends StatelessWidget {
  const CardValueSwap({required this.child, this.alignment, super.key});

  final Widget child;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.resolve(context, Motion.medium),
    switchInCurve: Motion.standard,
    switchOutCurve: Motion.standard,
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: alignment ?? Alignment.center,
      children: [...previousChildren, ?currentChild],
    ),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.22),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );
}
