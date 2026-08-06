import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../state/providers.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  String? _selectedAccountId;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(Account account) async {
    if (_submitting) return;

    final amountText = _amountController.text.trim();
    final inputAmount = double.tryParse(amountText);
    
    if (inputAmount == null || inputAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid deposit amount.');
      return;
    }

    // Step 1: Generate Reference Code and show Receipt instead of depositing immediately
    final refCode = 'DEP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deposit Receipt (POC)', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${account.name}'),
            const SizedBox(height: 8),
            Text('Inputted Amount: ₱${inputAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Reference Code: $refCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 24),
            const Text(
              'To complete this deposit in the real world, input this reference code at a cash machine. \n\nFor this POC, closing this dialog will simulate a machine deposit and add a default of ₱100.00 to your account.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F0D96)),
              onPressed: () async {
                Navigator.pop(ctx); // Close receipt
                await _executeDefaultDeposit(account); // Process the actual 100 PHP
              },
              child: const Text('Close & Deposit ₱100.00', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: The actual Riverpod logic forcing the 100 PHP deposit
  Future<void> _executeDefaultDeposit(Account account) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      const double hackathonDefaultAmount = 100.0; // Forced rule
      await ref.read(accountRepositoryProvider).deposit(
            accountId: account.id,
            amount: hackathonDefaultAmount,
          );

      ref.invalidate(accountsProvider);
      ref.invalidate(accountProvider(account.id));
      ref.invalidate(transactionsProvider);
      
      if (mounted) {
        Navigator.pop(context); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulated machine deposit of ₱100.00 to ${account.name} successful!')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Deposit failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Funds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('No accounts available.'));
          }

          _selectedAccountId ??= accounts.first.id;
          final selectedAccount = accounts.firstWhere(
            (a) => a.id == _selectedAccountId,
            orElse: () => accounts.first,
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Deposit to',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: accounts.map((Account account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(
                        '${account.name} (${account.maskedNumber})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedAccountId = newValue);
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${selectedAccount.currencyCode} \$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(selectedAccount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F0D96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirm Deposit',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load accounts: $err')),
      ),
    );
  }
}