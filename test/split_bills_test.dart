import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_bank_app/core/format/money.dart';
import 'package:mobile_bank_app/domain/models.dart';
import 'package:mobile_bank_app/domain/split_bill_model.dart';
import 'package:mobile_bank_app/state/providers.dart';
import 'package:mobile_bank_app/state/split_bills_controller.dart';

void main() {
  group('Split Bills State & Domain', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('creates a split bill and calculates equal shares correctly', () {
      final controller = container.read(splitBillsProvider.notifier);

      controller.createBill(
        title: 'Friday Dinner',
        totalAmount: 120.00,
        category: 'Food & Dining',
        participantNames: ['Alice', 'Bob', 'Charlie'],
      );

      final bills = container.read(splitBillsProvider);
      final newBill = bills.first;

      expect(newBill.title, 'Friday Dinner');
      expect(newBill.totalAmount, 120.00);
      expect(newBill.participants.length, 4); // Host + 3 friends
      expect(newBill.participants.first.shareAmount, 30.00);
      expect(newBill.participants.first.isPaid, isTrue); // Host auto paid
      expect(newBill.paidCount, 1);
      expect(newBill.remainingBalance, 90.00);
    });

    test('confirming payment updates participant status, remaining balance, and records transaction', () async {
      final controller = container.read(splitBillsProvider.notifier);
      final bills = container.read(splitBillsProvider);
      final bill = bills.first;

      final pendingParticipant = bill.participants.firstWhere((p) => !p.isPaid);

      final success = controller.confirmPayment(
        billId: bill.id,
        participantId: pendingParticipant.id,
        payingAccountId: 'acc_wallet',
        currencyCode: 'USD',
      );

      expect(success, isTrue);

      final updatedBills = container.read(splitBillsProvider);
      final updatedBill = updatedBills.firstWhere((b) => b.id == bill.id);
      final updatedParticipant = updatedBill.participants.firstWhere((p) => p.id == pendingParticipant.id);

      expect(updatedParticipant.isPaid, isTrue);
      expect(updatedBill.remainingBalance, bill.remainingBalance - pendingParticipant.shareAmount);

      // Verify transaction was added to MockDataSource
      final ds = container.read(mockDataSourceProvider);
      final txns = await ds.transactions();

      expect(txns.any((t) => t.type == TxnType.qrPayment && t.amount == pendingParticipant.shareAmount), isTrue);
    });

    test('generates valid JSON QR code payload', () {
      const participant = SplitBillParticipant(
        id: 'p123',
        name: 'Alice',
        shareAmount: 25.00,
      );

      final payload = participant.generateQrPayload('bill_999', 'Weekend Trip');
      expect(payload, contains('"type":"split_bill_payment"'));
      expect(payload, contains('"billId":"bill_999"'));
      expect(payload, contains('"participantId":"p123"'));
      expect(payload, contains('"amount":25.0'));
    });
  });

  group('Currency Preferences', () {
    test('formats balances with supported currency symbols', () {
      expect(Money.format(100.0, currencyCode: 'EUR'), '€100.00');
      expect(Money.format(100.0, currencyCode: 'GBP'), '£100.00');
      expect(Money.format(100.0, currencyCode: 'JPY'), '¥100.00');
      expect(Money.format(100.0, currencyCode: 'PHP'), '₱100.00');
    });

    test('converts amounts between currencies using real-time exchange rates', () {
      expect(Money.convert(100.0, fromCurrency: 'USD', toCurrency: 'PHP'), 5800.0);
      expect(Money.convert(100.0, fromCurrency: 'USD', toCurrency: 'EUR'), 92.0);
      expect(Money.convert(100.0, fromCurrency: 'USD', toCurrency: 'GBP'), 78.0);
      expect(Money.convert(100.0, fromCurrency: 'USD', toCurrency: 'JPY'), 15500.0);
      expect(Money.convert(58.0, fromCurrency: 'PHP', toCurrency: 'USD'), 1.0);
    });

    test('updates preferences controller state', () {
      final container = ProviderContainer();
      final prefsController = container.read(preferencesProvider.notifier);

      expect(container.read(preferencesProvider).currencyCode, 'USD');

      prefsController.setCurrencyCode('EUR');
      expect(container.read(preferencesProvider).currencyCode, 'EUR');
      expect(container.read(preferencesProvider).activeCurrency.symbol, '€');
    });
  });
}
