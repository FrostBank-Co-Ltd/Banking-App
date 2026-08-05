import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/providers.dart';
import '../state/session_controller.dart';
import 'screens/account_detail_screen.dart';
import 'screens/card_detail_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_in_build_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'shell/app_shell.dart';

//for routing to deposit, transfer, and qr
import 'screens/deposit_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/qr_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Declarative routes plus one guard. Branch state, including scroll offset,
/// survives switching between destinations.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;

      const unauthenticated = {'/login', '/register'};

      return switch (session) {
        SessionUnknown() => location == '/splash' ? null : '/splash',
        SessionSignedOut() =>
          unauthenticated.contains(location) ? null : '/login',
        SessionSignedIn() =>
          unauthenticated.contains(location) || location == '/splash'
              ? '/'
              : null,
      };
    },
    errorBuilder: (context, state) =>
        RouteErrorScreen(location: state.uri.toString()),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/account/:id',
        builder: (_, state) =>
            AccountDetailScreen(accountId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/card/:id',
        builder: (_, state) =>
            CardDetailScreen(cardId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/txn/:id',
        builder: (_, state) =>
            TransactionDetailScreen(txnId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/soon/:feature',
        builder: (_, state) =>
            NotInBuildScreen(feature: state.pathParameters['feature']!),
      ),
      GoRoute(
        path: '/deposit',
        builder: (_, state) => const DepositScreen(),
      ),
      GoRoute(
        path: '/transfer',
        builder: (_, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (_, state) => const QRScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (_, _) => const TransactionHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/cards', builder: (_, _) => const CardsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/hub', builder: (_, _) => const HubScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod session changes into the router so the guard re-runs.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen<SessionState>(
      sessionProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }
}
