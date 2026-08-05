import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../domain/models.dart';

/// Open, high, low, close chart for one pair over one span.
///
/// Every bar drawn here is real market data. The series is aggregated down to
/// whatever the available width can show as readable candles, so a six month
/// span on a phone becomes wider bars rather than a picket fence.
///
/// The chart draws itself in from left to right on arrival and on every span
/// change, which is what makes a span switch read as new data rather than a
/// redraw. Under reduced motion it paints complete immediately.
class CandleChart extends StatefulWidget {
  const CandleChart({
    required this.series,
    this.height = 220,
    this.currencyCode = 'USD',
    super.key,
  });

  final CryptoSeries series;
  final double height;
  final String currencyCode;

  /// Logical pixels per candle, body plus gap. Sets how far the series is
  /// aggregated for a given width.
  static const double _slotWidth = 9;

  /// Width reserved for the price axis labels on the right.
  static const double axisWidth = 54;

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: Motion.long,
  );

  @override
  void initState() {
    super.initState();
    _draw.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _replay();
  }

  @override
  void didUpdateWidget(CandleChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new span, or a new pair, is new information and earns a redraw. A
    // refreshed quote on the same span is not.
    if (oldWidget.series.range != widget.series.range ||
        oldWidget.series.symbol != widget.series.symbol) {
      _replay();
    }
  }

  void _replay() {
    if (Motion.isReduced(context)) {
      _draw.value = 1;
      return;
    }
    _draw.forward(from: 0);
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      label:
          '${widget.series.range.spokenLabel} chart, '
          '${widget.series.candles.length} bars, '
          '${Money.percentSpoken(widget.series.percentChange)}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final plotWidth = (constraints.maxWidth - CandleChart.axisWidth)
                  .clamp(1.0, double.infinity);
              final slots = (plotWidth / CandleChart._slotWidth).floor().clamp(
                8,
                400,
              );
              final series = widget.series.downsampled(slots);

              return AnimatedBuilder(
                animation: _draw,
                builder: (context, _) => CustomPaint(
                  painter: _CandlePainter(
                    series: series,
                    progress: Motion.standard.transform(_draw.value),
                    up: tokens.success,
                    down: tokens.error,
                    grid: tokens.border,
                    label: tokens.textSecondary,
                    axisWidth: CandleChart.axisWidth,
                    currencyCode: widget.currencyCode,
                    textDirection: Directionality.of(context),
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.series,
    required this.progress,
    required this.up,
    required this.down,
    required this.grid,
    required this.label,
    required this.axisWidth,
    required this.currencyCode,
    required this.textDirection,
  });

  final CryptoSeries series;
  final double progress;
  final Color up;
  final Color down;
  final Color grid;
  final Color label;
  final double axisWidth;
  final String currencyCode;
  final TextDirection textDirection;

  /// Rows of price gridline and label.
  static const int _gridRows = 4;

  /// Room under the plot for the date axis.
  static const double _dateAxisHeight = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final candles = series.candles;
    if (candles.isEmpty) return;

    final plot = Rect.fromLTWH(
      0,
      4,
      size.width - axisWidth,
      size.height - _dateAxisHeight - 4,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    // Pad the range so the extremes are not welded to the frame.
    final low = series.low;
    final high = series.high;
    final span = (high - low).abs() < 1e-9 ? (high.abs() * 0.01 + 1) : high - low;
    final padded = span * 0.08;
    final minY = low - padded;
    final maxY = high + padded;

    double yFor(double price) =>
        plot.bottom - ((price - minY) / (maxY - minY)) * plot.height;

    _paintGrid(canvas, size, plot, minY, maxY, yFor);

    final slot = plot.width / candles.length;
    // Leave a hairline of air between bodies, and never draw a zero width body.
    final bodyWidth = (slot * 0.66).clamp(1.0, 14.0);

    // The draw in reveals whole candles left to right.
    final revealed = (candles.length * progress).ceil().clamp(
      0,
      candles.length,
    );

    for (var index = 0; index < revealed; index++) {
      final candle = candles[index];
      final centre = plot.left + slot * (index + 0.5);
      final colour = candle.isUp ? up : down;

      final wick = Paint()
        ..color = colour.withValues(alpha: 0.85)
        ..strokeWidth = (bodyWidth * 0.16).clamp(0.8, 2.0)
        ..isAntiAlias = true;

      canvas.drawLine(
        Offset(centre, yFor(candle.high)),
        Offset(centre, yFor(candle.low)),
        wick,
      );

      final openY = yFor(candle.open);
      final closeY = yFor(candle.close);
      final top = openY < closeY ? openY : closeY;
      final bottom = openY < closeY ? closeY : openY;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          // A doji would otherwise vanish, so the body keeps a minimum height.
          Rect.fromLTRB(
            centre - bodyWidth / 2,
            top,
            centre + bodyWidth / 2,
            bottom - top < 1 ? top + 1 : bottom,
          ),
          Radius.circular(bodyWidth * 0.18),
        ),
        Paint()..color = colour,
      );
    }

    _paintDateAxis(canvas, size, plot, slot, revealed);
  }

  void _paintGrid(
    Canvas canvas,
    Size size,
    Rect plot,
    double minY,
    double maxY,
    double Function(double) yFor,
  ) {
    final line = Paint()
      ..color = grid.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    for (var row = 0; row <= _gridRows; row++) {
      final price = minY + (maxY - minY) * (row / _gridRows);
      final y = yFor(price);

      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), line);

      _text(
        canvas,
        Money.axis(price),
        Offset(plot.right + 6, y - 6),
        maxWidth: axisWidth - 6,
      );
    }
  }

  void _paintDateAxis(
    Canvas canvas,
    Size size,
    Rect plot,
    double slot,
    int revealed,
  ) {
    if (revealed == 0) return;

    final candles = series.candles;
    // Four stamps at most, so the axis never crowds on a narrow screen.
    final stride = (candles.length / 4).ceil().clamp(1, candles.length);
    final intraday = series.range.isIntraday;

    for (var index = 0; index < revealed; index += stride) {
      final centre = plot.left + slot * (index + 0.5);
      final at = candles[index].at;
      _text(
        canvas,
        intraday ? Dates.clock(at) : Dates.monthDay(at),
        Offset(centre - 20, plot.bottom + 4),
        maxWidth: 44,
        align: TextAlign.center,
      );
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset at, {
    required double maxWidth,
    TextAlign align = TextAlign.start,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: AppType.numericSmall.copyWith(color: label, fontSize: 10),
      ),
      textAlign: align,
      textDirection: textDirection,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, at);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.series != series ||
      oldDelegate.up != up ||
      oldDelegate.down != down;
}
