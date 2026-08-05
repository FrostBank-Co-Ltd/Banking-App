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
                    Pressable(
                      onTap: () => _go(0),
                      semanticLabel: 'Home',
                      borderRadius: AppRadius.pill,
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.all(AppRadius.md),
                              border: Border.all(
                                color: active == 0
                                    ? tokens.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: FrostMark(size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
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
    final color = isActive ? tokens.accent : Colors.white.withValues(alpha: 0.7);

    return Pressable(
      onTap: onTap,
      semanticLabel: '${destination.label}${isActive ? ', selected' : ''}',
      borderRadius: AppRadius.pill,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(destination.icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: AppType.labelSmall.copyWith(color: color, fontSize: 9.5),
              maxLines: 1,
            ),
            const SizedBox(height: 3),
            // Hierarchy: the accent bar marks the destination in view.
            AnimatedContainer(
              duration: Motion.resolve(context, Motion.short),
              curve: Motion.standard,
              height: 2,
              width: isActive ? 16 : 0,
              decoration: BoxDecoration(
                color: tokens.accent,
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
