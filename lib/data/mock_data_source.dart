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
      _goalCounter = MockSeed.goalSaves().length;

  final Random _random;
  final List<Account> _accounts;
  final List<BankCard> _cards;
  final List<Txn> _transactions;
  final List<Promo> _promos;
  UserProfile _profile;
  final List<GoalSave> _goals;
  final List<GoalTxn> _goalTxns;
  int _goalCounter;

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

  Future<List<BankCard>> cards() =>
      read('cards', () => List<BankCard>.unmodifiable(_cards));

  Future<BankCard> card(String id) => read('cards', () {
    final match = _cards.where((card) => card.id == id).firstOrNull;
    if (match == null) {
      throw const RepositoryFailure('That card is no longer available.');
    }
    return match;
  });

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

  /// Demo sign in. This build presents the interface, so any entry opens the
  /// seeded profile and nothing is validated or checked.
  Future<UserProfile> signIn(String email, String password) async {
    await Future<void>.delayed(_latency());
    _session = _profile;
    return _profile;
  }

  /// Demo sign up. Takes the entered name and email into the seeded profile so
  /// the rest of the application reflects what was typed.
  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String mobile,
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
