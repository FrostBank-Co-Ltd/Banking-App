import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../domain/models.dart';
import 'money_text.dart';
import 'pressable.dart';
import 'surfaces.dart';

/// One transaction row: monogram avatar, merchant, category, right aligned
/// signed amount, and a smaller secondary line under the amount.
class TransactionRow extends StatelessWidget {
  const TransactionRow({required this.txn, required this.onTap, super.key});

  final Txn txn;
  final VoidCallback onTap;

  Color _statusColor(AppTokens tokens) => switch (txn.status) {
    TxnStatus.completed => tokens.textSecondary,
    TxnStatus.pending => tokens.warning,
    TxnStatus.failed => tokens.error,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final amountColor = txn.status == TxnStatus.failed
        ? tokens.textSecondary
        : (txn.isInflow ? tokens.success : tokens.textPrimary);
    final secondary = txn.status == TxnStatus.completed
        ? Dates.time(txn.date)
        : txn.status.label;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.md,
      semanticLabel:
          '${txn.merchant}, ${txn.category}, ${txn.type.label}, '
          '${txn.status.label}, ${Dates.dayAndTime(txn.date)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.x3),
        child: Row(
          children: [
            Monogram(initials: txn.monogram),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.merchant,
                    style: AppType.titleSmall.copyWith(
                      color: tokens.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    txn.category,
                    style: AppType.bodySmall.copyWith(
                      color: tokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.x3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  txn.signedAmount,
                  signed: true,
                  color: amountColor,
                  currencyCode: txn.currencyCode,
                  style: AppType.numericMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  style: AppType.bodySmall.copyWith(
                    color: _statusColor(tokens),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Transactions grouped under day headers, newest first.
class GroupedTransactions extends StatelessWidget {
  const GroupedTransactions({
    required this.rows,
    required this.onSelect,
    this.limit,
    super.key,
  });

  final List<Txn> rows;
  final void Function(Txn txn) onSelect;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final visible = limit == null || rows.length <= limit!
        ? rows
        : rows.sublist(0, limit!);

    final children = <Widget>[];
    DateTime? currentDay;

    for (final txn in visible) {
      final day = Dates.dayKey(txn.date);
      if (currentDay == null || day != currentDay) {
        currentDay = day;
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : Space.x4,
              bottom: Space.x1,
            ),
            child: Semantics(
              header: true,
              child: Text(
                Dates.dayHeader(txn.date),
                style: AppType.labelMedium.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ),
        );
      }
      children.add(TransactionRow(txn: txn, onTap: () => onSelect(txn)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
