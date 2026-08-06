import 'dart:math' as math;
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
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: frozen ? 1 : 0),
          duration: Motion.resolve(context, Motion.long),
          curve: Motion.standard,
          // The boundary keeps the frost repaint inside the face. Without it,
          // every frame of the freeze marks the deck and the list above it dirty
          // as well.
          builder: (context, frost, content) => RepaintBoundary(
            child: CustomPaint(
              painter: _CardFacePainter(
                sheen: sheen,
                frost: frost,
                radius: radius,
              ),
              // Signals that the painter is mid animation while the frost is
              // between its two rest states, so the raster cache does not try to
              // hold on to a frame that is about to change.
              willChange: frost > 0 && frost < 1,
              child: content,
            ),
          ),
          // Handed in rather than rebuilt, so freezing repaints the material
          // without rebuilding the type, the glyph, and the scheme mark on every
          // frame.
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
                          _FrozenTag(frozen: frozen),
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

/// Frozen marker.
///
/// Wipes in from the right edge as the card freezes and back out as it thaws,
/// rather than being added to and removed from the tree, so the state change is
/// one continuous movement. It takes no width at all when the card is active, so
/// the face still stays at four elements in its normal state.
///
/// Runs on its own timeline from the same [frozen] flag as the frost, with the
/// same duration and curve, so the two stay together without being wired to each
/// other.
class _FrozenTag extends StatelessWidget {
  const _FrozenTag({required this.frozen});

  final bool frozen;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: frozen ? 1 : 0),
    duration: Motion.resolve(context, Motion.long),
    curve: Motion.standard,
    builder: (context, t, child) {
      if (t <= 0) return const SizedBox.shrink();
      return ClipRect(
        child: Align(
          alignment: Alignment.centerRight,
          widthFactor: t.clamp(0.0, 1.0),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        ),
      );
    },
    child: Container(
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

  /// The Visa word mark, bundled as artwork rather than drawn, because the
  /// letterforms are a custom typeface that no interface font approximates. The
  /// artwork carries Visa Blue itself, so no colour constant is needed for it.
  static const String visaAsset = 'assets/brand/visa.webp';
}

