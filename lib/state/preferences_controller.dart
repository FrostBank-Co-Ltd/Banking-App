import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  String get displayName => '$name ($symbol)';
}

const List<CurrencyOption> supportedCurrencies = [
  CurrencyOption(code: 'USD', name: 'US dollar', symbol: '\$'),
  CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€'),
  CurrencyOption(code: 'GBP', name: 'British pound', symbol: '£'),
  CurrencyOption(code: 'JPY', name: 'Japanese yen', symbol: '¥'),
  CurrencyOption(code: 'PHP', name: 'Philippine peso', symbol: '₱'),
  CurrencyOption(code: 'CAD', name: 'Canadian dollar', symbol: 'CA\$'),
  CurrencyOption(code: 'AUD', name: 'Australian dollar', symbol: 'A\$'),
];

/// User preferences that affect the whole application.
@immutable
class Preferences {
  const Preferences({
    this.themeMode = ThemeMode.system,
    this.balancesHidden = false,
    this.currencyCode = 'USD',
    this.rememberedEmail,
  });

  final ThemeMode themeMode;

  /// When true, every monetary figure renders as a fixed mask glyph sequence.
  final bool balancesHidden;

  final String currencyCode;

  /// Remembered user email for quick 6-digit PIN unlock on subsequent sign-ins.
  final String? rememberedEmail;

  CurrencyOption get activeCurrency => supportedCurrencies.firstWhere(
        (c) => c.code == currencyCode,
        orElse: () => supportedCurrencies.first,
      );

  Preferences copyWith({
    ThemeMode? themeMode,
    bool? balancesHidden,
    String? currencyCode,
    Object? rememberedEmail = _absent,
  }) =>
      Preferences(
        themeMode: themeMode ?? this.themeMode,
        balancesHidden: balancesHidden ?? this.balancesHidden,
        currencyCode: currencyCode ?? this.currencyCode,
        rememberedEmail: rememberedEmail == _absent
            ? this.rememberedEmail
            : rememberedEmail as String?,
      );
}

const Object _absent = Object();

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();

  void setThemeMode(ThemeMode mode) =>
      state = state.copyWith(themeMode: mode);

  void toggleBalanceVisibility() =>
      state = state.copyWith(balancesHidden: !state.balancesHidden);

  void setCurrencyCode(String code) =>
      state = state.copyWith(currencyCode: code);

  void setRememberedEmail(String? email) =>
      state = state.copyWith(rememberedEmail: email);

  void clearRememberedEmail() =>
      state = state.copyWith(rememberedEmail: null);
}
