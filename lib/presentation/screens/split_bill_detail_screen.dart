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

/// Detail view for a specific split bill expense.
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FE), // Touch of light blue tint for window
      appBar: AppBar(
        title: Text(bill.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Bill Summary',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shared summary for "${bill.title}" (${bill.paidCount}/${bill.totalCount} paid).',
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
            // Bill Header Card with EXACT Dashboard FrostBackdrop Gradient (default glow = 0.34)
            FrostBackdrop(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(Space.x5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x3,
                            vertical: Space.x1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppRadius.all(AppRadius.pill),
                          ),
                          child: Text(
                            bill.category,
                            style: AppType.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.x3,
                            vertical: Space.x1,
                          ),
                          decoration: BoxDecoration(
                            color: bill.isSettled
                                ? Colors.greenAccent.withValues(alpha: 0.25)
                                : Colors.amber.withValues(alpha: 0.25),
                            borderRadius: AppRadius.all(AppRadius.pill),
                          ),
                          child: Text(
                            bill.isSettled ? 'Settled' : 'In Progress',
                            style: AppType.labelSmall.copyWith(
                              color: bill.isSettled ? Colors.greenAccent : Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.x4),
                    Text(
                      bill.title,
                      style: AppType.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: Space.x1),
                    Text(
                      'Created by ${bill.createdBy} • ${Dates.monthYear(bill.createdAt)}',
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Expense',
                              style: AppType.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                              ),
                            ),
                            MoneyText(
                              bill.totalAmount,
                              style: AppType.numericMedium,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Remaining Balance',
                              style: AppType.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                              ),
                            ),
                            MoneyText(
                              bill.remainingBalance,
                              style: AppType.numericMedium,
                              color: bill.isSettled ? Colors.greenAccent : Colors.amberAccent,
                            ),
                          ],
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
                          bill.isSettled ? Colors.greenAccent : Palette.skyBlue,
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

            // Participant cards
            Column(
              children: [
                for (final p in bill.participants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.x3),
                    child: _ParticipantCard(
                      bill: bill,
                      participant: p,
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

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.bill,
    required this.participant,
  });

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
                          color: participant.isPaid ? Colors.green : Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          participant.isPaid ? 'Paid' : 'Pending',
                          style: AppType.bodySmall.copyWith(
                            color: participant.isPaid ? Colors.green : Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MoneyText(
                participant.shareAmount,
                style: AppType.numericMedium,
                color: tokens.textPrimary,
                label: '${participant.name} share',
              ),
            ],
          ),
          if (!participant.isPaid) ...[
            const SizedBox(height: Space.x4),
            Divider(color: tokens.border, height: 1),
            const SizedBox(height: Space.x3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SplitBillQrScreen(
                            billId: bill.id,
                            participantId: participant.id,
                          ),
                        ),
                      );
                    },
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
                      final payload = participant.generateQrPayload(bill.id, bill.title);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => QrScannerScreen(
                            initialPayload: payload,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: const Text('Simulate Pay'),
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.interactivePrimary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      textStyle: AppType.labelLarge.copyWith(fontWeight: FontWeight.bold),
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
