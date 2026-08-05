import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User preferences that affect the whole application.
@immutable
class Preferences {
  const Preferences({
    this.themeMode = ThemeMode.system,
    this.balancesHidden = false,
  });

  final ThemeMode themeMode;

  /// When true, every monetary figure renders as a fixed mask glyph sequence.
  final bool balancesHidden;

  Preferences copyWith({ThemeMode? themeMode, bool? balancesHidden}) =>
      Preferences(
        themeMode: themeMode ?? this.themeMode,
        balancesHidden: balancesHidden ?? this.balancesHidden,
      );
}

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void setThemeMode(ThemeMode mode) =>
      state = state.copyWith(themeMode: mode);

  void toggleBalanceVisibility() =>
      state = state.copyWith(balancesHidden: !state.balancesHidden);
}
