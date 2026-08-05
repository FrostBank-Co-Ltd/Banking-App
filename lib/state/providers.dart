import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/supabase_config.dart';
import '../data/mock_data_source.dart';
import '../data/mock_repositories.dart';
import '../domain/models.dart';
import '../data/mock_seed.dart';
import '../data/twelve_data_market_repository.dart';
import '../data/supabase_repositories.dart';
import '../domain/repositories.dart';
import 'preferences_controller.dart';
import 'session_controller.dart';
import 'txn_filter.dart';

/// Riverpod retries failed providers on its own by default, which would hold a
/// failed section in its loading skeleton instead of showing the failure. Retry
/// belongs to the user here, through the retry control in the error state.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Controls whether the app uses Supabase or offline Mock repositories.
final useSupabaseProvider = NotifierProvider<UseSupabaseNotifier, bool>(
  UseSupabaseNotifier.new,
);

class UseSupabaseNotifier extends Notifier<bool> {
  @override
  bool build() => SupabaseConfig.isInitialized;

  void toggle() => state = !state;
  void setUseSupabase(bool value) => state = value;
}

/// Data source and repositories. Override [mockDataSourceProvider] in tests to
/// seed a different world or to remove latency.
final mockDataSourceProvider = Provider<MockDataSource>(
  (ref) => MockDataSource(),
);

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase && SupabaseConfig.isInitialized) {
    return SupabaseAccountRepository();
  }
  return MockAccountRepository(ref.watch(mockDataSourceProvider));
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase && SupabaseConfig.isInitialized) {
    return SupabaseCardRepository();
  }
  return MockCardRepository(ref.watch(mockDataSourceProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase && SupabaseConfig.isInitialized) {
    return SupabaseTransactionRepository();
  }
  return MockTransactionRepository(ref.watch(mockDataSourceProvider));
});

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase && SupabaseConfig.isInitialized) {
    return SupabasePromoRepository();
  }
  return MockPromoRepository(ref.watch(mockDataSourceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseProvider);
  if (useSupabase && SupabaseConfig.isInitialized) {
    return SupabaseProfileRepository();
  }
  return MockProfileRepository(ref.watch(mockDataSourceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(ref.watch(mockDataSourceProvider)),
);

/// Application state.
final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );

final txnFilterProvider = NotifierProvider<TxnFilterController, TxnFilter>(
  TxnFilterController.new,
);

/// Reads. Every one of these renders through an async value, so loading,
/// empty, and error states come from one place in the presentation layer.
final accountsProvider = FutureProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).fetchAccounts(),
);

final accountProvider = FutureProvider.family<Account, String>(
  (ref, id) => ref.watch(accountRepositoryProvider).fetchAccount(id),
);

final cardsProvider = FutureProvider<List<BankCard>>(
  (ref) => ref.watch(cardRepositoryProvider).fetchCards(),
);

final cardProvider = FutureProvider.family<BankCard, String>(
  (ref, id) => ref.watch(cardRepositoryProvider).fetchCard(id),
);

/// Pass null for every account.
final transactionsProvider = FutureProvider.family<List<Txn>, String?>(
  (ref, accountId) => ref
      .watch(transactionRepositoryProvider)
      .fetchTransactions(accountId: accountId),
);

final transactionProvider = FutureProvider.family<Txn, String>(
  (ref, id) => ref.watch(transactionRepositoryProvider).fetchTransaction(id),
);

final promosProvider = FutureProvider<List<Promo>>(
  (ref) => ref.watch(promoRepositoryProvider).fetchPromos(),
);

final profileProvider = FutureProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).fetchProfile(),
);

/// Dashboard selection. Null resolves to the first seeded account.
final selectedAccountIdProvider =
    NotifierProvider<SelectedAccountId, String?>(SelectedAccountId.new);

class SelectedAccountId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

/// The account the dashboard is currently showing.
final selectedAccountProvider = Provider<AsyncValue<Account?>>((ref) {
  final accounts = ref.watch(accountsProvider);
  final selectedId = ref.watch(selectedAccountIdProvider);
  return accounts.whenData((rows) {
    if (rows.isEmpty) return null;
    return rows.firstWhere(
      (account) => account.id == selectedId,
      orElse: () => rows.first,
    );
  });
});

/// The full ledger with the active filter applied.
final filteredTransactionsProvider = FutureProvider<List<Txn>>((ref) async {
  final rows = await ref.watch(transactionsProvider(null).future);
  final filter = ref.watch(txnFilterProvider);
  return filter.apply(rows);
});

