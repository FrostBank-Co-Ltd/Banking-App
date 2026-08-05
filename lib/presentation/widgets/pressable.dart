import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

/// Tap wrapper used by every card, tile, row, and icon control.
///
/// Gives four things that would otherwise be repeated on every screen: a press
/// that gives way under the finger and springs back on release, a light haptic
/// tick on activation, a keyboard focus ring resolved from the accent token, and
/// a minimum 48 by 48 logical pixel target.
///
/// The press takes hold in [Motion.instant] and releases over [Motion.short],
/// because a control that yields slowly feels unresponsive while one that
/// returns instantly feels brittle.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.borderRadius = AppRadius.md,
    this.minSize = Layout.minTapTarget,
    this.isButton = true,
    this.haptic = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double borderRadius;
  final double minSize;
  final bool isButton;

  /// A light tick on activation. Turned off for controls that fire in bursts.
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: Motion.instant,
    reverseDuration: Motion.short,
  );

  bool _focused = false;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _activate() {
    if (widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = widget.onTap != null;
    final radius = AppRadius.all(widget.borderRadius);
    final reduced = Motion.isReduced(context);

    final target = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.minSize,
        minHeight: widget.minSize,
      ),
      child: ExcludeSemantics(
        excluding: widget.semanticLabel != null,
        child: widget.child,
      ),
    );

    return Semantics(
      button: widget.isButton,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: enabled ? _activate : null,
          onTapDown: enabled ? (_) => _press.forward() : null,
          onTapUp: enabled ? (_) => _press.reverse() : null,
          onTapCancel: enabled ? () => _press.reverse() : null,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: _focused
                  ? Border.all(color: tokens.accent, width: 2)
                  : null,
            ),
            child: reduced
                ? target
                : AnimatedBuilder(
                    animation: _press,
                    child: target,
                    builder: (context, child) {
                      // Feedback: the surface sinks under the finger, then
                      // springs back a hair past its resting size. The curve is
                      // mirrored on release so the overshoot lands above one
                      // rather than below it.
                      final v = _press.value;
                      final t = _press.status == AnimationStatus.reverse
                          ? 1 - Motion.settle.transform(1 - v)
                          : Motion.standard.transform(v);
                      return Transform.translate(
                        offset: Offset(0, t),
                        child: Transform.scale(
                          scale: 1 - 0.035 * t,
                          child: child,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
