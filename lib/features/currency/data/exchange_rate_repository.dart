import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../domain/exchange_rates.dart';
import 'bundled_rates.dart';
import 'rates_remote_datasource.dart';

/// Holds the current [CurrencyConverter]: downloaded rates (cached in `app_settings`),
/// user-pinned rates, and the built-in fallback. Notifies when any of them change.
class ExchangeRateRepository extends ChangeNotifier {
  static const String keyRates = 'onespend_fx_rates';
  static const String keyOverrides = 'onespend_fx_overrides';

  /// Downloaded rates older than this are refreshed on the next chance.
  static const Duration maxAge = Duration(hours: 12);

  final AppDatabase? _db;
  final RatesRemoteDataSource remote;
  final DateTime Function() _now;

  ExchangeRateRepository({
    AppDatabase? database,
    this.remote = const OfflineRatesRemoteDataSource(),
    DateTime Function()? now,
  })  : _db = database,
        _now = now ?? DateTime.now;

  ExchangeRateSnapshot? _live;
  Map<String, RateOverride> _overrides = const {};
  CurrencyConverter _converter = const CurrencyConverter(builtIn: bundledUsdRates);
  Future<bool>? _inFlight;
  bool _lastRefreshFailed = false;

  CurrencyConverter get converter => _converter;
  Map<String, RateOverride> get overrides => Map.unmodifiable(_overrides);

  /// When the downloaded rates were fetched; null when only built-in rates are available.
  DateTime? get lastUpdated => _live?.fetchedAt;
  String? get provider => _live?.provider;
  bool get isRefreshing => _inFlight != null;
  bool get lastRefreshFailed => _lastRefreshFailed;
  bool get isStale => _live == null || _now().difference(_live!.fetchedAt) > maxAge;

  void _rebuild() {
    _converter = CurrencyConverter(builtIn: bundledUsdRates, live: _live, overrides: _overrides);
    notifyListeners();
  }

  /// Reads cached rates and pinned rates. Fast; never touches the network.
  Future<void> load() async {
    final db = _db;
    if (db == null) return;
    try {
      final rawRates = await db.getSetting(keyRates);
      if (rawRates != null) _live = ExchangeRateSnapshot.tryFromJson(jsonDecode(rawRates) as Map<String, dynamic>);
      final rawOverrides = await db.getSetting(keyOverrides);
      if (rawOverrides != null) _overrides = decodeOverrides(jsonDecode(rawOverrides));
    } catch (e) {
      debugPrint('OneSpend: Failed to load exchange rates: $e');
    }
    _rebuild();
  }

  /// Downloads fresh rates when the cached ones are older than [maxAge] (or always, with
  /// [force]). Returns whether usable downloaded rates are available afterwards.
  Future<bool> refresh({bool force = false}) {
    if (!force && !isStale) return Future.value(true);
    return _inFlight ??= _download().whenComplete(() {
      _inFlight = null;
      notifyListeners();
    });
  }

  Future<bool> _download() async {
    notifyListeners();
    try {
      final snapshot = await remote.fetchUsdRates();
      _live = snapshot;
      _lastRefreshFailed = false;
      _rebuild();
      await _db?.setSetting(keyRates, jsonEncode(snapshot.toJson()));
      return true;
    } catch (e) {
      debugPrint('OneSpend: Exchange rate download failed: $e');
      _lastRefreshFailed = true;
      return _live != null;
    }
  }

  /// Pins 1 [code] = [rate] units of [base], or clears the pin when [rate] is null.
  Future<void> setOverride(String code, {double? rate, String? base}) async {
    final next = Map<String, RateOverride>.from(_overrides);
    if (rate == null || base == null || rate <= 0 || base == code) {
      if (next.remove(code) == null) return;
    } else {
      next[code] = RateOverride(base: base, rate: rate);
    }
    await replaceOverrides(next);
  }

  /// Replaces every pinned rate (restoring a backup).
  Future<void> replaceOverrides(Map<String, RateOverride> overrides) async {
    _overrides = Map.of(overrides);
    _rebuild();
    await _db?.setSetting(keyOverrides, jsonEncode(encodeOverrides(_overrides)));
  }

  static Map<String, dynamic> encodeOverrides(Map<String, RateOverride> overrides) => {
        for (final e in overrides.entries) e.key: e.value.toJson(),
      };

  static Map<String, RateOverride> decodeOverrides(Object? json) {
    if (json is! Map) return const {};
    return {
      for (final e in json.entries) e.key.toString(): ?RateOverride.tryFromJson(e.value),
    };
  }
}
