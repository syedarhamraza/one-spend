import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/notifications/domain/notification_planner.dart';
import 'package:onespend/features/notifications/domain/planned_notification.dart';
import 'package:onespend/features/payment_methods/domain/entities/payment_method.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';

final _now = DateTime(2026, 10, 1, 12, 0);
const _nineAm = 9 * 60;

Subscription _sub({
  String id = 'netflix',
  String name = 'Netflix',
  double price = 15.49,
  BillingCycle cycle = BillingCycle.monthly,
  DateTime? next,
  int reminderDays = 2,
  int? reminderTimeMinutes,
  SubscriptionStatus status = SubscriptionStatus.active,
  List<DateTime> history = const [],
}) {
  return Subscription(
    id: id,
    name: name,
    description: '',
    price: price,
    billingCycle: cycle,
    category: SubscriptionCategory.entertainment,
    nextBillingDate: next ?? DateTime(2026, 10, 10),
    reminderDays: reminderDays,
    reminderTimeMinutes: reminderTimeMinutes,
    status: status,
    paymentHistory: history,
  );
}

List<PlannedNotification> _plan({
  List<Subscription> subs = const [],
  List<PaymentMethod> cards = const [],
  double budget = 0,
}) {
  return NotificationPlanner.plan(
    subscriptions: subs,
    paymentMethods: cards,
    monthlyBudget: budget,
    currency: '\$',
    defaultReminderTimeMinutes: _nineAm,
    now: _now,
  );
}

void main() {
  group('Renewal reminders', () {
    test('fire reminderDays before each billing date at the default time', () {
      final plan = _plan(subs: [_sub()]);

      expect(plan.map((n) => n.fireAt), [
        DateTime(2026, 10, 8, 9),
        DateTime(2026, 11, 8, 9),
      ]);
      expect(plan.first.kind, NotificationKind.renewal);
      expect(plan.first.title, 'Netflix renews in 2 days');
      expect(plan.first.body, '\$15.49 will be charged on Oct 10.');
      expect(plan.first.subjectId, 'netflix');
    });

    test('same-day reminders fire on the billing date and say "today"', () {
      final plan = _plan(subs: [_sub(reminderDays: 0)]);
      expect(plan.first.fireAt, DateTime(2026, 10, 10, 9));
      expect(plan.first.title, 'Netflix renews today');
    });

    test('a per-subscription time overrides the default; null falls back', () {
      final custom = _plan(subs: [_sub(reminderTimeMinutes: 20 * 60 + 30)]);
      expect(custom.first.fireAt, DateTime(2026, 10, 8, 20, 30));

      final fallback = _plan(subs: [_sub()]);
      expect(fallback.first.fireAt, DateTime(2026, 10, 8, 9));
    });

    test('skips reminders whose time has already passed', () {
      // Billing Oct 2 with 2 days notice would have fired Sep 30.
      final plan = _plan(subs: [_sub(next: DateTime(2026, 10, 2))]);
      expect(plan.first.fireAt, DateTime(2026, 10, 31, 9));
    });

    test('paused subscriptions get no reminders', () {
      expect(_plan(subs: [_sub(status: SubscriptionStatus.paused)]), isEmpty);
    });

    test('ids are stable across runs and outside the reserved developer range', () {
      final a = _plan(subs: [_sub()]);
      final b = _plan(subs: [_sub()]);
      expect(a.map((n) => n.id), b.map((n) => n.id));
      expect(a.every((n) => n.id > PlannedNotification.maxReservedId), isTrue);
      expect(a.map((n) => n.id).toSet().length, a.length);
    });

    test('plans only within the 60-day window and caps the total', () {
      final weekly = _sub(cycle: BillingCycle.weekly, next: DateTime(2026, 10, 5));
      final plan = _plan(subs: [weekly]);
      expect(plan.every((n) => !n.fireAt.isAfter(_now.add(NotificationPlanner.window))), isTrue);

      final many = [
        for (var i = 0; i < 40; i++) _sub(id: 's$i', cycle: BillingCycle.weekly, next: DateTime(2026, 10, 5)),
      ];
      final capped = _plan(subs: many);
      expect(capped.length, NotificationPlanner.maxCount);
      final times = capped.map((n) => n.fireAt).toList();
      expect(times, [...times]..sort());
    });
  });

  group('Card expiry', () {
    PaymentMethod card(String expiry) => PaymentMethod(
          id: 'card_$expiry',
          nickname: 'Main card',
          type: PaymentMethodType.creditCard,
          brand: CardBrand.visa,
          last4: '4242',
          expiryDate: expiry,
        );

    test('fires on the 1st of the month before expiry', () {
      final plan = _plan(cards: [card('12/26')]);
      expect(plan.single.kind, NotificationKind.card);
      expect(plan.single.fireAt, DateTime(2026, 11, 1, 9));
    });

    test('falls back to the 1st of the expiry month when the month before has passed', () {
      final plan = _plan(cards: [card('11/26')]);
      expect(plan.single.fireAt, DateTime(2026, 11, 1, 9));
    });

    test('skips expired cards, expiries beyond the window, and unparseable dates', () {
      expect(_plan(cards: [card('08/26'), card('06/28'), card('')]), isEmpty);
    });
  });

  group('Budget alerts', () {
    test('alerts on the charge that pushes the month over budget, once per month', () {
      final plan = _plan(
        budget: 30,
        subs: [
          _sub(id: 'a', name: 'Netflix', price: 15.49, next: DateTime(2026, 10, 10)),
          _sub(id: 'b', name: 'Spotify', price: 10.99, next: DateTime(2026, 10, 12)),
          _sub(id: 'c', name: 'iCloud+', price: 9.99, next: DateTime(2026, 10, 20)),
        ],
      ).where((n) => n.kind == NotificationKind.budget).toList();

      // October: 15.49 + 10.99 = 26.48, then iCloud+ on Oct 20 crosses 30. November repeats.
      expect(plan.map((n) => n.fireAt), [DateTime(2026, 10, 20, 9), DateTime(2026, 11, 20, 9)]);
      expect(plan.first.title, 'Over budget on Oct 20');
      expect(plan.first.body, contains('iCloud+'));
      expect(plan.first.body, contains('over your \$30.00 budget'));
    });

    test('counts charges already paid this month', () {
      final plan = _plan(
        budget: 20,
        subs: [
          _sub(id: 'a', price: 15, next: DateTime(2026, 11, 1), history: [DateTime(2026, 10, 1)]),
          _sub(id: 'b', name: 'Spotify', price: 10, next: DateTime(2026, 10, 12)),
        ],
      ).where((n) => n.kind == NotificationKind.budget);
      expect(plan.first.fireAt, DateTime(2026, 10, 12, 9));
    });

    test('no alert without a budget, when under budget, or for paused and trial subscriptions', () {
      bool hasBudgetAlert(List<PlannedNotification> plan) => plan.any((n) => n.kind == NotificationKind.budget);
      expect(hasBudgetAlert(_plan(subs: [_sub(price: 500)])), isFalse);
      expect(hasBudgetAlert(_plan(budget: 100, subs: [_sub()])), isFalse);
      expect(
        hasBudgetAlert(_plan(budget: 10, subs: [
          _sub(price: 500, status: SubscriptionStatus.paused),
          _sub(id: 't', price: 500, status: SubscriptionStatus.trial),
        ])),
        isFalse,
      );
    });
  });
}
