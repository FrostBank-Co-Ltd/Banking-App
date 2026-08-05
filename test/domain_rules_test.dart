import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/data/mock_seed.dart';
import 'package:mobile_bank_app/domain/models.dart';
import 'package:mobile_bank_app/domain/credentials.dart';
import 'package:mobile_bank_app/state/txn_filter.dart';

void main() {
  group('Credentials', () {
    test('rejects a malformed email with the expected format message', () {
      expect(Credentials.emailError('ava.mercado'), isNotNull);
      expect(Credentials.emailError('ava.mercado@northmark.app'), isNull);
    });

    test('requires at least eight password characters', () {
      expect(Credentials.passwordError('short'), isNotNull);
      expect(Credentials.passwordError('longenough'), isNull);
    });
  });

  group('TxnFilter', () {
    final rows = MockSeed.transactions(now: DateTime(2026, 8, 5));

    test('returns every row when no criterion is set', () {
      expect(const TxnFilter().apply(rows).length, rows.length);
    });

    test('narrows to the selected types', () {
      final filtered = TxnFilter(
        types: const {TxnType.deposit},
      ).apply(rows, now: DateTime(2026, 8, 5));
      expect(filtered, isNotEmpty);
      expect(filtered.every((txn) => txn.type == TxnType.deposit), isTrue);
    });

    test('matches merchant text without case sensitivity', () {
      final filtered = TxnFilter(
        query: 'ludlow',
      ).apply(rows, now: DateTime(2026, 8, 5));
      expect(filtered, isNotEmpty);
      expect(
        filtered.every((txn) => txn.merchant.contains('Ludlow')),
        isTrue,
      );
    });

    test('honours the date range', () {
      final filtered = const TxnFilter(
        range: TxnDateRange.last7Days,
      ).apply(rows, now: DateTime(2026, 8, 5, 23, 59));
      expect(filtered, isNotEmpty);
      expect(filtered.length, lessThan(rows.length));
    });

    test('combines criteria and can match nothing', () {
      final filtered = TxnFilter(
        types: const {TxnType.deposit},
        query: 'ludlow',
      ).apply(rows, now: DateTime(2026, 8, 5));
      expect(filtered, isEmpty);
    });
  });

  group('Seed content', () {
    final rows = MockSeed.transactions(now: DateTime(2026, 8, 5));

    test('seeds three accounts and two cards', () {
      expect(MockSeed.accounts.length, 3);
      expect(MockSeed.cards.length, 2);
    });

    test('seeds at least forty transactions across sixty days or more', () {
      expect(rows.length, greaterThanOrEqualTo(40));
      final span = rows.first.date.difference(rows.last.date).inDays;
      expect(span, greaterThanOrEqualTo(60));
    });

    test('includes a pending row and a failed row', () {
      expect(rows.any((txn) => txn.status == TxnStatus.pending), isTrue);
      expect(rows.any((txn) => txn.status == TxnStatus.failed), isTrue);
    });

    test('card digits pass the Luhn check for their scheme', () {
      for (final card in MockSeed.cards) {
        final digits = card.number
            .replaceAll(' ', '')
            .split('')
            .map(int.parse)
            .toList()
            .reversed
            .toList();
        var sum = 0;
        for (var index = 0; index < digits.length; index++) {
          var digit = digits[index];
          if (index.isOdd) {
            digit *= 2;
            if (digit > 9) digit -= 9;
          }
          sum += digit;
        }
        expect(sum % 10, 0, reason: '${card.label} fails the Luhn check');
      }
    });

    test('masks a card number down to the last four digits', () {
      expect(MockSeed.cards.first.maskedNumber, endsWith('1879'));
      expect(MockSeed.cards.first.maskedNumber.contains('4137'), isFalse);
    });
  });
}
