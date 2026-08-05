import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/split_bills_controller.dart';
import '../widgets/brand.dart';
import '../widgets/money_text.dart';
import '../widgets/qr_painter.dart';
import '../widgets/surfaces.dart';
import 'qr_scanner_screen.dart';

/// Screen displaying a unique payment QR code for a participant's split share.
class SplitBillQrScreen extends ConsumerWidget {
  const SplitBillQrScreen({
    required this.billId,
    required this.participantId,
    super.key,
  });

  final String billId;
  final String participantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final bills = ref.watch(splitBillsProvider);

    final billMatch = bills.where((b) => b.id == billId);
    if (billMatch.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment QR')),
        body: const Center(child: Text('Bill not found.')),
      );
    }

    final bill = billMatch.first;
    final pMatch = bill.participants.where((p) => p.id == participantId);
    if (pMatch.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment QR')),
        body: const Center(child: Text('Participant not found.')),
      );
    }

    final participant = pMatch.first;
    final qrPayload = participant.generateQrPayload(bill.id, bill.title);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FE), // Touch of light blue tint for window
      appBar: AppBar(
        title: const Text('Payment Request QR'),
      ),
      body: ResponsiveShell(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.x5,
            Space.x4,
            Space.x5,
            Space.x16,
          ),
          children: [
            // Payment Request Card with EXACT Dashboard FrostBackdrop Gradient
            FrostBackdrop(
              borderRadius: AppRadius.all(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(Space.x6),
                child: Column(
                  children: [
                    Text(
                      'Request Payment',
                      style: AppType.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: Space.x1),
                    Text(
                      participant.name,
                      style: AppType.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      bill.title,
                      style: AppType.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: Space.x4),
                    MoneyText(
                      participant.shareAmount,
                      style: AppType.numericHero,
                      color: tokens.textOnBrand,
                      label: 'Payment amount',
                    ),
                    const SizedBox(height: Space.x6),

                    // QR Code Widget
                    QrCodeWidget(
                      data: qrPayload,
                      size: 220,
                    ),

                    const SizedBox(height: Space.x6),
                    Container(
                      padding: const EdgeInsets.all(Space.x3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.all(AppRadius.md),
                        border: Border.all(
                          color: Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: Space.x3),
                          Expanded(
                            child: Text(
                              'Scan this QR code within the app to simulate paying ${participant.name}\'s share.',
                              style: AppType.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.x6),

            // Action Buttons
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrScannerScreen(
                      initialPayload: qrPayload,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan & Pay Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                backgroundColor: tokens.interactivePrimary,
                foregroundColor: Colors.white,
                elevation: 4,
                textStyle: AppType.labelLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: Space.x3),
            OutlinedButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.pop();
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.textPrimary,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
