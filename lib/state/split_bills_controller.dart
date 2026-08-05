import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_repositories.dart';
import '../domain/split_bill_model.dart';
import 'providers.dart';

class SplitBillsController extends Notifier<List<SplitBill>> {
  @override
  List<SplitBill> build() {
    final repo = ref.watch(splitBillRepositoryProvider);
    if (repo is MockSplitBillRepository) {
      return repo.initialBills;
    }
    _loadBills(repo);
    return const [];
  }

  Future<void> _loadBills(dynamic repo) async {
    try {
      final bills = await repo.fetchSplitBills();
      state = bills;
    } catch (_) {}
  }

  Future<bool> createBill({
    required String title,
    required double totalAmount,
    required String category,
    required List<String> participantNames,
  }) async {
    try {
      final repo = ref.read(splitBillRepositoryProvider);
      await repo.createSplitBill(
        title: title,
        totalAmount: totalAmount,
        category: category,
        participantNames: participantNames,
      );
      final updatedList = await repo.fetchSplitBills();
      state = updatedList;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmPayment({
    required String billId,
    required String participantId,
    String? payingAccountId,
    String currencyCode = 'USD',
  }) async {
    try {
      final repo = ref.read(splitBillRepositoryProvider);
      final success = await repo.confirmPayment(
        billId: billId,
        participantId: participantId,
        payingAccountId: payingAccountId,
        currencyCode: currencyCode,
      );

      if (success) {
        final updatedBills = await repo.fetchSplitBills();
        state = updatedBills;

        ref.invalidate(accountsProvider);
        ref.invalidate(accountProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(filteredTransactionsProvider);
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}

final splitBillsProvider =
    NotifierProvider<SplitBillsController, List<SplitBill>>(
      SplitBillsController.new,
    );