/// Scheme mark on the card face.
///
/// Both marks belong to their schemes, not to FrostBank, which is why the
/// colours live here rather than in [Palette]. Visa is the real word mark, drawn
/// from bundled artwork. Mastercard is drawn from its published geometry: two
/// circles of equal diameter overlapping, with the intersection in a third
/// colour.
///
/// Visa sits on a white plate. Visa Blue is dark, so on the near black lower
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
            child: Padding(
              // Clear space around the word mark. The plate is proportioned to
              // match the Mastercard symbol beside it, so the mark is centred in
              // it rather than filling it.
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.1,
                vertical: width * 0.09,
              ),
              child: Image.asset(
                _Scheme.visaAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                // The mark is decorative here: NetworkMark already announces the
                // scheme through Semantics.
                excludeFromSemantics: true,
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

/// One frost needle, in coordinates relative to the face.
///
/// Fixed rather than random, so a card looks the same every time it freezes and
/// no seeded generator has to run inside a painter.
class _Crystal {
  const _Crystal(this.x, this.y, this.r, this.rotation, this.delay);

  /// Position as a share of the face, from 0 to 1.
  final double x;
  final double y;

  /// Arm length as a share of the face width.
  final double r;

  final double rotation;

  /// Share of the freeze that passes before this one starts to grow. Set by hand
  /// rather than derived from the position: the needles all sit near an edge now,
  /// so geometry alone would start them together and there would be no creep.
  final double delay;
}

/// Where the frost takes hold.
///
/// All of them hug an edge or a corner, which is where a real card ices up first
/// and, just as usefully, leaves the middle of the face clear so the mark and the
/// scheme artwork still read through the frost. An earlier pass put sixteen large
/// needles across the whole face, including over the mark, and a frozen card
/// stopped looking like a FrostBank card at all.
const List<_Crystal> _frostCrystals = [
  _Crystal(0.07, 0.05, 0.1, 0.2, 0),
  _Crystal(0.92, 0.96, 0.085, 1.25, 0.06),
  _Crystal(0.91, 0.07, 0.085, 1.1, 0.14),
  _Crystal(0.06, 0.95, 0.095, 0.45, 0.2),
  _Crystal(0.04, 0.3, 0.075, 0.9, 0.3),
  _Crystal(0.96, 0.38, 0.08, 0.3, 0.36),
  _Crystal(0.46, 0.02, 0.07, 0.6, 0.42),
  _Crystal(0.93, 0.7, 0.07, 0.75, 0.46),
  _Crystal(0.06, 0.64, 0.075, 1.4, 0.5),
  _Crystal(0.42, 0.98, 0.065, 0.15, 0.55),
];

class _CardFacePainter extends CustomPainter {
  const _CardFacePainter({
    required this.sheen,
    required this.frost,
    required this.radius,
    this.needles = true,
  });

  final double sheen;

  /// How far the freeze has taken hold, from 0 to 1. A continuous value rather
  /// than a flag, so freezing and thawing are the same code run in opposite
  /// directions.
  final double frost;

  /// Corner radius of the face, needed for the rime that hugs the edge.
  final double radius;

  /// Whether to grow crystals. Off for the small face, where they would be a
  /// scribble at that size and are not worth the path.
  final bool needles;

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

    if (frost <= 0) return;
    _paintFrost(canvas, size, rect);
  }

  /// The freeze.
  ///
  /// Five layers, each a function of [frost], so the whole thing runs backwards
  /// on a thaw with no separate code path:
  ///
  ///   1. a haze whose clear centre closes as the frost rises, which is what
  ///      makes the freeze read as spreading inward rather than fading in
  ///      everywhere at once
  ///   2. rime thickening along the milled edge
  ///   3. needles, each waiting its turn, with the wait shorter the nearer it
  ///      sits to an edge, so growth travels inward behind the haze
  ///   4. a bright snap that peaks halfway through the change and is gone at
  ///      both ends, so it fires on freezing and again on thawing but never
  ///      shows at rest
  ///   5. the settled veil, which cools and flattens the face
  ///
  /// Every layer is a plain shader fill or a stroke. There is deliberately no
  /// [MaskFilter] anywhere: an earlier version blurred each needle and drew each
  /// one separately, which came to 576 draw calls per frame with 288 of them
  /// blurred, and that alone was enough to drop frames and take the rasteriser
  /// down. The needles now accumulate into one [Path] stroked twice, so the whole
  /// freeze costs five draw calls.
  void _paintFrost(Canvas canvas, Size size, Rect rect) {
    const ice = Palette.frostIceWhite;
    const pale = Palette.frostIcePale;

    // Clamped before it reaches a curve. Curve.transform asserts on anything
    // outside the unit range, and a tween that overshoots by a float's width
    // would otherwise take the whole frame down.
    final t = frost.clamp(0.0, 1.0);

    // Stops short of the middle even at full frost, so the mark and the scheme
    // artwork keep their contrast under the ice.
    final clear = ui.lerpDouble(
      1.02,
      0.3,
      Curves.easeIn.transform(t),
    )!.clamp(0.0, 0.995);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          size.width * 0.78,
          [pale.withValues(alpha: 0), pale.withValues(alpha: 0.26 * t)],
          [clear, 1],
        ),
    );

    // Rime along the milled edge, graded outward rather than blurred.
    final thickness = 2 + 6 * t;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(thickness / 2),
        Radius.circular(radius),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..shader = ui.Gradient.radial(
          rect.center,
          size.width * 0.72,
          [ice.withValues(alpha: 0), ice.withValues(alpha: 0.34 * t)],
          const [0.5, 1],
        ),
    );

    if (needles) {
      final path = Path();
      var any = false;

      for (final crystal in _frostCrystals) {
        final local = ((t - crystal.delay) / (1 - crystal.delay)).clamp(
          0.0,
          1.0,
        );
        if (local <= 0) continue;

        final arm =
            crystal.r * size.width * Curves.easeOutCubic.transform(local);
        // Below a pixel there is nothing to see, and a round cap would leave a
        // dot where no crystal has grown yet.
        if (arm < 1) continue;

        _needle(
          path,
          Offset(crystal.x * size.width, crystal.y * size.height),
          arm,
          crystal.rotation,
        );
        any = true;
      }

      if (any) {
        // Two strokes over the same path: a wide soft one for body, a narrow
        // bright one for the crystal itself.
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.8
            ..color = pale.withValues(alpha: 0.3 * t),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 1
            ..color = ice.withValues(alpha: 0.78 * t),
        );
      }
    }

    final snap = math.sin(math.pi * t);
    if (snap > 0.01) {
      canvas.drawRect(
        rect,
        Paint()..color = ice.withValues(alpha: 0.15 * snap),
      );
    }

    canvas.drawRect(rect, Paint()..color = pale.withValues(alpha: 0.09 * t));
  }

  /// Adds one needle to [path]: six arms from a centre, each forking into two
  /// barbs partway out.
  ///
  /// Appends rather than draws, so every needle on the face ends up in a single
  /// path and costs one rasterisation between them.
  static void _needle(
    Path path,
    Offset centre,
    double arm,
    double rotation,
  ) {
    for (var i = 0; i < 6; i++) {
      final angle = rotation + i * math.pi / 3;
      final direction = Offset(math.cos(angle), math.sin(angle));

      path
        ..moveTo(centre.dx, centre.dy)
        ..relativeLineTo(direction.dx * arm, direction.dy * arm);

      final fork = centre + direction * (arm * 0.52);
      for (final side in const [-1.0, 1.0]) {
        final barb = angle + side * math.pi / 3.2;
        path
          ..moveTo(fork.dx, fork.dy)
          ..relativeLineTo(
            math.cos(barb) * arm * 0.36,
            math.sin(barb) * arm * 0.36,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardFacePainter oldDelegate) =>
      oldDelegate.sheen != sheen ||
      oldDelegate.frost != frost ||
      oldDelegate.radius != radius ||
      oldDelegate.needles != needles;
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
          // Not animated, and no crystals. A strip of these can be on screen at
          // once, and the freeze is already told on the full face; paying for it
          // again on a 96 pixel thumbnail is not worth the frames.
          child: CustomPaint(
            painter: _CardFacePainter(
              sheen: 0,
              frost: card.status == CardStatus.frozen ? 1 : 0,
              radius: AppRadius.sm,
              needles: false,
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
