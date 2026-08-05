import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

enum TxnDateRange { anyTime, last7Days, last30Days, last90Days }

extension TxnDateRangeLabel on TxnDateRange {
  String get label => switch (this) {
    TxnDateRange.anyTime => 'Any time',
    TxnDateRange.last7Days => 'Last 7 days',
    TxnDateRange.last30Days => 'Last 30 days',
    TxnDateRange.last90Days => 'Last 90 days',
  };

  int? get days => switch (this) {
    TxnDateRange.anyTime => null,
    TxnDateRange.last7Days => 7,
    TxnDateRange.last30Days => 30,
    TxnDateRange.last90Days => 90,
  };
}

/// Filter state for the transaction history screen.
@immutable
class TxnFilter {
  const TxnFilter({
    this.types = const <TxnType>{},
    this.range = TxnDateRange.anyTime,
    this.accountId,
    this.query = '',
  });

  final Set<TxnType> types;
  final TxnDateRange range;
  final String? accountId;
  final String query;

  bool get isEmpty =>
      types.isEmpty &&
      range == TxnDateRange.anyTime &&
      accountId == null &&
      query.trim().isEmpty;

  TxnFilter copyWith({
    Set<TxnType>? types,
    TxnDateRange? range,
    String? accountId,
    bool clearAccount = false,
    String? query,
  }) => TxnFilter(
    types: types ?? this.types,
    range: range ?? this.range,
    accountId: clearAccount ? null : (accountId ?? this.accountId),
    query: query ?? this.query,
  );

  /// Applies every selected criterion. Search matches merchant or reference
  /// without case sensitivity.
  List<Txn> apply(List<Txn> rows, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final needle = query.trim().toLowerCase();
    final days = range.days;

    return rows.where((txn) {
      if (types.isNotEmpty && !types.contains(txn.type)) return false;
      if (accountId != null && txn.accountId != accountId) return false;
      if (days != null) {
        final cutoff = reference.subtract(Duration(days: days));
        if (txn.date.isBefore(cutoff)) return false;
      }
      if (needle.isNotEmpty) {
        final haystack =
            '${txn.merchant} ${txn.reference} ${txn.category}'.toLowerCase();
        if (!haystack.contains(needle)) return false;
      }
      return true;
    }).toList();
  }
}

class TxnFilterController extends Notifier<TxnFilter> {
  @override
  TxnFilter build() => const TxnFilter();

  void setQuery(String value) => state = state.copyWith(query: value);

  void toggleType(TxnType type) {
    final next = Set<TxnType>.of(state.types);
    if (!next.remove(type)) next.add(type);
    state = state.copyWith(types: next);
  }

  void removeType(TxnType type) {
    final next = Set<TxnType>.of(state.types)..remove(type);
    state = state.copyWith(types: next);
  }

  void setRange(TxnDateRange range) => state = state.copyWith(range: range);

  void setAccount(String? accountId) => accountId == null
      ? state = state.copyWith(clearAccount: true)
      : state = state.copyWith(accountId: accountId);

  void clear() => state = const TxnFilter();
}
