import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/core/design/theme.dart';
import 'package:mobile_bank_app/presentation/widgets/opening_ad_modal.dart';
import 'package:mobile_bank_app/state/providers.dart';

class _FakeRandom implements Random {
  _FakeRandom(this.fixedValue);

  final double fixedValue;

  @override
  double nextDouble() => fixedValue;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

Widget _harness(Widget child, {bool isDark = false}) => ProviderScope(
      child: MaterialApp(
        theme: isDark ? AppTheme.dark() : AppTheme.light(),
        home: child,
      ),
    );

void main() {
  test('selectRandomAdAsset selects ad_uma.webp on low roll (< 0.10)', () {
    final rng = _FakeRandom(0.05);
    final selected = selectRandomAdAsset(rng: rng);
    expect(selected, equals('assets/images/ad_uma.webp'));
  });

  test('selectRandomAdAsset selects standard ad on normal roll (>= 0.10)', () {
    final rng = _FakeRandom(0.50);
    final selected = selectRandomAdAsset(rng: rng);
    expect(selected, equals('assets/images/ad_light.png'));
  });

  testWidgets('OpeningAdModal renders Light Mode ad asset correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(
      OpeningAdModal(
        onDismiss: () {},
        assetPath: 'assets/images/ad_light.png',
      ),
      isDark: false,
    ));
    await tester.pumpAndSettle();

    expect(find.text('FrostBank'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Experience Smarter Banking'), findsOneWidget);
  });

  testWidgets('OpeningAdModal renders Dark Mode ad asset correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(
      OpeningAdModal(
        onDismiss: () {},
        assetPath: 'assets/images/ad_dark.png',
      ),
      isDark: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('FrostBank'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get Started Now'), findsOneWidget);
  });

  testWidgets('OpeningAdModal renders ad_uma.webp rare asset correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(
      OpeningAdModal(
        onDismiss: () {},
        assetPath: 'assets/images/ad_uma.webp',
      ),
      isDark: true,
    ));
    await tester.pumpAndSettle();

    expect(find.text('FrostBank'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get Started Now'), findsOneWidget);
  });

  testWidgets('Tapping Skip fires onDismiss callback and updates state', (
    tester,
  ) async {
    late ProviderContainer container;

    final widget = UncontrolledProviderScope(
      container: container = ProviderContainer(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              container.read(openingAdDismissedProvider.notifier).dismiss();
            },
            child: const Text('Dismiss Ad'),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(container.read(openingAdDismissedProvider), isFalse);

    await tester.tap(find.text('Dismiss Ad'));
    await tester.pumpAndSettle();

    expect(container.read(openingAdDismissedProvider), isTrue);
  });
}
