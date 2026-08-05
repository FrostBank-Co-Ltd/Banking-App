import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../../state/txn_filter.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';
import '../widgets/transaction_list.dart';

/// Full ledger with search, filters, and removable filter chips.
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  late final TextEditingController _search = TextEditingController(
    text: ref.read(txnFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final filter = ref.watch(txnFilterProvider);
    final rows = ref.watch(filteredTransactionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    // Keep the field in step when another screen hands a query over.
    ref.listen(txnFilterProvider, (_, next) {
      if (next.query != _search.text) _search.text = next.query;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            onPressed: () => _openFilters(context),
            tooltip: 'Filter transactions',
            icon: const Icon(Icons.filter_list_rounded),
          ),
          const SizedBox(width: Space.x2),
        ],
      ),
      body: ResponsiveShell(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x5, 0, Space.x5, Space.x3),
              child: TextField(
                controller: _search,
                onChanged: (value) =>
                    ref.read(txnFilterProvider.notifier).setQuery(value),
                textInputAction: TextInputAction.search,
                style: AppType.bodyMedium.copyWith(color: tokens.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search merchant or reference',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            ref.read(txnFilterProvider.notifier).setQuery('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.pill),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.pill),
                    borderSide: BorderSide(color: tokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.all(AppRadius.pill),
                    borderSide: BorderSide(color: tokens.accent, width: 2),
                  ),
                ),
              ),
            ),
            if (!filter.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.x5,
                  0,
                  Space.x5,
                  Space.x2,
                ),
                child: _ActiveFilters(filter: filter, accounts: accounts),
              ),
            Expanded(
              child: RefreshIndicator(
                color: tokens.accent,
                onRefresh: () async {
                  ref.invalidate(transactionsProvider);
                  await ref.read(filteredTransactionsProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.x5,
                    Space.x2,
                    Space.x5,
                    Space.x16 + Space.x8,
                  ),
                  children: [
                    AsyncSection<List<Txn>>(
                      value: rows,
                      onRetry: () => ref.invalidate(transactionsProvider),
                      skeleton: const SkeletonRows(count: 7),
                      isEmpty: (data) => data.isEmpty,
                      empty: EmptyStateView(
                        heading: 'Nothing matches those filters',
                        message:
                            'Clear the filters to see every transaction again.',
                        actionLabel: 'Clear filters',
                        icon: Icons.filter_alt_off_rounded,
                        onAction: () {
                          _search.clear();
                          ref.read(txnFilterProvider.notifier).clear();
                        },
                      ),
                      builder: (data) => GroupedTransactions(
                        rows: data,
                        onSelect: (txn) => context.push('/txn/${txn.id}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters({required this.filter, required this.accounts});

  final TxnFilter filter;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(txnFilterProvider.notifier);
    final account = accounts
        .where((item) => item.id == filter.accountId)
        .firstOrNull;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: Space.x2,
        runSpacing: Space.x2,
        children: [
          for (final type in filter.types)
            _RemovableChip(
              label: type.label,
              onRemove: () => controller.removeType(type),
            ),
          if (filter.range != TxnDateRange.anyTime)
            _RemovableChip(
              label: filter.range.label,
              onRemove: () => controller.setRange(TxnDateRange.anyTime),
            ),
          if (account != null)
            _RemovableChip(
              label: account.name,
              onRemove: () => controller.setAccount(null),
            ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: onRemove,
      semanticLabel: 'Remove filter $label',
      borderRadius: AppRadius.pill,
      minSize: 36,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x3,
          vertical: Space.x2,
        ),
        decoration: BoxDecoration(
          color: tokens.interactiveSecondary,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppType.labelMedium.copyWith(
                color: tokens.interactivePrimary,
              ),
            ),
            const SizedBox(width: Space.x1),
            Icon(
              Icons.close_rounded,
              size: 16,
              color: tokens.interactivePrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final filter = ref.watch(txnFilterProvider);
    final controller = ref.read(txnFilterProvider.notifier);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.x5, 0, Space.x5, Space.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter transactions',
              style: AppType.headlineMedium.copyWith(color: tokens.textPrimary),
            ),
            const SizedBox(height: Space.x5),
            _FilterGroupLabel('Type'),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: [
                for (final type in TxnType.values)
                  _ChoiceChipTile(
                    label: type.label,
                    selected: filter.types.contains(type),
                    onTap: () => controller.toggleType(type),
                  ),
              ],
            ),
            const SizedBox(height: Space.x5),
            _FilterGroupLabel('Date range'),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: [
                for (final range in TxnDateRange.values)
                  _ChoiceChipTile(
                    label: range.label,
                    selected: filter.range == range,
                    onTap: () => controller.setRange(range),
                  ),
              ],
            ),
            const SizedBox(height: Space.x5),
            _FilterGroupLabel('Account'),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x2,
              children: [
                _ChoiceChipTile(
                  label: 'All accounts',
                  selected: filter.accountId == null,
                  onTap: () => controller.setAccount(null),
                ),
                for (final account in accounts)
                  _ChoiceChipTile(
                    label: account.name,
                    selected: filter.accountId == account.id,
                    onTap: () => controller.setAccount(account.id),
                  ),
              ],
            ),
            const SizedBox(height: Space.x6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.clear,
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Show results'),
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

class _FilterGroupLabel extends StatelessWidget {
  const _FilterGroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.x3),
    child: Text(
      text,
      style: AppType.labelLarge.copyWith(color: context.tokens.textSecondary),
    ),
  );
}

class _ChoiceChipTile extends StatelessWidget {
  const _ChoiceChipTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label${selected ? ', selected' : ''}',
      borderRadius: AppRadius.pill,
      minSize: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        decoration: BoxDecoration(
          color: selected ? tokens.interactiveSecondary : tokens.surface,
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(
            color: selected ? tokens.accent : tokens.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppType.labelMedium.copyWith(
            color: selected ? tokens.interactivePrimary : tokens.textPrimary,
          ),
        ),
      ),
    );
  }
}
