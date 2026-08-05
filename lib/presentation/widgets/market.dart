import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/money.dart';

/// Round mark for a crypto pair.
///
/// Each coin's own colour, with the ticker set on top. Drawn rather than shipped
/// as artwork, so there is no asset to keep in step and no third party logo
/// reproduced.
class CoinBadge extends StatelessWidget {
  const CoinBadge({required this.code, this.size = 40, super.key});

  final String code;
  final double size;

  /// Coin colours, as each project publishes them. Kept out of [Palette]
  /// because they are not FrostBank's.
  static const Map<String, Color> _colors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'SOL': Color(0xFF9945FF),
    'XRP': Color(0xFF2D3748),
    'LTC': Color(0xFF345D9D),
    'ADA': Color(0xFF0033AD),
    'DOGE': Color(0xFFC2A633),
  };

  static Color colorFor(String code) =>
      _colors[code.toUpperCase()] ?? Palette.frostLift;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(code);

    return Semantics(
      label: code,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.28)!],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.34),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: Text(
            code.toUpperCase(),
            style: AppType.labelSmall.copyWith(
              color: Colors.white,
              fontSize: size * 0.235,
              letterSpacing: 0,
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// A market move, coloured by direction.
///
/// Direction is carried by an arrow as well as by colour, so it survives a
/// colour vision deficiency and a greyscale screenshot.
class MoveBadge extends StatelessWidget {
  const MoveBadge({
    required this.percentChange,
    this.amountChange,
    this.currencyCode = 'USD',
    this.compact = false,
    this.onBrand = false,
    super.key,
  });

  final double percentChange;

  /// Absolute move. Shown alongside the percentage when there is room.
  final double? amountChange;

  final String currencyCode;

  /// Trailing form for a list row: one line, no plate.
  final bool compact;

  /// True when the badge sits on the dark brand surface.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isUp = percentChange >= 0;

    // On the brand surface the sheet's semantic greens and reds are too dark to
    // read, so the badge steps up to the brighter pair.
    final color = onBrand
        ? (isUp ? const Color(0xFF6EE7A0) : const Color(0xFFFF9A9A))
        : (isUp ? tokens.success : tokens.error);

    final icon = Icon(
      isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
      size: compact ? 14 : 18,
      color: color,
    );

    final amount = amountChange;

    if (compact) {
      return Semantics(
        label: Money.percentSpoken(percentChange),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              Text(
                amount == null
                    ? Money.percent(percentChange)
                    : '${Money.priceChange(amount, currencyCode: currencyCode)}'
                          '  ${Money.percent(percentChange)}',
                style: AppType.numericSmall.copyWith(
                  color: color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: Money.percentSpoken(percentChange),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.only(
            left: Space.x1,
            right: Space.x3,
            top: 3,
            bottom: 3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: onBrand ? 0.18 : 0.14),
            borderRadius: AppRadius.all(AppRadius.pill),
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              Text(
                Money.percent(percentChange),
                style: AppType.numericSmall.copyWith(color: color),
              ),
              if (amount != null) ...[
                const SizedBox(width: Space.x2),
                Text(
                  Money.priceChange(amount, currencyCode: currencyCode),
                  style: AppType.numericSmall.copyWith(
                    color: color.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cross fades a live figure in place, so a new quote reads as an update to the
/// same number rather than a redraw.
class LiveValueSwap extends StatelessWidget {
  const LiveValueSwap({
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.resolve(context, Motion.medium),
    switchInCurve: Motion.standard,
    switchOutCurve: Motion.standard,
    layoutBuilder: (currentChild, previousChildren) =>
        Stack(alignment: alignment, children: [...previousChildren, ?currentChild]),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );
}
