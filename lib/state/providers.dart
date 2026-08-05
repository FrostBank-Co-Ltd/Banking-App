import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data_source.dart';
import '../data/mock_repositories.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'preferences_controller.dart';
import 'session_controller.dart';
import 'txn_filter.dart';

/// Riverpod retries failed providers on its own by default, which would hold a
/// failed section in its loading skeleton instead of showing the failure. Retry
/// belongs to the user here, through the retry control in the error state.
Duration? noAutomaticRetry(int retryCount, Object error) => null;

/// Data source and repositories. Override [mockDataSourceProvider] in tests to
/// seed a different world or to remove latency.
final mockDataSourceProvider = Provider<MockDataSource>(
  (ref) => MockDataSource(),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => MockAccountRepository(ref.watch(mockDataSourceProvider)),
);

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => MockCardRepository(ref.watch(mockDataSourceProvider)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => MockTransactionRepository(ref.watch(mockDataSourceProvider)),
);

final promoRepositoryProvider = Provider<PromoRepository>(
  (ref) => MockPromoRepository(ref.watch(mockDataSourceProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(ref.watch(mockDataSourceProvider)),
);

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

// ---------------------------------------------------------------------------
// Savings Goals
// ---------------------------------------------------------------------------

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => MockSavingsGoalRepository(ref.watch(mockDataSourceProvider)),
);

final goalsProvider = FutureProvider<List<GoalSave>>(
  (ref) => ref.read(savingsGoalRepositoryProvider).fetchGoals(),
  retry: noAutomaticRetry,
);

final goalProvider = FutureProvider.family<GoalSave, String>(
  (ref, id) => ref.read(savingsGoalRepositoryProvider).fetchGoal(id),
  retry: noAutomaticRetry,
);

final goalTransactionsProvider = FutureProvider.family<List<GoalTxn>, String>(
  (ref, goalId) =>
      ref.read(savingsGoalRepositoryProvider).fetchGoalTransactions(goalId),
  retry: noAutomaticRetry,
);

/// Total balance across all active goal saves.
final totalSavingsProvider = FutureProvider<double>((ref) async {
  final goals = await ref.watch(goalsProvider.future);
  var total = 0.0;
  for (final g in goals) {
    if (g.status == GoalSaveStatus.active) total += g.balance;
  }
  return total;
}, retry: noAutomaticRetry);

/// Async state for mutations (open, transfer, close).
sealed class SavingsActionState {
  const SavingsActionState();
}

class SavingsIdle extends SavingsActionState {
  const SavingsIdle();
}

class SavingsWorking extends SavingsActionState {
  const SavingsWorking();
}

class SavingsSuccess extends SavingsActionState {
  const SavingsSuccess(this.goal);
  final GoalSave goal;
}

class SavingsError extends SavingsActionState {
  const SavingsError(this.message);
  final String message;
}

/// Handles all write operations on goal saves and invalidates read providers
/// after each successful mutation so the UI reflects the new state.
class SavingsController extends Notifier<SavingsActionState> {
  @override
  SavingsActionState build() => const SavingsIdle();

  SavingsGoalRepository get _repo =>
      ref.read(savingsGoalRepositoryProvider);

  Future<bool> openGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    required double initialDeposit,
  }) async {
    state = const SavingsWorking();
    try {
      final goal = await _repo.openGoal(
        name: name,
        emoji: emoji,
        targetAmount: targetAmount,
        initialDeposit: initialDeposit,
      );
      ref.invalidate(goalsProvider);
      ref.invalidate(totalSavingsProvider);
      state = SavingsSuccess(goal);
      return true;
    } on RepositoryFailure catch (e) {
      state = SavingsError(e.message);
      return false;
    } catch (_) {
      state = const SavingsError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> transferIn({
    required String goalId,
    required double amount,
  }) async {
    state = const SavingsWorking();
    try {
      final goal =
          await _repo.transferIn(goalId: goalId, amount: amount);
      ref.invalidate(goalsProvider);
      ref.invalidate(goalProvider(goalId));
      ref.invalidate(goalTransactionsProvider(goalId));
      ref.invalidate(totalSavingsProvider);
      state = SavingsSuccess(goal);
      return true;
    } on RepositoryFailure catch (e) {
      state = SavingsError(e.message);
      return false;
    } catch (_) {
      state = const SavingsError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> transferOut({
    required String goalId,
    required double amount,
  }) async {
    state = const SavingsWorking();
    try {
      final goal =
          await _repo.transferOut(goalId: goalId, amount: amount);
      ref.invalidate(goalsProvider);
      ref.invalidate(goalProvider(goalId));
      ref.invalidate(goalTransactionsProvider(goalId));
      ref.invalidate(totalSavingsProvider);
      state = SavingsSuccess(goal);
      return true;
    } on RepositoryFailure catch (e) {
      state = SavingsError(e.message);
      return false;
    } catch (_) {
      state = const SavingsError('Something went wrong. Please try again.');
      return false;
    }
  }

  Future<bool> closeGoal(String goalId) async {
    state = const SavingsWorking();
    try {
      final goal = await _repo.closeGoal(goalId);
      ref.invalidate(goalsProvider);
      ref.invalidate(goalProvider(goalId));
      ref.invalidate(goalTransactionsProvider(goalId));
      ref.invalidate(totalSavingsProvider);
      state = SavingsSuccess(goal);
      return true;
    } on RepositoryFailure catch (e) {
      state = SavingsError(e.message);
      return false;
    } catch (_) {
      state = const SavingsError('Something went wrong. Please try again.');
      return false;
    }
  }

  void reset() => state = const SavingsIdle();
}

final savingsControllerProvider =
    NotifierProvider<SavingsController, SavingsActionState>(
  SavingsController.new,
);
