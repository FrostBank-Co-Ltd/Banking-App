import 'dart:math';

import '../domain/models.dart';
import '../domain/repositories.dart';
import 'mock_seed.dart';

/// Seeded in memory store shared by every mock repository.
///
/// Reads resolve after a randomised delay so loading skeletons are observable,
/// and no call touches the network.
class MockDataSource {
  MockDataSource({DateTime? now, Random? random})
    : _random = random ?? Random(7),
      _accounts = List.of(MockSeed.accounts),
      _cards = List.of(MockSeed.cards),
      _transactions = MockSeed.transactions(now: now),
      _promos = List.of(MockSeed.promos),
      _profile = MockSeed.profile,
      _goals = MockSeed.goalSaves(now: now),
      _goalTxns = MockSeed.goalTransactions(now: now),
      _goalCounter = MockSeed.goalSaves().length,
      _cardCounter = MockSeed.cards.length;

  final Random _random;
  final List<Account> _accounts;
  final List<BankCard> _cards;
  final List<Txn> _transactions;
  final List<Promo> _promos;
  UserProfile _profile;
  final List<GoalSave> _goals;
  final List<GoalTxn> _goalTxns;
  int _goalCounter;
  int _cardCounter;

  /// Domains that should fail, so error states can be verified without a real
  /// backend. Add a key such as `accounts` or `transactions`.
  final Set<String> errorSimulation = <String>{};

  /// Set to zero in tests to keep them fast.
  Duration Function()? latencyOverride;

  UserProfile? _session;

  List<Account> get accountsView => List.unmodifiable(_accounts);

  Duration _latency() {
    final override = latencyOverride;
    if (override != null) return override();
    return Duration(milliseconds: 300 + _random.nextInt(600));
  }

  Future<T> read<T>(String domain, T Function() body) async {
    await Future<void>.delayed(_latency());
    if (errorSimulation.contains(domain)) {
      throw RepositoryFailure('We could not load your $domain right now.');
    }
    return body();
  }

  Future<List<Account>> accounts() =>
      read('accounts', () => List<Account>.unmodifiable(_accounts));

  Future<Account> account(String id) => read('accounts', () {
    final match = _accounts.where((account) => account.id == id).firstOrNull;
    if (match == null) {
      throw const RepositoryFailure('That account is no longer available.');
    }
    return match;
  });

  Future<Account> deposit(String accountId, double amount) async {
    return read('accounts', () {
      final index = _accounts.indexWhere((acc) => acc.id == accountId);
      if (index == -1) {
        throw const RepositoryFailure('Account not found.');
      }
      final old = _accounts[index];
      final newTotal = old.totalBalance + amount;
      final newAvail = old.availableBalance + amount;
      final updated = Account(
        id: old.id,
        name: old.name,
        shortCode: old.shortCode,
        kind: old.kind,
        maskedNumber: old.maskedNumber,
        currencyCode: old.currencyCode,
        totalBalance: newTotal,
        availableBalance: newAvail,
        cryptoQuantity: old.cryptoQuantity,
        cryptoUnit: old.cryptoUnit,
      );
      _accounts[index] = updated;

      final txn = Txn(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        accountId: accountId,
        merchant: 'Deposit',
        category: 'Deposit',
        amount: amount,
        currencyCode: old.currencyCode,
        direction: TxnDirection.inflow,
        type: TxnType.deposit,
        status: TxnStatus.completed,
        date: DateTime.now(),
        reference: 'NM-${_random.nextInt(900000) + 100000}',
        note: 'Deposit to ${old.name}',
      );
      _transactions.insert(0, txn);
      return updated;
    });
  }

