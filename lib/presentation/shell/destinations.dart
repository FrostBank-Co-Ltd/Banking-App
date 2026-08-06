import 'package:flutter/material.dart';

/// One destination in the shell, bound to its branch index in the router.
@immutable
class ShellDestination {
  const ShellDestination({
    required this.branch,
    required this.icon,
    required this.label,
  });

  /// Index of the matching `StatefulShellBranch` in the router.
  final int branch;

  final IconData icon;
  final String label;
}

/// The five shell destinations, in the order they read across the bar.
///
/// Branch order in the router and slot order on screen are not the same thing:
/// the dashboard is branch zero but sits in the middle slot, so the brand mark
/// anchors the centre of the pane. Both the travel of the selection capsule and
/// the direction of the branch transition are read from the slot, because that
/// is the order the eye sees.
abstract final class ShellDestinations {
  static const List<ShellDestination> ordered = [
    ShellDestination(
      branch: 1,
      icon: Icons.receipt_long_rounded,
      label: 'Activity',
    ),
    ShellDestination(
      branch: 2,
      icon: Icons.credit_card_rounded,
      label: 'Cards',
    ),
    ShellDestination(branch: 0, icon: Icons.home_rounded, label: 'Home'),
    ShellDestination(branch: 3, icon: Icons.pie_chart_rounded, label: 'Hub'),
    ShellDestination(branch: 4, icon: Icons.person_rounded, label: 'Profile'),
  ];

  static const int count = 5;

  /// Slot [branch] occupies, left to right.
  static int slotOf(int branch) {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].branch == branch) return i;
    }
    return 0;
  }
}
