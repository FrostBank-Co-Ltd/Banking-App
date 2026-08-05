import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';

/// Live crypto market data from Twelve Data.
///
/// Verified against the service rather than assumed:
///
/// - `GET /quote?symbol=BTC/USD` returns one flat object.
/// - `GET /quote?symbol=BTC/USD,ETH/USD` returns an object keyed by symbol.
/// - `GET /time_series?symbol=BTC/USD&interval=1h&outputsize=n` returns
///   `{meta, values, status}` with `values` newest first.
/// - Every numeric field arrives as a string, so all of them are parsed.
/// - Crypto pairs carry no volume field on either endpoint, which is why nothing
///   in this build reports volume.
/// - A rejected symbol answers 404 with a JSON error body.
///
/// Two things protect the free plan's eight credits a minute: a short lived
/// cache per request shape, and in flight request sharing so a rebuild storm
/// cannot multiply calls. Both are invisible to callers apart from being fast.
class TwelveDataMarketRepository implements MarketRepository {
  TwelveDataMarketRepository({http.Client? client, DateTime Function()? clock})
    : _client = client ?? http.Client(),
      _now = clock ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  final Map<String, _CacheEntry<List<CryptoQuote>>> _quoteCache = {};
  final Map<String, _CacheEntry<CryptoSeries>> _seriesCache = {};
  final Map<String, Future<Object>> _inFlight = {};

  DateTime? _lastRequestAt;

  void dispose() => _client.close();

  @override
  Future<List<CryptoQuote>> fetchCryptoQuotes(List<CryptoAsset> assets) async {
    if (assets.isEmpty) return const [];

    final bySymbol = {for (final asset in assets) asset.symbol: asset};
    final key = 'quote:${bySymbol.keys.join(',')}';

    final cached = _quoteCache[key];
    if (cached != null && !cached.isStale(_now(), ApiConfig.quoteCacheWindow)) {
      return cached.value;
    }

    final quotes = await _share<List<CryptoQuote>>(key, () async {
      final body = await _get('/quote', {'symbol': bySymbol.keys.join(',')});

      // One symbol answers flat, several answer keyed by symbol. Normalise both
      // into a list of raw quote objects before parsing.
      final raw = <Map<String, Object?>>[];
      if (body.containsKey('symbol')) {
        raw.add(body);
      } else {
        for (final entry in body.entries) {
          final value = entry.value;
          if (value is Map<String, Object?> && value['symbol'] != null) {
            raw.add(value);
          }
        }
      }

      final parsed = <String, CryptoQuote>{};
      for (final item in raw) {
        final symbol = item['symbol'] as String?;
        if (symbol == null) continue;
        final asset = bySymbol[symbol];
        if (asset == null) continue;
        final quote = _parseQuote(item, asset);
        if (quote != null) parsed[symbol] = quote;
      }

      if (parsed.isEmpty) {
        throw const RepositoryFailure(
          'No live prices came back for these pairs.',
        );
      }

      // Preserve the order the caller asked for, dropping pairs the venue did
      // not return rather than failing the whole call.
      return [for (final asset in assets) ?parsed[asset.symbol]];
    });

    _quoteCache[key] = _CacheEntry(quotes, _now());
    return quotes;
  }

  @override
  Future<CryptoSeries> fetchCryptoSeries(
    CryptoAsset asset,
    ChartRange range,
  ) async {
    final key = 'series:${asset.symbol}:${range.name}';

    final cached = _seriesCache[key];
    if (cached != null && !cached.isStale(_now(), ApiConfig.seriesCacheWindow)) {
      return cached.value;
    }

    final series = await _share<CryptoSeries>(key, () async {
      final body = await _get('/time_series', {
        'symbol': asset.symbol,
        'interval': range.interval,
        'outputsize': '${range.bars}',
        'order': 'ASC',
      });

      final values = body['values'];
      if (values is! List || values.isEmpty) {
        throw RepositoryFailure(
          'No price history for ${asset.code} over ${range.spokenLabel}.',
        );
      }

      final candles = <CryptoCandle>[];
      for (final item in values) {
        if (item is! Map<String, Object?>) continue;
        final at = _parseDate(item['datetime']);
        final open = _parseDouble(item['open']);
        final high = _parseDouble(item['high']);
        final low = _parseDouble(item['low']);
        final close = _parseDouble(item['close']);
        if (at == null ||
            open == null ||
            high == null ||
            low == null ||
            close == null) {
          continue;
        }
        candles.add(
          CryptoCandle(at: at, open: open, high: high, low: low, close: close),
        );
      }

      if (candles.isEmpty) {
        throw RepositoryFailure(
          'Price history for ${asset.code} came back unreadable.',
        );
      }

      // `order=ASC` is requested, but the sort is asserted here so the chart can
      // rely on oldest first regardless of what the service returns.
      candles.sort((a, b) => a.at.compareTo(b.at));

      return CryptoSeries(
        symbol: asset.symbol,
        range: range,
        candles: candles,
      );
    });

    _seriesCache[key] = _CacheEntry(series, _now());
    return series;
  }

