/// Converts [amount] in [currency] into the app's main currency.
typedef ToMainCurrency = double Function(double amount, String currency);

/// A [ToMainCurrency] that leaves amounts as they are (single-currency callers and tests).
double sameCurrency(double amount, String currency) => amount;

/// Where the rate used for a currency came from.
enum RateSource {
  /// Pinned by the user.
  custom,

  /// Downloaded (possibly cached from an earlier download).
  live,

  /// Shipped with the app; approximate, used until rates are downloaded.
  builtIn,
}

/// Market rates as units of each currency per 1 USD.
class ExchangeRateSnapshot {
  final Map<String, double> rates;
  final DateTime fetchedAt;

  /// Which service provided them, e.g. `open.er-api.com`.
  final String provider;

  const ExchangeRateSnapshot({required this.rates, required this.fetchedAt, required this.provider});

  Map<String, dynamic> toJson() => {
        'rates': rates,
        'fetchedAt': fetchedAt.toIso8601String(),
        'provider': provider,
      };

  /// Null when [json] isn't a usable snapshot.
  static ExchangeRateSnapshot? tryFromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    final fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? '');
    if (rawRates is! Map || fetchedAt == null) return null;
    final rates = <String, double>{
      for (final e in rawRates.entries)
        if (e.value is num && (e.value as num) > 0) e.key.toString(): (e.value as num).toDouble(),
    };
    if (rates.isEmpty) return null;
    return ExchangeRateSnapshot(rates: rates, fetchedAt: fetchedAt, provider: json['provider'] as String? ?? '');
  }
}

/// A user-pinned rate: 1 unit of the currency = [rate] units of [base].
class RateOverride {
  final String base;
  final double rate;

  const RateOverride({required this.base, required this.rate});

  Map<String, dynamic> toJson() => {'base': base, 'rate': rate};

  static RateOverride? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final base = json['base'], rate = json['rate'];
    if (base is! String || rate is! num || rate <= 0) return null;
    return RateOverride(base: base, rate: rate.toDouble());
  }

  @override
  bool operator ==(Object other) => other is RateOverride && other.base == base && other.rate == rate;

  @override
  int get hashCode => Object.hash(base, rate);
}

/// Converts between currencies using, in order: the user's pinned rates, downloaded
/// rates, then the built-in approximate rates.
class CurrencyConverter {
  final Map<String, double> builtIn;
  final ExchangeRateSnapshot? live;
  final Map<String, RateOverride> overrides;

  const CurrencyConverter({required this.builtIn, this.live, this.overrides = const {}});

  double? _perUsd(String code) => code == 'USD' ? 1.0 : (live?.rates[code] ?? builtIn[code]);

  double? _market(double amount, String from, String to) {
    if (from == to) return amount;
    final f = _perUsd(from), t = _perUsd(to);
    if (f == null || t == null) return null;
    return amount / f * t;
  }

  /// [amount] of [from] expressed in [to]; null when a rate is missing.
  double? convert(double amount, String from, String to) {
    if (from == to) return amount;
    final fromOverride = overrides[from];
    if (fromOverride != null) return _market(amount * fromOverride.rate, fromOverride.base, to);
    final toOverride = overrides[to];
    if (toOverride != null) {
      final inBase = _market(amount, from, toOverride.base);
      return inBase == null ? null : inBase / toOverride.rate;
    }
    return _market(amount, from, to);
  }

  /// How many [to] one unit of [from] buys, or null when unknown.
  double? rate(String from, String to) => convert(1, from, to);

  RateSource? sourceOf(String code) {
    if (overrides.containsKey(code)) return RateSource.custom;
    if (code == 'USD' || (live?.rates.containsKey(code) ?? false)) return live == null ? RateSource.builtIn : RateSource.live;
    if (builtIn.containsKey(code)) return RateSource.builtIn;
    return null;
  }
}
