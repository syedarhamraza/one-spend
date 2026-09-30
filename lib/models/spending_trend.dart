import 'package:intl/intl.dart';
import '../features/currency/domain/exchange_rates.dart';
import '../features/subscriptions/domain/entities/subscription.dart';
import '../features/subscriptions/domain/entities/subscription_enums.dart';
import '../features/subscriptions/domain/services/charge_schedule.dart';

/// Ranges for the spending trajectory chart. Each range shows past months, the current
/// month and a forecast, so the chart always reads "where I was → where I'm heading".
enum SpendingTrendHorizon {
  sixMonths('6M', 'Last 3 months · next 2', 3, 2),
  oneYear('1Y', 'Last 6 months · next 5', 6, 5),
  twoYears('2Y', 'Last 12 months · next 11', 12, 11);

  final String label;
  final String title;
  final int pastMonths;
  final int futureMonths;
  const SpendingTrendHorizon(this.label, this.title, this.pastMonths, this.futureMonths);

  int get monthCount => pastMonths + 1 + futureMonths;
}

/// One subscription's contribution to a month.
typedef MonthCharge = ({Subscription subscription, double amount});

/// Represents spending data for a single calendar month
class MonthlySpendPoint {
  final DateTime month;
  final String label; // e.g. "Apr"
  final String fullLabel; // e.g. "April 2026"
  final double amount;
  final double? previousAmount;
  final double momPercentage; // e.g. +4.5% or -2.1%
  final double momDifference; // amount - previousAmount
  final int renewalCount;

  /// The current month or later (partly or fully forecast).
  final bool isProjected;

  /// The calendar month containing the reference date.
  final bool isCurrent;
  final Map<SubscriptionCategory, double> categoryBreakdown;

  /// Per-subscription totals for the month, largest first.
  final List<MonthCharge> topCharges;

  const MonthlySpendPoint({
    required this.month,
    required this.label,
    required this.fullLabel,
    required this.amount,
    this.previousAmount,
    required this.momPercentage,
    required this.momDifference,
    required this.renewalCount,
    required this.isProjected,
    this.isCurrent = false,
    required this.categoryBreakdown,
    this.topCharges = const [],
  });

  bool get isIncrease => momDifference > 0.001;
  bool get isDecrease => momDifference < -0.001;
  bool get isNeutral => !isIncrease && !isDecrease;

  /// Strictly after the current month.
  bool get isForecast => isProjected && !isCurrent;
}

/// Overall trajectory summary across a given horizon
class TrendSummary {
  /// Average over every point in the range.
  final double averageMonthlySpend;

  /// Average over months before the current one (0 when there are none).
  final double pastAverage;

  /// Sum of the months after the current one.
  final double forecastTotal;
  final int forecastMonths;

  /// Months whose total exceeds the monthly budget (0 without a budget).
  final int overBudgetCount;
  final MonthlySpendPoint? peakMonth;
  final MonthlySpendPoint? lowestMonth;

  /// The most expensive month after the current one.
  final MonthlySpendPoint? heaviestForecast;
  final MonthlySpendPoint? currentMonth;

  /// Month-over-month change of the current month.
  final double latestMoMPercentage;
  final double latestMoMDifference;
  final bool hasData;

  const TrendSummary({
    required this.averageMonthlySpend,
    this.pastAverage = 0.0,
    this.forecastTotal = 0.0,
    this.forecastMonths = 0,
    this.overBudgetCount = 0,
    this.peakMonth,
    this.lowestMonth,
    this.heaviestForecast,
    this.currentMonth,
    required this.latestMoMPercentage,
    required this.latestMoMDifference,
    required this.hasData,
  });

  static const empty = TrendSummary(
    averageMonthlySpend: 0.0,
    latestMoMPercentage: 0.0,
    latestMoMDifference: 0.0,
    hasData: false,
  );
}

/// Calculation Engine for Month-over-Month Spending Trends and Trajectory
class SpendingTrendsEngine {
  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _fullMonthFormat = DateFormat('MMMM yyyy');

