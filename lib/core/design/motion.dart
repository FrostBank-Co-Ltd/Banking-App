import 'package:flutter/material.dart';

/// The single motion system.
///
/// Four duration bands, four curves, and only opacity, translation, scale, and
/// rotation are ever animated.
abstract final class Motion {
  /// Touch response. The frame the finger lands on.
  static const Duration instant = Duration(milliseconds: 110);

  /// Press release and state feedback.
  static const Duration short = Duration(milliseconds: 180);

  /// Screen and section transitions.
  static const Duration medium = Duration(milliseconds: 300);

  /// Entrances that carry distance, and the splash sequence.
  static const Duration long = Duration(milliseconds: 560);

  /// Gap between two neighbours in a staggered entrance.
  static const Duration staggerStep = Duration(milliseconds: 55);

  /// Entrances stop staggering past this many items, so a long list never
  /// leaves its tail waiting.
  static const int staggerCap = 8;

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;

  /// Overshoot for surfaces that arrive under their own weight. Kept shallow so
  /// figures never appear to wobble.
  static const Curve settle = Curves.easeOutBack;

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

  /// Delay for the item at [index] in a staggered entrance.
  static Duration stagger(BuildContext context, int index) => isReduced(context)
      ? Duration.zero
      : staggerStep * index.clamp(0, staggerCap);

  /// Scales a rotation, translation, or parallax amount to zero under reduced
  /// motion, so a transform driven by a gesture flattens instead of vanishing.
  static double amount(BuildContext context, double value) =>
      isReduced(context) ? 0 : value;
}
