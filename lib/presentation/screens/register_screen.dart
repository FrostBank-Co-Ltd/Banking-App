import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/repositories.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/surfaces.dart';

/// Account registration screen. Creates a new user profile in Supabase Auth
/// and the profiles database table, with default Philippines mobile formatting (+63).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _email = TextEditingController();
  late final TextEditingController _mobile = TextEditingController();
  late final TextEditingController _password = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Format mobile number to ensure Philippines (+63) format
  String _normalizeMobile(String input) {
    var raw = input.trim();
    if (raw.isEmpty) return '+63 917 847 1928';

    // Remove any non-digit characters except +
    raw = raw.replaceAll(RegExp(r'[^\d+]'), '');

    if (raw.startsWith('+63')) {
      return raw;
    } else if (raw.startsWith('63')) {
      return '+$raw';
    } else if (raw.startsWith('0')) {
      return '+63${raw.substring(1)}';
    } else {
      return '+63$raw';
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final fullName = _name.text.trim();
    final email = _email.text.trim();
    final mobileRaw = _mobile.text.trim();
    final password = _password.text;

    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    final formattedMobile = _normalizeMobile(mobileRaw);

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(sessionProvider.notifier).signUp(
            fullName: fullName,
            email: email,
            mobile: formattedMobile,
            password: password,
          );
    } on RepositoryFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
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
                Space.x6,
                Space.x6,
                Space.x6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/login'),
                        tooltip: 'Back to sign in',
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                      ),
                      const SizedBox(width: Space.x2),
                      const FrostLockup(markSize: 34),
                    ],
                  ),
                  const SizedBox(height: Space.x7),
                  Text(
                    'OPEN AN ACCOUNT',
                    style: AppType.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    'A few details and your FrostBank profile is ready.',
                    style: AppType.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                  const SizedBox(height: Space.x6),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(Space.x4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.white),
                          const SizedBox(width: Space.x3),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppType.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.x4),
                  ],

                  GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FrostFieldLabel('Full name'),
                        FrostField(
                          controller: _name,
                          hint: 'First and last name',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: Space.x5),
                        const FrostFieldLabel('Email'),
                        FrostField(
                          controller: _email,
                          hint: 'name@domain.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: Space.x5),
                        const FrostFieldLabel('Mobile number (Philippines)'),
                        FrostField(
                          controller: _mobile,
                          hint: '+63 9XX XXX XXXX',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                          ],
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Text(
                              '🇵🇭',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.x5),
                        const FrostFieldLabel('Password'),
                        FrostField(
                          controller: _password,
                          hint: 'Choose a password',
                          obscure: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: Space.x6),
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
                                : const Text('Create account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x5),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already with us',
                          style: AppType.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign in'),
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
