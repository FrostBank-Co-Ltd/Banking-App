import 'package:intl/intl.dart';

/// Currency and quantity formatting.
///
/// One place decides how a figure looks on screen and how a screen reader
/// speaks it.
abstract final class Money {
  static const String maskGlyphs = '\u2022\u2022\u2022\u2022\u2022\u2022';

  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compact = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _quantity = NumberFormat('#,##0.00000000', 'en_US');

  static const Map<String, String> _spokenCurrency = {
    'USD': 'US dollars',
    'BTC': 'bitcoin',
    'ETH': 'ether',
    'SOL': 'solana',
  };

  static String symbolFor(String currencyCode) =>
      currencyCode == 'USD' ? '\$' : '';

  /// Visible figure, for example `$12,480.55`.
  static String format(
    double value, {
    String currencyCode = 'USD',
    bool signed = false,
  }) {
    final sign = signed ? (value < 0 ? '-' : '+') : (value < 0 ? '-' : '');
    final symbol = symbolFor(currencyCode);
    final magnitude = _amount.format(value.abs());
    if (symbol.isEmpty) return '$sign$magnitude $currencyCode';
    return '$sign$symbol$magnitude';
  }

  static String rounded(double value, {String currencyCode = 'USD'}) {
    final symbol = symbolFor(currencyCode);
    final magnitude = _compact.format(value.abs());
    if (symbol.isEmpty) return '$magnitude $currencyCode';
    return '${value < 0 ? '-' : ''}$symbol$magnitude';
  }

  /// Crypto quantity, trailing zeros trimmed.
  static String quantity(double value, String unit) {
    var text = _quantity.format(value);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return '$text $unit';
  }

  /// Screen reader label that reads the amount and the currency in words.
  static String spoken(
    double value, {
    String currencyCode = 'USD',
    bool signed = false,
  }) {
    final currency = _spokenCurrency[currencyCode] ?? currencyCode;
    final magnitude = _amount.format(value.abs());
    if (!signed) return '$magnitude $currency';
    return value < 0
        ? 'minus $magnitude $currency'
        : 'plus $magnitude $currency';
  }

  static String percent(double value) {
    final formatted = NumberFormat('#,##0.0', 'en_US').format(value.abs());
    return '${value < 0 ? '-' : '+'}$formatted%';
  }
}
