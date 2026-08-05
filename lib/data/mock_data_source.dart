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
      _profile = MockSeed.profile;

  final Random _random;
  final List<Account> _accounts;
  final List<BankCard> _cards;
  final List<Txn> _transactions;
  final List<Promo> _promos;
  UserProfile _profile;

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
}
