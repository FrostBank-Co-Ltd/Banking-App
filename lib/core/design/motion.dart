import 'package:flutter/material.dart';

/// The single motion system.
///
/// Three duration bands, three curves, and only opacity, translation, scale,
/// and rotation are ever animated.
abstract final class Motion {
  /// Press and state feedback.
  static const Duration short = Duration(milliseconds: 180);

  /// Screen and section transitions.
  static const Duration medium = Duration(milliseconds: 300);

  /// Reserved for the splash sequence.
  static const Duration long = Duration(milliseconds: 600);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve linear = Curves.linear;

  /// True when the platform asks for less animation.
  static bool isReduced(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.disableAnimations || media.accessibleNavigation;
  }

  /// Collapses a duration to zero under reduced motion so transitions render
  /// their end state immediately.
  static Duration resolve(BuildContext context, Duration duration) =>
      isReduced(context) ? Duration.zero : duration;
}
