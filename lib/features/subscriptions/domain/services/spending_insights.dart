import '../../../currency/domain/exchange_rates.dart';
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
///
/// Totals are in the main currency via `toMain`; [UpcomingCharge.amount] stays in the
/// subscription's own currency.
class SpendingInsights {
  const SpendingInsights._();

  static double _total(Iterable<Subscription> subs, ToMainCurrency toMain) =>
      SubscriptionStats.totalMonthlySpend(subs, toMain);

  /// Spend per category, largest first. Shares sum to 1 when anything is spent.
  static List<CategorySpend> byCategory(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    final total = _total(subs, toMain);
    final monthly = <SubscriptionCategory, double>{};
    final counts = <SubscriptionCategory, int>{};
    for (final sub in SubscriptionStats.billable(subs)) {
      monthly[sub.category] = (monthly[sub.category] ?? 0) + SubscriptionStats.monthlyCost(sub, toMain);
      counts[sub.category] = (counts[sub.category] ?? 0) + 1;
    }
    return [
      for (final e in monthly.entries)
        (category: e.key, monthly: e.value, count: counts[e.key]!, share: total > 0 ? e.value / total : 0.0),
    ]..sort((a, b) => b.monthly.compareTo(a.monthly));
  }

  /// Spend per billing cycle, largest first.
  static List<CycleSpend> byCycle(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    final total = _total(subs, toMain);
    final monthly = <BillingCycle, double>{};
    final counts = <BillingCycle, int>{};
    for (final sub in SubscriptionStats.billable(subs)) {
      monthly[sub.billingCycle] = (monthly[sub.billingCycle] ?? 0) + SubscriptionStats.monthlyCost(sub, toMain);
      counts[sub.billingCycle] = (counts[sub.billingCycle] ?? 0) + 1;
    }
    return [
      for (final e in monthly.entries)
        (cycle: e.key, monthly: e.value, count: counts[e.key]!, share: total > 0 ? e.value / total : 0.0),
    ]..sort((a, b) => b.monthly.compareTo(a.monthly));
  }

  /// Paid subscriptions by monthly-equivalent cost, most expensive first.
  static List<Subscription> ranked(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    double cost(Subscription s) => SubscriptionStats.monthlyCost(s, toMain);
    return SubscriptionStats.billable(subs).where((s) => s.price > 0).toList()
      ..sort((a, b) => cost(b).compareTo(cost(a)));
  }

  /// The single most expensive subscription and its share of spend.
  static ({Subscription subscription, double share})? topExpense(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    final list = ranked(subs, toMain);
    final total = _total(subs, toMain);
    if (list.isEmpty || total <= 0) return null;
    return (subscription: list.first, share: SubscriptionStats.monthlyCost(list.first, toMain) / total);
  }

  /// Share of spend taken by the [top] most expensive subscriptions. Needs more than [top] of them.
  static ({int count, double share})? concentration(
    Iterable<Subscription> subs, {
    int top = 3,
    ToMainCurrency toMain = sameCurrency,
  }) {
    final list = ranked(subs, toMain);
    final total = _total(subs, toMain);
    if (list.length <= top || total <= 0) return null;
    final topTotal = list.take(top).fold(0.0, (sum, s) => sum + SubscriptionStats.monthlyCost(s, toMain));
    return (count: top, share: topTotal / total);
  }

  /// The most expensive of the next [months] calendar months (after the current one).
  static MonthOutlook? heaviestMonthAhead(
    Iterable<Subscription> subs, {
    required DateTime now,
    int months = 12,
    ToMainCurrency toMain = sameCurrency,
  }) {
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
      final total = e.value.dueTotal(toMain);
      if (best == null || total > best.total + 0.001) {
        best = (
          month: e.key,
          total: total,
          charges: [...e.value]..sort((a, b) => toMain(b.amount, b.currency).compareTo(toMain(a.amount, a.currency))),
        );
      }
    }
    return best == null || best.total <= 0 ? null : best;
  }

  /// Yearly renewals due within [days], soonest first.
  static ({int count, double total, List<UpcomingCharge> charges})? yearlyRenewalsSoon(
    Iterable<Subscription> subs, {
    required DateTime now,
    int days = 90,
    ToMainCurrency toMain = sameCurrency,
  }) {
    final charges = ChargeSchedule.annualRenewalsWithin(SubscriptionStats.billable(subs), now: now, days: days);
    if (charges.isEmpty) return null;
    return (count: charges.length, total: charges.fold(0.0, (sum, c) => sum + toMain(c.amount, c.currency)), charges: charges);
  }

  /// Monthly-equivalent cost of paused subscriptions (money not being spent).
  static ({double monthly, int count}) pausedSavings(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    final paused = subs.where((s) => s.status == SubscriptionStatus.paused);
    return (monthly: paused.fold(0.0, (sum, s) => sum + SubscriptionStats.monthlyCost(s, toMain)), count: paused.length);
  }

  /// Logged payments, newest first.
  static List<({Subscription subscription, DateTime date})> recentPayments(Iterable<Subscription> subs) {
    return [
      for (final sub in subs)
        for (final d in sub.paymentHistory) (subscription: sub, date: d),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }
}
