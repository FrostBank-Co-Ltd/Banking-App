import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../widgets/brand.dart';
import '../widgets/pressable.dart';

/// Floating pill navigation with four peripheral destinations and the brand
/// mark in the centre.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<_Destination> _peripheral = [
    _Destination(branch: 1, icon: Icons.receipt_long_rounded, label: 'Activity'),
    _Destination(branch: 2, icon: Icons.credit_card_rounded, label: 'Cards'),
    _Destination(branch: 3, icon: Icons.pie_chart_rounded, label: 'Hub'),
    _Destination(branch: 4, icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _go(int branch) => navigationShell.goBranch(
    branch,
    // Selecting the active destination returns that branch to its first route.
    initialLocation: branch == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final active = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: tokens.backgroundAlt,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: Space.x4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.x5),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: tokens.isDark
                      ? tokens.surfaceRaised
                      : Palette.deepNavy,
                  borderRadius: AppRadius.all(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Palette.deepNavy.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      destination: _peripheral[0],
                      isActive: active == _peripheral[0].branch,
                      onTap: () => _go(_peripheral[0].branch),
                    ),
                    _NavItem(
                      destination: _peripheral[1],
                      isActive: active == _peripheral[1].branch,
                      onTap: () => _go(_peripheral[1].branch),
                    ),
                    _HomeMark(isActive: active == 0, onTap: () => _go(0)),
                    _NavItem(
                      destination: _peripheral[2],
                      isActive: active == _peripheral[2].branch,
                      onTap: () => _go(_peripheral[2].branch),
                    ),
                    _NavItem(
                      destination: _peripheral[3],
                      isActive: active == _peripheral[3].branch,
                      onTap: () => _go(_peripheral[3].branch),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.branch,
    required this.icon,
    required this.label,
  });

  final int branch;
  final IconData icon;
  final String label;
}

/// The brand mark in the centre of the pill. Lifts and picks up a ring when the
/// home branch is the one in view.
class _HomeMark extends StatelessWidget {
  const _HomeMark({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Pressable(
      onTap: onTap,
      semanticLabel: 'Home${isActive ? ', selected' : ''}',
      borderRadius: AppRadius.pill,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: isActive ? 1 : 0),
            duration: Motion.resolve(context, Motion.medium),
            curve: Motion.emphasized,
            builder: (context, t, child) => Transform.scale(
              scale: 1 + 0.06 * t,
              child: Transform.translate(
                offset: Offset(0, Motion.amount(context, -2) * t),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.all(AppRadius.md),
                    border: Border.all(
                      color: tokens.accent.withValues(alpha: t),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.accent.withValues(alpha: 0.45 * t),
                        blurRadius: 16 * t,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: FrostMark(size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  final _Destination destination;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resting = Colors.white.withValues(alpha: 0.7);

    return Pressable(
      onTap: onTap,
      semanticLabel: '${destination.label}${isActive ? ', selected' : ''}',
      borderRadius: AppRadius.pill,
      // Selection is a single driver, so the tint, the lift, the icon size, and
      // the accent bar all resolve on one timeline instead of drifting apart.
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isActive ? 1 : 0),
        duration: Motion.resolve(context, Motion.medium),
        curve: Motion.emphasized,
        builder: (context, t, _) {
          final color = Color.lerp(resting, tokens.accent, t)!;
          return SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hierarchy: a soft wash sets the destination in view apart
                // before colour is read.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: 0.14 * t),
                      borderRadius: AppRadius.all(AppRadius.pill),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, Motion.amount(context, -1.5) * t),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(destination.icon, size: 20 + 2 * t, color: color),
                      const SizedBox(height: 3),
                      Text(
                        destination.label,
                        style: AppType.labelSmall.copyWith(
                          color: color,
                          fontSize: 9.5,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      // Hierarchy: the accent bar marks the destination in view.
                      Container(
                        height: 2,
                        width: 16 * t,
                        decoration: BoxDecoration(
                          color: tokens.accent,
                          borderRadius: AppRadius.all(AppRadius.pill),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
