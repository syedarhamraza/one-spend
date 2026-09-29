import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/data/ics_exporter.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/domain/services/charge_schedule.dart';

void main() {
  final now = DateTime(2026, 10, 1, 12);

  Subscription sub({
    String id = 'netflix',
    String name = 'Netflix',
    int reminderDays = 2,
    int? reminderTimeMinutes,
    String? paymentMethodId = 'visa',
  }) =>
      Subscription(
        id: id,
        name: name,
        description: '',
        price: 15.49,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 10, 10),
        reminderDays: reminderDays,
        reminderTimeMinutes: reminderTimeMinutes,
        paymentMethodId: paymentMethodId,
      );

  List<UpcomingCharge> charges(List<Subscription> subs) =>
      ChargeSchedule.between(subs, from: now, to: DateTime(2026, 11, 30), now: now);

  test('builds a valid calendar with one all-day event per charge and CRLF line endings', () {
    final ics = IcsExporter.build(charges([sub()]), now: now, paymentMethodName: (_) => 'Visa •••• 4242');

    expect(ics, startsWith('BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'));
    expect(ics, endsWith('END:VCALENDAR\r\n'));
    expect(ics.replaceAll('\r\n', '').contains('\n'), isFalse);
    expect('BEGIN:VEVENT'.allMatches(ics).length, 2);
    expect(ics, contains('DTSTART;VALUE=DATE:20261010\r\nDTEND;VALUE=DATE:20261011'));
    expect(ics, contains('DTSTART;VALUE=DATE:20261110'));
    expect(ics, contains('SUMMARY:Netflix · \$15.49'));
    expect(ics, contains('Paid with Visa •••• 4242'));
  });

  test('uids are stable per subscription and date', () {
    final a = IcsExporter.build(charges([sub()]), now: now);
    final b = IcsExporter.build(charges([sub()]), now: now.add(const Duration(hours: 5)));
    final uids = RegExp(r'UID:(.+)').allMatches(a).map((m) => m.group(1)!.trim()).toList();
    expect(uids, ['netflix-20261010@onespend.app', 'netflix-20261110@onespend.app']);
    expect(RegExp(r'UID:(.+)').allMatches(b).map((m) => m.group(1)!.trim()), uids);
  });

  test('escapes commas, semicolons and backslashes in text', () {
    final ics = IcsExporter.build(charges([sub(name: r'Tea, Coffee; & C\o')]), now: now);
    expect(ics, contains(r'SUMMARY:Tea\, Coffee\; & C\\o'));
  });

  test('adds an alarm at the reminder time only when reminders are on', () {
    final off = IcsExporter.build(charges([sub()]), now: now);
    expect(off, isNot(contains('BEGIN:VALARM')));

    final on = IcsExporter.build(charges([sub()]), now: now, reminderTimeMinutes: 9 * 60);
    // 2 days before midnight, then +9h: -48h + 9h = -39h = -2340 minutes.
    expect(on, contains('TRIGGER:-PT2340M'));

    final sameDayCustom = IcsExporter.build(
      charges([sub(reminderDays: 0, reminderTimeMinutes: 20 * 60)]),
      now: now,
      reminderTimeMinutes: 9 * 60,
    );
    expect(sameDayCustom, contains('TRIGGER:PT1200M'));
  });

  test('skips paid charges and folds long lines', () {
    final paid = Subscription(
      id: 'p',
      name: 'A very long subscription name that will definitely need folding in the calendar file',
      description: '',
      price: 1,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime(2026, 11, 20),
      paymentHistory: [DateTime(2026, 10, 20)],
    );
    final ics = IcsExporter.build(charges([paid]), now: now);
    expect('BEGIN:VEVENT'.allMatches(ics).length, 1);
    for (final line in ics.split('\r\n')) {
      expect(line.length, lessThanOrEqualTo(74));
    }
    expect(ics, contains('\r\n '));
  });
}
