import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/candle_chart.dart';
import '../widgets/market.dart';
import '../widgets/money_text.dart';
import '../widgets/motion_effects.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// One crypto pair: the live quote, the session range, the price history over a
/// selectable span, and the position held in it.
class CryptoDetailScreen extends ConsumerStatefulWidget {
  const CryptoDetailScreen({required this.code, super.key});

  final String code;

  @override
  ConsumerState<CryptoDetailScreen> createState() =>
      _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends ConsumerState<CryptoDetailScreen> {
  ChartRange _range = ChartRange.week;

  @override
  Widget build(BuildContext context) {
    final code = widget.code.toUpperCase();
    final asset = ref.watch(cryptoAssetProvider(code));
    final quote = ref.watch(cryptoQuoteProvider(code));
    final quantity = ref.watch(cryptoHoldingProvider(code));

    if (asset == null) {
      return Scaffold(
        appBar: AppBar(title: Text(code)),
        body: ResponsiveShell(
          child: Padding(
            padding: const EdgeInsets.all(Space.x5),
            child: ErrorStateView(
              message: '$code is not one of the tracked pairs.',
              onRetry: () => context.pop(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${asset.name} (${asset.code})'),
        actions: [
          IconButton(
            onPressed: () {
              ref
                ..invalidate(cryptoQuotesProvider)
                ..invalidate(
                  cryptoSeriesProvider((code: code, range: _range)),
                );
            },
            tooltip: 'Refresh prices',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: Space.x1),
        ],
      ),
      body: ResponsiveShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x2,
            Space.x5,
            Space.x12,
          ),
          children: [
            AsyncSection<CryptoQuote?>(
              value: quote,
              onRetry: () => ref.invalidate(cryptoQuotesProvider),
              skeleton: const _QuoteSkeleton(),
              isEmpty: (value) => value == null,
              empty: ErrorStateView(
                message: 'No live quote for ${asset.code} right now.',
                onRetry: () => ref.invalidate(cryptoQuotesProvider),
              ),
              builder: (value) => _QuoteHeader(quote: value!),
            ),
            const SizedBox(height: Space.x6),
            FadeSlideIn(
              index: 1,
              child: _RangeBar(
                selected: _range,
                onSelect: (range) => setState(() => _range = range),
              ),
            ),
            const SizedBox(height: Space.x4),
            AsyncSection<CryptoSeries>(
              value: ref.watch(
                cryptoSeriesProvider((code: code, range: _range)),
              ),
              onRetry: () => ref.invalidate(
                cryptoSeriesProvider((code: code, range: _range)),
              ),
              skeleton: const SkeletonBlock(
                height: 220,
                radius: AppRadius.lg,
              ),
              builder: (series) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SeriesSummary(series: series),
                  const SizedBox(height: Space.x2),
                  CandleChart(series: series),
                ],
              ),
            ),
            const SizedBox(height: Space.x6),
            FadeSlideIn(
              index: 2,
              child: _Holding(
                asset: asset,
                quantity: quantity,
                price: quote.value?.price,
              ),
            ),
            const SizedBox(height: Space.x5),
            FadeSlideIn(
              index: 3,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.push('/soon/buy-crypto'),
                      child: const Text('Buy'),
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: quantity > 0
                          ? () => context.push('/soon/sell-crypto')
                          : null,
                      child: const Text('Sell'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x5),
            Text(
              'Live prices from Twelve Data. The position shown is mock ledger '
              'data valued at the live price.',
              style: AppType.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Price and session range. Volume is deliberately absent: Twelve Data does not
/// publish it for these crypto pairs, and an invented figure on a banking screen
/// is worse than one fewer figure.
class _QuoteHeader extends StatelessWidget {
  const _QuoteHeader({required this.quote});

  final CryptoQuote quote;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _Figure(
          label: '1 ${quote.code} / ${quote.symbol.split('/').last}',
          value: LiveValueSwap(
            child: Text(
              Money.price(quote.price),
              key: ValueKey(quote.price),
              style: AppType.numericLarge.copyWith(
                color: context.tokens.textPrimary,
              ),
            ),
          ),
          footer: MoveBadge(
            percentChange: quote.percentChange,
            amountChange: quote.change,
            compact: true,
          ),
        ),
      ),
      const SizedBox(width: Space.x4),
      Expanded(
        child: _Figure(
          label: '24h range',
          value: Text(
            Money.price(quote.dayHigh),
            style: AppType.numericLarge.copyWith(
              color: context.tokens.textPrimary,
            ),
          ),
          footer: Text(
            'low ${Money.price(quote.dayLow)}',
            style: AppType.numericSmall.copyWith(
              color: context.tokens.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ),
    ],
  );
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.footer,
  });

  final String label;
  final Widget value;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppType.bodySmall.copyWith(color: context.tokens.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: Space.x1),
      value,
      const SizedBox(height: Space.x1),
      footer,
    ],
  );
}

/// Span selector. The selected span carries a filled plate rather than only a
/// colour, so selection survives a greyscale screen.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.selected, required this.onSelect});

  final ChartRange selected;
  final ValueChanged<ChartRange> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          for (final range in ChartRange.values)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(range),
                borderRadius: AppRadius.pill,
                minSize: 36,
                semanticLabel:
                    '${range.spokenLabel}'
                    '${range == selected ? ', selected' : ''}',
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: range == selected ? 1 : 0),
                  duration: Motion.resolve(context, Motion.short),
                  curve: Motion.standard,
                  builder: (context, t, _) => Container(
                    padding: const EdgeInsets.symmetric(vertical: Space.x2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        tokens.interactivePrimary,
                        t,
                      ),
                      borderRadius: AppRadius.all(AppRadius.pill),
                    ),
                    child: Text(
                      range.label,
                      style: AppType.labelSmall.copyWith(
                        color: Color.lerp(
                          tokens.textSecondary,
                          tokens.textOnBrand,
                          t,
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Move across the charted span, so the chart is readable without tracing it.
class _SeriesSummary extends StatelessWidget {
  const _SeriesSummary({required this.series});

  final CryptoSeries series;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      MoveBadge(
        percentChange: series.percentChange,
        amountChange: series.change,
        compact: true,
      ),
      const SizedBox(width: Space.x2),
      Expanded(
        child: Text(
          'over ${series.range.spokenLabel.toLowerCase()}, to '
          '${Dates.dayAndTime(series.candles.last.at)}',
          style: AppType.bodySmall.copyWith(
            color: context.tokens.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

/// The holder's position, valued at the live price.
class _Holding extends StatelessWidget {
  const _Holding({
    required this.asset,
    required this.quantity,
    required this.price,
  });

  final CryptoAsset asset;
  final double quantity;
  final double? price;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SoftCard(
      padding: const EdgeInsets.all(Space.x4),
      child: Row(
        children: [
          CoinBadge(code: asset.code, size: 36),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your ${asset.code} balance',
                  style: AppType.bodySmall.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quantity > 0
                      ? Money.quantity(quantity, asset.code)
                      : 'None held',
                  style: AppType.numericMedium.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (price != null && quantity > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  asset.quote,
                  style: AppType.bodySmall.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  quantity * price!,
                  style: AppType.numericMedium,
                  label: '${asset.code} holding value',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _QuoteSkeleton extends StatelessWidget {
  const _QuoteSkeleton();

  @override
  Widget build(BuildContext context) => Row(
    children: const [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 80, height: 12),
            SizedBox(height: Space.x2),
            SkeletonBlock(width: 120, height: 26),
            SizedBox(height: Space.x2),
            SkeletonBlock(width: 90, height: 12),
          ],
        ),
      ),
      SizedBox(width: Space.x4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBlock(width: 70, height: 12),
            SizedBox(height: Space.x2),
            SkeletonBlock(width: 110, height: 26),
            SizedBox(height: Space.x2),
            SkeletonBlock(width: 80, height: 12),
          ],
        ),
      ),
    ],
  );
}
