import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/split_bill_model.dart';
import 'mock_data_source.dart';

/// Mock implementations of every repository contract.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<Account>> fetchAccounts() => _source.accounts();

  @override
  Future<Account> fetchAccount(String id) => _source.account(id);

  @override
  Future<Account> deposit({
    required String accountId,
    required double amount,
  }) => _source.deposit(accountId, amount);

  @override
  Future<Account> transfer({
    required String fromAccountId,
    required String recipient,
    required double amount,
    String? note,
  }) => _source.transfer(
        fromAccountId: fromAccountId,
        recipient: recipient,
        amount: amount,
        note: note,
      );
}

class MockCardRepository implements CardRepository {
  const MockCardRepository(this._source);

  final MockDataSource _source;

  @override
  Future<List<BankCard>> fetchCards() => _source.cards();

  @override
  Future<BankCard> fetchCard(String id) => _source.card(id);

  @override
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
  }) => _source.createCard(
    accountId: accountId,
    label: label,
    holderName: holderName,
    number: number,
    cvc: cvc,
    expiry: expiry,
    network: network,
    kind: kind,
    spendingLimit: spendingLimit,
  );

  @override
  Future<BankCard> toggleCardFreeze(String cardId) =>
      _source.toggleCardFreeze(cardId);

  @override
  Future<BankCard> updateSpendingLimit(String cardId, double limit) =>
      _source.updateSpendingLimit(cardId, limit);
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

  @override
  Future<UserProfile> updateProfile(UserProfile profile) =>
      _source.updateProfile(profile);
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

class MockSplitBillRepository implements SplitBillRepository {
  MockSplitBillRepository(this._source) {
    final now = DateTime.now();
    _bills = [
      SplitBill(
        id: 'bill_1',
        title: 'Team Lunch at Luigi\'s',
        totalAmount: 120.00,
        category: 'Food & Dining',
        createdAt: now.subtract(const Duration(days: 2)),
        createdBy: 'You (Host)',
        participants: const [
          SplitBillParticipant(
            id: 'p1_host',
            name: 'You (Host)',
            shareAmount: 30.00,
            status: SplitParticipantStatus.paid,
          ),
          SplitBillParticipant(
            id: 'p1_alice',
            name: 'Alice Johnson',
            shareAmount: 30.00,
            status: SplitParticipantStatus.paid,
          ),
          SplitBillParticipant(
            id: 'p1_bob',
            name: 'Bob Smith',
            shareAmount: 30.00,
            status: SplitParticipantStatus.pending,
          ),
          SplitBillParticipant(
            id: 'p1_charlie',
            name: 'Charlie Brown',
            shareAmount: 30.00,
            status: SplitParticipantStatus.pending,
          ),
        ],
      ),
      SplitBill(
        id: 'bill_2',
        title: 'Weekend Cabin Rental',
        totalAmount: 300.00,
        category: 'Travel & Lodging',
        createdAt: now.subtract(const Duration(days: 5)),
        createdBy: 'You (Host)',
        participants: const [
          SplitBillParticipant(
            id: 'p2_host',
            name: 'You (Host)',
            shareAmount: 100.00,
            status: SplitParticipantStatus.paid,
          ),
          SplitBillParticipant(
            id: 'p2_david',
            name: 'David Lee',
            shareAmount: 100.00,
            status: SplitParticipantStatus.pending,
          ),
          SplitBillParticipant(
            id: 'p2_emma',
            name: 'Emma Watson',
            shareAmount: 100.00,
            status: SplitParticipantStatus.pending,
          ),
        ],
      ),
    ];
  }

  final MockDataSource _source;
  late final List<SplitBill> _bills;

  List<SplitBill> get initialBills => List.unmodifiable(_bills);

  @override
  Future<List<SplitBill>> fetchSplitBills() async => List.unmodifiable(_bills);

  @override
  Future<SplitBill> fetchSplitBill(String id) async {
    final match = _bills.where((b) => b.id == id).firstOrNull;
    if (match == null) throw const RepositoryFailure('Bill not found.');
    return match;
  }

  @override
  Future<SplitBill> createSplitBill({
    required String title,
    required double totalAmount,
    required String category,
    required List<String> participantNames,
  }) async {
    final now = DateTime.now();
    final billId = 'bill_${now.millisecondsSinceEpoch}';

    final cleanNames = participantNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final allParticipants = <SplitBillParticipant>[];
    final totalPeople = cleanNames.length + 1;
    final share = (totalAmount / totalPeople);

    allParticipants.add(
      SplitBillParticipant(
        id: 'p_${billId}_host',
        name: 'You (Host)',
        shareAmount: share,
        status: SplitParticipantStatus.paid,
        paidAt: now,
      ),
    );

    for (var i = 0; i < cleanNames.length; i++) {
      allParticipants.add(
        SplitBillParticipant(
          id: 'p_${billId}_$i',
          name: cleanNames[i],
          shareAmount: share,
          status: SplitParticipantStatus.pending,
        ),
      );
    }

    final newBill = SplitBill(
      id: billId,
      title: title.trim().isEmpty ? 'Split Bill' : title.trim(),
      totalAmount: totalAmount,
      category: category.trim().isEmpty ? 'General' : category.trim(),
      createdAt: now,
      createdBy: 'You (Host)',
      participants: allParticipants,
    );

    _bills.insert(0, newBill);
    return newBill;
  }

  @override
  Future<bool> confirmPayment({
    required String billId,
    required String participantId,
    String? payingAccountId,
    String currencyCode = 'USD',
  }) async {
    final billIndex = _bills.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return false;

    final bill = _bills[billIndex];
    final pIndex = bill.participants.indexWhere((p) => p.id == participantId);
    if (pIndex == -1) return false;

    final participant = bill.participants[pIndex];
    if (participant.isPaid) return true;

    final updatedParticipant = participant.copyWith(
      status: SplitParticipantStatus.paid,
      paidAt: DateTime.now(),
    );

    final updatedParticipants =
        List<SplitBillParticipant>.from(bill.participants);
    updatedParticipants[pIndex] = updatedParticipant;

    _bills[billIndex] = bill.copyWith(participants: updatedParticipants);

    final accountId = payingAccountId ?? 'acc_wallet';
    final now = DateTime.now();

    final txn = Txn(
      id: 'txn_split_${now.millisecondsSinceEpoch}',
      accountId: accountId,
      merchant: 'Split Bill: ${bill.title} (${participant.name})',
      category: 'Split Bills',
      amount: participant.shareAmount,
      currencyCode: currencyCode,
      direction: TxnDirection.outflow,
      type: TxnType.qrPayment,
      status: TxnStatus.completed,
      date: now,
      reference:
          'SPLIT-${bill.id.substring(0, bill.id.length.clamp(0, 6)).toUpperCase()}',
      note: 'Paid share for ${bill.title}',
    );

    _source.addTransaction(txn);
    _source.deductAccountBalance(accountId, participant.shareAmount);

    return true;
  }
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
    required String password,
  }) => _source.signUp(
        fullName: fullName,
        email: email,
        mobile: mobile,
        password: password,
      );

  @override
  Future<void> signOut() => _source.signOut();
}
