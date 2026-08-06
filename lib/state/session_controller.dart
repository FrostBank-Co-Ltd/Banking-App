import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/repositories.dart';
import 'providers.dart';

/// Authentication state. `unknown` is the launch state while the splash screen
/// resolves the session.
sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.notice});

  /// Set when a restore attempt failed, so login can explain why.
  final String? notice;
}

class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.profile);

  final UserProfile profile;
}

/// Owns sign in, sign out, and session restore.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionUnknown();

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  void _invalidateUserData() {
    ref.invalidate(profileProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(cardsProvider);
    ref.invalidate(goalsProvider);
    ref.invalidate(selectedAccountIdProvider);
  }

  /// Called once by the splash screen.
  Future<void> restore() async {
    try {
      final profile = await _auth.restoreSession();
      state = profile == null
          ? const SessionSignedOut()
          : SessionSignedIn(profile);
      _invalidateUserData();
    } on Object {
      state = const SessionSignedOut(
        notice: 'We could not restore your session. Please sign in again.',
      );
      _invalidateUserData();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final profile = await _auth.signIn(email: email, password: password);
    state = SessionSignedIn(profile);
    _invalidateUserData();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final profile = await _auth.signUp(
      fullName: fullName,
      email: email,
      mobile: mobile,
      password: password,
    );
    state = SessionSignedIn(profile);
    _invalidateUserData();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    ref.read(preferencesProvider.notifier).clearRememberedEmail();
    state = const SessionSignedOut();
    _invalidateUserData();
  }
}
