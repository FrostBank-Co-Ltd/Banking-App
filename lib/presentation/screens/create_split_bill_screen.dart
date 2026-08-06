import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/providers.dart';
import '../../state/split_bills_controller.dart';
import '../widgets/brand.dart';
import '../widgets/money_text.dart';
import '../widgets/surfaces.dart';

/// Screen for creating a new split bill expense with multiple participants.
class CreateSplitBillScreen extends ConsumerStatefulWidget {
  const CreateSplitBillScreen({super.key});

  @override
  ConsumerState<CreateSplitBillScreen> createState() =>
      _CreateSplitBillScreenState();
}

class _CreateSplitBillScreenState extends ConsumerState<CreateSplitBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _participantController = TextEditingController();

  String _selectedCategory = 'Food & Dining';
  final List<String> _categories = const [
    'Food & Dining',
    'Travel & Lodging',
    'Entertainment',
    'Utilities',
    'Shopping',
    'Other',
  ];

  final List<String> _participants = [];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isEmpty) return;

    if (name.toLowerCase() == 'you' || name.toLowerCase() == 'you (host)') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already included as the host.')),
      );
      _participantController.clear();
      return;
    }

    if (_participants.any((p) => p.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participant already added.')),
      );
      _participantController.clear();
      return;
    }

    setState(() {
      _participants.add(name);
      _participantController.clear();
    });
  }

  void _removeParticipant(int index) {
    if (index >= 0 && index < _participants.length) {
      setState(() {
        _participants.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final rawAmount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (rawAmount <= 0 || rawAmount.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one participant to split the bill with.'),
        ),
      );
      return;
    }

    final cleanTitle = _titleController.text.trim();
    if (cleanTitle.isEmpty) return;

    final success = await ref.read(splitBillsProvider.notifier).createBill(
          title: cleanTitle,
          totalAmount: rawAmount,
          category: _selectedCategory,
          participantNames: List<String>.from(_participants),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Split bill created successfully!')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/split-bills');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create bill. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final prefs = ref.watch(preferencesProvider);
    final currency = prefs.activeCurrency;

    final rawAmount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final amount = (rawAmount.isNegative || rawAmount.isNaN) ? 0.0 : rawAmount;
    final totalPeople = _participants.length + 1; // Host + participants
    final equalShare =
        (totalPeople > 0 && amount > 0) ? (amount / totalPeople) : 0.0;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text('Create Split Bill'),
        backgroundColor: tokens.background,
      ),
      body: ResponsiveShell(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.x5,
              Space.x2,
              Space.x5,
              Space.x16,
            ),
            children: [
              // Title Input
              Text(
                'Expense Title',
                style: AppType.labelMedium.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: Space.x2),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Team Dinner, Flight Tickets',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: Space.x4),

              // Amount Input
              Text(
                'Total Amount (${currency.symbol})',
                style: AppType.labelMedium.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: Space.x2),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: '${currency.symbol} ',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(val.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: Space.x4),

              // Category Picker
              Text(
                'Category',
                style: AppType.labelMedium.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: Space.x2),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: Space.x6),

              // Participants Section
              Text(
                'Participants',
                style: AppType.titleSmall.copyWith(color: tokens.textPrimary),
              ),
              const SizedBox(height: Space.x1),
              Text(
                'Add people to split this bill equally with.',
                style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
              ),
              const SizedBox(height: Space.x3),

              // Add Participant Input
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _participantController,
                      decoration: const InputDecoration(
                        hintText: 'Participant Name',
                        prefixIcon: Icon(Icons.person_add_rounded),
                      ),
                      onSubmitted: (_) => _addParticipant(),
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  ElevatedButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.x4),

              // Participant list cards
              Container(
                decoration: BoxDecoration(
                  color: tokens.surfaceRaised,
                  borderRadius: AppRadius.all(AppRadius.lg),
                  border: Border.all(color: tokens.border),
                ),
                child: Column(
                  children: [
                    // Host row (fixed)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tokens.interactivePrimary,
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: const Text('You (Host)'),
                      subtitle: const Text('Creator • Auto-paid share'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(equalShare, style: AppType.numericSmall),
                          Text(
                            'Paid',
                            style: TextStyle(
                              color: tokens.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_participants.isNotEmpty) const Divider(height: 1),

                    for (var i = 0; i < _participants.length; i++) ...[
                      ListTile(
                        key: ValueKey('participant_${_participants[i]}_$i'),
                        leading: CircleAvatar(
                          backgroundColor: tokens.interactiveSecondary,
                          child: Text(
                            _participants[i].trim().isNotEmpty
                                ? _participants[i].trim()[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: tokens.accent),
                          ),
                        ),
                        title: Text(_participants[i]),
                        subtitle: const Text('Pending Payment'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoneyText(equalShare, style: AppType.numericSmall),
                            const SizedBox(width: Space.x2),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => _removeParticipant(i),
                            ),
                          ],
                        ),
                      ),
                      if (i < _participants.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.x6),

              // Summary Banner
              FrostBackdrop(
                borderRadius: AppRadius.all(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.all(Space.x4),
                  child: Row(
                    children: [
                      const Icon(Icons.pie_chart_rounded, color: Colors.white),
                      const SizedBox(width: Space.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Equal Split Summary',
                              style: AppType.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Total of $totalPeople people ($totalPeople-way split)',
                              style: AppType.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.76),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(
                            equalShare,
                            style: AppType.numericMedium,
                            color: Colors.white,
                          ),
                          Text(
                            'per person',
                            style: AppType.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.76),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.x8),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Create Split Bill'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: tokens.interactivePrimary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
