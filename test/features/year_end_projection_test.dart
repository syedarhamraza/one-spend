import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';

Subscription _monthly({
  required DateTime next,
  double price = 10,
  List<DateTime> history = const [],
  String currency = 'USD',
  SubscriptionStatus status = SubscriptionStatus.active,
}) =>
    Subscription(
      id: 'm${next.toIso8601String()}$price',
      name: 'Monthly',
      description: '',
      price: price,
      currency: currency,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      nextBillingDate: next,
      paymentHistory: history,
      status: status,
    );

void main() {
  test('logged months count as spent; the rest of the year is still to come', () {
    // Paid on the 5th of Jan–Oct; next due Nov 5. Today is Oct 20.
    final sub = _monthly(
      next: DateTime(2026, 11, 5),
      history: [for (var m = 1; m <= 10; m++) DateTime(2026, m, 5)],
    );
    final p = SpendingTrendsEngine.projectYear(
      subscriptions: [sub],
      referenceDate: DateTime(2026, 10, 20),
      trackingSince: DateTime(2026, 1, 1),
      monthlyBudget: 15,
    );
    expect(p.year, 2026);
    expect(p.fromMonth, DateTime(2026, 1, 1));
    expect(p.spentSoFar, 100);
    expect(p.stillToCome, 20); // Nov + Dec
    expect(p.total, 120);
    expect(p.budgetForYear, 180);
    expect(p.overBudget, -60);
    expect(p.isEstimated, isFalse);
  });

  test('tracking that started mid-year only covers months since then', () {
    final sub = _monthly(next: DateTime(2026, 11, 5), history: [DateTime(2026, 9, 5), DateTime(2026, 10, 5)]);
    final p = SpendingTrendsEngine.projectYear(
      subscriptions: [sub],
      referenceDate: DateTime(2026, 10, 20),
      trackingSince: DateTime(2026, 9, 1),
      monthlyBudget: 10,
    );
    expect(p.fromMonth, DateTime(2026, 9, 1));
    expect(p.total, 40); // Sep, Oct, Nov, Dec
    expect(p.budgetForYear, 40);
  });

  test('months without logged payments are estimated', () {
    final sub = _monthly(next: DateTime(2026, 11, 5));
    final p = SpendingTrendsEngine.projectYear(
      subscriptions: [sub],
      referenceDate: DateTime(2026, 10, 20),
      trackingSince: DateTime(2026, 8, 1),
    );
    expect(p.isEstimated, isTrue);
    expect(p.spentSoFar, 30); // Aug, Sep estimated + Oct 5 renewal
    expect(p.stillToCome, 20);
    expect(p.budgetForYear, 0);
  });

  test('in December only what is left this month is to come', () {
    final sub = _monthly(
      next: DateTime(2026, 12, 28),
      history: [for (var m = 1; m <= 11; m++) DateTime(2026, m, 28)],
    );
    final p = SpendingTrendsEngine.projectYear(
      subscriptions: [sub],
      referenceDate: DateTime(2026, 12, 10),
      trackingSince: DateTime(2026, 1, 1),
    );
    expect(p.spentSoFar, 110);
    expect(p.stillToCome, 10);
  });

  test('paused subscriptions are left out and currencies convert', () {
    final p = SpendingTrendsEngine.projectYear(
      subscriptions: [
        _monthly(next: DateTime(2026, 11, 5), price: 10, currency: 'EUR'),
        _monthly(next: DateTime(2026, 11, 5), price: 99, status: SubscriptionStatus.paused),
      ],
      referenceDate: DateTime(2026, 10, 20),
      trackingSince: DateTime(2026, 10, 1),
      toMain: (amount, currency) => currency == 'EUR' ? amount * 2 : amount,
    );
    expect(p.stillToCome, 40); // Nov + Dec at 20 each
  });
}
