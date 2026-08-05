// screens/qr_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRScreen extends ConsumerStatefulWidget {
  const QRScreen({super.key});

  @override
  ConsumerState<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends ConsumerState<QRScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountInputController = TextEditingController();
  String _generatedQRText = '';

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

  void _simulateScanAuth() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm QR Payment'),
        content: const Text('Random merchant QR detected. Authorize deduction of ₱100.00?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5F0D96)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('₱100.00 successfully deducted via QR scan!')),
              );
            },
            child: const Text('Authorize', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                GestureDetector(
                  onTap: _simulateScanAuth, // Triggers simulated camera scan action item
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF5F0D96), width: 3),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 56, color: Color(0xFF5F0D96)),
                        SizedBox(height: 12),
                        Text('Tap here to simulate scan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Point camera at merchant QR code to process auto-payment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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