/// Cards belonging to one account.
final accountCardsProvider = FutureProvider.family<List<BankCard>, String>(
  (ref, accountId) async {
    final cards = await ref.watch(cardsProvider.future);
    return cards.where((card) => card.accountId == accountId).toList();
  },
);

/// The pairs the Crypto screen tracks.
final cryptoAssetsProvider = Provider<List<CryptoAsset>>(
  (ref) => MockSeed.cryptoAssets,
);

final cryptoAssetProvider = Provider.family<CryptoAsset?, String>(
  (ref, code) => ref
      .watch(cryptoAssetsProvider)
      .where((asset) => asset.code.toUpperCase() == code.toUpperCase())
      .firstOrNull,
);

/// Live quotes for every tracked pair.
///
/// Auto disposed and kept on a timer, so prices stay current while the Crypto
/// screen is open and stop costing credits the moment it is closed. One refresh
/// spends one credit per symbol, so the period is set well inside the free
/// plan's budget.
final cryptoQuotesProvider = FutureProvider.autoDispose<List<CryptoQuote>>((
  ref,
) async {
  final repository = ref.watch(marketRepositoryProvider);
  final assets = ref.watch(cryptoAssetsProvider);

  final timer = Timer.periodic(
    const Duration(seconds: 45),
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(timer.cancel);

  return repository.fetchCryptoQuotes(assets);
});

/// Live quote for one pair, read off the same batch call the list uses so
/// opening a pair costs no extra credits.
final cryptoQuoteProvider = Provider.autoDispose
    .family<AsyncValue<CryptoQuote?>, String>(
      (ref, code) => ref.watch(cryptoQuotesProvider).whenData(
        (quotes) => quotes
            .where((quote) => quote.code.toUpperCase() == code.toUpperCase())
            .firstOrNull,
      ),
    );

/// Units held in one pair. Ledger data, so mock in this build.
final cryptoHoldingProvider = Provider.family<double, String>(
  (ref, code) => MockSeed.cryptoHoldings[code.toUpperCase()] ?? 0,
);

/// Every tracked pair paired with the position held in it, held pairs first and
/// then by value.
final cryptoPositionsProvider =
    Provider.autoDispose<AsyncValue<List<CryptoPosition>>>((ref) {
      return ref.watch(cryptoQuotesProvider).whenData((quotes) {
        final positions = [
          for (final quote in quotes)
            CryptoPosition(
              quote: quote,
              quantity: ref.watch(cryptoHoldingProvider(quote.code)),
            ),
        ]..sort((a, b) {
          if (a.isHeld != b.isHeld) return a.isHeld ? -1 : 1;
          return b.value.compareTo(a.value);
        });
        return positions;
      });
    });

/// Live valuation of the mock crypto ledger.
final cryptoPortfolioProvider = Provider.autoDispose<AsyncValue<CryptoPortfolio>>(
  (ref) => ref.watch(cryptoPositionsProvider).whenData(CryptoPortfolio.of),
);

/// One pair over one span. A record, so the family key compares structurally and
/// each span is cached separately.
typedef CryptoSeriesQuery = ({String code, ChartRange range});

/// Bars for one pair over one span. Auto disposed, so leaving the screen stops
/// the span being held in memory, and each span is fetched at most once inside
/// the repository's cache window.
final cryptoSeriesProvider = FutureProvider.autoDispose
    .family<CryptoSeries, CryptoSeriesQuery>((ref, query) async {
      final asset = ref.watch(cryptoAssetProvider(query.code));
      if (asset == null) {
        throw RepositoryFailure('${query.code} is not a tracked pair.');
      }
      return ref
          .watch(marketRepositoryProvider)
          .fetchCryptoSeries(asset, query.range);
    });

/// Inflow and outflow totals for the current calendar month.
class MonthFlow {
  const MonthFlow({required this.inflow, required this.outflow});

  final double inflow;
  final double outflow;
}

final monthFlowProvider = FutureProvider.family<MonthFlow, String>(
  (ref, accountId) async {
    final rows = await ref.watch(transactionsProvider(accountId).future);
    final now = DateTime.now();
    var inflow = 0.0;
    var outflow = 0.0;
    for (final txn in rows) {
      if (txn.date.year != now.year || txn.date.month != now.month) continue;
      if (txn.status == TxnStatus.failed) continue;
      if (txn.isInflow) {
        inflow += txn.amount;
      } else {
        outflow += txn.amount;
      }
    }
    return MonthFlow(inflow: inflow, outflow: outflow);
  },
);
