import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../widgets/card_face.dart';
import '../widgets/money_text.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';
import '../widgets/transaction_list.dart';

/// Detail template shared by the Wallet, the Savings account, and the Crypto
/// wallet. Account specific actions come from the account kind.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider(accountId));

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ResponsiveShell(
        child: AsyncSection<Account>(
          value: account,
          onRetry: () => ref.invalidate(accountProvider(accountId)),
          skeleton: const Padding(
            padding: EdgeInsets.all(Space.x5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 180, height: 22),
                SizedBox(height: Space.x4),
                SkeletonBlock(width: 220, height: 38),
                SizedBox(height: Space.x6),
                SkeletonBlock(height: 88, radius: AppRadius.lg),
                SizedBox(height: Space.x6),
                SkeletonRows(),
              ],
            ),
          ),
          builder: (data) => _AccountBody(account: data),
        ),
      ),
    );
  }
}

class _AccountBody extends ConsumerWidget {
  const _AccountBody({required this.account});

  final Account account;

  List<_AccountAction> get _actions => switch (account.kind) {
    AccountKind.savings => const [
      _AccountAction('Deposit', Icons.south_west_rounded, '/soon/deposit'),
      _AccountAction('Transfer', Icons.swap_horiz_rounded, '/soon/transfer'),
    ],
    AccountKind.wallet => const [
      _AccountAction('Deposit', Icons.south_west_rounded, '/soon/deposit'),
      _AccountAction('Send', Icons.north_east_rounded, '/soon/send-money'),
      _AccountAction('Scan', Icons.qr_code_scanner_rounded, '/soon/qr-payment'),
    ],
    AccountKind.crypto => const [
      _AccountAction('Buy', Icons.add_rounded, '/soon/buy-crypto'),
      _AccountAction('Sell', Icons.remove_rounded, '/soon/sell-crypto'),
      _AccountAction('Send', Icons.north_east_rounded, '/soon/send-crypto'),
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final flow = ref.watch(monthFlowProvider(account.id));
    final rows = ref.watch(transactionsProvider(account.id));
    final cards = ref.watch(accountCardsProvider(account.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.x5, 0, Space.x5, Space.x10),
      children: [
        Text(
          account.name,
          style: AppType.headlineLarge.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: Space.x1),
        Text(
          '${account.kind.label}  \u2022  ${account.maskedNumber}',
          style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: Space.x5),
        MoneyText(
          account.totalBalance,
          style: AppType.numericHero,
          currencyCode: account.currencyCode,
          label: '${account.name} total balance',
        ),
        const SizedBox(height: Space.x2),
        Row(
          children: [
            Text(
              'Available ',
              style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
            ),
            MoneyText(
              account.availableBalance,
              style: AppType.numericSmall,
              color: tokens.textSecondary,
              currencyCode: account.currencyCode,
              label: '${account.name} available balance',
            ),
          ],
        ),
        if (account.isCrypto && account.cryptoQuantity != null) ...[
          const SizedBox(height: Space.x2),
          NumericText(
            Money.quantity(account.cryptoQuantity!, account.cryptoUnit ?? ''),
            style: AppType.numericMedium,
            color: tokens.textPrimary,
            label:
                'Holding ${Money.quantity(account.cryptoQuantity!, account.cryptoUnit ?? '')}',
          ),
        ],
        const SizedBox(height: Space.x6),
        Row(
          children: [
            for (final action in _actions)
              Padding(
                padding: const EdgeInsets.only(right: Space.x2),
                child: _ActionChip(action: action),
              ),
          ],
        ),
        const SizedBox(height: Space.x6),
        AsyncSection<MonthFlow>(
          value: flow,
          onRetry: () => ref.invalidate(monthFlowProvider(account.id)),
          skeleton: const SkeletonBlock(height: 84, radius: AppRadius.lg),
          builder: (data) => Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FlowFigure(
                    label: 'In this month',
                    value: data.inflow,
                    color: tokens.success,
                    currencyCode: account.currencyCode,
                  ),
                ),
                Container(width: 1, height: 42, color: tokens.border),
                Expanded(
                  child: _FlowFigure(
                    label: 'Out this month',
                    value: data.outflow,
                    color: tokens.textPrimary,
                    currencyCode: account.currencyCode,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.x6),
        AsyncSection<List<BankCard>>(
          value: cards,
          onRetry: () => ref.invalidate(accountCardsProvider(account.id)),
          skeleton: const SkeletonBlock(height: 60, radius: AppRadius.lg),
          isEmpty: (data) => data.isEmpty,
          empty: const SizedBox.shrink(),
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Linked cards'),
              for (final card in data)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.x2),
                  child: Pressable(
                    onTap: () => context.push('/card/${card.id}'),
                    semanticLabel:
                        '${card.label}, ${card.network.label} ending ${card.last4}',
                    borderRadius: AppRadius.lg,
                    child: Container(
                      padding: const EdgeInsets.all(Space.x4),
                      decoration: BoxDecoration(
                        color: tokens.surfaceRaised,
                        borderRadius: AppRadius.all(AppRadius.lg),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Row(
                        children: [
                          // The card itself, not a generic card icon, so the
                          // row names the object the holder recognises.
                          MiniCardFace(card: card, width: 38),
                          const SizedBox(width: Space.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.label,
                                  style: AppType.titleSmall.copyWith(
                                    color: tokens.textPrimary,
                                  ),
                                ),
                                NumericText(
                                  card.maskedNumber,
                                  color: tokens.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: tokens.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.x6),
        Text(
          'Activity in ${Dates.monthYear(DateTime.now())}',
          style: AppType.headlineMedium.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: Space.x2),
        AsyncSection<List<Txn>>(
          value: rows,
          onRetry: () => ref.invalidate(transactionsProvider(account.id)),
          skeleton: const SkeletonRows(),
          isEmpty: (data) => data.isEmpty,
          empty: EmptyStateView(
            heading: 'No activity yet',
            message: 'Transactions on this account will appear here.',
            actionLabel: 'Add funds',
            onAction: () => context.push('/soon/deposit'),
          ),
          builder: (data) => GroupedTransactions(
            rows: data,
            onSelect: (txn) => context.push('/txn/${txn.id}'),
          ),
        ),
      ],
    );
  }
}

class _FlowFigure extends StatelessWidget {
  const _FlowFigure({
    required this.label,
    required this.value,
    required this.color,
    required this.currencyCode,
  });

  final String label;
  final double value;
  final Color color;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppType.labelMedium.copyWith(color: context.tokens.textSecondary),
      ),
      const SizedBox(height: Space.x1),
      MoneyText(
        value,
        style: AppType.numericMedium,
        color: color,
        currencyCode: currencyCode,
        label: label,
      ),
    ],
  );
}

class _AccountAction {
  const _AccountAction(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action});

  final _AccountAction action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: () => context.push(action.route),
      semanticLabel: action.label,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        decoration: BoxDecoration(
          color: tokens.interactiveSecondary,
          borderRadius: AppRadius.all(AppRadius.pill),
        ),
        child: Row(
          children: [
            Icon(action.icon, size: 18, color: tokens.interactivePrimary),
            const SizedBox(width: Space.x2),
            Text(
              action.label,
              style: AppType.labelLarge.copyWith(
                color: tokens.interactivePrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
