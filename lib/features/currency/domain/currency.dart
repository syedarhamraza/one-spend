/// An ISO 4217 currency as the app shows it.
class Currency {
  /// ISO 4217 code, e.g. `USD`.
  final String code;

  /// What's printed next to amounts, e.g. `$`, `Rs`, `kr`.
  final String symbol;
  final String name;

  /// Minor-unit digits shown on amounts: 0 for JPY, and for currencies whose prices are
  /// whole in practice even though ISO 4217 lists 2 (PKR, INR); 3 for KWD.
  final int decimals;

  /// Whether the symbol goes after the number (`99.00 kr`).
  final bool symbolAfter;

  const Currency(this.code, this.symbol, this.name, {this.decimals = 2, this.symbolAfter = false});

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// The currencies OneSpend knows how to show and convert.
class CurrencyCatalog {
  const CurrencyCatalog._();

  static const String defaultCode = 'USD';

  static const List<Currency> all = [
    Currency('USD', '\$', 'US dollar'),
    Currency('EUR', '€', 'Euro'),
    Currency('GBP', '£', 'British pound'),
    Currency('PKR', 'Rs', 'Pakistani rupee', decimals: 0),
    Currency('INR', '₹', 'Indian rupee', decimals: 0),
    Currency('AED', 'AED', 'UAE dirham'),
    Currency('SAR', 'SAR', 'Saudi riyal'),
    Currency('QAR', 'QAR', 'Qatari riyal'),
    Currency('KWD', 'KD', 'Kuwaiti dinar', decimals: 3),
    Currency('BHD', 'BD', 'Bahraini dinar', decimals: 3),
    Currency('OMR', 'OMR', 'Omani rial', decimals: 3),
    Currency('CAD', 'CA\$', 'Canadian dollar'),
    Currency('AUD', 'A\$', 'Australian dollar'),
    Currency('NZD', 'NZ\$', 'New Zealand dollar'),
    Currency('JPY', '¥', 'Japanese yen', decimals: 0),
    Currency('CNY', 'CN¥', 'Chinese yuan'),
    Currency('KRW', '₩', 'South Korean won', decimals: 0),
    Currency('HKD', 'HK\$', 'Hong Kong dollar'),
    Currency('TWD', 'NT\$', 'New Taiwan dollar'),
    Currency('SGD', 'S\$', 'Singapore dollar'),
    Currency('MYR', 'RM', 'Malaysian ringgit'),
    Currency('THB', '฿', 'Thai baht'),
    Currency('IDR', 'Rp', 'Indonesian rupiah', decimals: 0),
    Currency('PHP', '₱', 'Philippine peso'),
    Currency('VND', '₫', 'Vietnamese dong', decimals: 0, symbolAfter: true),
    Currency('BDT', '৳', 'Bangladeshi taka', decimals: 0),
    Currency('LKR', 'LKR', 'Sri Lankan rupee', decimals: 0),
    Currency('NPR', 'NPR', 'Nepalese rupee', decimals: 0),
    Currency('CHF', 'CHF', 'Swiss franc'),
    Currency('SEK', 'kr', 'Swedish krona', symbolAfter: true),
    Currency('NOK', 'kr', 'Norwegian krone', symbolAfter: true),
    Currency('DKK', 'kr', 'Danish krone', symbolAfter: true),
    Currency('PLN', 'zł', 'Polish złoty', symbolAfter: true),
    Currency('CZK', 'Kč', 'Czech koruna', symbolAfter: true),
    Currency('HUF', 'Ft', 'Hungarian forint', decimals: 0, symbolAfter: true),
    Currency('TRY', '₺', 'Turkish lira'),
    Currency('RUB', '₽', 'Russian ruble', symbolAfter: true),
    Currency('UAH', '₴', 'Ukrainian hryvnia'),
    Currency('EGP', 'E£', 'Egyptian pound'),
    Currency('NGN', '₦', 'Nigerian naira', decimals: 0),
    Currency('KES', 'KSh', 'Kenyan shilling', decimals: 0),
    Currency('ZAR', 'R', 'South African rand'),
    Currency('BRL', 'R\$', 'Brazilian real'),
    Currency('MXN', 'MX\$', 'Mexican peso'),
    Currency('ARS', 'ARS', 'Argentine peso'),
    Currency('CLP', 'CLP', 'Chilean peso', decimals: 0),
    Currency('COP', 'COP', 'Colombian peso', decimals: 0),
  ];

  static final Map<String, Currency> _byCode = {for (final c in all) c.code: c};

  /// The currency for [code], or null when it isn't in the catalog.
  static Currency? tryOf(String code) => _byCode[code.toUpperCase()];

  /// The currency for [code]; an unknown code is shown as itself with 2 decimals.
  static Currency of(String code) => tryOf(code) ?? Currency(code, code, code);

  static bool isKnown(String code) => _byCode.containsKey(code.toUpperCase());

  /// Before v3 the app stored display symbols instead of ISO codes.
  static const Map<String, String> legacySymbols = {
    '\$': 'USD',
    '€': 'EUR',
    '£': 'GBP',
    '¥': 'JPY',
    '₹': 'INR',
    '₩': 'KRW',
    'Rs': 'PKR',
    'CHF': 'CHF',
    'AED': 'AED',
  };

  /// Turns a stored value (an ISO code, or a legacy symbol) into an ISO code.
  static String normalize(String? value) {
    if (value == null) return defaultCode;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return defaultCode;
    final legacy = legacySymbols[trimmed];
    if (legacy != null) return legacy;
    final upper = trimmed.toUpperCase();
    if (_byCode.containsKey(upper)) return upper;
    return defaultCode;
  }
}
