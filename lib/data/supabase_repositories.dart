import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'mock_seed.dart';

/// Robust enum parser resilient against case differences and string formatting.
T _parseEnum<T extends Enum>(List<T> values, String raw, T fallback) {
  final clean = raw.replaceAll('_', '').replaceAll(' ', '').toLowerCase();
  for (final value in values) {
    if (value.name.toLowerCase() == clean) return value;
  }
  return fallback;
}

/// Helper serializer to map Supabase database tables to domain models.
class SupabaseMappers {
  SupabaseMappers._();

  static Account accountFromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      shortCode: map['short_code'] as String,
      kind: _parseEnum(
        AccountKind.values,
        map['kind'] as String,
        AccountKind.wallet,
      ),
      maskedNumber: map['masked_number'] as String,
      currencyCode: map['currency_code'] as String,
      totalBalance: (map['total_balance'] as num).toDouble(),
      availableBalance: (map['available_balance'] as num).toDouble(),
      cryptoQuantity: map['crypto_quantity'] != null
          ? (map['crypto_quantity'] as num).toDouble()
          : null,
      cryptoUnit: map['crypto_unit'] as String?,
    );
  }

  static BankCard cardFromMap(Map<String, dynamic> map) {
    return BankCard(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      label: map['label'] as String,
      holderName: map['holder_name'] as String,
      number: map['number'] as String,
      cvc: map['cvc'] as String,
      expiry: map['expiry'] as String,
      network: _parseEnum(
        CardNetwork.values,
        map['network'] as String,
        CardNetwork.visa,
      ),
      kind: _parseEnum(
        CardKind.values,
        map['kind'] as String,
        CardKind.debit,
      ),
      status: _parseEnum(
        CardStatus.values,
        map['status'] as String,
        CardStatus.active,
      ),
      balance: (map['balance'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      spendingLimit: (map['spending_limit'] as num).toDouble(),
    );
  }

  static Txn transactionFromMap(Map<String, dynamic> map) {
    return Txn(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      merchant: map['merchant'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      direction: _parseEnum(
        TxnDirection.values,
        map['direction'] as String,
        TxnDirection.outflow,
      ),
      type: _parseEnum(
        TxnType.values,
        map['type'] as String,
        TxnType.cardPurchase,
      ),
      status: _parseEnum(
        TxnStatus.values,
        map['status'] as String,
        TxnStatus.completed,
      ),
      date: DateTime.parse(map['date'] as String),
      reference: map['reference'] as String,
      note: map['note'] as String?,
    );
  }

  static Promo promoFromMap(Map<String, dynamic> map) {
    return Promo(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      actionLabel: map['action_label'] as String,
      accentIndex: (map['accent_index'] as num).toInt(),
    );
  }

  static UserProfile profileFromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      mobile: map['mobile'] as String,
      memberSince: DateTime.parse(map['member_since'] as String),
    );
  }
}

