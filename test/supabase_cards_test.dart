import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/data/supabase_repositories.dart';
import 'package:mobile_bank_app/domain/models.dart';

void main() {
  group('SupabaseMappers Card Tests', () {
    test('cardFromMap parses string and integer IDs correctly', () {
      final map = {
        'id': 'card_99',
        'account_id': 'acc_wallet',
        'label': 'FrostBank Platinum',
        'holder_name': 'Ava Mercado',
        'number': '4137 8947 1175 2043',
        'cvc': '412',
        'expiry': '08/31',
        'network': 'visa',
        'kind': 'debit',
        'status': 'active',
        'balance': 1500.0,
        'currency_code': 'USD',
        'spending_limit': 5000.0,
      };

      final card = SupabaseMappers.cardFromMap(map);
      expect(card.id, equals('card_99'));
      expect(card.accountId, equals('acc_wallet'));
      expect(card.label, equals('FrostBank Platinum'));
      expect(card.network, equals(CardNetwork.visa));
      expect(card.kind, equals(CardKind.debit));
      expect(card.status, equals(CardStatus.active));
      expect(card.spendingLimit, equals(5000.0));
    });

    test('cardFromMap handles integer IDs without crashing', () {
      final map = {
        'id': 101,
        'account_id': 202,
        'label': 'FrostBank Gold',
        'holder_name': 'Ava Mercado',
        'number': '4137 8947 1175 2043',
        'cvc': '412',
        'expiry': '08/31',
        'network': 'mastercard',
        'kind': 'credit',
        'status': 'frozen',
        'balance': 0.0,
        'currency_code': 'USD',
        'spending_limit': 10000.0,
      };

      final card = SupabaseMappers.cardFromMap(map);
      expect(card.id, equals('101'));
      expect(card.accountId, equals('202'));
      expect(card.network, equals(CardNetwork.mastercard));
      expect(card.kind, equals(CardKind.credit));
      expect(card.status, equals(CardStatus.frozen));
    });

    test('BankCard.copyWith updates freeze status correctly', () {
      final card = BankCard(
        id: 'card_1',
        accountId: 'acc_1',
        label: 'Everyday Debit',
        holderName: 'Ava Mercado',
        number: '4137 8947 1175 2043',
        cvc: '123',
        expiry: '12/28',
        network: CardNetwork.visa,
        kind: CardKind.debit,
        status: CardStatus.active,
        balance: 250.0,
        currencyCode: 'USD',
        spendingLimit: 2000.0,
      );

      final frozenCard = card.copyWith(status: CardStatus.frozen);
      expect(frozenCard.status, equals(CardStatus.frozen));
      expect(frozenCard.label, equals('Everyday Debit'));

      final unfrozenCard = frozenCard.copyWith(status: CardStatus.active);
      expect(unfrozenCard.status, equals(CardStatus.active));
    });
  });
}
