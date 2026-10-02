import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/services/annual_savings.dart';
import 'package:onespend/models/subscription.dart';

Subscription _sub(
  String id, {
  double price = 10,
  BillingCycle cycle = BillingCycle.monthly,
  double? annual,
  SubscriptionStatus status = SubscriptionStatus.active,
  String currency = 'USD',
}) =>
    Subscription(
      id: id,
      name: id,
      description: '',
      price: price,
      currency: currency,
      billingCycle: cycle,
      category: SubscriptionCategory.utilities,
      nextBillingDate: DateTime(2026, 11, 1),
      status: status,
      annualPlanPrice: annual,
    );

void main() {
  test('monthly: 12 × price against the yearly plan', () {
    final s = AnnualSavings.forSubscription(_sub('a', price: 10, annual: 100))!;
    expect(s.currentYearly, 120);
    expect(s.saving, 20);
    expect(s.percent, closeTo(1 / 6, 1e-9));
  });

  test('weekly and quarterly use their billing counts', () {
    expect(AnnualSavings.forSubscription(_sub('w', price: 2, cycle: BillingCycle.weekly, annual: 100))!.saving, 4);
    expect(AnnualSavings.forSubscription(_sub('q', price: 30, cycle: BillingCycle.quarterly, annual: 100))!.saving, 20);
  });

  test('a yearly plan that costs more gives a negative saving', () {
    expect(AnnualSavings.forSubscription(_sub('a', price: 5, annual: 70))!.saving, -10);
  });

  test('does not apply to yearly, unset, paused or trial subscriptions', () {
    expect(AnnualSavings.forSubscription(_sub('y', cycle: BillingCycle.yearly, annual: 50)), isNull);
    expect(AnnualSavings.forSubscription(_sub('n')), isNull);
    expect(AnnualSavings.forSubscription(_sub('z', annual: 0)), isNull);
    expect(AnnualSavings.forSubscription(_sub('p', annual: 50, status: SubscriptionStatus.paused)), isNull);
    expect(AnnualSavings.forSubscription(_sub('t', annual: 50, status: SubscriptionStatus.trial)), isNull);
  });

  test('potential totals only real savings, biggest first, in the main currency', () {
    final result = AnnualSavings.potential(
      [
        _sub('small', price: 10, annual: 110), // saves 10
        _sub('big', price: 20, annual: 200), // saves 40
        _sub('worse', price: 5, annual: 80), // costs more
        _sub('eur', price: 10, annual: 100, currency: 'EUR'), // saves 20 EUR = 40 at 2×
      ],
      (amount, currency) => currency == 'EUR' ? amount * 2 : amount,
    );
    expect(result.savings.map((s) => s.subscription.id), ['big', 'eur', 'small']);
    expect(result.total, 90);
  });

  test('round-trips through JSON (backups)', () {
    final restored = Subscription.fromJson(_sub('a', annual: 99.5).toJson());
    expect(restored.annualPlanPrice, 99.5);
    expect(restored.copyWith(clearAnnualPlanPrice: true).annualPlanPrice, isNull);
  });
}
