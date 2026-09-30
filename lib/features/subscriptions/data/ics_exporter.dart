import 'package:intl/intl.dart';
import '../../currency/domain/money_format.dart';
import '../domain/services/charge_schedule.dart';

/// Builds an iCalendar (.ics, RFC 5545) file with one all-day event per upcoming charge,
/// importable into Samsung Calendar, Google Calendar and others.
///
/// Charges are written individually (not as RRULEs) so month-end clamping matches the app.
class IcsExporter {
  const IcsExporter._();

  static final DateFormat _day = DateFormat('yyyyMMdd');

  /// [paymentMethodName] resolves a payment method id to a display name for the description.
  /// When [reminderTimeMinutes] is non-null, each event gets an alarm `reminderDays` before
  /// the charge at that time of day (per-subscription times override it).
  static String build(
    List<UpcomingCharge> charges, {
    required DateTime now,
    String? Function(String? paymentMethodId)? paymentMethodName,
    int? reminderTimeMinutes,
  }) {
    final stamp = '${DateFormat("yyyyMMdd'T'HHmmss").format(now.toUtc())}Z';
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//OneSpend//Subscription renewals//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:OneSpend renewals',
    ];

    for (final charge in charges.where((c) => !c.isPaid)) {
      final sub = charge.subscription;
      final day = _day.format(charge.date);
      final nextDay = _day.format(DateTime(charge.date.year, charge.date.month, charge.date.day + 1));
      final amount = formatMoney(sub.price, sub.currency);
      final card = paymentMethodName?.call(sub.paymentMethodId);
      final description = [
        '${sub.billingCycle.label} subscription · $amount',
        if (card != null && card.isNotEmpty) 'Paid with $card',
        'Exported from OneSpend',
      ].join('\n');

      lines.addAll([
        'BEGIN:VEVENT',
        'UID:${_escape(sub.id)}-$day@onespend.app',
        'DTSTAMP:$stamp',
        'DTSTART;VALUE=DATE:$day',
        'DTEND;VALUE=DATE:$nextDay',
        'SUMMARY:${_escape('${sub.name} · $amount')}',
        'DESCRIPTION:${_escape(description)}',
        'TRANSP:TRANSPARENT',
      ]);

      if (reminderTimeMinutes != null) {
        // All-day events start at midnight, so offset = time of day minus the lead days.
        final minutes = (sub.reminderTimeMinutes ?? reminderTimeMinutes) - sub.reminderDays * 24 * 60;
        lines.addAll([
          'BEGIN:VALARM',
          'ACTION:DISPLAY',
          'DESCRIPTION:${_escape('${sub.name} renews ${sub.reminderDays == 0 ? 'today' : 'soon'} · $amount')}',
          'TRIGGER:${minutes < 0 ? '-' : ''}PT${minutes.abs()}M',
          'END:VALARM',
        ]);
      }
      lines.add('END:VEVENT');
    }

    lines.add('END:VCALENDAR');
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Escapes TEXT values (RFC 5545 §3.3.11).
  static String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r\n', '\\n')
      .replaceAll('\n', '\\n');

  /// Folds content lines longer than 74 characters (RFC 5545 §3.1).
  static String _fold(String line) {
    const limit = 74;
    if (line.length <= limit) return line;
    final parts = <String>[line.substring(0, limit)];
    for (var i = limit; i < line.length; i += limit - 1) {
      parts.add(' ${line.substring(i, (i + limit - 1).clamp(0, line.length))}');
    }
    return parts.join('\r\n');
  }
}
