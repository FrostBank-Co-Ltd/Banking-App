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

  /// Create a new split bill.
  ///
  /// Supports all three [SplitMode]s.  For [SplitMode.custom] supply
  /// [customAmounts] (length == [participantNames].length + 1, host first).
  /// For [SplitMode.percentage] supply [percentages] (same length, sums to 100).
  Future<bool> createBill({
    required String title,
    required double totalAmount,
    required String category,
    required List<String> participantNames,
    SplitMode splitMode = SplitMode.equal,
    List<double>? customAmounts,
    List<double>? percentages,
    String? description,
  }) async {
    try {
      final repo = ref.read(splitBillRepositoryProvider);
      await repo.createSplitBill(
        title: title,
        totalAmount: totalAmount,
        category: category,
        participantNames: participantNames,
        splitMode: splitMode,
        customAmounts: customAmounts,
        percentages: percentages,
        description: description,
      );
      final updatedList = await repo.fetchSplitBills();
      state = updatedList;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mark a participant's share as paid and deduct from the chosen account.
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

  /// Join an existing split bill by its ID (scanned from a join-QR code).
  ///
  /// Returns the updated [SplitBill] on success, null otherwise.
  Future<SplitBill?> joinBill({
    required String billId,
    required String participantName,
  }) async {
    try {
      final repo = ref.read(splitBillRepositoryProvider);
      final updated = await repo.joinBill(
        billId: billId,
        participantName: participantName,
      );
      if (updated != null) {
        final updatedList = await repo.fetchSplitBills();
        state = updatedList;
      }
      return updated;
    } catch (_) {
      return null;
    }
  }
}

final splitBillsProvider =
    NotifierProvider<SplitBillsController, List<SplitBill>>(
      SplitBillsController.new,
    );
