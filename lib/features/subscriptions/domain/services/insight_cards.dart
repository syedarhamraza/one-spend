import 'package:intl/intl.dart';

import '../../../../models/spending_trend.dart';
import '../entities/subscription.dart';
import 'spending_insights.dart';
import 'subscription_stats.dart';

/// How an insight reads: red, amber, green or blue on the card. Declared in priority order.
enum InsightTone { negative, caution, positive, info }

/// What the card's pill button does.
enum InsightAction { openSubscription, openUpcoming, showTrajectory, showTopSubscriptions, acknowledge }

/// One Digital Wellbeing style tip on the Analytics tab.
class InsightCardData {
  /// Identifies the situation (e.g. `all|over:2026-09`), so a dismissed tip returns when it changes.
  final String key;
  final InsightTone tone;
  final String title;
  final String message;
  final String actionLabel;
  final InsightAction action;
  final Subscription? subscription;

  const InsightCardData({
    required this.key,
    required this.tone,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.action,
    this.subscription,
  });
}

/// Builds the Analytics insight cards from the (possibly category-filtered) subscriptions.
class InsightCards {
  const InsightCards._();

  /// Month-over-month change that counts as notable: at least this share...
  static const double notableChangeShare = 0.10;

  /// ...and at least this amount.
  static const double notableChangeAmount = 5.0;

  /// A future month is "heavy" at this multiple of the average month.
  static const double heavyMonthFactor = 1.25;

  /// Yearly renewals within this many days get a heads-up.
  static const int yearlyHeadsUpDays = 30;

  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _monthName = DateFormat('MMMM');
  static final DateFormat _monthYear = DateFormat('MMMM y');

