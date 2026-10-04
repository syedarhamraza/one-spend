import 'dart:math' as math;

import 'package:intl/intl.dart';

import 'currency.dart';

final Map<int, NumberFormat> _formats = {};
final NumberFormat _compact = NumberFormat.compact();
final RegExp _nonZeroDigit = RegExp(r'[1-9]');
final RegExp _endsWithLetter = RegExp(r'[A-Za-z]$');

/// How much precision an amount needs.
enum MoneyStyle {
  /// An actual price or charge: keeps its cents (`$15.49`), but drops `.00` (`$15`).
  exact,

  /// A total or headline figure: whole units from 1,000 up (`$2,045`), cents below.
  summary,

  /// A converted estimate: whole units from 10 up (`≈ $42`), cents below.
  approximate,
}

/// Formats [amount] in the currency [code]: `$1,299.49`, `$15`, `Rs 4,300`, `¥1,500`, `99 kr`.
///
/// Cents follow [style]; whole amounts never show `.00`. [decimals] forces a digit count
/// (e.g. 0 for a rounded budget). [compact] gives `$1.2K` for chart axes and tight spots.
String formatMoney(
  double amount,
  String code, {
  MoneyStyle style = MoneyStyle.exact,
  int? decimals,
  bool compact = false,
}) {
  final currency = CurrencyCatalog.of(code);
  final abs = amount.abs();
  final String number;
  if (compact && abs >= 1000) {
    number = _compact.format(abs);
  } else {
    final digits = decimals ?? _digitsFor(abs, currency.decimals, style);
    number = (_formats[digits] ??= NumberFormat.decimalPatternDigits(decimalDigits: digits)).format(abs);
  }
  final zero = !_nonZeroDigit.hasMatch(number);
  final sign = amount < 0 && !zero ? '-' : '';
  final symbol = currency.symbol;
  if (currency.symbolAfter) return '$sign$number $symbol';
  // Letter symbols (Rs, CHF, KSh) read better with a space: "Rs 1,500".
  final spaced = _endsWithLetter.hasMatch(symbol);
  return '$sign$symbol${spaced ? ' ' : ''}$number';
}

int _digitsFor(double abs, int currencyDigits, MoneyStyle style) {
  if (currencyDigits == 0) return 0;
  final wholeFrom = switch (style) {
    MoneyStyle.exact => double.infinity,
    MoneyStyle.summary => 1000.0,
    MoneyStyle.approximate => 10.0,
  };
  if (abs >= wholeFrom) return 0;
  // No ".00": an amount that rounds to whole units shows none.
  final scale = math.pow(10, currencyDigits);
  return (abs * scale).round() % scale == 0 ? 0 : currencyDigits;
}

/// The symbol users type after, for editor prefixes: `Rs `, `$`, `kr`.
String currencyPrefix(String code) {
  final symbol = CurrencyCatalog.of(code).symbol;
  return _endsWithLetter.hasMatch(symbol) ? '$symbol ' : symbol;
}