  Future<Account> transfer({
    required String fromAccountId,
    required String recipient,
    required double amount,
    String? note,
  }) async {
    return read('accounts', () {
      final index = _accounts.indexWhere((acc) => acc.id == fromAccountId);
      if (index == -1) {
        throw const RepositoryFailure('Source account not found.');
      }
      final old = _accounts[index];
      if (amount > old.availableBalance) {
        throw const RepositoryFailure('Insufficient balance for transfer.');
      }
      final newTotal = old.totalBalance - amount;
      final newAvail = old.availableBalance - amount;
      final updated = Account(
        id: old.id,
        name: old.name,
        shortCode: old.shortCode,
        kind: old.kind,
        maskedNumber: old.maskedNumber,
        currencyCode: old.currencyCode,
        totalBalance: newTotal,
        availableBalance: newAvail,
        cryptoQuantity: old.cryptoQuantity,
        cryptoUnit: old.cryptoUnit,
      );
      _accounts[index] = updated;

      final txn = Txn(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        accountId: fromAccountId,
        merchant: recipient,
        category: 'Transfer',
        amount: amount,
        currencyCode: old.currencyCode,
        direction: TxnDirection.outflow,
        type: TxnType.transfer,
        status: TxnStatus.completed,
        date: DateTime.now(),
        reference: 'NM-${_random.nextInt(900000) + 100000}',
        note: note,
      );
      _transactions.insert(0, txn);

      final targetIndex = _accounts.indexWhere(
        (acc) =>
            acc.id == recipient ||
            acc.name.toLowerCase() == recipient.toLowerCase() ||
            acc.maskedNumber == recipient,
      );
      if (targetIndex != -1 && targetIndex != index) {
        final targetOld = _accounts[targetIndex];
        _accounts[targetIndex] = Account(
          id: targetOld.id,
          name: targetOld.name,
          shortCode: targetOld.shortCode,
          kind: targetOld.kind,
          maskedNumber: targetOld.maskedNumber,
          currencyCode: targetOld.currencyCode,
          totalBalance: targetOld.totalBalance + amount,
          availableBalance: targetOld.availableBalance + amount,
          cryptoQuantity: targetOld.cryptoQuantity,
          cryptoUnit: targetOld.cryptoUnit,
        );
        _transactions.insert(
          0,
          Txn(
            id: 'txn_${DateTime.now().millisecondsSinceEpoch + 1}',
            accountId: targetOld.id,
            merchant: old.name,
            category: 'Transfer',
            amount: amount,
            currencyCode: targetOld.currencyCode,
            direction: TxnDirection.inflow,
            type: TxnType.transfer,
            status: TxnStatus.completed,
            date: DateTime.now(),
            reference: 'NM-${_random.nextInt(900000) + 100000}',
            note: note,
          ),
        );
      }

      return updated;
    });
  }

  Future<List<BankCard>> cards() =>
      read('cards', () => List<BankCard>.unmodifiable(_cards));

  Future<BankCard> card(String id) => read('cards', () {
    final match = _cards.where((card) => card.id == id).firstOrNull;
    if (match == null) {
      throw const RepositoryFailure('That card is no longer available.');
    }
    return match;
  });

  /// Issues a card and appends it to the deck.
  ///
  /// Goes through the plain delay rather than [read], the same way [openGoal]
  /// does, so a simulated read failure cannot swallow a write the holder just
  /// confirmed.
  Future<BankCard> createCard({
    required String accountId,
    required String label,
    required String holderName,
    required String number,
    required String cvc,
    required String expiry,
    required CardNetwork network,
    required CardKind kind,
    required double spendingLimit,
  }) async {
    await Future<void>.delayed(_latency());
    _cardCounter++;
    final account = _accounts.where((acc) => acc.id == accountId).firstOrNull;
    final card = BankCard(
      id: 'card_${_cardCounter.toString().padLeft(3, '0')}',
      accountId: accountId,
      label: label,
      holderName: holderName,
      number: number,
      cvc: cvc,
      expiry: expiry,
      network: network,
      kind: kind,
      status: CardStatus.active,
      // A card that was just issued has had nothing spent on it.
      balance: 0,
      currencyCode: account?.currencyCode ?? 'USD',
      spendingLimit: spendingLimit,
    );
    _cards.add(card);
    return card;
  }

  Future<BankCard> toggleCardFreeze(String cardId) async {
    return read('cards', () {
      final index = _cards.indexWhere((c) => c.id == cardId);
      if (index == -1) {
        throw const RepositoryFailure('Card not found.');
      }
      final old = _cards[index];
      final newStatus = old.status == CardStatus.active
          ? CardStatus.frozen
          : CardStatus.active;
      final updated = BankCard(
        id: old.id,
        accountId: old.accountId,
        label: old.label,
        holderName: old.holderName,
        number: old.number,
        cvc: old.cvc,
        expiry: old.expiry,
        network: old.network,
        kind: old.kind,
        status: newStatus,
        balance: old.balance,
        currencyCode: old.currencyCode,
        spendingLimit: old.spendingLimit,
      );
      _cards[index] = updated;
      return updated;
    });
  }

  Future<BankCard> updateSpendingLimit(String cardId, double limit) async {
    return read('cards', () {
      final index = _cards.indexWhere((c) => c.id == cardId);
      if (index == -1) {
        throw const RepositoryFailure('Card not found.');
      }
      final old = _cards[index];
      final updated = BankCard(
        id: old.id,
        accountId: old.accountId,
        label: old.label,
        holderName: old.holderName,
        number: old.number,
        cvc: old.cvc,
        expiry: old.expiry,
        network: old.network,
        kind: old.kind,
        status: old.status,
        balance: old.balance,
        currencyCode: old.currencyCode,
        spendingLimit: limit,
      );
      _cards[index] = updated;
      return updated;
    });
  }