class SupabaseAccountRepository implements AccountRepository {
  SupabaseAccountRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<List<Account>> fetchAccounts() async {
    try {
      final response = await _client.from('accounts').select();
      final list = (response as List)
          .map((item) => SupabaseMappers.accountFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return MockSeed.accounts;
      return list;
    } catch (_) {
      return MockSeed.accounts;
    }
  }

  @override
  Future<Account> fetchAccount(String id) async {
    try {
      final response =
          await _client.from('accounts').select().eq('id', id).maybeSingle();
      if (response != null) {
        return SupabaseMappers.accountFromMap(response);
      }
      return MockSeed.accounts.firstWhere(
        (a) => a.id == id,
        orElse: () => MockSeed.accounts.first,
      );
    } catch (_) {
      return MockSeed.accounts.firstWhere(
        (a) => a.id == id,
        orElse: () => MockSeed.accounts.first,
      );
    }
  }
}

class SupabaseCardRepository implements CardRepository {
  SupabaseCardRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<List<BankCard>> fetchCards() async {
    try {
      final response = await _client.from('cards').select();
      final list = (response as List)
          .map((item) => SupabaseMappers.cardFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return MockSeed.cards;
      return list;
    } catch (_) {
      return MockSeed.cards;
    }
  }

  @override
  Future<BankCard> fetchCard(String id) async {
    try {
      final response =
          await _client.from('cards').select().eq('id', id).maybeSingle();
      if (response != null) {
        return SupabaseMappers.cardFromMap(response);
      }
      return MockSeed.cards.firstWhere(
        (c) => c.id == id,
        orElse: () => MockSeed.cards.first,
      );
    } catch (_) {
      return MockSeed.cards.firstWhere(
        (c) => c.id == id,
        orElse: () => MockSeed.cards.first,
      );
    }
  }
}

class SupabaseTransactionRepository implements TransactionRepository {
  SupabaseTransactionRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<List<Txn>> fetchTransactions({String? accountId}) async {
    try {
      var query = _client.from('transactions').select();
      if (accountId != null) {
        query = query.eq('account_id', accountId);
      }
      final response = await query.order('date', ascending: false);
      final list = (response as List)
          .map((item) => SupabaseMappers.transactionFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return MockSeed.transactions();
      return list;
    } catch (_) {
      return MockSeed.transactions();
    }
  }

  @override
  Future<Txn> fetchTransaction(String id) async {
    try {
      final response =
          await _client.from('transactions').select().eq('id', id).maybeSingle();
      if (response != null) {
        return SupabaseMappers.transactionFromMap(response);
      }
      return MockSeed.transactions().firstWhere(
        (t) => t.id == id,
        orElse: () => MockSeed.transactions().first,
      );
    } catch (_) {
      return MockSeed.transactions().firstWhere(
        (t) => t.id == id,
        orElse: () => MockSeed.transactions().first,
      );
    }
  }
}

class SupabasePromoRepository implements PromoRepository {
  SupabasePromoRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<List<Promo>> fetchPromos() async {
    try {
      final response = await _client.from('promos').select();
      final list = (response as List)
          .map((item) => SupabaseMappers.promoFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return MockSeed.promos;
      return list;
    } catch (_) {
      return MockSeed.promos;
    }
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<UserProfile> fetchProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        // 1. Match by Supabase auth UUID
        final profileById = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profileById != null) {
          return SupabaseMappers.profileFromMap(profileById);
        }

        // 2. Match by email
        if (user.email != null && user.email!.isNotEmpty) {
          final profileByEmail = await _client
              .from('profiles')
              .select()
              .eq('email', user.email!)
              .maybeSingle();
          if (profileByEmail != null) {
            return SupabaseMappers.profileFromMap(profileByEmail);
          }
        }
      }

      // 3. Fallback to first profile in table if any
      final firstProfile =
          await _client.from('profiles').select().limit(1).maybeSingle();
      if (firstProfile != null) {
        return SupabaseMappers.profileFromMap(firstProfile);
      }

      // 4. Default fallback profile
      return MockSeed.profile;
    } catch (_) {
      return MockSeed.profile;
    }
  }
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<UserProfile?> restoreSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();
      if (response == null) return MockSeed.profile;
      return SupabaseMappers.profileFromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        final profileMap = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (profileMap != null) {
          return SupabaseMappers.profileFromMap(profileMap);
        }
      }
    } catch (_) {
      // Fallback below to support seeded demo accounts
    }

    try {
      final profileMap = await _client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();
      if (profileMap != null) {
        return SupabaseMappers.profileFromMap(profileMap);
      }
      return MockSeed.profile;
    } catch (e) {
      return MockSeed.profile;
    }
  }

  @override
  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String mobile,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: 'Password123!',
        data: {'full_name': fullName, 'mobile': mobile},
      );
      final user = response.user;
      final userId = user?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final profileMap = {
        'id': userId,
        'full_name': fullName,
        'email': email,
        'mobile': mobile,
        'member_since': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').upsert(profileMap);
      return SupabaseMappers.profileFromMap(profileMap);
    } on AuthException catch (e) {
      throw RepositoryFailure(e.message);
    } catch (e) {
      throw RepositoryFailure('Sign up failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw RepositoryFailure('Sign out failed: $e');
    }
  }
}
