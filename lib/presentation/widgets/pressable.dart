import 'package:flutter/material.dart';

import '../../core/design/motion.dart';
import '../../core/design/tokens.dart';

/// Tap wrapper used by every card, tile, row, and icon control.
///
/// Gives three things that would otherwise be repeated on every screen: a
/// 0.98 press scale, a keyboard focus ring resolved from the accent token, and
/// a minimum 48 by 48 logical pixel target.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.borderRadius = AppRadius.md,
    this.minSize = Layout.minTapTarget,
    this.isButton = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double borderRadius;
  final double minSize;
  final bool isButton;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = widget.onTap != null;
    final radius = AppRadius.all(widget.borderRadius);

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
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            // Feedback: the surface gives way under the finger.
            scale: _pressed ? 0.98 : 1,
            duration: Motion.resolve(context, Motion.short),
            curve: Motion.standard,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: _focused
                    ? Border.all(color: tokens.accent, width: 2)
                    : null,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.minSize,
                  minHeight: widget.minSize,
                ),
                child: ExcludeSemantics(
                  excluding: widget.semanticLabel != null,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
