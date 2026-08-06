import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../core/format/dates.dart';
import '../../domain/split_bill_model.dart';
import '../../state/split_bills_controller.dart';
import '../widgets/brand.dart';
import '../widgets/money_text.dart';
import '../widgets/surfaces.dart';
import 'qr_scanner_screen.dart';
import 'split_bill_qr_screen.dart';

// ---------------------------------------------------------------------------
// Split Bill Detail Screen
// ---------------------------------------------------------------------------

class SplitBillDetailScreen extends ConsumerWidget {
  const SplitBillDetailScreen({required this.billId, super.key});

  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(splitBillsProvider);
    final billMatch = bills.where((b) => b.id == billId);

    if (billMatch.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Split Bill')),
        body: const Center(child: Text('Bill not found.')),
      );
    }

    final bill = billMatch.first;
    final tokens = context.tokens;

    return Scaffold(
      // Theme-adaptive background — respects light/dark mode.
      backgroundColor: tokens.backgroundAlt,
      appBar: AppBar(
        backgroundColor: tokens.backgroundAlt,
        title: Text(bill.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Bill Summary',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shared summary for "${bill.title}" '
                    '(${bill.paidCount}/${bill.totalCount} paid).',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ResponsiveShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x4,
            Space.x5,
            Space.x16 + Space.x8,
          ),
          children: [
            // ── Bill header card ─────────────────────────────────────────
            FrostBackdrop(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(Space.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + status + split-mode badges
                    Wrap(
                      spacing: Space.x2,
                      runSpacing: Space.x2,
                      children: [
                        _GlassBadge(bill.category),
                        _GlassBadge(
                          _splitModeLabel(bill.splitMode),
                          icon: _splitModeIcon(bill.splitMode),
                        ),
                        _GlassBadge(
                          bill.isSettled ? 'Settled' : 'In Progress',
                          color: bill.isSettled
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.x4),
                    Text(
                      bill.title,
                      style: AppType.headlineMedium.copyWith(color: Colors.white),
                    ),
                    if (bill.description != null &&
                        bill.description!.isNotEmpty) ...[
                      const SizedBox(height: Space.x1),
                      Text(
                        bill.description!,
                        style: AppType.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                    ],
                    const SizedBox(height: Space.x1),
                    Text(
                      'Created by ${bill.createdBy} · '
                      '${Dates.monthYear(bill.createdAt)}',
                      style: AppType.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: Space.x4),
                    const Divider(color: Colors.white30),
                    const SizedBox(height: Space.x4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderStat(
                          label: 'Total',
                          value: bill.totalAmount,
                        ),
                        _HeaderStat(
                          label: 'Collected',
                          value: bill.paidAmount,
                          valueColor: Colors.greenAccent,
                        ),
                        _HeaderStat(
                          label: 'Remaining',
                          value: bill.remainingBalance,
                          valueColor: bill.isSettled
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.x4),
                    ClipRRect(
                      borderRadius: AppRadius.all(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: bill.progress,
                        minHeight: 8,
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          bill.isSettled
                              ? Colors.greenAccent
                              : Palette.skyBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.x2),
                    Text(
                      '${bill.paidCount} of ${bill.totalCount} participants paid',
                      style: AppType.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.x6),

            const SectionHeader(title: 'Participants & Shares'),
            const SizedBox(height: Space.x2),

            for (final p in bill.participants)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.x3),
                child: _ParticipantCard(bill: bill, participant: p),
              ),
          ],
        ),
      ),
    );
  }

  String _splitModeLabel(SplitMode mode) => switch (mode) {
        SplitMode.equal => 'Equal Split',
        SplitMode.custom => 'Custom Split',
        SplitMode.percentage => 'Percentage Split',
      };

  IconData _splitModeIcon(SplitMode mode) => switch (mode) {
        SplitMode.equal => Icons.balance_rounded,
        SplitMode.custom => Icons.edit_rounded,
        SplitMode.percentage => Icons.pie_chart_rounded,
      };
}

// ---------------------------------------------------------------------------
// Participant card
// ---------------------------------------------------------------------------

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({required this.bill, required this.participant});

  final SplitBill bill;
  final SplitBillParticipant participant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
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
          // ── Name row ────────────────────────────────────────────────────
          Row(
            children: [
              Monogram(
                initials: participant.monogram,
                size: 40,
                background: participant.isPaid
                    ? Colors.green.withValues(alpha: 0.16)
                    : tokens.interactiveSecondary,
                foreground: participant.isPaid
                    ? Colors.green
                    : tokens.interactivePrimary,
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: AppType.titleSmall.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          participant.isPaid
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          size: 14,
                          color: participant.isPaid
                              ? Colors.green
                              : Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          participant.isPaid ? 'Paid' : 'Pending',
                          style: AppType.bodySmall.copyWith(
                            color: participant.isPaid
                                ? Colors.green
                                : Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (participant.paidAt != null) ...[
                          Text(
                            ' · ${Dates.relative(participant.paidAt!)}',
                            style: AppType.bodySmall.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Share amount + optional percentage badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    participant.shareAmount,
                    style: AppType.numericMedium,
                    color: tokens.textPrimary,
                    label: '${participant.name} share',
                  ),
                  if (participant.sharePercentage != null)
                    Text(
                      '${participant.sharePercentage!.toStringAsFixed(1)}%',
                      style: AppType.labelSmall.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Note ────────────────────────────────────────────────────────
          if (participant.note != null && participant.note!.isNotEmpty) ...[
            const SizedBox(height: Space.x2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x3,
                vertical: Space.x2,
              ),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: AppRadius.all(AppRadius.sm),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded,
                      size: 14, color: tokens.textSecondary),
                  const SizedBox(width: Space.x2),
                  Expanded(
                    child: Text(
                      participant.note!,
                      style: AppType.bodySmall.copyWith(
                          color: tokens.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Action buttons (pending only) ────────────────────────────────
          if (!participant.isPaid) ...[
            const SizedBox(height: Space.x4),
            Divider(color: tokens.border, height: 1),
            const SizedBox(height: Space.x3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SplitBillQrScreen(
                          billId: bill.id,
                          participantId: participant.id,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('Request Payment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tokens.interactivePrimary,
                      side: BorderSide(color: tokens.border),
                    ),
                  ),
                ),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final payload =
                          participant.generateQrPayload(bill.id, bill.title);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              QrScannerScreen(initialPayload: payload),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: const Text('Simulate Pay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.interactivePrimary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      textStyle: AppType.labelLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

class _GlassBadge extends StatelessWidget {
  const _GlassBadge(this.label, {this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x1,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppType.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final double value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.76),
          ),
        ),
        MoneyText(
          value,
          style: AppType.numericSmall,
          color: valueColor ?? Colors.white,
        ),
      ],
    );
  }
}
