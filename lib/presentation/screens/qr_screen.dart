// screens/qr_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; 
import '../../domain/models.dart'; 
import '../../domain/repositories.dart'; 
import '../../state/providers.dart'; 

class QRScreen extends ConsumerStatefulWidget {
  const QRScreen({super.key});

  @override
  ConsumerState<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends ConsumerState<QRScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountInputController = TextEditingController();
  String _generatedQRText = '';
  bool _isProcessingQR = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountInputController.dispose();
    super.dispose();
  }

  // Helper formatting for 2 decimal places and comma separation
  void _updateGeneratedQR() {
    final rawVal = double.tryParse(_amountInputController.text) ?? 0.0;
    setState(() {
      _generatedQRText = 'PHP ${rawVal.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    });
  }

  void _onQRScanned(String qrData) {
    if (_isProcessingQR) return;
    setState(() => _isProcessingQR = true);
    
    // Step A: Fetch accounts and show source selector
    final accounts = ref.read(accountsProvider).value ?? [];
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No accounts available.')));
      setState(() => _isProcessingQR = false);
      return;
    }

    Account selectedAccount = accounts.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('QR Detected'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scanned Data: $qrData', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Select source of funds for this payment:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Account>(
                value: selectedAccount,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (val) => setModalState(() => selectedAccount = val!),
              ),
              const SizedBox(height: 16),
              const Text('A default of ₱100.00 will be deducted for this hackathon POC.', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isProcessingQR = false); // Reset scanner
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F0D96)),
              onPressed: () {
                Navigator.pop(ctx);
                _executeQRPayment(selectedAccount);
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeQRPayment(Account sourceAccount) async {
    const double qrAmount = 100.0;
    
    if (sourceAccount.availableBalance < qrAmount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient funds for ₱100.00 deduction.')));
      setState(() => _isProcessingQR = false);
      return;
    }

    try {
      // Assuming you have a transfer/withdraw method in your repo. Reusing transfer to a dummy merchant.
      await ref.read(accountRepositoryProvider).transfer(
        fromAccountId: sourceAccount.id,
        recipient: 'QR Merchant POC',
        amount: qrAmount,
        note: 'QR Scan Payment',
      );
      
      ref.invalidate(accountsProvider);
      
      if (mounted) {
        _showSuccessBottomSheet(sourceAccount.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Payment failed: $e')));
      setState(() => _isProcessingQR = false);
    }
  }

  void _showSuccessBottomSheet(String accountName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Color(0xFF5F0D96), size: 60),
            const SizedBox(height: 16),
            const Text('Payment Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('₱100.00 has been successfully deducted from $accountName.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F0D96)),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Exit QR Screen
                },
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Payments'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F0D96),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5F0D96),
          indicatorColor: const Color(0xFF5F0D96),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
            Tab(icon: Icon(Icons.qr_code, color: Color(0xFF5F0D96)), text: 'My QR Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // SCAN TAB
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF5F0D96), width: 3),
                    ),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _onQRScanned(barcode.rawValue!);
                            break; // Stop after first successful read
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Point your camera at a merchant QR code. It will detect automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // MY QR TAB (Generator)
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Enter target amount to receive:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountInputController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _updateGeneratedQR(),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                if (_generatedQRText.isNotEmpty && _generatedQRText != 'PHP 0.00') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: QrImageView(
                      data: _generatedQRText,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF5F0D96),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Payload: $_generatedQRText', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5F0D96))),
                ] else ...[
                  const Text('Input an amount above to generate your payment QR string.', style: TextStyle(color: Colors.grey)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}