import '../domain/models.dart';
import '../domain/repositories.dart';
import 'mock_data_source.dart';

/// Mock implementations of every repository contract. Swapping in an HTTP
/// implementation touches only this file and the providers that construct it.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<Account>> fetchAccounts() => _source.accounts();

  @override
  Future<Account> fetchAccount(String id) => _source.account(id);
}

class MockCardRepository implements CardRepository {
  const MockCardRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<BankCard>> fetchCards() => _source.cards();

  @override
  Future<BankCard> fetchCard(String id) => _source.card(id);
}

class MockTransactionRepository implements TransactionRepository {
  const MockTransactionRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<Txn>> fetchTransactions({String? accountId}) =>
      _source.transactions(accountId: accountId);

  @override
  Future<Txn> fetchTransaction(String id) => _source.transaction(id);
}

class MockPromoRepository implements PromoRepository {
  const MockPromoRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<Promo>> fetchPromos() => _source.promos();
}

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository(this._source);

  final MockDataSource _source;

  @override
  Future<UserProfile> fetchProfile() => _source.profile();
}

class MockSavingsGoalRepository implements SavingsGoalRepository {
  const MockSavingsGoalRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<GoalSave>> fetchGoals() => _source.goals();

  @override
  Future<GoalSave> fetchGoal(String id) => _source.goal(id);

  @override
  Future<GoalSave> openGoal({
    required String name,
    required String emoji,
    required double targetAmount,
    required double initialDeposit,
  }) => _source.openGoal(
        name: name,
        emoji: emoji,
        targetAmount: targetAmount,
        initialDeposit: initialDeposit,
      );

  @override
  Future<GoalSave> transferIn({
    required String goalId,
    required double amount,
  }) => _source.transferIn(goalId: goalId, amount: amount);

  @override
  Future<GoalSave> transferOut({
    required String goalId,
    required double amount,
  }) => _source.transferOut(goalId: goalId, amount: amount);

  @override
  Future<GoalSave> closeGoal(String id) => _source.closeGoal(id);

  @override
  Future<List<GoalTxn>> fetchGoalTransactions(String goalId) =>
      _source.goalTransactions(goalId);
}

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository(this._source);

  final MockDataSource _source;

  @override
  Future<UserProfile?> restoreSession() => _source.restoreSession();

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) => _source.signIn(email, password);

  @override
  Future<UserProfile> signUp({
    required String fullName,
    required String email,
    required String mobile,
  }) => _source.signUp(fullName: fullName, email: email, mobile: mobile);

  @override
  Future<void> signOut() => _source.signOut();
}