  Future<UserProfile> updateProfile(UserProfile newProfile) async {
    return read('profile', () {
      _profile = newProfile;
      if (_session != null) _session = newProfile;
      return _profile;
    });
  }

  Future<List<Txn>> transactions({String? accountId}) =>
      read('transactions', () {
        final rows = accountId == null
            ? _transactions
            : _transactions.where((txn) => txn.accountId == accountId).toList();
        return List<Txn>.unmodifiable(rows);
      });

  Future<Txn> transaction(String id) => read('transactions', () {
    final match = _transactions.where((txn) => txn.id == id).firstOrNull;
    if (match == null) {
      throw const RepositoryFailure('That transaction is no longer available.');
    }
    return match;
  });

  void addTransaction(Txn txn) {
    _transactions.insert(0, txn);
  }

  void deductAccountBalance(String accountId, double amount) {
    final index = _accounts.indexWhere((acc) => acc.id == accountId);
    if (index != -1) {
      final old = _accounts[index];
      final newTotal = (old.totalBalance - amount).clamp(0.0, double.infinity);
      final newAvail = (old.availableBalance - amount).clamp(0.0, double.infinity);
      _accounts[index] = Account(
        id: old.id,
        name: old.name,
        shortCode: old.shortCode,
        kind: old.kind,
        maskedNumber: old.maskedNumber,
        currencyCode: old.currencyCode,
        totalBalance: newTotal,
        availableBalance: newAvail,
        cryptoQuantity: old.cryptoQuantity,
        cryptoUnit: old.cryptoUnit,
      );
    }
  }

  Future<List<Promo>> promos() =>
      read('offers', () => List<Promo>.unmodifiable(_promos));

  Future<UserProfile> profile() => read('profile', () => _profile);

  void replaceProfile(UserProfile profile) => _profile = profile;

