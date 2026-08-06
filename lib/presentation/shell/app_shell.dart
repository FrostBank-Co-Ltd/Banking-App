import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/glass.dart';
import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../widgets/brand.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/pressable.dart';
import 'destinations.dart';

/// Floating liquid glass navigation over the branch in view.
///
/// The bar refracts whatever scrolls beneath it rather than sitting on an opaque
/// fill, and selection is carried by one capsule that travels between slots
/// instead of five independent highlights. See [_SelectionCapsule] for why that
/// distinction matters to how the bar reads.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _go(int branch) => navigationShell.goBranch(
    branch,
    // Selecting the active destination returns that branch to its first route.
    initialLocation: branch == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.tokens.backgroundAlt,
    // The body runs under the bar, which is the whole point of the glass.
    extendBody: true,
    body: navigationShell,
    bottomNavigationBar: _GlassNavBar(
      activeBranch: navigationShell.currentIndex,
      onSelect: _go,
    ),
  );
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.activeBranch, required this.onSelect});

  final int activeBranch;
  final ValueChanged<int> onSelect;

  static const double _height = 68;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(bottom: Space.x4),
    // heightFactor is load bearing. Scaffold hands its bottom slot a loose
    // height of the whole screen, and an Align without a height factor takes all
    // of it, which parks the pill in the vertical centre of the display.
    child: Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.x5),
          child: SizedBox(
            width: double.infinity,
            height: _height,
            child: LiquidGlass(
              // The pill token is a sentinel, not a measurement. Clamping it to
              // half the height gives the same stadium while keeping the radii
              // well formed for the rim and capsule painters.
              borderRadius: AppRadius.all(
                math.min(AppRadius.pill, _height / 2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SelectionCapsule(
                    slot: ShellDestinations.slotOf(activeBranch),
                    height: _height,
                  ),
                  Row(
                    children: [
                      for (final destination in ShellDestinations.ordered)
                        Expanded(
                          child: destination.branch == 0
                              ? _HomeMark(
                                  label: destination.label,
                                  isActive: activeBranch == 0,
                                  onTap: () => onSelect(0),
                                )
                              : _NavItem(
                                  destination: destination,
                                  isActive: activeBranch == destination.branch,
                                  onTap: () => onSelect(destination.branch),
                                ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The one moving part of the bar: a glass capsule that slides from the slot it
/// was in to the slot that was tapped.
///
/// A shared indicator, rather than a highlight per item, is what makes the bar
/// read as one surface with a selection on it instead of five buttons. It is
/// painted rather than laid out, so it can stretch and squash without pushing
/// the items around, and so it needs no second [BackdropFilter] on top of the
/// pane's own.
///
/// The liquid part is squash and stretch. While travelling, the capsule widens
/// by an amount proportional to the distance it has to cover and loses a little
/// height, both peaking at the halfway point. The position itself overshoots on
/// [Motion.settle] and comes back, so it arrives under its own weight. Both
/// effects flatten to nothing under reduced motion, leaving a plain slide.
class _SelectionCapsule extends StatefulWidget {
  const _SelectionCapsule({required this.slot, required this.height});

  final int slot;
  final double height;

  @override
  State<_SelectionCapsule> createState() => _SelectionCapsuleState();
}

class _SelectionCapsuleState extends State<_SelectionCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _travel = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );

  /// Slot the current run started from. A double rather than an int, because a
  /// tap that lands mid travel starts its run from wherever the capsule
  /// currently is.
  late double _from = widget.slot.toDouble();
  late int _to = widget.slot;

  /// Where the capsule sits right now, in slots.
  double get _position => ui.lerpDouble(
    _from,
    _to.toDouble(),
    Motion.settle.transform(_travel.value.clamp(0.0, 1.0)),
  )!;

  @override
  void didUpdateWidget(_SelectionCapsule old) {
    super.didUpdateWidget(old);
    if (widget.slot == _to) return;

    if (Motion.isReduced(context)) {
      _from = widget.slot.toDouble();
      _to = widget.slot;
      _travel.value = 1;
      return;
    }
    // Retargeting from the live position means a second tap mid travel bends the
    // path rather than snapping back to the slot the first tap left.
    _from = _travel.isAnimating ? _position : _to.toDouble();
    _to = widget.slot;
    _travel.forward(from: 0);
  }

  @override
  void dispose() {
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = Glass.of(context);
    final reducedGlass = Glass.isReduced(context);

    return AnimatedBuilder(
      animation: _travel,
      builder: (context, _) => SizedBox.expand(
        child: CustomPaint(
          painter: _CapsulePainter(
            from: _from,
            to: _to.toDouble(),
            progress: _travel.value,
            stretch: Motion.amount(context, 1),
            fill: glass.indicator,
            rim: glass.indicatorRim,
            glow: reducedGlass ? const Color(0x00000000) : glass.indicatorGlow,
          ),
        ),
      ),
    );
  }
}

class _CapsulePainter extends CustomPainter {
  const _CapsulePainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.stretch,
    required this.fill,
    required this.rim,
    required this.glow,
  });

  final double from;
  final double to;
  final double progress;

  /// Scales squash and stretch to zero under reduced motion.
  final double stretch;

  final List<Color> fill;
  final Color rim;
  final Color glow;

  /// Widest the capsule is allowed to get, so it stays a capsule on a tablet
  /// width bar rather than growing into a slab.
  static const double _maxWidth = 66;
  static const double _inset = Space.x2;

  @override
  void paint(Canvas canvas, Size size) {
    final slotWidth = size.width / ShellDestinations.count;
    final restWidth = math.min(slotWidth - _inset, _maxWidth);
    final restHeight = size.height - _inset * 2;

    final t = progress.clamp(0.0, 1.0);
    final travelled = Motion.settle.transform(t);
    // Peaks at the midpoint of the journey and is gone at both ends.
    final smear = math.sin(math.pi * t) * stretch;
    final reach = math.min((to - from).abs() * 0.14, 0.34);

    final width = restWidth * (1 + reach * smear);
    final height = restHeight * (1 - 0.1 * reach * smear);

    final centreX =
        ui.lerpDouble(from + 0.5, to + 0.5, travelled)! * slotWidth;

    final rect = Rect.fromCenter(
      center: Offset(centreX, size.height / 2),
      width: width,
      height: height,
    );
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(height / 2),
    );

    // The brand colour arrives as light spilling from under the capsule rather
    // than as fill, which is what keeps the selected destination reading as a
    // brighter piece of glass instead of a painted button.
    if (glow.a > 0) {
      canvas.drawRRect(
        shape.inflate(1.5),
        Paint()
          ..color = glow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawRRect(
      shape,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          fill,
        ),
    );

    // Rim, brightest across the top where the pane's own light lands.
    canvas.drawRRect(
      shape.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [rim, rim.withValues(alpha: rim.a * 0.3), rim.withValues(alpha: rim.a * 0.55)],
          const [0, 0.6, 1],
        ),
    );

    // A short highlight across the top third, so the capsule has a face and not
    // just an outline.
    canvas.save();
    canvas.clipRRect(shape);
    final crown = Rect.fromLTWH(rect.left, rect.top, rect.width, height * 0.42);
    canvas.drawRect(
      crown,
      Paint()
        ..shader = ui.Gradient.linear(
          crown.topCenter,
          crown.bottomCenter,
          [
            rim.withValues(alpha: rim.a * 0.3),
            rim.withValues(alpha: 0),
          ],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter old) =>
      old.progress != progress ||
      old.from != from ||
      old.to != to ||
      old.stretch != stretch ||
      old.rim != rim ||
      old.glow != glow;
}

/// The brand mark in the centre slot.
///
/// Selection here is a lift and nothing else. The shared capsule already marks
/// the destination in view, and an earlier version added a ring and a coloured
/// glow on top of it, which stacked into a blob around the mark.
class _HomeMark extends StatelessWidget {
  const _HomeMark({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: '$label${isActive ? ', selected' : ''}',
    borderRadius: AppRadius.pill,
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isActive ? 1 : 0),
        duration: Motion.resolve(context, Motion.medium),
        curve: Motion.emphasized,
        builder: (context, t, child) => Transform.scale(
          scale: 1 + 0.08 * t,
          child: Transform.translate(
            offset: Offset(0, Motion.amount(context, -2) * t),
            child: child,
          ),
        ),
        child: const FrostMark(size: 38),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = Glass.of(context);

    return Pressable(
      onTap: onTap,
      semanticLabel: '${destination.label}${isActive ? ', selected' : ''}',
      borderRadius: AppRadius.pill,
      // Selection is a single driver, so the tint, the lift, the icon size, and
      // the glyph glow all resolve on one timeline instead of drifting apart.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isActive ? 1 : 0),
        duration: Motion.resolve(context, Motion.medium),
        curve: Motion.emphasized,
        builder: (context, t, _) {
          final color = Color.lerp(glass.onGlassMuted, glass.onGlass, t)!;
          // A see through pane cannot guarantee contrast, so each glyph carries
          // its own halo. This is what lets the tint stay low enough to read the
          // backdrop through the bar.
          final halo = <Shadow>[
            Shadow(color: glass.glyphShadow, blurRadius: 5),
            if (t > 0)
              Shadow(
                color: glass.indicatorGlow.withValues(
                  alpha: glass.indicatorGlow.a * t,
                ),
                blurRadius: 14 * t,
              ),
          ];

          return Transform.translate(
            offset: Offset(0, Motion.amount(context, -1.5) * t),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  destination.icon,
                  size: 20 + 2 * t,
                  color: color,
                  shadows: halo,
                ),
                const SizedBox(height: 5),
                Text(
                  destination.label,
                  style: AppType.labelSmall.copyWith(
                    color: color,
                    fontSize: 9.5,
                    letterSpacing: 0.2,
                    shadows: halo,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