  /// Computes one point per calendar month in [horizon] around [referenceDate].
  ///
  /// - **Past months** use logged `paymentHistory`; a subscription with no history at all
  ///   contributes its `monthlyCost` as an estimate.
  /// - **Current and future months** use payments already logged in the month plus the
  ///   unpaid charges from [ChargeSchedule], so the forecast matches the Upcoming tab.
  ///
  /// Paused, free-trial and free subscriptions are excluded. Amounts are converted to the
  /// main currency with [toMain].
  static List<MonthlySpendPoint> calculateTrends({
    required List<Subscription> subscriptions,
    required SpendingTrendHorizon horizon,
    DateTime? referenceDate,
    ToMainCurrency toMain = sameCurrency,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final months = [
      for (var i = -horizon.pastMonths; i <= horizon.futureMonths; i++) DateTime(now.year, now.month + i, 1),
    ];

    final activeSubs = subscriptions
        .where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial && s.price > 0)
        .toList();

    // Unpaid charges from the start of this month to the end of the range, bucketed by month.
    final lastMonth = months.last;
    final scheduled = ChargeSchedule.between(
      activeSubs,
      from: currentMonthStart,
      to: DateTime(lastMonth.year, lastMonth.month + 1, 0),
      now: now,
      includePaid: false,
    );
    final scheduledByMonth = <DateTime, List<UpcomingCharge>>{};
    for (final c in scheduled) {
      (scheduledByMonth[DateTime(c.date.year, c.date.month, 1)] ??= []).add(c);
    }

    final List<MonthlySpendPoint> points = [];
    double? lastAmount;

    for (final monthDate in months) {
      final isPast = monthDate.isBefore(currentMonthStart);
      final perSub = <String, ({Subscription subscription, double amount, int count})>{};
      void add(Subscription sub, double amount, int count) {
        final current = perSub[sub.id];
        perSub[sub.id] = (
          subscription: sub,
          amount: (current?.amount ?? 0) + toMain(amount, sub.currency),
          count: (current?.count ?? 0) + count,
        );
      }

      for (final sub in activeSubs) {
        final logged = sub.paymentHistory.where((d) => d.year == monthDate.year && d.month == monthDate.month).length;
        if (logged > 0) {
          add(sub, logged * sub.price, logged);
        } else if (isPast && sub.paymentHistory.isEmpty) {
          add(sub, sub.monthlyCost, 1);
        }
      }
      if (!isPast) {
        for (final c in scheduledByMonth[monthDate] ?? const <UpcomingCharge>[]) {
          add(c.subscription, c.amount, 1);
        }
      }
      if (monthDate == currentMonthStart) {
        // Like the past-month estimate: a subscription with no history at all that already
        // renewed earlier this month still counts, otherwise the current month dips to zero.
        final today = DateTime(now.year, now.month, now.day);
        for (final sub in activeSubs) {
          if (sub.paymentHistory.isNotEmpty) continue;
          final earlier = _cycleDatesBefore(sub, from: currentMonthStart, until: today);
          if (earlier > 0) add(sub, earlier * sub.price, earlier);
        }
      }

      final charges = [for (final v in perSub.values) (subscription: v.subscription, amount: v.amount)]
        ..sort((a, b) => b.amount.compareTo(a.amount));
      final monthTotal = charges.fold(0.0, (sum, c) => sum + c.amount);
      final renewalCount = perSub.values.fold(0, (sum, v) => sum + v.count);
      final catBreakdown = <SubscriptionCategory, double>{};
      for (final c in charges) {
        catBreakdown[c.subscription.category] = (catBreakdown[c.subscription.category] ?? 0.0) + c.amount;
      }

      // Month-over-month deltas
      double momPct = 0.0;
      double momDiff = 0.0;
      if (lastAmount != null) {
        momDiff = monthTotal - lastAmount;
        if (lastAmount > 0.001) {
          momPct = ((monthTotal - lastAmount) / lastAmount) * 100;
        } else if (monthTotal > 0.001) {
          momPct = 100.0;
        }
      }

      points.add(MonthlySpendPoint(
        month: monthDate,
        label: _shortMonthFormat.format(monthDate),
        fullLabel: _fullMonthFormat.format(monthDate),
        amount: monthTotal,
        previousAmount: lastAmount,
        momPercentage: momPct,
        momDifference: momDiff,
        renewalCount: renewalCount,
        isProjected: !isPast,
        isCurrent: monthDate == currentMonthStart,
        categoryBreakdown: catBreakdown,
        topCharges: charges,
      ));

      lastAmount = monthTotal;
    }

    return points;
  }

  /// Number of billing dates of [sub] in `[from, until)`, stepping back from its next due date.
  static int _cycleDatesBefore(Subscription sub, {required DateTime from, required DateTime until}) {
    var count = 0;
    var date = DateTime(sub.nextBillingDate.year, sub.nextBillingDate.month, sub.nextBillingDate.day);
    for (var i = 0; i < 60; i++) {
      final anchor = sub.anchorDay ?? sub.nextBillingDate.day;
      date = switch (sub.billingCycle) {
        BillingCycle.weekly => DateTime(date.year, date.month, date.day - 7),
        BillingCycle.monthly => _clampedDay(date.year, date.month - 1, anchor),
        BillingCycle.quarterly => _clampedDay(date.year, date.month - 3, anchor),
        BillingCycle.yearly => _clampedDay(date.year - 1, date.month, anchor),
      };
      if (date.isBefore(from)) break;
      if (date.isBefore(until)) count++;
    }
    return count;
  }

  static DateTime _clampedDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }

  /// Statistical summary across [points]; pass [monthlyBudget] to count over-budget months.
  static TrendSummary calculateSummary(List<MonthlySpendPoint> points, {double monthlyBudget = 0}) {
    if (points.isEmpty) return TrendSummary.empty;

    double sum = 0.0;
    double pastSum = 0.0;
    int pastCount = 0;
    double forecastSum = 0.0;
    int forecastCount = 0;
    int overBudget = 0;
    MonthlySpendPoint? peak;
    MonthlySpendPoint? lowest;
    MonthlySpendPoint? heaviest;
    MonthlySpendPoint? current;

    for (final p in points) {
      sum += p.amount;
      if (peak == null || p.amount > peak.amount) peak = p;
      if (lowest == null || p.amount < lowest.amount) lowest = p;
      if (!p.isProjected) {
        pastSum += p.amount;
        pastCount++;
      }
      if (p.isForecast) {
        forecastSum += p.amount;
        forecastCount++;
        if (heaviest == null || p.amount > heaviest.amount) heaviest = p;
      }
      if (p.isCurrent) current = p;
      if (monthlyBudget > 0.01 && p.amount > monthlyBudget + 0.001) overBudget++;
    }

    final latest = current ?? points.last;

    return TrendSummary(
      averageMonthlySpend: sum / points.length,
      pastAverage: pastCount == 0 ? 0.0 : pastSum / pastCount,
      forecastTotal: forecastSum,
      forecastMonths: forecastCount,
      overBudgetCount: overBudget,
      peakMonth: peak,
      lowestMonth: lowest,
      heaviestForecast: heaviest,
      currentMonth: current,
      latestMoMPercentage: latest.momPercentage,
      latestMoMDifference: latest.momDifference,
      hasData: sum > 0.001,
    );
  }
}
