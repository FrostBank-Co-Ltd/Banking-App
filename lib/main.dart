import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/theme.dart';
import 'presentation/router.dart';
import 'state/providers.dart';

void main() {
  runApp(
    const ProviderScope(retry: noAutomaticRetry, child: FrostBankApp()),
  );
}

class FrostBankApp extends ConsumerWidget {
  const FrostBankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final preferences = ref.watch(preferencesProvider);

    return MaterialApp.router(
      title: 'FrostBank',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences.themeMode,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // Keeps very large system scales from breaking layouts while still
        // honouring the user's preference up to 1.4.
        maxScaleFactor: 1.4,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
