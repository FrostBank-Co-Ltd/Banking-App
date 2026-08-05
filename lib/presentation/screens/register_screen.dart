import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../data/mock_seed.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/surfaces.dart';

/// Demo sign up. Carries the entered name, email, and mobile into the seeded
/// profile, then opens the dashboard. Nothing is validated in this build.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _name = TextEditingController(
    text: MockSeed.demoName,
  );
  late final TextEditingController _email = TextEditingController(
    text: MockSeed.demoEmail,
  );
  late final TextEditingController _mobile = TextEditingController(
    text: MockSeed.demoMobile,
  );
  late final TextEditingController _password = TextEditingController(
    text: MockSeed.demoPassword,
  );

  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref.read(sessionProvider.notifier).signUp(
      fullName: _name.text,
      email: _email.text,
      mobile: _mobile.text,
    );
    if (mounted) setState(() => _submitting = false);
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
                        const FrostFieldLabel('Mobile number'),
                        FrostField(
                          controller: _mobile,
                          hint: '+1 (555) 000-0000',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.telephoneNumber,
                          ],
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
