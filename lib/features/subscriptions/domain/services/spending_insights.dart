import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';
import 'charge_schedule.dart';
import 'subscription_stats.dart';

/// Monthly-equivalent spend of one category.
typedef CategorySpend = ({SubscriptionCategory category, double monthly, int count, double share});

/// Monthly-equivalent spend of one billing cycle.
typedef CycleSpend = ({BillingCycle cycle, double monthly, int count, double share});

/// A calendar month's unpaid charges, largest first.
typedef MonthOutlook = ({DateTime month, double total, List<UpcomingCharge> charges});

/// Pure aggregates behind the Analytics tab. Everything counts only billable
/// subscriptions (see [SubscriptionStats.billable]), so paused plans and free trials are excluded.
class SpendingInsights {
  const SpendingInsights._();

  static double _total(Iterable<Subscription> subs) => SubscriptionStats.totalMonthlySpend(subs);

  /// Spend per category, largest first. Shares sum to 1 when anything is spent.
  static List<CategorySpend> byCategory(Iterable<Subscription> subs) {
    final total = _total(subs);
    final monthly = <SubscriptionCategory, double>{};
    final counts = <SubscriptionCategory, int>{};
    for (final sub in SubscriptionStats.billable(subs)) {
      monthly[sub.category] = (monthly[sub.category] ?? 0) + sub.monthlyCost;
      counts[sub.category] = (counts[sub.category] ?? 0) + 1;
    }
    return [
      for (final e in monthly.entries)
        (category: e.key, monthly: e.value, count: counts[e.key]!, share: total > 0 ? e.value / total : 0.0),
    ]..sort((a, b) => b.monthly.compareTo(a.monthly));
  }

  /// Spend per billing cycle, largest first.
  static List<CycleSpend> byCycle(Iterable<Subscription> subs) {
    final total = _total(subs);
    final monthly = <BillingCycle, double>{};
    final counts = <BillingCycle, int>{};
    for (final sub in SubscriptionStats.billable(subs)) {
      monthly[sub.billingCycle] = (monthly[sub.billingCycle] ?? 0) + sub.monthlyCost;
      counts[sub.billingCycle] = (counts[sub.billingCycle] ?? 0) + 1;
    }
    return [
      for (final e in monthly.entries)
        (cycle: e.key, monthly: e.value, count: counts[e.key]!, share: total > 0 ? e.value / total : 0.0),
    ]..sort((a, b) => b.monthly.compareTo(a.monthly));
  }

  /// Paid subscriptions by monthly-equivalent cost, most expensive first.
  static List<Subscription> ranked(Iterable<Subscription> subs) {
    return SubscriptionStats.billable(subs).where((s) => s.price > 0).toList()
      ..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
  }

  /// The single most expensive subscription and its share of spend.
  static ({Subscription subscription, double share})? topExpense(Iterable<Subscription> subs) {
    final list = ranked(subs);
    final total = _total(subs);
    if (list.isEmpty || total <= 0) return null;
    return (subscription: list.first, share: list.first.monthlyCost / total);
  }

  /// Share of spend taken by the [top] most expensive subscriptions. Needs more than [top] of them.
  static ({int count, double share})? concentration(Iterable<Subscription> subs, {int top = 3}) {
    final list = ranked(subs);
    final total = _total(subs);
    if (list.length <= top || total <= 0) return null;
    final topTotal = list.take(top).fold(0.0, (sum, s) => sum + s.monthlyCost);
    return (count: top, share: topTotal / total);
  }

  /// The most expensive of the next [months] calendar months (after the current one).
  static MonthOutlook? heaviestMonthAhead(Iterable<Subscription> subs, {required DateTime now, int months = 12}) {
    final billable = SubscriptionStats.billable(subs).where((s) => s.price > 0);
    final first = DateTime(now.year, now.month + 1, 1);
    final charges = ChargeSchedule.between(
      billable,
      from: first,
      to: DateTime(now.year, now.month + 1 + months, 0),
      now: now,
      includePaid: false,
    );
    final byMonth = <DateTime, List<UpcomingCharge>>{};
    for (final c in charges) {
      (byMonth[DateTime(c.date.year, c.date.month, 1)] ??= []).add(c);
    }
    MonthOutlook? best;
    for (final e in byMonth.entries) {
      final total = e.value.dueTotal;
      if (best == null || total > best.total + 0.001) {
        best = (month: e.key, total: total, charges: [...e.value]..sort((a, b) => b.amount.compareTo(a.amount)));
      }
    }
    return best == null || best.total <= 0 ? null : best;
  }

  /// Yearly renewals due within [days], soonest first.
  static ({int count, double total, List<UpcomingCharge> charges})? yearlyRenewalsSoon(
    Iterable<Subscription> subs, {
    required DateTime now,
    int days = 90,
  }) {
    final charges = ChargeSchedule.annualRenewalsWithin(SubscriptionStats.billable(subs), now: now, days: days);
    if (charges.isEmpty) return null;
    return (count: charges.length, total: charges.fold(0.0, (sum, c) => sum + c.amount), charges: charges);
  }

  /// Monthly-equivalent cost of paused subscriptions (money not being spent).
  static ({double monthly, int count}) pausedSavings(Iterable<Subscription> subs) {
    final paused = subs.where((s) => s.status == SubscriptionStatus.paused);
    return (monthly: paused.fold(0.0, (sum, s) => sum + s.monthlyCost), count: paused.length);
  }

  /// Logged payments, newest first.
  static List<({Subscription subscription, DateTime date})> recentPayments(Iterable<Subscription> subs) {
    return [
      for (final sub in subs)
        for (final d in sub.paymentHistory) (subscription: sub, date: d),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }
}
