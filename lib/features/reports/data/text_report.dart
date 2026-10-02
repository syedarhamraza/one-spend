import '../../../models/spending_trend.dart';
import '../../currency/domain/money_format.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import '../../subscriptions/domain/services/spending_insights.dart';
import '../../subscriptions/domain/services/subscription_stats.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';

/// The plain-text spending summary (shared as text or copied from Analytics).
class TextReport {
  const TextReport._();

  /// [category] narrows the report to one category.
  static String build(SubscriptionController store, {SubscriptionCategory? category, DateTime? now}) {
  final currency = store.currency;
  String money(double v) => formatMoney(v, currency, style: MoneyStyle.summary);
  final subs = [
    for (final s in store.subscriptions)
      if (category == null || s.category == category) s,
  ];
  final monthly = SubscriptionStats.totalMonthlySpend(subs, store.toMain);

  final buffer = StringBuffer()
    ..writeln('OneSpend spending report')
    ..writeln('------------------------');
  if (category != null) buffer.writeln('Category: ${category.label}');
  buffer
    ..writeln('Yearly cost: ${money(monthly * 12)}')
    ..writeln('Monthly: ${money(monthly)}')
    ..writeln('Active subscriptions: ${SubscriptionStats.billable(subs).length}');

  final points = SpendingTrendsEngine.calculateTrends(
    subscriptions: subs,
    horizon: SpendingTrendHorizon.oneYear,
    referenceDate: now,
    toMain: store.toMain,
    trackingSince: store.trackingSince,
  );
  final summary = SpendingTrendsEngine.calculateSummary(points, monthlyBudget: store.monthlyBudget);
  if (summary.hasData && summary.currentMonth != null) {
    final diff = summary.latestMoMDifference;
    final sign = diff > 0.001 ? '+' : (diff < -0.001 ? '-' : '');
    buffer
      ..writeln('This month: ${money(summary.currentMonth!.amount)}')
      ..writeln('Month-over-month: $sign${money(diff.abs())} (${summary.latestMoMPercentage.abs().toStringAsFixed(1)}%)')
      ..writeln('Forecast, next ${summary.forecastMonths} months: ${money(summary.forecastTotal)}');
  }

  final categories = SpendingInsights.byCategory(subs, store.toMain);
  if (category == null && categories.isNotEmpty) {
    buffer.writeln('\nBy category:');
    for (final c in categories) {
      buffer.writeln('• ${c.category.label}: ${money(c.monthly)}/mo (${(c.share * 100).toStringAsFixed(0)}%)');
    }
  }
  final top = SpendingInsights.ranked(subs, store.toMain).take(5).toList();
  if (top.isNotEmpty) {
    buffer.writeln('\nTop subscriptions:');
    for (final s in top) {
      buffer.writeln('• ${s.name}: ${money(store.monthlyCostInMain(s))}/mo');
    }
  }
  return buffer.toString().trimRight();
}
}