  static String _period(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Cards sorted by [InsightTone] priority. Budget cards need [includeBudget] and a budget.
  /// [categoryLabel] names the active category filter, if any.
  static List<InsightCardData> build(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    required String currency,
    double monthlyBudget = 0,
    bool includeBudget = true,
    String? categoryLabel,
  }) {
    final subs = subscriptions.toList();
    String money(double v) => '$currency${v.toStringAsFixed(2)}';
    final scope = categoryLabel ?? 'all';
    final month = _period(now);
    final today = DateTime(now.year, now.month, now.day);
    final monthly = SubscriptionStats.totalMonthlySpend(subs);
    final spending = categoryLabel == null ? 'your spending' : 'your $categoryLabel spending';
    final cards = <InsightCardData>[];

    // Budget
    if (includeBudget && monthlyBudget > 0.01 && monthly > 0) {
      if (monthly > monthlyBudget + 0.005) {
        cards.add(InsightCardData(
          key: '$scope|over:$month',
          tone: InsightTone.negative,
          title: 'You\'re ${money(monthly - monthlyBudget)} over budget',
          message: 'Subscriptions cost ${money(monthly)} a month, above your ${money(monthlyBudget)} budget.',
          actionLabel: 'Review subscriptions',
          action: InsightAction.showTopSubscriptions,
        ));
      } else {
        cards.add(InsightCardData(
          key: '$scope|under:$month',
          tone: InsightTone.positive,
          title: 'You\'re ${money(monthlyBudget - monthly)} under budget',
          message: 'Subscriptions use ${(monthly / monthlyBudget * 100).round()}% of your '
              '${money(monthlyBudget)} monthly budget.',
          actionLabel: 'Got it',
          action: InsightAction.acknowledge,
        ));
      }
    }

    // Month-over-month
    final points = SpendingTrendsEngine.calculateTrends(
      subscriptions: subs,
      horizon: SpendingTrendHorizon.sixMonths,
      referenceDate: now,
    );
    final currentIndex = points.indexWhere((p) => p.isCurrent);
    if (currentIndex > 0) {
      final current = points[currentIndex];
      final previous = points[currentIndex - 1];
      final diff = current.amount - previous.amount;
      final share = previous.amount > 0 ? diff / previous.amount : 0.0;
      final previousName = _monthName.format(previous.month);
      if (previous.amount > 0 && diff >= notableChangeAmount && share >= notableChangeShare) {
        final driver = _biggestIncrease(previous, current);
        cards.add(InsightCardData(
          key: '$scope|up:$month',
          tone: InsightTone.negative,
          title: 'Spending is up ${(share * 100).round()}% this month',
          message: '${money(diff)} more than $previousName${driver == null ? '' : ', led by ${driver.name}'}.',
          actionLabel: 'See trajectory',
          action: InsightAction.showTrajectory,
        ));
      } else if (previous.amount > 0 && -diff >= notableChangeAmount && -share >= notableChangeShare) {
        cards.add(InsightCardData(
          key: '$scope|down:$month',
          tone: InsightTone.positive,
          title: 'Spending is down ${(-share * 100).round()}% this month',
          message: '${money(-diff)} less than $previousName. Nice work.',
          actionLabel: 'Got it',
          action: InsightAction.acknowledge,
        ));
      }
    }

    // Yearly renewal heads-up
    final yearly = SpendingInsights.yearlyRenewalsSoon(subs, now: now, days: yearlyHeadsUpDays);
    if (yearly != null) {
      final charge = yearly.charges.first;
      final sub = charge.subscription;
      final days = charge.date.difference(today).inDays;
      final when = switch (days) {
        <= 0 => 'today',
        1 => 'tomorrow',
        _ => 'in $days days',
      };
      cards.add(InsightCardData(
        key: '$scope|yearly:${sub.id}:${charge.date.toIso8601String().substring(0, 10)}',
        tone: InsightTone.caution,
        title: '${sub.name} renews $when',
        message: '${money(charge.amount)} on ${_monthDay.format(charge.date)}. '
            'Cancel before then if you don\'t need it.',
        actionLabel: 'View subscription',
        action: InsightAction.openSubscription,
        subscription: sub,
      ));
    }

    // Heavy month ahead
    final heaviest = SpendingInsights.heaviestMonthAhead(subs, now: now);
    if (heaviest != null &&
        monthly > 0 &&
        heaviest.total >= monthly * heavyMonthFactor &&
        heaviest.total - monthly >= notableChangeAmount) {
      final name = heaviest.month.year == now.year ? _monthName.format(heaviest.month) : _monthYear.format(heaviest.month);
      final top = heaviest.charges.first;
      cards.add(InsightCardData(
        key: '$scope|heavy:${_period(heaviest.month)}',
        tone: InsightTone.caution,
        title: '$name will be a heavy month',
        message: heaviest.charges.length > 1
            ? '${money(heaviest.total)} is due, including ${top.subscription.name} ${money(top.amount)}.'
            : '${money(heaviest.total)} is due for ${top.subscription.name}.',
        actionLabel: 'Open Upcoming',
        action: InsightAction.openUpcoming,
      ));
    }

    // Paused savings
    final paused = SpendingInsights.pausedSavings(subs);
    if (paused.count > 0 && paused.monthly > 0) {
      cards.add(InsightCardData(
        key: '$scope|paused:${paused.count}:${paused.monthly.toStringAsFixed(2)}',
        tone: InsightTone.positive,
        title: 'Pausing saves ${money(paused.monthly)} a month',
        message: '${paused.count} paused subscription${paused.count == 1 ? '' : 's'}, '
            '${money(paused.monthly * 12)} a year.',
        actionLabel: 'Got it',
        action: InsightAction.acknowledge,
      ));
    }

    // Top expense
    final ranked = SpendingInsights.ranked(subs);
    final top = SpendingInsights.topExpense(subs);
    if (top != null && ranked.length > 1) {
      cards.add(InsightCardData(
        key: '$scope|top:${top.subscription.id}',
        tone: InsightTone.info,
        title: '${top.subscription.name} is ${(top.share * 100).round()}% of $spending',
        message: 'That\'s ${money(top.subscription.yearlyCost)} a year.',
        actionLabel: 'View ${top.subscription.name}',
        action: InsightAction.openSubscription,
        subscription: top.subscription,
      ));
    }

    // Stable sort by tone priority (insertion order breaks ties).
    final indexed = cards.indexed.toList()
      ..sort((a, b) {
        final byTone = a.$2.tone.index.compareTo(b.$2.tone.index);
        return byTone != 0 ? byTone : a.$1.compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }

  /// The subscription whose charge grew the most from [previous] to [current].
  static Subscription? _biggestIncrease(MonthlySpendPoint previous, MonthlySpendPoint current) {
    final before = {for (final c in previous.topCharges) c.subscription.id: c.amount};
    Subscription? best;
    var bestDelta = 0.0;
    for (final c in current.topCharges) {
      final delta = c.amount - (before[c.subscription.id] ?? 0);
      if (delta > bestDelta + 0.001) {
        bestDelta = delta;
        best = c.subscription;
      }
    }
    return best;
  }
}
