import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/services/charge_schedule.dart';
import 'package:onespend/features/subscriptions/domain/services/spending_insights.dart';
import 'package:onespend/models/subscription.dart';

void main() {
  final now = DateTime(2026, 9, 24);

  Subscription sub(
    String id, {
    double price = 10,
    BillingCycle cycle = BillingCycle.monthly,
    SubscriptionCategory category = SubscriptionCategory.entertainment,
    SubscriptionStatus status = SubscriptionStatus.active,
    DateTime? next,
    List<DateTime> history = const [],
  }) =>
      Subscription(
        id: id,
        name: id,
        description: '',
        price: price,
        billingCycle: cycle,
        category: category,
        status: status,
        nextBillingDate: next ?? DateTime(2026, 10, 5),
        paymentHistory: history,
      );

  group('SpendingInsights', () {
    final subs = [
      sub('netflix', price: 20),
      sub('spotify', price: 10, category: SubscriptionCategory.music),
      sub('cloud', price: 120, cycle: BillingCycle.yearly, category: SubscriptionCategory.cloud, next: DateTime(2026, 11, 2)),
      sub('gym', price: 5, cycle: BillingCycle.weekly, category: SubscriptionCategory.health, next: DateTime(2026, 9, 28)),
      sub('trial', price: 50, status: SubscriptionStatus.trial),
      sub('paused', price: 30, status: SubscriptionStatus.paused),
    ];

    test('byCategory excludes trials and paused, and shares sum to 1', () {
      final categories = SpendingInsights.byCategory(subs);
      expect(categories.map((c) => c.category), isNot(contains(SubscriptionCategory.developer)));
      expect(categories.fold(0.0, (s, c) => s + c.share), closeTo(1.0, 1e-9));
      final entertainment = categories.firstWhere((c) => c.category == SubscriptionCategory.entertainment);
      expect(entertainment.monthly, 20); // trial excluded
      expect(entertainment.count, 1);
      expect(categories.first.monthly >= categories.last.monthly, isTrue);
    });

    test('byCycle groups by billing cycle in monthly equivalents', () {
      final cycles = {for (final c in SpendingInsights.byCycle(subs)) c.cycle: c};
      expect(cycles[BillingCycle.monthly]!.monthly, 30);
      expect(cycles[BillingCycle.monthly]!.count, 2);
      expect(cycles[BillingCycle.yearly]!.monthly, 10);
      expect(cycles[BillingCycle.weekly]!.monthly, closeTo(5 * 52 / 12, 1e-9));
    });

    test('topExpense and concentration', () {
      final top = SpendingInsights.topExpense(subs)!;
      expect(top.subscription.id, 'gym'); // 21.67/mo
      final c = SpendingInsights.concentration(subs)!;
      expect(c.count, 3);
      expect(c.share, lessThan(1));
      expect(SpendingInsights.concentration(subs.take(3)), isNull, reason: 'needs more than 3');
    });

    test('heaviestMonthAhead picks the month with the yearly renewal', () {
      final heaviest = SpendingInsights.heaviestMonthAhead(subs, now: now)!;
      expect(heaviest.month, DateTime(2026, 11, 1));
      expect(heaviest.charges.first.subscription.id, 'cloud');
    });

    test('yearlyRenewalsSoon and pausedSavings', () {
      final yearly = SpendingInsights.yearlyRenewalsSoon(subs, now: now)!;
      expect(yearly.count, 1);
      expect(yearly.total, 120);
      final paused = SpendingInsights.pausedSavings(subs);
      expect(paused.count, 1);
      expect(paused.monthly, 30);
    });

    test('recentPayments is newest first', () {
      final payments = SpendingInsights.recentPayments([
        sub('a', history: [DateTime(2026, 7, 1), DateTime(2026, 9, 1)]),
        sub('b', history: [DateTime(2026, 8, 1)]),
      ]);
      expect(payments.map((p) => p.date), [DateTime(2026, 9, 1), DateTime(2026, 8, 1), DateTime(2026, 7, 1)]);
    });
  });

  group('SpendingTrendsEngine forecast', () {
    test('places a yearly charge in its renewal month only', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('cloud', price: 120, cycle: BillingCycle.yearly, next: DateTime(2026, 11, 2))],
        horizon: SpendingTrendHorizon.sixMonths,
        referenceDate: now,
      );
      final byMonth = {for (final p in points) p.month.month: p.amount};
      expect(byMonth[11], 120);
      expect(byMonth[10], 0);
      expect(byMonth[9], 0);
    });

    test('weekly charges match ChargeSchedule', () {
      final gym = sub('gym', price: 5, cycle: BillingCycle.weekly, next: DateTime(2026, 9, 28));
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [gym],
        horizon: SpendingTrendHorizon.sixMonths,
        referenceDate: now,
      );
      final october = points.firstWhere((p) => p.month == DateTime(2026, 10, 1));
      final expected = ChargeSchedule.between([gym], from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31), now: now);
      expect(october.renewalCount, expected.length);
      expect(october.amount, expected.length * 5);
    });

    test('current month adds logged payments to charges still due', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [
          sub('paid', price: 10, next: DateTime(2026, 10, 3), history: [DateTime(2026, 9, 3)]),
          sub('due', price: 7, next: DateTime(2026, 9, 29)),
        ],
        horizon: SpendingTrendHorizon.sixMonths,
        referenceDate: now,
      );
      final current = points.firstWhere((p) => p.isCurrent);
      expect(current.amount, 17);
      expect(current.topCharges.map((c) => c.subscription.id), ['paid', 'due']);
    });

    test('current month estimates a renewal earlier this month for subs without history', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('fresh', price: 15, next: DateTime(2026, 10, 3))],
        horizon: SpendingTrendHorizon.sixMonths,
        referenceDate: now,
      );
      expect(points.firstWhere((p) => p.isCurrent).amount, 15);
      expect(points.firstWhere((p) => p.month == DateTime(2026, 10, 1)).amount, 15);
    });

    test('summary counts months over budget', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('cloud', price: 120, cycle: BillingCycle.yearly, next: DateTime(2026, 11, 2))],
        horizon: SpendingTrendHorizon.sixMonths,
        referenceDate: now,
      );
      final summary = SpendingTrendsEngine.calculateSummary(points, monthlyBudget: 50);
      expect(summary.overBudgetCount, 1);
      expect(summary.heaviestForecast?.month, DateTime(2026, 11, 1));
      expect(summary.forecastTotal, 120);
    });
  });
}
