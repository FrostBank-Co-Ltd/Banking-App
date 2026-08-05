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

  /// Called once by the splash screen.
  Future<void> restore() async {
    try {
      final profile = await _auth.restoreSession();
      state = profile == null
          ? const SessionSignedOut()
          : SessionSignedIn(profile);
    } on Object {
      state = const SessionSignedOut(
        notice: 'We could not restore your session. Please sign in again.',
      );
    }
  }

  /// Demo sign in. Nothing is validated in this build, so any entry opens the
  /// seeded profile.
  Future<void> signIn({required String email, required String password}) async {
    final profile = await _auth.signIn(email: email, password: password);
    state = SessionSignedIn(profile);
  }

  /// Demo sign up. Carries the entered details into the seeded profile.
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
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = const SessionSignedOut();
  }
}
