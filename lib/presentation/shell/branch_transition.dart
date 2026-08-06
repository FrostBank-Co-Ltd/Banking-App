import 'package:flutter/widgets.dart';

import '../../core/design/motion.dart';
import 'destinations.dart';

/// Animated stand in for the [IndexedStack] that `StatefulShellRoute` uses by
/// default, wired in through `navigatorContainerBuilder`.
///
/// The default container swaps branches on the same frame, which makes a tap on
/// the bar feel like a cut rather than a move. This keeps every branch navigator
/// mounted, exactly as the default does, so scroll offsets and nested routes
/// survive, and cross fades the outgoing and incoming branch over
/// [Motion.medium] instead.
///
/// The two panes travel horizontally in the direction of the tap, read from the
/// slot order in [ShellDestinations] rather than the branch index, so moving
/// right along the bar always moves content leftward. Under reduced motion the
/// swap lands immediately.
class BranchTransition extends StatefulWidget {
  const BranchTransition({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  /// Branch index in view.
  final int currentIndex;

  /// One navigator per branch, in branch order.
  final List<Widget> children;

  @override
  State<BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<BranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  )..addStatusListener(_onStatus);

  late int _current = widget.currentIndex;

  /// Branch on its way out. Null once the transition has landed, which is what
  /// returns the pane to offstage so it stops painting.
  int? _leaving;

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _leaving == null) return;
    setState(() => _leaving = null);
  }

  @override
  void didUpdateWidget(BranchTransition old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex == _current) return;

    final previous = _current;
    _current = widget.currentIndex;

    if (Motion.isReduced(context)) {
      _leaving = null;
      _controller.value = 1;
      return;
    }
    _leaving = previous;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaving = _leaving;
    final forward =
        leaving == null ||
        ShellDestinations.slotOf(_current) > ShellDestinations.slotOf(leaving);

    // Paint order matters, so the stack is ordered rather than indexed: idle
    // branches first, then the one leaving, then the one arriving on top. Keys
    // keep each navigator bound to its own element across the reorder.
    final order = <int>[
      for (var i = 0; i < widget.children.length; i++)
        if (i != _current && i != leaving) i,
      ?leaving,
      _current,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in order)
          KeyedSubtree(
            key: ValueKey<int>(index),
            child: _pane(index, leaving, forward),
          ),
      ],
    );
  }

  Widget _pane(int index, int? leaving, bool forward) {
    final navigator = widget.children[index];

    if (index == _current) {
      return TickerMode(
        enabled: true,
        child: _BranchPane(
          animation: _controller,
          arriving: true,
          forward: forward,
          child: navigator,
        ),
      );
    }

    if (index == leaving) {
      return TickerMode(
        enabled: false,
        // The pane on its way out must not take taps, or be read out, in place
        // of the one arriving.
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: _BranchPane(
              animation: _controller,
              arriving: false,
              forward: forward,
              child: navigator,
            ),
          ),
        ),
      );
    }

    return Offstage(child: TickerMode(enabled: false, child: navigator));
  }
}

/// Opacity, scale, and horizontal drift for one side of the cross fade.
///
/// An [AnimatedWidget] rather than an [AnimatedBuilder] around the whole stack,
/// because the child is held in a field and handed back unchanged on every
/// frame. That lets the element tree short circuit, so a transition repaints the
/// branch without rebuilding the screen inside it.
class _BranchPane extends AnimatedWidget {
  const _BranchPane({
    required Animation<double> animation,
    required this.child,
    required this.arriving,
    required this.forward,
  }) : super(listenable: animation);

  final Widget child;
  final bool arriving;
  final bool forward;

  /// Distance the panes travel. Short, because the fade carries the change and
  /// a long slide on a tab swap reads as a push to a new screen.
  static const double _drift = 26;

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final t = Motion.standard.transform(_animation.value.clamp(0, 1));
    final sign = forward ? 1.0 : -1.0;
    final drift = Motion.amount(context, _drift);

    // The arriving pane resolves over the full duration. The one leaving is gone
    // by two thirds, so the two are never both at half opacity for long enough
    // to read as a smear.
    final double opacity;
    final double dx;
    final double scale;

    if (arriving) {
      opacity = (t * 1.45).clamp(0, 1);
      dx = sign * drift * (1 - t);
      scale = 0.972 + 0.028 * t;
    } else {
      opacity = (1 - t * 1.7).clamp(0, 1);
      dx = -sign * drift * 0.55 * t;
      scale = 1 - 0.014 * t;
    }

    // The child is never swapped out for a placeholder, even at zero opacity.
    // Dropping it would tear down the branch navigator and lose its route stack.
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}
