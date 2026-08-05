import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/providers.dart';
import '../../state/split_bills_controller.dart';
import '../widgets/money_text.dart';
import '../widgets/pressable.dart';

/// In-app QR scanner simulating camera viewfinder and payment execution.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({this.initialPayload, super.key});

  final String? initialPayload;

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPayload != null && widget.initialPayload!.isNotEmpty) {
        _handlePayload(widget.initialPayload!);
      }
    });
  }

  void _handlePayload(String rawPayload) {
    try {
      final data = jsonDecode(rawPayload) as Map<String, dynamic>;
      if (data['type'] == 'split_bill_payment') {
        _showPaymentConfirmationModal(
          billId: data['billId'] as String,
          participantId: data['participantId'] as String,
          participantName: data['participantName'] as String,
          billTitle: data['billTitle'] as String,
          amount: (data['amount'] as num).toDouble(),
        );
      } else {
        _showError('Invalid QR code format for split bill payment.');
      }
    } catch (_) {
      _showError('Unrecognized QR code payload.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPaymentConfirmationModal({
    required String billId,
    required String participantId,
    required String participantName,
    required String billTitle,
    required double amount,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _PaymentConfirmationSheet(
        billId: billId,
        participantId: participantId,
        participantName: participantName,
        billTitle: billTitle,
        amount: amount,
        onSuccess: () {
          Navigator.of(modalContext).pop();
          if (mounted && context.canPop()) {
            context.pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bills = ref.watch(splitBillsProvider);

    // Find all pending participants across active bills for simulated scanning
    final pendingScannables = <_PendingScanItem>[];
    for (final bill in bills) {
      if (bill.isSettled) continue;
      for (final p in bill.participants) {
        if (!p.isPaid) {
          pendingScannables.add(
            _PendingScanItem(
              billId: bill.id,
              billTitle: bill.title,
              participantId: p.id,
              participantName: p.name,
              amount: p.shareAmount,
              payload: p.generateQrPayload(bill.id, bill.title),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _flashOn = !_flashOn),
          ),
        ],
      ),
      body: Column(
        children: [
          // Simulated Camera Viewfinder
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  color: const Color(0xFF121212),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Scanning reticle frame
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _flashOn ? Colors.yellow : tokens.accent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (tokens.accent).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.x4,
                      vertical: Space.x2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Position QR code inside the frame to scan',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Simulation Options Sheet
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.x5),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulate QR Scan',
                    style: AppType.titleMedium.copyWith(color: tokens.textPrimary),
                  ),
                  Text(
                    'Select a pending split bill payment to simulate scanning its QR code:',
                    style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: Space.x3),
                  Expanded(
                    child: pendingScannables.isEmpty
                        ? Center(
                            child: Text(
                              'No pending split bill payments available to scan.',
                              style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pendingScannables.length,
                            itemBuilder: (context, index) {
                              final item = pendingScannables[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Space.x2),
                                child: Pressable(
                                  onTap: () => _handlePayload(item.payload),
                                  borderRadius: AppRadius.md,
                                  child: Container(
                                    padding: const EdgeInsets.all(Space.x3),
                                    decoration: BoxDecoration(
                                      color: tokens.surfaceRaised,
                                      borderRadius: AppRadius.all(AppRadius.md),
                                      border: Border.all(color: tokens.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code_2_rounded,
                                          color: tokens.accent,
                                        ),
                                        const SizedBox(width: Space.x3),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Pay ${item.participantName}\'s share',
                                                style: AppType.titleSmall.copyWith(color: tokens.textPrimary),
                                              ),
                                              Text(
                                                item.billTitle,
                                                style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        MoneyText(item.amount, style: AppType.numericSmall),
                                        const SizedBox(width: Space.x2),
                                        Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingScanItem {
  const _PendingScanItem({
    required this.billId,
    required this.billTitle,
    required this.participantId,
    required this.participantName,
    required this.amount,
    required this.payload,
  });

  final String billId;
  final String billTitle;
  final String participantId;
  final String participantName;
  final double amount;
  final String payload;
}

class _PaymentConfirmationSheet extends ConsumerStatefulWidget {
  const _PaymentConfirmationSheet({
    required this.billId,
    required this.participantId,
    required this.participantName,
    required this.billTitle,
    required this.amount,
    required this.onSuccess,
  });

  final String billId;
  final String participantId;
  final String participantName;
  final String billTitle;
  final double amount;
  final VoidCallback onSuccess;

  @override
  ConsumerState<_PaymentConfirmationSheet> createState() =>
      _PaymentConfirmationSheetState();
}

class _PaymentConfirmationSheetState
    extends ConsumerState<_PaymentConfirmationSheet> {
  String? _selectedAccountId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsAsync = ref.watch(accountsProvider);
    final currency = ref.watch(preferencesProvider).activeCurrency;

    return Container(
      padding: const EdgeInsets.all(Space.x6),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            'Confirm QR Payment',
            style: AppType.headlineMedium.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: Space.x1),
          Text(
            'Review transaction details to complete payment.',
            style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: Space.x6),

          // Payment Overview Card
          Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Payment To', value: widget.participantName),
                const Divider(),
                _DetailRow(label: 'Split Expense', value: widget.billTitle),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Payment', style: AppType.titleSmall.copyWith(color: tokens.textPrimary)),
                    MoneyText(
                      widget.amount,
                      style: AppType.numericMedium,
                      color: tokens.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x6),

          // Pay from Account selector
          Text(
            'Pay From Account',
            style: AppType.labelMedium.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: Space.x2),
          accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) {
                return const Text('No accounts available to pay.');
              }
              _selectedAccountId ??= accounts.first.id;

              return DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
                items: accounts
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text('${acc.name} (${acc.maskedNumber})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAccountId = val);
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
          ),
          const SizedBox(height: Space.x8),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await ref
                          .read(splitBillsProvider.notifier)
                          .confirmPayment(
                            billId: widget.billId,
                            participantId: widget.participantId,
                            payingAccountId: _selectedAccountId,
                            currencyCode: currency.code,
                          );

                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Payment of ${currency.symbol}${widget.amount.toStringAsFixed(2)} for ${widget.billTitle} completed successfully!',
                            ),
                          ),
                        );
                        widget.onSuccess();
                      } else {
                        if (mounted) setState(() => _isProcessing = false);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Payment failed. Please try again.')),
                        );
                      }
                    },
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(_isProcessing ? 'Processing...' : 'Confirm & Pay Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                backgroundColor: tokens.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppType.bodySmall.copyWith(color: tokens.textSecondary)),
          Text(value, style: AppType.titleSmall.copyWith(color: tokens.textPrimary)),
        ],
      ),
    );
  }
}
