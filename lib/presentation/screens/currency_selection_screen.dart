import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/preferences_controller.dart';
import '../../state/providers.dart';
import '../widgets/pressable.dart';
import '../widgets/surfaces.dart';

/// Screen allowing the user to select and save their preferred currency display.
class CurrencySelectionScreen extends ConsumerStatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  ConsumerState<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState
    extends ConsumerState<CurrencySelectionScreen> {
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(preferencesProvider).currencyCode;
  }

  void _saveCurrency() {
    final codeToSave = _selectedCode ?? 'USD';
    ref.read(preferencesProvider.notifier).setCurrencyCode(codeToSave);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Currency preference updated to $codeToSave!'),
        duration: const Duration(seconds: 2),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final activeCode = _selectedCode ?? ref.watch(preferencesProvider).currencyCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Display'),
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
            Text(
              'Select your preferred currency display. Tap "Save Currency" below to apply changes across account balances, transactions, and split bills.',
              style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: Space.x6),
            Container(
              decoration: BoxDecoration(
                color: tokens.surfaceRaised,
                borderRadius: AppRadius.all(AppRadius.lg),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < supportedCurrencies.length; i++) ...[
                    _CurrencyRow(
                      option: supportedCurrencies[i],
                      isSelected: activeCode == supportedCurrencies[i].code,
                      onTap: () {
                        setState(() {
                          _selectedCode = supportedCurrencies[i].code;
                        });
                      },
                    ),
                    if (i < supportedCurrencies.length - 1)
                      Divider(
                        height: 1,
                        color: tokens.border,
                        indent: Space.x4,
                        endIndent: Space.x4,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.x8),

            // Save Currency Button
            FilledButton.icon(
              onPressed: _saveCurrency,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text('Save Currency'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Space.x4),
                backgroundColor: tokens.interactivePrimary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CurrencyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${option.name}, ${option.code}, ${isSelected ? 'selected' : 'not selected'}',
      borderRadius: AppRadius.lg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? tokens.interactivePrimary
                    : tokens.interactiveSecondary,
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
              child: Center(
                child: Text(
                  option.symbol,
                  style: AppType.titleMedium.copyWith(
                    color: isSelected ? Colors.white : tokens.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Space.x4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: AppType.titleSmall.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  Text(
                    '${option.code} (${option.symbol})',
                    style: AppType.bodySmall.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: tokens.accent,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: tokens.border,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
