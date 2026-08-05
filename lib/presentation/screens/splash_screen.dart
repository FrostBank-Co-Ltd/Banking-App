import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../state/providers.dart';
import '../widgets/brand.dart';
import '../widgets/surfaces.dart';

/// Launch screen. Resolves the session, then the router guard moves on.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    // Feedback: the only repeating animation in the application, and it stops
    // the moment session resolution completes.
    _loader = AnimationController(vsync: this, duration: Motion.long)..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final controller = ref.read(sessionProvider.notifier);
    await Future.wait([
      controller.restore(),
      // Hold the brand moment briefly, and never beyond the 2 second cap.
      Future<void>.delayed(const Duration(milliseconds: 750)),
    ]).timeout(
      const Duration(milliseconds: 2000),
      onTimeout: () => const <void>[],
    );
    if (!mounted) return;
    _loader.stop();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      body: FrostBackdrop(
        glow: 0.4,
        child: SafeArea(
          child: ResponsiveShell(
            child: Padding(
              padding: const EdgeInsets.all(Space.x6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const FrostMark(size: 88),
                  const SizedBox(height: Space.x5),
                  Text(
                    'FrostBank',
                    style: AppType.displayMedium.copyWith(
                      color: tokens.textOnBrand,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: Space.x2),
                  Text(
                    'Everyday banking, clearly presented.',
                    style: AppType.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 180,
                    child: AnimatedBuilder(
                      animation: _loader,
                      builder: (context, _) => ClipRRect(
                        borderRadius: AppRadius.all(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: Motion.isReduced(context)
                              ? 0.6
                              : _loader.value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.24),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.textOnBrand,
                          ),
                          semanticsLabel: 'Preparing your session',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.x8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
