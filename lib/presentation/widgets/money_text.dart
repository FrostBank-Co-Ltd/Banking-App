import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/money.dart';
import '../../state/providers.dart';

/// Renders a monetary figure in GeistMono, honours the masking preference, and
/// speaks the amount and currency in words to a screen reader.
class MoneyText extends ConsumerWidget {
  const MoneyText(
    this.value, {
    this.style,
    this.color,
    this.currencyCode = 'USD',
    this.signed = false,
    this.label,
    this.maskable = true,
    this.textAlign,
    super.key,
  });

  final double value;
  final TextStyle? style;
  final Color? color;
  final String currencyCode;
  final bool signed;

  /// Prefixed to the spoken label, for example the account name.
  final String? label;
  final bool maskable;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden =
        maskable && ref.watch(preferencesProvider).balancesHidden;
    final tokens = context.tokens;
    final resolved = (style ?? AppType.numericMedium).copyWith(
      color: color ?? tokens.textPrimary,
    );

    final visible = hidden
        ? Money.maskGlyphs
        : Money.format(value, currencyCode: currencyCode, signed: signed);

    final spoken = hidden
        ? 'Amount hidden'
        : [
            ?label,
            Money.spoken(value, currencyCode: currencyCode, signed: signed),
          ].join(', ');

    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Text(visible, style: resolved, textAlign: textAlign),
      ),
    );
  }
}

/// Hero balance figure. Announces the account name and the new value whenever
/// the figure changes.
class HeroBalance extends ConsumerStatefulWidget {
  const HeroBalance({
    required this.accountName,
    required this.value,
    required this.currencyCode,
    this.color,
    super.key,
  });

  final String accountName;
  final double value;
  final String currencyCode;
  final Color? color;

  @override
  ConsumerState<HeroBalance> createState() => _HeroBalanceState();
}

class _HeroBalanceState extends ConsumerState<HeroBalance> {
  @override
  void didUpdateWidget(HeroBalance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.accountName != widget.accountName) {
      final hidden = ref.read(preferencesProvider).balancesHidden;
      // Accessibility: a changed balance is spoken with the account it belongs
      // to, because the figure alone gives no context.
      SemanticsService.sendAnnouncement(
        View.of(context),
        hidden
            ? '${widget.accountName}, balance hidden'
            : '${widget.accountName}, '
                  '${Money.spoken(widget.value, currencyCode: widget.currencyCode)}',
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // State transition: a new balance fades and lifts into place so the change
    // reads as an update rather than a redraw.
    return AnimatedSwitcher(
      duration: Motion.resolve(context, Motion.medium),
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: MoneyText(
        widget.value,
        key: ValueKey('${widget.accountName}:${widget.value}'),
        style: AppType.numericHero,
        color: widget.color,
        currencyCode: widget.currencyCode,
        label: widget.accountName,
      ),
    );
  }
}

/// Non monetary numeric text, for example a crypto quantity.
class NumericText extends StatelessWidget {
  const NumericText(this.text, {this.style, this.color, this.label, super.key});

  final String text;
  final TextStyle? style;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? AppType.numericSmall).copyWith(
      color: color ?? context.tokens.textPrimary,
    );
    if (label == null) return Text(text, style: resolved);
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: Text(text, style: resolved)),
    );
  }
}
