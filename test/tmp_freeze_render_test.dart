// Throwaway render harness for the freeze animation.
// Run: flutter test --update-goldens test/tmp_freeze_render_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_bank_app/core/design/theme.dart';
import 'package:mobile_bank_app/data/mock_data_source.dart';
import 'package:mobile_bank_app/presentation/screens/cards_screen.dart';
import 'package:mobile_bank_app/state/providers.dart';

MockDataSource _instantSource() =>
    MockDataSource(now: DateTime(2026, 8, 6))
      ..latencyOverride = (() => Duration.zero);

Future<void> _loadFonts() async {
  const project = {
    'Outfit': 'assets/fonts/Outfit.ttf',
    'Geist': 'assets/fonts/Geist.ttf',
    'GeistMono': 'assets/fonts/GeistMono.ttf',
  };
  for (final entry in project.entries) {
    final bytes = await File(entry.value).readAsBytes();
    await (FontLoader(entry.key)
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }
  final icons = File(
    r'C:\Users\JLB83807\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    final bytes = await icons.readAsBytes();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('freeze the front card', (tester) async {
    tester.view
      ..physicalSize = const ui.Size(1170, 2700)
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

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('tmp_out/freeze_0_before.png'),
    );

    await tester.tap(find.text('Freeze'));
    // Mid transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('tmp_out/freeze_1_mid.png'),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('tmp_out/freeze_2_after.png'),
    );
  });
}
