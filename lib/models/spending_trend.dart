import 'package:intl/intl.dart';
import 'subscription.dart';

/// Supported time horizons for the spending trends chart
enum SpendingTrendHorizon {
  sixMonths('6M', 'Past 6 Months', 6),
  oneYear('1Y', 'Past 12 Months', 12),
  forecastSixMonths('Forecast', 'Next 6 Months', 6);

  final String label;
  final String title;
  final int monthCount;
  const SpendingTrendHorizon(this.label, this.title, this.monthCount);
}

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
  final bool isProjected;
  final Map<SubscriptionCategory, double> categoryBreakdown;

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
    required this.categoryBreakdown,
  });

  bool get isIncrease => momDifference > 0.001;
  bool get isDecrease => momDifference < -0.001;
  bool get isNeutral => !isIncrease && !isDecrease;
}

/// Overall trajectory summary across a given horizon
class TrendSummary {
  final double averageMonthlySpend;
  final MonthlySpendPoint? peakMonth;
  final MonthlySpendPoint? lowestMonth;
  final double latestMoMPercentage;
  final double latestMoMDifference;
  final bool hasData;

  const TrendSummary({
    required this.averageMonthlySpend,
    this.peakMonth,
    this.lowestMonth,
    required this.latestMoMPercentage,
    required this.latestMoMDifference,
    required this.hasData,
  });

  static const empty = TrendSummary(
    averageMonthlySpend: 0.0,
    peakMonth: null,
    lowestMonth: null,
    latestMoMPercentage: 0.0,
    latestMoMDifference: 0.0,
    hasData: false,
  );
}

/// Calculation Engine for Month-over-Month Spending Trends and Trajectory
class SpendingTrendsEngine {
  static final DateFormat _shortMonthFormat = DateFormat('MMM');
  static final DateFormat _fullMonthFormat = DateFormat('MMMM yyyy');

  /// Computes month-over-month data points for the given subscriptions and horizon
  static List<MonthlySpendPoint> calculateTrends({
    required List<Subscription> subscriptions,
    required SpendingTrendHorizon horizon,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);

    // Build the list of target months (first day of each calendar month)
    final List<DateTime> months = [];
    if (horizon == SpendingTrendHorizon.forecastSixMonths) {
      // Current month and next 5 months (6 total)
      for (int i = 0; i < horizon.monthCount; i++) {
        final targetMonth = currentMonthStart.month + i;
        final targetYear = currentMonthStart.year + ((targetMonth - 1) ~/ 12);
        final normalizedMonth = ((targetMonth - 1) % 12) + 1;
        months.add(DateTime(targetYear, normalizedMonth, 1));
      }
    } else {
      // Past N-1 months up to current month (e.g. 6 or 12 total)
      for (int i = horizon.monthCount - 1; i >= 0; i--) {
        // Correct year and month for negative offset
        int y = currentMonthStart.year;
        int m = currentMonthStart.month - i;
        while (m <= 0) {
          m += 12;
          y -= 1;
        }
        months.add(DateTime(y, m, 1));
      }
    }

    final activeSubs = subscriptions.where((s) =>
        s.status != SubscriptionStatus.paused &&
        s.status != SubscriptionStatus.trial &&
        s.price > 0).toList();

    final List<MonthlySpendPoint> points = [];
    double? lastAmount;

    for (final monthDate in months) {
      final isFutureOrCurrent = !monthDate.isBefore(currentMonthStart);
      final isStrictlyPast = monthDate.isBefore(currentMonthStart);

      double monthTotal = 0.0;
      int renewalCount = 0;
      final Map<SubscriptionCategory, double> catBreakdown = {};

      for (final sub in activeSubs) {
        // 1. Check explicit paymentHistory for this month
        final loggedInMonth = sub.paymentHistory.where((d) =>
            d.year == monthDate.year && d.month == monthDate.month).toList();

        if (loggedInMonth.isNotEmpty) {
          final paidAmount = loggedInMonth.length * sub.price;
          monthTotal += paidAmount;
          renewalCount += loggedInMonth.length;
          catBreakdown[sub.category] = (catBreakdown[sub.category] ?? 0.0) + paidAmount;
        } else if (isStrictlyPast) {
          // If no explicit log in this past month, use regular recurring baseline
          // if this subscription has no recorded payments at all in the past
          if (sub.paymentHistory.isEmpty) {
            final cost = sub.monthlyCost;
            monthTotal += cost;
            renewalCount += 1;
            catBreakdown[sub.category] = (catBreakdown[sub.category] ?? 0.0) + cost;
          }
        } else {
          // Current or future projected month:
          // Calculate occurrences based on billing cycle
          final occurrences = _calculateOccurrencesInMonth(sub, monthDate);
          if (occurrences > 0) {
            final charge = sub.price * occurrences;
            monthTotal += charge;
            renewalCount += occurrences;
            catBreakdown[sub.category] = (catBreakdown[sub.category] ?? 0.0) + charge;
          }
        }
      }

      // Calculate Month-over-Month deltas
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
        isProjected: isFutureOrCurrent,
        categoryBreakdown: catBreakdown,
      ));

      lastAmount = monthTotal;
    }

    return points;
  }

  /// Calculates how many billing occurrences of a subscription fall in a target calendar month
  static int _calculateOccurrencesInMonth(Subscription sub, DateTime targetMonth) {
    final monthStart = DateTime(targetMonth.year, targetMonth.month, 1);
    final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

    switch (sub.billingCycle) {
      case BillingCycle.monthly:
        return 1;

      case BillingCycle.weekly:
        // Project weekly recurrences
        int count = 0;
        DateTime cur = sub.nextBillingDate;
        // Align backward or forward into the window
        while (cur.isAfter(monthEnd)) {
          cur = cur.subtract(const Duration(days: 7));
        }
        while (cur.isBefore(monthStart)) {
          cur = cur.add(const Duration(days: 7));
        }
        while (cur.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
            cur.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
          count++;
          cur = cur.add(const Duration(days: 7));
        }
        return count > 0 ? count : 4; // Default to ~4 weekly cycles if outside bounds

      case BillingCycle.quarterly:
        // Hits every 3 months from next billing date
        final diffMonths = (targetMonth.year - sub.nextBillingDate.year) * 12 +
            (targetMonth.month - sub.nextBillingDate.month);
        return (diffMonths % 3 == 0) ? 1 : 0;

      case BillingCycle.yearly:
        // Hits in the same month of the year
        return (sub.nextBillingDate.month == targetMonth.month) ? 1 : 0;
    }
  }

  /// Calculates statistical trajectory summary across a list of points
  static TrendSummary calculateSummary(List<MonthlySpendPoint> points) {
    if (points.isEmpty) return TrendSummary.empty;

    double sum = 0.0;
    MonthlySpendPoint? peak;
    MonthlySpendPoint? lowest;

    for (final p in points) {
      sum += p.amount;
      if (peak == null || p.amount > peak.amount) {
        peak = p;
      }
      if (lowest == null || p.amount < lowest.amount) {
        lowest = p;
      }
    }

    final avg = sum / points.length;
    final latest = points.last;

    return TrendSummary(
      averageMonthlySpend: avg,
      peakMonth: peak,
      lowestMonth: lowest,
      latestMoMPercentage: latest.momPercentage,
      latestMoMDifference: latest.momDifference,
      hasData: sum > 0.001,
    );
  }
}
