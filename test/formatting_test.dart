import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/core/format/dates.dart';
import 'package:mobile_bank_app/core/format/money.dart';

void main() {
  group('Money', () {
    test('formats a balance with grouping and two decimals', () {
      expect(Money.format(12480.55), r'$12,480.55');
    });

    test('signs an outflow and an inflow', () {
      expect(Money.format(-84.37, signed: true), r'-$84.37');
      expect(Money.format(240, signed: true), r'+$240.00');
    });

    test('speaks the amount and the currency in words', () {
      expect(Money.spoken(1240.5), '1,240.50 US dollars');
      expect(Money.spoken(-84.37, signed: true), 'minus 84.37 US dollars');
    });

    test('trims trailing zeros from a crypto quantity', () {
      expect(Money.quantity(0.14382, 'BTC'), '0.14382 BTC');
      expect(Money.quantity(2, 'ETH'), '2 ETH');
    });

    test('renders a percentage with an explicit sign', () {
      expect(Money.percent(-2.41), '-2.4%');
      expect(Money.percent(3.5), '+3.5%');
    });
  });

  group('Dates', () {
    final now = DateTime(2026, 8, 5, 14, 30);

    test('labels today and yesterday', () {
      expect(Dates.dayHeader(now, now: now), 'Today');
      expect(
        Dates.dayHeader(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
    });

    test('falls back to a weekday and month header', () {
      expect(
        Dates.dayHeader(DateTime(2026, 7, 30), now: now),
        'Thursday, 30 July',
      );
    });

    test('reads recent gaps in plain words', () {
      expect(
        Dates.relative(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        Dates.relative(now.subtract(const Duration(hours: 5)), now: now),
        '5 hours ago',
      );
    });
  });
}
