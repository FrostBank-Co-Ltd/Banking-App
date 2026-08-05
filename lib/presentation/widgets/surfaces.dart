import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';

/// Caps content width and centres it, so the web and tablet builds read as a
/// designed application instead of a stretched phone layout.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({required this.child, this.maxWidth, super.key});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? Layout.maxContentWidth,
      ),
      child: child,
    ),
  );
}

/// Section heading with an optional trailing control.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.x3),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppType.headlineMedium.copyWith(
                color: context.tokens.textPrimary,
              ),
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

/// Circular monogram avatar derived from a name.
class Monogram extends StatelessWidget {
  const Monogram({
    required this.initials,
    this.size = 44,
    this.background,
    this.foreground,
    super.key,
  });

  final String initials;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? tokens.interactiveSecondary,
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.16)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppType.labelLarge.copyWith(
          color: foreground ?? tokens.interactivePrimary,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Label and value row used by card, account, and transaction detail screens.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
    super.key,
  });

  final String label;
  final Widget value;
  final Widget? trailing;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
            ),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: DefaultTextStyle.merge(
              style: AppType.titleSmall.copyWith(
                color: valueColor ?? tokens.textPrimary,
              ),
              child: value,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Status pill bound to a real semantic state.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Space.x3,
      vertical: Space.x1 + 2,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: AppRadius.all(AppRadius.pill),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(label, style: AppType.labelSmall.copyWith(color: color)),
  );
}

/// Thin divider used inside grouped lists.
class SoftDivider extends StatelessWidget {
  const SoftDivider({this.inset = Space.x4, super.key});

  final double inset;

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: context.tokens.border.withValues(alpha: 0.6),
    indent: inset,
    endIndent: inset,
  );
}
