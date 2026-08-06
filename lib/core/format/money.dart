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
    'EUR': 'Euros',
    'GBP': 'British pounds',
    'JPY': 'Japanese yen',
    'PHP': 'Philippine pesos',
    'CAD': 'Canadian dollars',
    'AUD': 'Australian dollars',
    'BTC': 'bitcoin',
    'ETH': 'ether',
    'SOL': 'solana',
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'PHP': '₱',
    'CAD': 'CA\$',
    'AUD': 'A\$',
  };

  static String symbolFor(String currencyCode) =>
      _currencySymbols[currencyCode] ?? '\$';

  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.78,
    'JPY': 155.0,
    'PHP': 58.0,
    'CAD': 1.38,
    'AUD': 1.52,
  };

  /// Converts [amount] from [fromCurrency] to [toCurrency] using exchange rates.
  static double convert(
    double amount, {
    String fromCurrency = 'USD',
    required String toCurrency,
  }) {
    if (fromCurrency == toCurrency) return amount;
    final rateFrom = exchangeRates[fromCurrency];
    final rateTo = exchangeRates[toCurrency];
    if (rateFrom == null || rateTo == null) return amount;
    final baseUsd = amount / rateFrom;
    return baseUsd * rateTo;
  }

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

  /// Spoken form of a move, because a signed percentage does not read aloud.
  static String percentSpoken(double value) {
    final formatted = NumberFormat('#,##0.0', 'en_US').format(value.abs());
    return value < 0 ? 'down $formatted percent' : 'up $formatted percent';
  }

  static final NumberFormat _axisWhole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _axisFine = NumberFormat('0.0000', 'en_US');

  /// Chart axis figure, unadorned and as short as the magnitude allows, so four
  /// or five labels fit in a narrow gutter.
  static String axis(double value) {
    final magnitude = value.abs();
    if (magnitude >= 1000) return _axisWhole.format(value);
    if (magnitude >= 1) return _amount.format(value);
    return _axisFine.format(value);
  }

  static final NumberFormat _priceSmall = NumberFormat('#,##0.0000', 'en_US');

  /// Market price. Sub dollar instruments need more decimals than a balance
  /// does, otherwise a move of a tenth of a cent renders as no move at all.
  static String price(double value, {String currencyCode = 'USD'}) {
    final symbol = symbolFor(currencyCode);
    final magnitude = value.abs() < 1
        ? _priceSmall.format(value.abs())
        : _amount.format(value.abs());
    final sign = value < 0 ? '-' : '';
    if (symbol.isEmpty) return '$sign$magnitude $currencyCode';
    return '$sign$symbol$magnitude';
  }

  /// Signed market move, matched to the precision [price] would use.
  static String priceChange(double value, {String currencyCode = 'USD'}) {
    final symbol = symbolFor(currencyCode);
    final magnitude = value.abs() < 1
        ? _priceSmall.format(value.abs())
        : _amount.format(value.abs());
    final sign = value < 0 ? '-' : '+';
    if (symbol.isEmpty) return '$sign$magnitude $currencyCode';
    return '$sign$symbol$magnitude';
  }
}
