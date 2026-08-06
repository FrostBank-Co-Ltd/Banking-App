// Throwaway reproduction for "freezing the card in the display freezes the other
// card". Run: flutter test test/tmp_freeze_bug_test.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/core/design/theme.dart';
import 'package:mobile_bank_app/data/mock_data_source.dart';
import 'package:mobile_bank_app/domain/models.dart';
import 'package:mobile_bank_app/presentation/screens/cards_screen.dart';
import 'package:mobile_bank_app/state/providers.dart';

MockDataSource _instantSource() =>
    MockDataSource(now: DateTime(2026, 8, 6))
      ..latencyOverride = (() => Duration.zero);

void main() {
  testWidgets('freezing the card in front does not touch its neighbour', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const ui.Size(1170, 2200)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      retry: noAutomaticRetry,
      overrides: [mockDataSourceProvider.overrideWithValue(_instantSource())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const CardsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    Future<List<BankCard>> read() => container.read(cardsProvider.future);

    var rows = await read();
    expect(rows[0].id, 'card_visa');
    expect(rows[0].status, CardStatus.active);
    expect(rows[1].id, 'card_mc');
    expect(rows[1].status, CardStatus.frozen);

    // The card in front is the first one, so the deck labels it and offers to
    // freeze it.
    expect(find.text('FrostBank Signature'), findsOneWidget);
    expect(find.text('Freeze'), findsOneWidget);

    // Swipe to the second card.
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    // What the deck now says it is showing.
    debugPrint('--- after swipe ---');
    debugPrint('label shown: Horizon Everyday? '
        '${find.text('Horizon Everyday').evaluate().isNotEmpty}');
    debugPrint('button says Unfreeze? '
        '${find.text('Unfreeze').evaluate().isNotEmpty}');
    debugPrint('button says Freeze? '
        '${find.text('Freeze').evaluate().isNotEmpty}');

    expect(
      find.text('Horizon Everyday'),
      findsOneWidget,
      reason: 'the deck should describe the card that is now in front',
    );

    // Act on whichever control the deck is offering.
    final unfreeze = find.text('Unfreeze');
    await tester.tap(unfreeze.evaluate().isEmpty ? find.text('Freeze') : unfreeze);
    await tester.pumpAndSettle();

    rows = await read();
    debugPrint('--- after tap ---');
    for (final card in rows) {
      debugPrint('${card.id} -> ${card.status}');
    }

    expect(
      rows.firstWhere((c) => c.id == 'card_visa').status,
      CardStatus.active,
      reason: 'the untouched neighbour must keep its status',
    );
    expect(
      rows.firstWhere((c) => c.id == 'card_mc').status,
      CardStatus.active,
      reason: 'the card in front was frozen, so it should now be active',
    );
  });
}
