/// Outbound API configuration.
///
/// SECURITY: [_fallbackTwelveDataKey] is a development key checked into the
/// repository so the build runs without extra setup. Treat it as public. Before
/// this ships, rotate the key at https://twelvedata.com/account/api-keys and
/// pass the replacement at build time instead:
///
/// ```
/// flutter run --dart-define=TWELVE_DATA_API_KEY=your_key
/// ```
///
/// The dart define always wins over the checked in value, so a real build never
/// has to touch this file.
library;

abstract final class ApiConfig {
  static const String twelveDataBaseUrl = 'https://api.twelvedata.com';

  /// Development key. Rotate before release, see the library note above.
  static const String _fallbackTwelveDataKey =
      '41bbc6a2834545dcbcda6217a2b00c20'; //This should be 'YOUR_KEY_HERE';

  static const String twelveDataApiKey = String.fromEnvironment(
    'TWELVE_DATA_API_KEY',
    defaultValue: _fallbackTwelveDataKey,
  );

  static bool get hasTwelveDataKey => twelveDataApiKey.isNotEmpty;

  /// How long a request is given before it is treated as a failure. Market data
  /// that arrives late is worse than a retry control.
  static const Duration networkTimeout = Duration(seconds: 12);

  /// The free plan allows eight credits a minute, and one symbol in a quote or
  /// one time series call costs one credit. These two windows keep the
  /// application inside that budget without the user ever seeing a rate limit.
  static const Duration quoteCacheWindow = Duration(seconds: 20);
  static const Duration seriesCacheWindow = Duration(minutes: 2);

  /// Spacing between two outbound calls, so a burst of taps cannot spend the
  /// whole minute's budget at once.
  static const Duration minRequestSpacing = Duration(milliseconds: 250);
}









