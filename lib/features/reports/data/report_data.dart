import '../../../models/spending_trend.dart';
import '../../currency/domain/money_format.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import '../../subscriptions/domain/services/charge_schedule.dart';
import '../../subscriptions/domain/services/spending_insights.dart';
import '../../subscriptions/domain/services/subscription_stats.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../../subscriptions/presentation/utils/subscription_ui_adapters.dart';

/// One month in the report's spending chart.
typedef ReportMonth = ({DateTime month, double amount, bool isCurrent, bool isForecast});

/// One category in the report's breakdown.
typedef ReportCategory = ({String label, int colorValue, double monthly, double share, int count});

/// One charge (upcoming or paid) in the report's tables, in its own currency.
typedef ReportCharge = ({DateTime date, String name, double amount, String currency, double amountInMain});

/// Everything the PDF spending report shows, gathered from the store with the
/// same rules as the app (stats, trajectory, Upcoming schedule), so the report
/// and the screens always agree. Building it is pure: no I/O.
class SpendingReportData {
  final DateTime generatedAt;

  /// Main currency code; totals are converted into it.
  final String currency;

  /// Set when the report covers one category only.
  final String? categoryLabel;
  final double monthly;
  final double yearly;
  final int activeCount;
  final int pausedCount;
  final double monthlyBudget;
  final List<ReportCategory> categories;
  final List<ReportMonth> months;
  final List<Subscription> subscriptions;
  final List<ReportCharge> upcoming;
  final List<ReportCharge> payments;

  /// Converts an amount in [code] into [currency].
  final double Function(double amount, String code) toMain;

  const SpendingReportData({
    required this.generatedAt,
    required this.currency,
    this.categoryLabel,
    required this.monthly,
    required this.yearly,
    required this.activeCount,
    required this.pausedCount,
    required this.monthlyBudget,
    required this.categories,
    required this.months,
    required this.subscriptions,
    required this.upcoming,
    required this.payments,
    required this.toMain,
  });

  /// Days of upcoming charges the report lists.
  static const int upcomingDays = 30;

  /// Months of payment history the report lists.
  static const int historyMonths = 12;

  double get paymentsTotal => payments.fold(0.0, (sum, c) => sum + c.amountInMain);

  String money(double amount, [String? code]) => formatMoney(amount, code ?? currency, style: MoneyStyle.exact);

  /// Collects the report for every subscription, or just [category].
  factory SpendingReportData.fromStore(
    SubscriptionController store, {
    SubscriptionCategory? category,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final today = DateTime(at.year, at.month, at.day);
    final toMain = store.toMain;
    final subs = [
      for (final s in store.subscriptions)
        if (category == null || s.category == category) s,
    ];
    final monthly = SubscriptionStats.totalMonthlySpend(subs, toMain);

    final points = SpendingTrendsEngine.calculateTrends(
      subscriptions: subs,
      horizon: SpendingTrendHorizon.oneYear,
      referenceDate: at,
      toMain: toMain,
      trackingSince: store.trackingSince,
    );

    final upcoming = ChargeSchedule.between(
      SubscriptionStats.billable(subs),
      from: today,
      to: today.add(const Duration(days: upcomingDays)),
      now: at,
      includePaid: false,
    );

    final historyStart = DateTime(today.year, today.month - historyMonths + 1, 1);
    final payments = <ReportCharge>[
      for (final s in subs)
        for (final d in s.paymentHistory)
          if (!d.isBefore(historyStart) && !d.isAfter(at))
            (date: d, name: s.name, amount: s.price, currency: s.currency, amountInMain: toMain(s.price, s.currency)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return SpendingReportData(
      generatedAt: at,
      currency: store.currency,
      categoryLabel: category?.label,
      monthly: monthly,
      yearly: monthly * 12,
      activeCount: SubscriptionStats.billable(subs).length,
      pausedCount: SubscriptionStats.pausedCount(subs),
      monthlyBudget: category == null ? store.monthlyBudget : 0,
      categories: [
        for (final c in SpendingInsights.byCategory(subs, toMain))
          (label: c.category.label, colorValue: c.category.color.toARGB32(), monthly: c.monthly, share: c.share, count: c.count),
      ],
      months: [
        for (final p in points) (month: p.month, amount: p.amount, isCurrent: p.isCurrent, isForecast: p.isForecast),
      ],
      // Billed subscriptions by cost, then paused and free ones.
      subscriptions: [
        ...SpendingInsights.ranked(subs, toMain),
        for (final s in subs)
          if (!SpendingInsights.ranked([s], toMain).contains(s)) s,
      ],
      upcoming: [
        for (final c in upcoming)
          (
            date: c.date,
            name: c.subscription.name,
            amount: c.amount,
            currency: c.currency,
            amountInMain: toMain(c.amount, c.currency),
          ),
      ],
      payments: payments,
      toMain: toMain,
    );
  }
}
