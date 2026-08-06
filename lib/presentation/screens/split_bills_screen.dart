import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../domain/split_bill_model.dart';
import '../../state/split_bills_controller.dart';
import '../widgets/brand.dart';
import '../widgets/money_text.dart';
import '../widgets/pressable.dart';
import '../widgets/states.dart';
import '../widgets/surfaces.dart';
import 'create_split_bill_screen.dart';
import 'qr_scanner_screen.dart';
import 'split_bill_detail_screen.dart';

// ---------------------------------------------------------------------------
// Split Bills Screen
// ---------------------------------------------------------------------------

class SplitBillsScreen extends ConsumerStatefulWidget {
  const SplitBillsScreen({super.key});

  @override
  ConsumerState<SplitBillsScreen> createState() => _SplitBillsScreenState();
}

class _SplitBillsScreenState extends ConsumerState<SplitBillsScreen> {
  int _selectedTab = 0; // 0: Active, 1: Settled, 2: All

  void _openCreateExpense() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateSplitBillScreen()),
      );

  void _openScanQr() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );

  void _openDetail(String billId) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SplitBillDetailScreen(billId: billId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bills = ref.watch(splitBillsProvider);

    final activeBills = bills.where((b) => !b.isSettled).toList();
    final settledBills = bills.where((b) => b.isSettled).toList();

    final displayedBills = switch (_selectedTab) {
      0 => activeBills,
      1 => settledBills,
      _ => bills,
    };

    final totalOutstanding = activeBills.fold<double>(
      0.0,
      (sum, bill) => sum + bill.remainingBalance,
    );

    return Scaffold(
      // Theme-adaptive background — respects light/dark mode.
      backgroundColor: tokens.backgroundAlt,
      appBar: AppBar(
        backgroundColor: tokens.backgroundAlt,
        title: const Text('Split Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan QR to Pay',
            onPressed: _openScanQr,
          ),
        ],
      ),
      body: ResponsiveShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x2,
            Space.x5,
            Space.x16 + Space.x8,
          ),
          children: [
            // ── Summary banner ─────────────────────────────────────────────
            FrostBackdrop(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(Space.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total outstanding balance',
                      style: AppType.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    MoneyText(
                      totalOutstanding,
                      style: AppType.numericLarge,
                      color: tokens.textOnBrand,
                      label: 'Total outstanding split bill balance',
                    ),
                    const SizedBox(height: Space.x4),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openCreateExpense,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Expense'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Palette.frostBaseBottom,
                              elevation: 4,
                              textStyle: AppType.labelLarge
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.x3),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openScanQr,
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 18,
                            ),
                            label: const Text('Scan QR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white60,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.x6),

            // ── Tab filter ─────────────────────────────────────────────────
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text('Active (${activeBills.length})'),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Settled (${settledBills.length})'),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('All (${bills.length})'),
                ),
              ],
              selected: {_selectedTab},
              showSelectedIcon: false,
              onSelectionChanged: (sel) =>
                  setState(() => _selectedTab = sel.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: tokens.surface,
                foregroundColor: tokens.textSecondary,
                selectedBackgroundColor: tokens.interactiveSecondary,
                selectedForegroundColor: tokens.interactivePrimary,
                side: BorderSide(color: tokens.border),
                textStyle: AppType.labelMedium,
              ),
            ),
            const SizedBox(height: Space.x6),

            // ── Bills list ─────────────────────────────────────────────────
            if (displayedBills.isEmpty)
              EmptyStateView(
                heading: _selectedTab == 1
                    ? 'No settled bills'
                    : 'No split bills found',
                message:
                    'Create a split bill to manage shared expenses with friends.',
                actionLabel: 'Create Expense',
                icon: Icons.groups_rounded,
                onAction: _openCreateExpense,
              )
            else
              Column(
                children: [
                  for (final bill in displayedBills)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.x3),
                      child: _SplitBillCard(
                        bill: bill,
                        onTap: () => _openDetail(bill.id),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Expense'),
        backgroundColor: tokens.interactivePrimary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bill list card
// ---------------------------------------------------------------------------

class _SplitBillCard extends StatelessWidget {
  const _SplitBillCard({required this.bill, required this.onTap});

  final SplitBill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Pressable(
      onTap: onTap,
      semanticLabel: '${bill.title}, ${bill.category}, total ${bill.totalAmount}, '
          '${bill.isSettled ? 'Settled' : '${bill.paidCount} of ${bill.totalCount} paid'}',
      borderRadius: AppRadius.lg,
      child: Container(
        padding: const EdgeInsets.all(Space.x4),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: AppRadius.all(AppRadius.lg),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: tokens.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.x2),
                  decoration: BoxDecoration(
                    color: tokens.interactiveSecondary,
                    borderRadius: AppRadius.all(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: tokens.interactivePrimary,
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: AppType.titleSmall.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${bill.category} · ${Dates.relative(bill.createdAt)}',
                        style: AppType.bodySmall.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyText(
                  bill.totalAmount,
                  style: AppType.numericMedium,
                  color: tokens.textPrimary,
                  label: '${bill.title} total',
                ),
              ],
            ),
            const SizedBox(height: Space.x3),

            // Split mode chip
            _SplitModeChip(bill.splitMode, tokens: tokens),
            const SizedBox(height: Space.x3),

            // Progress bar
            ClipRRect(
              borderRadius: AppRadius.all(AppRadius.pill),
              child: LinearProgressIndicator(
                value: bill.progress,
                minHeight: 6,
                backgroundColor: tokens.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  bill.isSettled ? Colors.green : tokens.interactivePrimary,
                ),
              ),
            ),
            const SizedBox(height: Space.x3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bill.isSettled
                      ? 'Fully Paid'
                      : '${bill.paidCount} of ${bill.totalCount} Paid',
                  style: AppType.labelSmall.copyWith(
                    color: bill.isSettled ? Colors.green : tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!bill.isSettled)
                  Row(
                    children: [
                      Text(
                        'Remaining: ',
                        style: AppType.bodySmall
                            .copyWith(color: tokens.textSecondary),
                      ),
                      MoneyText(
                        bill.remainingBalance,
                        style: AppType.numericSmall,
                        color: tokens.interactivePrimary,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Split mode chip
// ---------------------------------------------------------------------------

class _SplitModeChip extends StatelessWidget {
  const _SplitModeChip(this.mode, {required this.tokens});

  final SplitMode mode;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (mode) {
      SplitMode.equal => ('Equal', Icons.balance_rounded),
      SplitMode.custom => ('Custom', Icons.edit_rounded),
      SplitMode.percentage => ('Percentage', Icons.pie_chart_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tokens.interactiveSecondary,
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tokens.interactivePrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppType.labelSmall.copyWith(
              color: tokens.interactivePrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