  // Session handling. The MVP keeps the session in memory for the running
  // process; a persistence store is a later task and changes no widget.
  Future<UserProfile?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _session;
  }

  /// Demo sign in with strict password and credential validation.
  Future<UserProfile> signIn(String email, String password) async {
    await Future<void>.delayed(_latency());

    if (password.trim().length < 8) {
      throw const RepositoryFailure(
        'Password must be at least 8 characters long.',
      );
    }

    final cleanEmail = email.trim().toLowerCase();

    // Map of seeded profiles and their valid passwords
    final credentialsMap = <String, ({String password, UserProfile profile})>{
      'ava.mercado@frostbank.app': (
        password: 'frost2026',
        profile: MockSeed.profile,
      ),
      'yujin.an@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000002',
          fullName: 'An Yujin',
          email: 'yujin.an@frostbank.app',
          mobile: '+82 10-1001-0901',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
      'wonyoung.jang@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000003',
          fullName: 'Jang Wonyoung',
          email: 'wonyoung.jang@frostbank.app',
          mobile: '+82 10-2002-0831',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
      'gaeul.kim@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000004',
          fullName: 'Gaeul (Kim Gaeul)',
          email: 'gaeul.kim@frostbank.app',
          mobile: '+82 10-3003-0924',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
      'rei.naoi@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000005',
          fullName: 'Rei (Naoi Rei)',
          email: 'rei.naoi@frostbank.app',
          mobile: '+82 10-4004-0203',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
      'liz.kim@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000006',
          fullName: 'Liz (Kim Jiwon)',
          email: 'liz.kim@frostbank.app',
          mobile: '+82 10-5005-1121',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
      'hyunseo.lee@frostbank.app': (
        password: 'ive2026',
        profile: UserProfile(
          id: '00000000-0000-0000-0000-000000000007',
          fullName: 'Leeseo (Lee Hyunseo)',
          email: 'hyunseo.lee@frostbank.app',
          mobile: '+82 10-6006-0221',
          memberSince: DateTime(2021, 12, 1),
        ),
      ),
    };

    final match = credentialsMap[cleanEmail];
    if (match != null) {
      if (password != match.password) {
        throw const RepositoryFailure('Incorrect password. Please try again.');
      }
      _profile = match.profile;
      _session = match.profile;
      return match.profile;
    }

    if (_profile.email.toLowerCase() == cleanEmail) {
      _session = _profile;
      return _profile;
    }

    throw const RepositoryFailure(
      'Invalid email or password. Account not found.',
    );
  }

  /// Demo sign up. Takes the entered name and email into the seeded profile so
  /// the rest of the application reflects what was typed.
  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    await Future<void>.delayed(_latency());
    _profile = UserProfile(
      id: _profile.id,
      fullName: fullName.trim().isEmpty ? _profile.fullName : fullName.trim(),
      email: email.trim().isEmpty ? _profile.email : email.trim(),
      mobile: mobile.trim().isEmpty ? _profile.mobile : mobile.trim(),
      memberSince: DateTime.now(),
    );
    _session = _profile;
    return _profile;
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _session = null;
  }

  // ---------------------------------------------------------------------------
  // Goal Saves
  // ---------------------------------------------------------------------------

  Future<List<GoalSave>> goals() => read(
        'savings',
        () => List<GoalSave>.unmodifiable(
          List.of(_goals)..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        ),
      );

  Future<GoalSave> goal(String id) => read('savings', () {
        final match = _goals.where((g) => g.id == id).firstOrNull;
        if (match == null) {
          throw const RepositoryFailure('That goal is no longer available.');
        }
        return match;
      });

  Future<GoalSave> openGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    required double initialDeposit,
  }) async {
    await Future<void>.delayed(_latency());
    _goalCounter++;
    final newGoal = GoalSave(
      id: 'goal_${_goalCounter.toString().padLeft(3, '0')}',
      name: name.trim(),
      emoji: emoji,
      targetAmount: targetAmount,
      balance: initialDeposit,
      currencyCode: 'USD',
      dailyRatePercent: MockSeed.goalDailyRate,
      interestEarned: 0,
      createdAt: DateTime.now(),
      status: GoalSaveStatus.active,
    );
    _goals.add(newGoal);

    if (initialDeposit > 0) {
      _goalTxns.add(GoalTxn(
        id: 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
        goalId: newGoal.id,
        kind: GoalTxnKind.transferIn,
        amount: initialDeposit,
        runningBalance: initialDeposit,
        date: DateTime.now(),
        note: 'Initial deposit',
      ));
    }
    return newGoal;
  }

  Future<GoalSave> transferIn({
    required String goalId,
    required double amount,
  }) async {
    await Future<void>.delayed(_latency());
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) {
      throw const RepositoryFailure('That goal is no longer available.');
    }
    final old = _goals[index];
    if (old.status != GoalSaveStatus.active) {
      throw const RepositoryFailure('You can only add funds to an active goal.');
    }
    final updated = old.copyWith(balance: old.balance + amount);
    _goals[index] = updated;
    _goalTxns.add(GoalTxn(
      id: 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      kind: GoalTxnKind.transferIn,
      amount: amount,
      runningBalance: updated.balance,
      date: DateTime.now(),
    ));
    return updated;
  }

  Future<GoalSave> transferOut({
    required String goalId,
    required double amount,
  }) async {
    await Future<void>.delayed(_latency());
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) {
      throw const RepositoryFailure('That goal is no longer available.');
    }
    final old = _goals[index];
    if (old.status != GoalSaveStatus.active) {
      throw const RepositoryFailure(
          'You can only withdraw from an active goal.');
    }
    if (amount > old.balance) {
      throw const RepositoryFailure(
          'Withdrawal amount exceeds the goal balance.');
    }
    final updated = old.copyWith(balance: old.balance - amount);
    _goals[index] = updated;
    _goalTxns.add(GoalTxn(
      id: 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
      goalId: goalId,
      kind: GoalTxnKind.transferOut,
      amount: amount,
      runningBalance: updated.balance,
      date: DateTime.now(),
    ));
    return updated;
  }

  Future<GoalSave> closeGoal(String id) async {
    await Future<void>.delayed(_latency());
    final index = _goals.indexWhere((g) => g.id == id);
    if (index == -1) {
      throw const RepositoryFailure('That goal is no longer available.');
    }
    final old = _goals[index];
    final updated = old.copyWith(status: GoalSaveStatus.closed, balance: 0);
    _goals[index] = updated;
    if (old.balance > 0) {
      _goalTxns.add(GoalTxn(
        id: 'gtxn_${DateTime.now().millisecondsSinceEpoch}',
        goalId: id,
        kind: GoalTxnKind.transferOut,
        amount: old.balance,
        runningBalance: 0,
        date: DateTime.now(),
        note: 'Goal closed — funds returned',
      ));
    }
    return updated;
  }

  Future<List<GoalTxn>> goalTransactions(String goalId) =>
      read('savings', () {
        final rows = _goalTxns
            .where((t) => t.goalId == goalId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        return List<GoalTxn>.unmodifiable(rows);
      });
}
