// Throwaway render harness. Renders the shell over a busy backdrop and over the
// real app background, and writes PNGs so the glass can be looked at.
// Run: flutter test --update-goldens test/tmp_render_shell_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_bank_app/core/design/theme.dart';
import 'package:mobile_bank_app/presentation/shell/app_shell.dart';
import 'package:mobile_bank_app/presentation/shell/branch_transition.dart';

const _paths = ['/', '/activity', '/cards', '/hub', '/profile'];

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

/// Colour, hard edges, and text, so blur, displacement, and tint are obvious.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF7A18),
          Color(0xFFAF002D),
          Color(0xFF3B0DB0),
          Color(0xFF00D4FF),
        ],
        stops: [0, 0.35, 0.7, 1],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontFamily: 'Geist',
          ),
        ),
        // Straight stripes land under the bar, so any bending of the backdrop
        // shows up as a kink in a straight line.
        for (var i = 0; i < 9; i++)
          Container(
            height: 14,
            color: i.isEven ? Colors.white : const Color(0xFF04060B),
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Flat app background with cards running under the bar, which is what the glass
/// actually has to sit on.
class _Realistic extends StatelessWidget {
  const _Realistic();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF07091C),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      children: [
        for (var i = 0; i < 10; i++)
          Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: i == 6 ? const Color(0xFF6A5CFF) : const Color(0xFF1E2347),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Transaction ${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Geist',
              ),
            ),
          ),
      ],
    ),
  );
}

GoRouter _router({bool realistic = false, String at = '/cards'}) => GoRouter(
  initialLocation: at,
  routes: [
    StatefulShellRoute(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      navigatorContainerBuilder: (_, shell, children) => BranchTransition(
        currentIndex: shell.currentIndex,
        children: children,
      ),
      branches: [
        for (final path in _paths)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: path,
                builder: (_, _) =>
                    realistic ? const _Realistic() : _Backdrop(label: path),
              ),
            ],
          ),
      ],
    ),
  ],
);

void main() {
  setUpAll(_loadFonts);

  Future<void> shot(
    WidgetTester tester,
    String name, {
    required ThemeData theme,
    bool realistic = false,
    String at = '/cards',
  }) async {
    tester.view
      ..physicalSize = const ui.Size(1170, 760)
      ..devicePixelRatio = 3
      ..padding = const FakeViewPadding(bottom: 102);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: theme,
        routerConfig: _router(realistic: realistic, at: at),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('tmp_out/$name.png'),
    );
  }

  testWidgets('dark over stripes', (tester) async {
    await shot(tester, 'dark_stripes', theme: AppTheme.dark());
  });

  testWidgets('dark over the app background', (tester) async {
    await shot(
      tester,
      'dark_app',
      theme: AppTheme.dark(),
      realistic: true,
    );
  });

  testWidgets('dark with home selected', (tester) async {
    await shot(
      tester,
      'dark_home',
      theme: AppTheme.dark(),
      realistic: true,
      at: '/',
    );
  });

  testWidgets('light over stripes', (tester) async {
    await shot(tester, 'light_stripes', theme: AppTheme.light());
  });
}
