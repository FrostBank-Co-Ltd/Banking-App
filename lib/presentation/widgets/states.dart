import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens.dart';
import '../../core/design/typography.dart';
import '../../domain/repositories.dart';

/// One non interactive placeholder block. Shape matched skeletons are built
/// from these, and they carry no repeating animation so the splash indicator
/// stays the only looping motion in the application.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    this.width,
    this.height = 14,
    this.radius = AppRadius.xs,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.tokens.skeletonHighlight,
      borderRadius: AppRadius.all(radius),
    ),
  );
}

/// Skeleton shaped like a transaction row.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < count; index++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x3),
          child: Row(
            children: [
              const SkeletonBlock(
                width: 44,
                height: 44,
                radius: AppRadius.pill,
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBlock(width: 150, height: 14),
                    SizedBox(height: Space.x2),
                    SkeletonBlock(width: 90, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: Space.x3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonBlock(width: 70, height: 14),
                  SizedBox(height: Space.x2),
                  SkeletonBlock(width: 44, height: 11),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

/// Composed message plus one action that leads to populating the surface.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.heading,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.inbox_rounded,
    super.key,
  });

  final String heading;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.x8),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.interactiveSecondary,
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
              child: Icon(icon, color: tokens.accent),
            ),
            const SizedBox(height: Space.x4),
            Text(
              heading,
              style: AppType.titleLarge.copyWith(color: tokens.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x2),
            Text(
              message,
              style: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x4),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// Inline failure plus a retry control that re-invokes the same call.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Space.x4),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: AppRadius.all(AppRadius.lg),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: tokens.error),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: Text(
                    message,
                    style: AppType.bodyMedium.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Space.x2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps an asynchronous region so loading, empty, and error rendering is
/// declared once for the whole application.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    required this.value,
    required this.skeleton,
    required this.builder,
    this.onRetry,
    this.isEmpty,
    this.empty,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget skeleton;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => ExcludeSemantics(child: IgnorePointer(child: skeleton)),
    error: (error, _) => ErrorStateView(
      message: error is RepositoryFailure
          ? error.message
          : 'Something went wrong on our side.',
      onRetry: onRetry,
    ),
    data: (data) {
      if ((isEmpty?.call(data) ?? false) && empty != null) return empty!;
      return builder(data);
    },
  );
}
