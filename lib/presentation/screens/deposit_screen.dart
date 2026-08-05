import 'package:flutter/material.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  String _selectedAccount = 'Primary Wallet';
  final List<String> _accounts = ['Primary Wallet', 'High-Yield Savings', 'Crypto Vault'];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Funds'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deposit to',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAccount,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _accounts.map((String account) {
                return DropdownMenuItem(
                  value: account,
                  child: Text(account, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) setState(() => _selectedAccount = newValue);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₱ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement state management / backend logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deposited ₱${_amountController.text} to $_selectedAccount')),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F0D96),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm Deposit', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}