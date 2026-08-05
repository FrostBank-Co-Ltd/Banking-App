/// Repository contracts. Presentation code depends on these and on the domain
/// models, never on a data source.
library;

import 'models.dart';

/// Domain level failure surfaced to the presentation layer.
class RepositoryFailure implements Exception {
  const RepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AccountRepository {
  Future<List<Account>> fetchAccounts();

  Future<Account> fetchAccount(String id);
}

abstract interface class CardRepository {
  Future<List<BankCard>> fetchCards();

  Future<BankCard> fetchCard(String id);
}

abstract interface class TransactionRepository {
  /// Reverse chronological. [accountId] null means every account.
  Future<List<Txn>> fetchTransactions({String? accountId});

  Future<Txn> fetchTransaction(String id);
}

abstract interface class PromoRepository {
  Future<List<Promo>> fetchPromos();
}

/// Live market data. The only repository backed by a network service rather than
/// the seeded mock world.
abstract interface class MarketRepository {
  /// Quotes for [assets], in the order given. Assets the venue does not return
  /// are dropped rather than failing the whole call, so one delisted pair cannot
  /// blank the screen.
  Future<List<CryptoQuote>> fetchCryptoQuotes(List<CryptoAsset> assets);

  Future<CryptoSeries> fetchCryptoSeries(CryptoAsset asset, ChartRange range);
}

abstract interface class ProfileRepository {
  Future<UserProfile> fetchProfile();
}

abstract interface class AuthRepository {
  /// Resolves the stored session, or null when there is none.
  Future<UserProfile?> restoreSession();

  Future<UserProfile> signIn({required String email, required String password});

  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String mobile,
  });

  Future<void> signOut();
}
