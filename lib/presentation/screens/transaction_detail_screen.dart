import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/money_text.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';

/// One transaction, with the account it belongs to and its reference.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({required this.txnId, super.key});

  final String txnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txn = ref.watch(transactionProvider(txnId));
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: ResponsiveShell(
        child: AsyncSection<Txn>(
          value: txn,
          onRetry: () => ref.invalidate(transactionProvider(txnId)),
          skeleton: const Padding(
            padding: EdgeInsets.all(Space.x5),
            child: Column(
              children: [
                SkeletonBlock(width: 64, height: 64, radius: AppRadius.pill),
                SizedBox(height: Space.x4),
                SkeletonBlock(width: 200, height: 32),
                SizedBox(height: Space.x6),
                SkeletonRows(count: 5),
              ],
            ),
          ),
          builder: (data) {
            final accountName = ref
                .watch(accountsProvider)
                .value
                ?.where((account) => account.id == data.accountId)
                .firstOrNull
                ?.name;

            final statusColor = switch (data.status) {
              TxnStatus.completed => tokens.success,
              TxnStatus.pending => tokens.warning,
              TxnStatus.failed => tokens.error,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.x5,
                0,
                Space.x5,
                Space.x10,
              ),
              children: [
                Center(
                  child: Column(
                    children: [
                      Monogram(initials: data.monogram, size: 64),
                      const SizedBox(height: Space.x4),
                      Text(
                        data.merchant,
                        style: AppType.headlineMedium.copyWith(
                          color: tokens.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Space.x2),
                      MoneyText(
                        data.signedAmount,
                        signed: true,
                        style: AppType.numericLarge,
                        color: data.isInflow
                            ? tokens.success
                            : tokens.textPrimary,
                        currencyCode: data.currencyCode,
                        label: '${data.merchant} amount',
                      ),
                      const SizedBox(height: Space.x3),
                      StatusPill(label: data.status.label, color: statusColor),
                    ],
                  ),
                ),
                const SizedBox(height: Space.x8),
                DetailRow(label: 'Type', value: Text(data.type.label)),
                DetailRow(label: 'Category', value: Text(data.category)),
                DetailRow(
                  label: 'Account',
                  value: Text(accountName ?? 'Linked account'),
                ),
                DetailRow(
                  label: 'Date and time',
                  value: Text(Dates.dayAndTime(data.date)),
                ),
                DetailRow(
                  label: 'Reference',
                  value: NumericText(
                    data.reference,
                    style: AppType.numericMedium,
                    label: 'Reference ${data.reference.split('').join(' ')}',
                  ),
                ),
                if (data.note != null)
                  DetailRow(label: 'Note', value: Text(data.note!)),
                const SizedBox(height: Space.x8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/soon/receipts'),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share receipt'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
