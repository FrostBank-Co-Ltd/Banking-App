import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/split_bill_model.dart';
import 'providers.dart';

class SplitBillsController extends Notifier<List<SplitBill>> {
  @override
  List<SplitBill> build() {
    final now = DateTime.now();
    return [
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

  void createBill({
    required String title,
    required double totalAmount,
    required String category,
    required List<String> participantNames,
  }) {
    final now = DateTime.now();
    final billId = 'bill_${now.millisecondsSinceEpoch}';

    // Filter out host if included in names, always ensure Host + participants
    final cleanNames = participantNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final allParticipants = <SplitBillParticipant>[];

    // Host share
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
      final pId = 'p_${billId}_$i';
      allParticipants.add(
        SplitBillParticipant(
          id: pId,
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

    state = [newBill, ...state];
  }

  bool confirmPayment({
    required String billId,
    required String participantId,
    String? payingAccountId,
    String currencyCode = 'USD',
  }) {
    final billIndex = state.indexWhere((b) => b.id == billId);
    if (billIndex == -1) return false;

    final bill = state[billIndex];
    final pIndex = bill.participants.indexWhere((p) => p.id == participantId);
    if (pIndex == -1) return false;

    final participant = bill.participants[pIndex];
    if (participant.isPaid) return true; // Already paid

    final updatedParticipant = participant.copyWith(
      status: SplitParticipantStatus.paid,
      paidAt: DateTime.now(),
    );

    final updatedParticipants = List<SplitBillParticipant>.from(bill.participants);
    updatedParticipants[pIndex] = updatedParticipant;

    final updatedBill = bill.copyWith(participants: updatedParticipants);
    final updatedList = List<SplitBill>.from(state);
    updatedList[billIndex] = updatedBill;
    state = updatedList;

    // Record payment in MockDataSource transaction history and deduct balance
    final ds = ref.read(mockDataSourceProvider);
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
      reference: 'SPLIT-${bill.id.substring(0, bill.id.length.clamp(0, 6)).toUpperCase()}',
      note: 'Paid share for ${bill.title}',
    );

    ds.addTransaction(txn);
    ds.deductAccountBalance(accountId, participant.shareAmount);

    // Refresh providers so UI updates transaction history and account balances
    ref.invalidate(accountsProvider);
    ref.invalidate(accountProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(filteredTransactionsProvider);

    return true;
  }
}

final splitBillsProvider =
    NotifierProvider<SplitBillsController, List<SplitBill>>(
      SplitBillsController.new,
    );
