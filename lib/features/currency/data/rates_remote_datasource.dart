import 'dart:convert';
import 'dart:io';

import '../domain/exchange_rates.dart';

/// Downloads current market rates.
abstract class RatesRemoteDataSource {
  /// Units of each currency per 1 USD. Throws when offline or the service fails.
  Future<ExchangeRateSnapshot> fetchUsdRates();
}

/// Free, keyless services: open.er-api.com (~160 currencies, daily), then Frankfurter
/// (ECB, ~30 currencies) as a fallback.
class HttpRatesRemoteDataSource implements RatesRemoteDataSource {
  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<ExchangeRateSnapshot> fetchUsdRates() async {
    try {
      final json = await _getJson(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (json['result'] != 'success') throw const HttpException('open.er-api.com returned an error');
      return _snapshot(json['rates'], 'open.er-api.com');
    } catch (_) {
      final json = await _getJson(Uri.parse('https://api.frankfurter.dev/v1/latest?base=USD'));
      return _snapshot(json['rates'], 'frankfurter.dev');
    }
  }

  ExchangeRateSnapshot _snapshot(Object? rawRates, String provider) {
    if (rawRates is! Map) throw FormatException('No rates from $provider');
    final rates = <String, double>{
      'USD': 1.0,
      for (final e in rawRates.entries)
        if (e.value is num && (e.value as num) > 0) e.key.toString().toUpperCase(): (e.value as num).toDouble(),
    };
    return ExchangeRateSnapshot(rates: rates, fetchedAt: DateTime.now(), provider: provider);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) throw HttpException('HTTP ${response.statusCode}', uri: uri);
      final body = await response.transform(utf8.decoder).join().timeout(_timeout);
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

/// Never reaches the network; used in tests and whenever DI isn't configured for it.
class OfflineRatesRemoteDataSource implements RatesRemoteDataSource {
  const OfflineRatesRemoteDataSource();

  @override
  Future<ExchangeRateSnapshot> fetchUsdRates() => Future.error(const SocketException('Offline'));
}
