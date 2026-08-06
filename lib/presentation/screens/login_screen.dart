import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/pressable.dart';
import '../widgets/surfaces.dart';

/// Demo sign in with Password & 4-Digit PIN Authentication support.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _email = TextEditingController(text: 'ava.mercado@northmark.app');
  late final TextEditingController _password = TextEditingController(text: 'password123');
  late final TextEditingController _pin = TextEditingController(text: '1234');

  bool _obscure = true;
  bool _usePin = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_usePin) {
      final pinText = _pin.text.trim();
      if (pinText.length < 4) {
        setState(() {
          _errorMessage = 'Please enter a valid 4-digit security PIN.';
        });
        return;
      }
    } else {
      final emailText = _email.text.trim();
      final passwordText = _password.text;

      if (emailText.isEmpty || passwordText.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your email and password.';
        });
        return;
      }
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final emailText = _usePin ? 'ava.mercado@northmark.app' : _email.text.trim();
      final passwordText = _usePin ? 'password123' : _password.text;

      await ref
          .read(sessionProvider.notifier)
          .signIn(email: emailText, password: passwordText);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FrostBackdrop(
        child: SafeArea(
          child: ResponsiveShell(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Space.x6,
                Space.x8,
                Space.x6,
                Space.x6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FrostLockup(markSize: 44),
                  const SizedBox(height: Space.x10),
                  Text(
                    'WELCOME BACK',
                    style: AppType.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    'Sign in to see balances, cards, and activity.',
                    style: AppType.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: Space.x6),

                  // Mode Switcher: Password vs PIN
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: AppRadius.all(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Pressable(
                            onTap: () => setState(() => _usePin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: Space.x2),
                              decoration: BoxDecoration(
                                color: !_usePin ? Colors.white : Colors.transparent,
                                borderRadius: AppRadius.all(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Password',
                                style: AppType.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: !_usePin ? Palette.frostBaseTop : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Pressable(
                            onTap: () => setState(() => _usePin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: Space.x2),
                              decoration: BoxDecoration(
                                color: _usePin ? Colors.white : Colors.transparent,
                                borderRadius: AppRadius.all(AppRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pin_rounded,
                                    size: 16,
                                    color: _usePin ? Palette.frostBaseTop : Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Security PIN',
                                    style: AppType.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _usePin ? Palette.frostBaseTop : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Space.x5),

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(Space.x3),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: Space.x2),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppType.bodySmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Space.x4),
                        ],

                        if (_usePin) ...[
                          const FrostFieldLabel('4-Digit Security PIN'),
                          FrostField(
                            controller: _pin,
                            hint: '••••',
                            obscure: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: Space.x2),
                        ] else ...[
                          const FrostFieldLabel('Email'),
                          FrostField(
                            controller: _email,
                            hint: 'name@domain.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: Space.x5),
                          const FrostFieldLabel('Password'),
                          FrostField(
                            controller: _password,
                            hint: 'Your password',
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.x2),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/soon/password-reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: Palette.frostIcePale,
                              ),
                              child: const Text('Forgot password'),
                            ),
                          ),
                        ],

                        const SizedBox(height: Space.x3),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Palette.frostBaseTop,
                              disabledBackgroundColor: Colors.white.withValues(
                                alpha: 0.7,
                              ),
                              disabledForegroundColor: Palette.frostBaseTop,
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Palette.frostBaseTop,
                                    ),
                                  )
                                : Text(_usePin ? 'Sign in with PIN' : 'Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x6),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'New to FrostBank',
                          style: AppType.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
