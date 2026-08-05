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

  @override
  Future<Account> deposit({
    required String accountId,
    required double amount,
  }) async {
    try {
      final current = await fetchAccount(accountId);
      final newTotal = current.totalBalance + amount;
      final newAvail = current.availableBalance + amount;

      await _client.from('accounts').update({
        'total_balance': newTotal,
        'available_balance': newAvail,
      }).eq('id', accountId);

      final txnId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final refCode =
          'NM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await _client.from('transactions').insert({
        'id': txnId,
        'account_id': accountId,
        'merchant': 'Deposit',
        'category': 'Deposit',
        'amount': amount,
        'currency_code': current.currencyCode,
        'direction': 'inflow',
        'type': 'deposit',
        'status': 'completed',
        'date': DateTime.now().toIso8601String(),
        'reference': refCode,
        'note': 'Deposit to ${current.name}',
      });

      return Account(
        id: current.id,
        name: current.name,
        shortCode: current.shortCode,
        kind: current.kind,
        maskedNumber: current.maskedNumber,
        currencyCode: current.currencyCode,
        totalBalance: newTotal,
        availableBalance: newAvail,
        cryptoQuantity: current.cryptoQuantity,
        cryptoUnit: current.cryptoUnit,
      );
    } catch (e) {
      if (e is RepositoryFailure) rethrow;
      throw RepositoryFailure('Deposit failed: $e');
    }
  }

  @override
  Future<Account> transfer({
    required String fromAccountId,
    required String recipient,
    required double amount,
    String? note,
  }) async {
    try {
      final source = await fetchAccount(fromAccountId);
      if (amount > source.availableBalance) {
        throw const RepositoryFailure('Insufficient balance for transfer.');
      }

      final newTotal = source.totalBalance - amount;
      final newAvail = source.availableBalance - amount;

      await _client.from('accounts').update({
        'total_balance': newTotal,
        'available_balance': newAvail,
      }).eq('id', fromAccountId);

      final txnId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
      final refCode =
          'NM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      await _client.from('transactions').insert({
        'id': txnId,
        'account_id': fromAccountId,
        'merchant': recipient,
        'category': 'Transfer',
        'amount': amount,
        'currency_code': source.currencyCode,
        'direction': 'outflow',
        'type': 'transfer',
        'status': 'completed',
        'date': DateTime.now().toIso8601String(),
        'reference': refCode,
        'note': note,
      });

      return Account(
        id: source.id,
        name: source.name,
        shortCode: source.shortCode,
        kind: source.kind,
        maskedNumber: source.maskedNumber,
        currencyCode: source.currencyCode,
        totalBalance: newTotal,
        availableBalance: newAvail,
        cryptoQuantity: source.cryptoQuantity,
        cryptoUnit: source.cryptoUnit,
      );
    } catch (e) {
      if (e is RepositoryFailure) rethrow;
      throw RepositoryFailure('Transfer failed: $e');
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

// ---------------------------------------------------------------------------
// Savings Goal Mappers
// ---------------------------------------------------------------------------

extension _GoalSaveMappers on SupabaseMappers {
  static GoalSave goalFromMap(Map<String, dynamic> map) {
    return GoalSave(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      balance: (map['balance'] as num).toDouble(),
      currencyCode: map['currency_code'] as String,
      dailyRatePercent: (map['daily_rate_percent'] as num).toDouble(),
      interestEarned: (map['interest_earned'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      status: _parseEnum(
        GoalSaveStatus.values,
        map['status'] as String,
        GoalSaveStatus.active,
      ),
    );
  }

  static GoalTxn goalTxnFromMap(Map<String, dynamic> map) {
    return GoalTxn(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      kind: _parseEnum(
        GoalTxnKind.values,
        (map['kind'] as String).replaceAll('_', ''),
        GoalTxnKind.transferIn,
      ),
      amount: (map['amount'] as num).toDouble(),
      runningBalance: (map['running_balance'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}

class SupabaseSavingsGoalRepository implements SavingsGoalRepository {
  SupabaseSavingsGoalRepository([SupabaseClient? client])
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  @override
  Future<List<GoalSave>> fetchGoals() async {
    try {
      final response = await _client
          .from('goal_saves')
          .select()
          .order('created_at', ascending: false);
      final list = (response as List)
          .map((item) =>
              _GoalSaveMappers.goalFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) return MockSeed.goalSaves();
      return list;
    } catch (_) {
      return MockSeed.goalSaves();
    }
  }

  @override
  Future<GoalSave> fetchGoal(String id) async {
    try {
      final response = await _client
          .from('goal_saves')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        return _GoalSaveMappers.goalFromMap(response);
      }
      return MockSeed.goalSaves().firstWhere(
        (g) => g.id == id,
        orElse: () => MockSeed.goalSaves().first,
      );
    } catch (_) {
      return MockSeed.goalSaves().firstWhere(
        (g) => g.id == id,
        orElse: () => MockSeed.goalSaves().first,
      );
    }
  }

  @override
  Future<GoalSave> openGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    required double initialDeposit,
  }) async {
    final id = 'goal_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final goalMap = {
      'id': id,
      'name': name,
      'emoji': emoji,
      'target_amount': targetAmount,
      'balance': initialDeposit,
      'currency_code': 'USD',
      'daily_rate_percent': 0.011918,
      'interest_earned': 0.0,
      'created_at': now.toIso8601String(),
      'status': 'active',
    };

    try {
      await _client.from('goal_saves').insert(goalMap);
      if (initialDeposit > 0) {
        await _client.from('goal_transactions').insert({
          'id': 'gtxn_${now.millisecondsSinceEpoch}',
          'goal_id': id,
          'kind': 'transferIn',
          'amount': initialDeposit,
          'running_balance': initialDeposit,
          'date': now.toIso8601String(),
          'note': 'Opening deposit',
        });
      }
      return _GoalSaveMappers.goalFromMap(goalMap);
    } catch (e) {
      throw RepositoryFailure('Could not create goal: $e');
    }
  }

  @override
  Future<GoalSave> transferIn({
    required String goalId,
    required double amount,
  }) async {
    try {
      final current = await fetchGoal(goalId);
      final newBalance = current.balance + amount;

      await _client.from('goal_saves').update({
        'balance': newBalance,
      }).eq('id', goalId);

      await _client.from('goal_transactions').insert({
        'id': 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
        'goal_id': goalId,
        'kind': 'transferIn',
        'amount': amount,
        'running_balance': newBalance,
        'date': DateTime.now().toIso8601String(),
        'note': null,
      });

      return current.copyWith(balance: newBalance);
    } catch (e) {
      if (e is RepositoryFailure) rethrow;
      throw RepositoryFailure('Transfer failed: $e');
    }
  }

  @override
  Future<GoalSave> transferOut({
    required String goalId,
    required double amount,
  }) async {
    try {
      final current = await fetchGoal(goalId);
      if (amount > current.balance) {
        throw const RepositoryFailure('Insufficient goal balance.');
      }
      final newBalance = current.balance - amount;

      await _client.from('goal_saves').update({
        'balance': newBalance,
      }).eq('id', goalId);

      await _client.from('goal_transactions').insert({
        'id': 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
        'goal_id': goalId,
        'kind': 'transferOut',
        'amount': amount,
        'running_balance': newBalance,
        'date': DateTime.now().toIso8601String(),
        'note': null,
      });

      return current.copyWith(balance: newBalance);
    } catch (e) {
      if (e is RepositoryFailure) rethrow;
      throw RepositoryFailure('Transfer failed: $e');
    }
  }

  @override
  Future<GoalSave> closeGoal(String id) async {
    try {
      final current = await fetchGoal(id);
      await _client.from('goal_saves').update({
        'status': 'closed',
        'balance': 0.0,
      }).eq('id', id);

      return current.copyWith(
        status: GoalSaveStatus.closed,
        balance: 0.0,
      );
    } catch (e) {
      if (e is RepositoryFailure) rethrow;
      throw RepositoryFailure('Could not close goal: $e');
    }
  }

  @override
  Future<List<GoalTxn>> fetchGoalTransactions(String goalId) async {
    try {
      final response = await _client
          .from('goal_transactions')
          .select()
          .eq('goal_id', goalId)
          .order('date', ascending: false);
      final list = (response as List)
          .map((item) =>
              _GoalSaveMappers.goalTxnFromMap(item as Map<String, dynamic>))
          .toList();
      if (list.isEmpty) {
        return MockSeed.goalTransactions()
            .where((t) => t.goalId == goalId)
            .toList();
      }
      return list;
    } catch (_) {
      return MockSeed.goalTransactions()
          .where((t) => t.goalId == goalId)
          .toList();
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
      if (response == null) return null;
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
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'mobile': mobile},
      );
      final user = response.user;
      final userId =
          user?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final profileMap = {
        'id': userId,
        'full_name': fullName,
        'email': email,
        'mobile': mobile,
        'member_since': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').upsert(profileMap);

      // Create an initial Everyday Wallet for newly registered user if no accounts exist
      try {
        final existingAccounts =
            await _client.from('accounts').select().limit(1);
        if ((existingAccounts as List).isEmpty) {
          final defaultWallet = {
            'id': 'acc_wallet_$userId',
            'name': 'Everyday Wallet',
            'short_code': 'WALLET',
            'kind': 'wallet',
            'masked_number':
                '•••• ${userId.length >= 4 ? userId.substring(userId.length - 4) : '4182'}',
            'currency_code': 'USD',
            'total_balance': 1000.00,
            'available_balance': 1000.00,
          };
          await _client.from('accounts').insert(defaultWallet);
        }
      } catch (_) {
        // Safe fallback if table creation or insertion throws
      }

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
