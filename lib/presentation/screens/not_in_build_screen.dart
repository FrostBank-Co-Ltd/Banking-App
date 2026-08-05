import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../widgets/surfaces.dart';

/// Named notice for a capability that lands in a later slice, so no control on
/// a finished screen is a dead end.
class NotInBuildScreen extends StatelessWidget {
  const NotInBuildScreen({required this.feature, super.key});

  final String feature;

  static const Map<String, String> _titles = {
    'deposit': 'Deposit',
    'send-money': 'Send money',
    'transfer': 'Transfer',
    'qr-payment': 'QR payment',
    'savings': 'Savings goals',
    'crypto': 'Crypto',
    'split-bills': 'Split Bills',
    'time-deposit': 'Time Deposit',
    'notifications': 'Notifications',
    'new-card': 'Add card',
    'card-freeze': 'Freeze card',
    'card-limit': 'Spending limit',
    'registration': 'Create account',
    'change-pin': 'Change PIN',
    'biometrics': 'Biometric unlock',
    'session-timeout': 'Session timeout',
    'edit-profile': 'Edit details',
    'language': 'Language',
    'currency': 'Currency display',
    'about': 'About this build',
    'offers': 'Offers',
    'receipts': 'Share receipt',
    'new-account': 'Open account',
    'buy-crypto': 'Buy crypto',
    'sell-crypto': 'Sell crypto',
    'send-crypto': 'Send crypto',
  };

  String get _title => _titles[feature] ?? 'This screen';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: ResponsiveShell(
        child: Padding(
          padding: const EdgeInsets.all(Space.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: tokens.interactiveSecondary,
                  borderRadius: AppRadius.all(AppRadius.pill),
                ),
                child: Icon(Icons.construction_rounded, color: tokens.accent),
              ),
              const SizedBox(height: Space.x5),
              Text(
                '$_title is not in this build',
                style: AppType.headlineMedium.copyWith(
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.x3),
              Text(
                'This build covers balances, cards, and transaction history. Money movement lands in the next slice.',
                style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.x6),
              FilledButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a requested route does not exist.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      body: ResponsiveShell(
        child: Padding(
          padding: const EdgeInsets.all(Space.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wrong_location_rounded,
                size: 40,
                color: tokens.textSecondary,
              ),
              const SizedBox(height: Space.x4),
              Text(
                'We could not find that screen',
                style: AppType.headlineMedium.copyWith(
                  color: tokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.x2),
              Text(
                location,
                style: AppType.bodySmall.copyWith(color: tokens.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Space.x6),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
