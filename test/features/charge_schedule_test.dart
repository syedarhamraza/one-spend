import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/domain/services/charge_schedule.dart';

final _now = DateTime(2026, 10, 1, 14, 30);

Subscription _sub({
  String id = 'netflix',
  String name = 'Netflix',
  double price = 15.49,
  BillingCycle cycle = BillingCycle.monthly,
  required DateTime next,
  SubscriptionStatus status = SubscriptionStatus.active,
  List<DateTime> history = const [],
  String? paymentMethodId,
  int? anchorDay,
}) {
  return Subscription(
    id: id,
    name: name,
    description: '',
    price: price,
    billingCycle: cycle,
    category: SubscriptionCategory.entertainment,
    nextBillingDate: next,
    status: status,
    paymentHistory: history,
    paymentMethodId: paymentMethodId,
    anchorDay: anchorDay,
  );
}

List<UpcomingCharge> _between(List<Subscription> subs, DateTime from, DateTime to, {bool includePaid = true}) =>
    ChargeSchedule.between(subs, from: from, to: to, now: _now, includePaid: includePaid);

void main() {
  group('ChargeSchedule.between', () {
    test('a weekly subscription appears on every billing day', () {
      final charges = _between(
        [_sub(cycle: BillingCycle.weekly, next: DateTime(2026, 10, 3))],
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      );
      expect(charges.map((c) => c.date.day), [3, 10, 17, 24, 31]);
      expect(charges.every((c) => c.status == ChargeStatus.upcoming), isTrue);
    });

    test('month-end anchors clamp like the billing logic', () {
      final charges = _between(
        [_sub(next: DateTime(2027, 1, 31), anchorDay: 31)],
        DateTime(2027, 1, 1),
        DateTime(2027, 4, 30),
      );
      expect(charges.map((c) => c.date), [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30),
      ]);
    });

    test('range is inclusive by calendar day and ignores time of day', () {
      final charges = _between(
        [_sub(next: DateTime(2026, 10, 10, 23, 59))],
        DateTime(2026, 10, 10, 12),
        DateTime(2026, 10, 10, 12),
      );
      expect(charges.single.date, DateTime(2026, 10, 10));
    });

    test('paused subscriptions are excluded', () {
      final charges = _between(
        [_sub(next: DateTime(2026, 10, 10), status: SubscriptionStatus.paused)],
        DateTime(2026, 10, 1),
        DateTime(2026, 12, 31),
      );
      expect(charges, isEmpty);
    });

    test('logged payments in range appear as paid, and can be excluded', () {
      final sub = _sub(next: DateTime(2026, 11, 1), history: [DateTime(2026, 10, 1, 9), DateTime(2026, 9, 1)]);

      final withPaid = _between([sub], DateTime(2026, 10, 1), DateTime(2026, 11, 30));
      expect(withPaid.map((c) => (c.date, c.status)), [
        (DateTime(2026, 10, 1), ChargeStatus.paid),
        (DateTime(2026, 11, 1), ChargeStatus.upcoming),
      ]);

      final withoutPaid = _between([sub], DateTime(2026, 10, 1), DateTime(2026, 11, 30), includePaid: false);
      expect(withoutPaid.map((c) => c.status), [ChargeStatus.upcoming]);
    });

    test('an unpaid past billing date is one overdue charge, then projection resumes from today', () {
      final charges = _between(
        [_sub(next: DateTime(2026, 8, 15))],
        DateTime(2026, 8, 1),
        DateTime(2026, 11, 30),
      );
      expect(charges.map((c) => (c.date, c.status)), [
        (DateTime(2026, 8, 15), ChargeStatus.overdue),
        (DateTime(2026, 10, 15), ChargeStatus.upcoming),
        (DateTime(2026, 11, 15), ChargeStatus.upcoming),
      ]);
    });

    test('sorts by date, then name', () {
      final charges = _between(
        [
          _sub(id: 'b', name: 'Spotify', next: DateTime(2026, 10, 5)),
          _sub(id: 'a', name: 'apple tv', next: DateTime(2026, 10, 5)),
          _sub(id: 'c', name: 'Adobe', next: DateTime(2026, 10, 2)),
        ],
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 6),
      );
      expect(charges.map((c) => c.subscription.name), ['Adobe', 'apple tv', 'Spotify']);
    });
  });

  group('ChargeListSummary', () {
    final charges = _between(
      [
        _sub(id: 'n', name: 'Netflix', price: 15.49, next: DateTime(2026, 10, 5), paymentMethodId: 'visa'),
        _sub(id: 's', name: 'Spotify', price: 10.99, next: DateTime(2026, 10, 7), paymentMethodId: 'visa'),
        _sub(id: 'i', name: 'iCloud+', price: 2.99, next: DateTime(2026, 10, 20)),
        _sub(id: 'a', name: 'Adobe', price: 59.99, next: DateTime(2026, 10, 25), paymentMethodId: 'amex'),
        _sub(id: 'p', name: 'Paid', price: 100, next: DateTime(2026, 11, 2), history: [DateTime(2026, 10, 2)]),
      ],
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 31),
    );

    test('dueTotal and unpaid ignore paid charges', () {
      expect(charges.unpaid, hasLength(4));
      expect(charges.dueTotal, closeTo(15.49 + 10.99 + 2.99 + 59.99, 1e-9));
    });

    test('byDay groups charges in date order', () {
      final days = charges.byDay();
      expect(days.keys.first, DateTime(2026, 10, 2));
      expect(days[DateTime(2026, 10, 5)]!.single.subscription.name, 'Netflix');
    });

    test('byPaymentMethod totals unpaid charges per card, largest first, null for no card', () {
      final byCard = charges.byPaymentMethod();
      expect(byCard.keys.toList(), ['amex', 'visa', null]);
      expect(byCard['visa']!.count, 2);
      expect(byCard['visa']!.total, closeTo(26.48, 1e-9));
      expect(byCard[null]!.total, closeTo(2.99, 1e-9));
    });

    test('biggest is the largest unpaid charge', () {
      expect(charges.biggest!.subscription.name, 'Adobe');
    });

    test('busiestWeek finds the heaviest 7-day window', () {
      final week = charges.busiestWeek()!;
      expect(week.start, DateTime(2026, 10, 20));
      expect(week.total, closeTo(2.99 + 59.99, 1e-9));
      expect(week.count, 2);
    });

    test('summaries of an empty list are empty', () {
      const empty = <UpcomingCharge>[];
      expect(empty.dueTotal, 0);
      expect(empty.biggest, isNull);
      expect(empty.busiestWeek(), isNull);
      expect(empty.byPaymentMethod(), isEmpty);
    });
  });

  test('annualRenewalsWithin lists yearly subscriptions renewing soon, once each', () {
    final renewals = ChargeSchedule.annualRenewalsWithin(
      [
        _sub(id: 'y1', name: 'iCloud+ yearly', cycle: BillingCycle.yearly, next: DateTime(2026, 12, 2)),
        _sub(id: 'y2', name: 'Far yearly', cycle: BillingCycle.yearly, next: DateTime(2027, 6, 1)),
        _sub(id: 'm', name: 'Monthly', next: DateTime(2026, 10, 10)),
      ],
      now: _now,
    );
    expect(renewals.map((c) => c.subscription.id), ['y1']);
  });
}