  /// Joins a caller onto an identical request that is already running, instead
  /// of spending a second credit on the same data.
  Future<T> _share<T>(String key, Future<T> Function() run) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);

    final future = run();
    _inFlight[key] = future as Future<Object>;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  Future<Map<String, Object?>> _get(
    String path,
    Map<String, String> query,
  ) async {
    if (!ApiConfig.hasTwelveDataKey) {
      throw const RepositoryFailure(
        'No market data API key is configured for this build.',
      );
    }

    await _space();

    final uri = Uri.parse('${ApiConfig.twelveDataBaseUrl}$path').replace(
      queryParameters: {...query, 'apikey': ApiConfig.twelveDataApiKey},
    );

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConfig.networkTimeout);
    } on TimeoutException {
      throw const RepositoryFailure(
        'The market data service did not respond in time.',
      );
    } on http.ClientException {
      // package:http wraps transport level failures, including a dropped
      // connection, in this one type on every platform. Caught by type rather
      // than by dart:io, which does not exist on the web target.
      throw const RepositoryFailure(
        'No connection, so live prices are unavailable.',
      );
    } on Exception {
      throw const RepositoryFailure('Could not reach the market data service.');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const RepositoryFailure(
        'The market data service returned something unreadable.',
      );
    }

    final body = decoded is Map<String, Object?>
        ? decoded
        : <String, Object?>{};

    // Twelve Data reports failures both in the status line and in the body, so
    // both are checked and mapped to one message the interface can show.
    final status = body['status'];
    final code = _parseInt(body['code']) ?? response.statusCode;
    if (response.statusCode != 200 || status == 'error') {
      throw RepositoryFailure(_messageFor(code, body['message']));
    }

    return body;
  }

  /// Holds a minimum gap between outbound calls.
  Future<void> _space() async {
    final last = _lastRequestAt;
    final now = _now();
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < ApiConfig.minRequestSpacing) {
        await Future<void>.delayed(ApiConfig.minRequestSpacing - elapsed);
      }
    }
    _lastRequestAt = _now();
  }

  static String _messageFor(int code, Object? message) => switch (code) {
    401 || 403 => 'The market data API key was rejected.',
    404 => 'That pair is not available from the market data service.',
    429 => 'Live price limit reached. Prices refresh again in a moment.',
    >= 500 => 'The market data service is having trouble. Try again shortly.',
    _ =>
      message is String && message.isNotEmpty
          ? message
          : 'Live prices are unavailable right now.',
  };

  static CryptoQuote? _parseQuote(Map<String, Object?> raw, CryptoAsset asset) {
    final price = _parseDouble(raw['close']);
    if (price == null) return null;

    final previousClose = _parseDouble(raw['previous_close']) ?? price;
    final change = _parseDouble(raw['change']) ?? (price - previousClose);
    final percentChange =
        _parseDouble(raw['percent_change']) ??
        (previousClose == 0 ? 0 : (change / previousClose) * 100);

    final fiftyTwoWeek = raw['fifty_two_week'];
    final range = fiftyTwoWeek is Map<String, Object?>
        ? fiftyTwoWeek
        : const <String, Object?>{};

    return CryptoQuote(
      symbol: asset.symbol,
      code: asset.code,
      // The service name reads `Bitcoin US Dollar`. The catalogue name is the
      // one the holder recognises, so that wins.
      name: asset.name,
      exchange: raw['exchange'] as String? ?? '',
      price: price,
      open: _parseDouble(raw['open']) ?? price,
      dayHigh: _parseDouble(raw['high']) ?? price,
      dayLow: _parseDouble(raw['low']) ?? price,
      previousClose: previousClose,
      change: change,
      percentChange: percentChange,
      asOf:
          _parseEpochSeconds(raw['last_quote_at']) ??
          _parseEpochSeconds(raw['timestamp']) ??
          DateTime.now(),
      rolling1dChangePercent: _parseDouble(raw['rolling_1d_change']),
      yearLow: _parseDouble(range['low']),
      yearHigh: _parseDouble(range['high']),
    );
  }

  /// Every numeric field on this API arrives as a string.
  static double? _parseDouble(Object? value) => switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value),
    _ => null,
  };

  static int? _parseInt(Object? value) => switch (value) {
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };

  static DateTime? _parseEpochSeconds(Object? value) {
    final seconds = _parseInt(value);
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000,
      isUtc: true,
    ).toLocal();
  }

  /// Bar stamps arrive as `2026-08-05` on daily spans and
  /// `2026-08-05 08:00:00` on intraday spans.
  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.storedAt);

  final T value;
  final DateTime storedAt;

  bool isStale(DateTime now, Duration window) =>
      now.difference(storedAt) >= window;
}
