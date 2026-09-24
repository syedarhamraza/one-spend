import 'package:intl/intl.dart';

/// Pre-initialized, canonical DateFormat instances.
///
/// Prevents expensive runtime locale table lookups and repeated allocations
/// inside widget `build()` methods and scroll frames.
abstract final class OneUIDateFormats {
  /// e.g. "Oct 12"
  static final DateFormat monthDay = DateFormat('MMM dd');

  /// e.g. "Oct 12, 2026"
  static final DateFormat monthDayYear = DateFormat('MMM dd, yyyy');

  /// e.g. "October 12, 2026"
  static final DateFormat fullMonthDayYear = DateFormat('MMMM dd, yyyy');

  /// e.g. "Monday, October 12, 2026"
  static final DateFormat fullDate = DateFormat('EEEE, MMMM dd, yyyy');

  /// e.g. "Mon, Oct 12"
  static final DateFormat weekdayMonthDay = DateFormat('EEE, MMM d');

  /// e.g. "Oct"
  static final DateFormat shortMonth = DateFormat('MMM');

  /// e.g. "October 2026"
  static final DateFormat fullMonthYear = DateFormat('MMMM yyyy');
}
