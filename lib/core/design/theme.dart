import 'package:flutter/material.dart';

import 'motion.dart';
import 'tokens.dart';
import 'typography.dart';

/// Builds light and dark [ThemeData] from [AppTokens]. No screen declares its
/// own colors, radii, or text sizes.
abstract final class AppTheme {
  static ThemeData light() => _build(AppTokens.light);

  static ThemeData dark() => _build(AppTokens.dark);

  static ThemeData _build(AppTokens tokens) {
    final scheme = ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.interactivePrimary,
      onPrimary: tokens.textOnBrand,
      secondary: tokens.accent,
      onSecondary: tokens.textOnBrand,
      surface: tokens.background,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.surface,
      error: tokens.error,
      onError: tokens.textOnBrand,
      outline: tokens.border,
    );

    final textTheme = AppType.textTheme(tokens.textPrimary, tokens.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      fontFamily: AppType.ui,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitions(),
          TargetPlatform.iOS: _FadeThroughTransitions(),
          TargetPlatform.macOS: _FadeThroughTransitions(),
          TargetPlatform.windows: _FadeThroughTransitions(),
          TargetPlatform.linux: _FadeThroughTransitions(),
          TargetPlatform.fuchsia: _FadeThroughTransitions(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.headlineMedium.copyWith(
          color: tokens.textPrimary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 22),
      cardTheme: CardThemeData(
        color: tokens.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
          side: BorderSide(color: tokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        // The entered value always resolves from the active theme, so it can
        // never land as white text on a white field.
        hintStyle: AppType.bodyMedium.copyWith(color: tokens.textSecondary),
        labelStyle: AppType.labelLarge.copyWith(color: tokens.textSecondary),
        helperStyle: AppType.bodySmall.copyWith(color: tokens.textSecondary),
        errorStyle: AppType.bodySmall.copyWith(color: tokens.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: tokens.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: tokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.interactivePrimary,
          foregroundColor: tokens.textOnBrand,
          disabledBackgroundColor: tokens.disabled,
          disabledForegroundColor: tokens.textSecondary,
          minimumSize: const Size.fromHeight(Layout.minTapTarget + 4),
          textStyle: AppType.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: AppType.labelLarge,
          minimumSize: const Size(Layout.minTapTarget, Layout.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border),
          minimumSize: const Size.fromHeight(Layout.minTapTarget),
          textStyle: AppType.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.all(AppRadius.pill),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.isDark ? tokens.surfaceRaised : Palette.deepNavy,
        contentTextStyle: AppType.bodyMedium.copyWith(color: Palette.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
        ),
        titleTextStyle: AppType.headlineMedium.copyWith(
          color: tokens.textPrimary,
        ),
        contentTextStyle: AppType.bodyMedium.copyWith(
          color: tokens.textSecondary,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.surface,
      ),
      focusColor: tokens.accent,
    );
  }
}

/// Route transitions built from opacity and translation only, inside the
/// medium duration band.
class _FadeThroughTransitions extends PageTransitionsBuilder {
  const _FadeThroughTransitions();

  @override
  Duration get transitionDuration => Motion.medium;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.isReduced(context)) return child;
    // Storytelling: incoming content lifts and fades in so the change of place
    // reads as forward movement.
    final curved = CurvedAnimation(parent: animation, curve: Motion.standard);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
