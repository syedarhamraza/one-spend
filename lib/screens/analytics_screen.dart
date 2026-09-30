import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/router/app_router.dart';
import '../features/subscriptions/domain/services/spending_insights.dart';
import '../features/subscriptions/domain/services/subscription_stats.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_analytics_hero_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_category_ring.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_spending_chart.dart';
import '../widgets/one_ui_toast.dart';

/// Analytics tab: answers "what am I spending, where is it going, and what's next?".
///
/// Tapping a category filters the whole page (hero, trajectory, insights, lists) until the
/// filter pill is dismissed.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  /// Plain-text report for sharing; [category] narrows it to one category.
  static String buildReport(SubscriptionStore store, {SubscriptionCategory? category, DateTime? now}) {
    final currency = store.currency;
    String money(double v) => '$currency${v.toStringAsFixed(2)}';
    final subs = [
      for (final s in store.subscriptions)
        if (category == null || s.category == category) s,
    ];
    final monthly = SubscriptionStats.totalMonthlySpend(subs);

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

    final categories = SpendingInsights.byCategory(subs);
    if (category == null && categories.isNotEmpty) {
      buffer.writeln('\nBy category:');
      for (final c in categories) {
        buffer.writeln('• ${c.category.label}: ${money(c.monthly)}/mo (${(c.share * 100).toStringAsFixed(0)}%)');
      }
    }
    final top = SpendingInsights.ranked(subs).take(5).toList();
    if (top.isNotEmpty) {
      buffer.writeln('\nTop subscriptions:');
      for (final s in top) {
        buffer.writeln('• ${s.name}: ${money(s.monthlyCost)}/mo');
      }
    }
    return buffer.toString().trimRight();
  }

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _monthDayYear = DateFormat('MMM d, y');
  static final DateFormat _monthName = DateFormat('MMMM');

  static const int _topLimit = 5;
  static const int _paymentsLimit = 6;

  static const Map<BillingCycle, Color> _cycleColors = {
    BillingCycle.monthly: OneUITheme.accentBlue,
    BillingCycle.yearly: OneUITheme.accentGreen,
    BillingCycle.quarterly: OneUITheme.accentPurple,
    BillingCycle.weekly: OneUITheme.accentAmber,
  };

  final GlobalKey _headerActionsKey = GlobalKey();

  SubscriptionCategory? _category;
  bool _showAllTop = false;

  String _money(String currency, double amount) => '$currency${amount.toStringAsFixed(2)}';
  String _percent(double share) => '${(share * 100).round()}%';
  String _plural(int count, String noun) => '$count $noun${count == 1 ? '' : 's'}';

  void _setCategory(SubscriptionCategory? category) {
    HapticFeedback.selectionClick();
    setState(() {
      _category = category;
      _showAllTop = false;
    });
  }

  void _openSubscription(Subscription sub) {
    HapticFeedback.lightImpact();
    context.push(AppRoutes.subscriptionDetail(sub.id));
  }

  // --- Report ----------------------------------------------------------------

  Future<void> _shareReport(SubscriptionStore store) async {
    final report = AnalyticsScreen.buildReport(store, category: _category);
    try {
      await SharePlus.instance.share(ShareParams(text: report, subject: 'OneSpend spending report'));
    } catch (_) {
      if (mounted) OneUIToast.show(context, 'Couldn\'t open the share sheet');
    }
  }

  void _copyReport(SubscriptionStore store) {
    Clipboard.setData(ClipboardData(text: AnalyticsScreen.buildReport(store, category: _category)));
    OneUIToast.show(context, 'Report copied to clipboard');
  }

  void _showMoreMenu(SubscriptionStore store) {
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _headerActionsKey,
      fallbackTop: MediaQuery.of(context).padding.top + 6.0,
      width: 220,
      items: [
        OneUIFloatingMenuItem(label: 'Share report', onTap: () => _shareReport(store)),
        OneUIFloatingMenuItem(label: 'Copy report', onTap: () => _copyReport(store)),
      ],
    );
  }

  // --- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([SubscriptionStore.instance, OneUIEffectsController.instance]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final all = store.subscriptions;

        // Drop the filter if its last subscription was deleted.
        if (_category != null && !all.any((s) => s.category == _category)) _category = null;
        final category = _category;
        final subs = category == null ? all : [for (final s in all) if (s.category == category) s];
        final monthly = SubscriptionStats.totalMonthlySpend(subs);

        final subtitle = category == null
            ? '${_money(store.currency, monthly)}/mo · ${store.totalActiveCount} active'
            : '${category.label} · ${_money(store.currency, monthly)}/mo';

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: 'Analytics',
                      subtitle: all.isEmpty ? 'Spending patterns and forecasts' : subtitle,
                      hasBigHeader: true,
                      expandedHeight: 270.0,
                      actionsPillKey: _headerActionsKey,
                      actions: all.isEmpty
                          ? null
                          : [
                              OneUIHeaderAction(
                                icon: Icons.more_vert_rounded,
                                tooltip: 'More options',
                                onTap: () => _showMoreMenu(store),
                              ),
                            ],
                    ),
                  ),
                  if (all.isEmpty)
                    _noSubscriptionsSliver()
                  else
                    ..._contentSlivers(store, subs, monthly),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
              const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _contentSlivers(SubscriptionStore store, List<Subscription> subs, double monthly) {
    final now = DateTime.now();
    final currency = store.currency;
    final allCategories = SpendingInsights.byCategory(store.subscriptions);
    final ranked = SpendingInsights.ranked(subs);
    final cycles = SpendingInsights.byCycle(subs);
    final insights = _insightItems(store, subs, now);

    return [
      if (_category != null) _padded(_filterPill(_category!), top: 6),
      _padded(_hero(store, subs, monthly), top: _category != null ? 12 : 6),
      _padded(
        OneUISpendingTrendsCard(
          subscriptions: subs,
          currency: currency,
          // The budget covers all spending, so it's only a fair guide when unfiltered.
          monthlyBudget: _category == null ? store.monthlyBudget : 0,
          onOpenSubscription: _openSubscription,
        ),
        top: 12,
      ),
      if (insights.isNotEmpty)
        _padded(
          OneUISection(
            title: 'Insights',
            child: OneUIGroupCard(margin: EdgeInsets.zero, items: insights),
          ),
        ),
      if (allCategories.isNotEmpty) _padded(_categorySection(currency, allCategories)),
      if (ranked.isNotEmpty) _padded(_topSection(currency, ranked, monthly)),
      if (cycles.isNotEmpty) _padded(_cycleSection(currency, subs, cycles)),
      _padded(_paymentsSection(store, subs, now)),
    ];
  }

  // --- Hero ------------------------------------------------------------------

  Widget _hero(SubscriptionStore store, List<Subscription> subs, double monthly) {
    final currency = store.currency;
    final category = _category;
    final paused = SpendingInsights.pausedSavings(subs);
    final budget = store.monthlyBudget;

    final rows = <AnalyticsHeroRow>[
      (
        label: 'Per month',
        value: _money(currency, monthly),
        caption: 'about ${_money(currency, monthly * 12 / 365)} a day',
        valueColor: null,
      ),
      if (category != null && store.totalMonthlySpend > 0)
        (
          label: 'Share of spend',
          value: _percent(monthly / store.totalMonthlySpend),
          caption: 'of ${_money(currency, store.totalMonthlySpend)}/mo in total',
          valueColor: null,
        )
      else if (category == null && budget > 0.01)
        (
          label: 'Budget',
          value: monthly <= budget
              ? '${_money(currency, budget - monthly)} left'
              : '${_money(currency, monthly - budget)} over',
          caption: 'of ${_money(currency, budget)} a month',
          valueColor: monthly <= budget ? OneUITheme.accentGreen : OneUITheme.accentRed,
        ),
      if (paused.count > 0)
        (
          label: 'Paused',
          value: '${_money(currency, paused.monthly)}/mo saved',
          caption: _plural(paused.count, 'paused subscription'),
          valueColor: null,
        ),
    ];

    return OneUIAnalyticsHeroCard(
      title: category == null ? 'Yearly cost' : '${category.label} · yearly',
      amount: _money(currency, monthly * 12),
      badge: '${SubscriptionStats.billable(subs).length} active',
      segments: [
        for (final c in SpendingInsights.byCategory(subs)) (color: c.category.color, total: c.monthly),
      ],
      rows: rows,
    );
  }

  // --- Insights --------------------------------------------------------------

  List<OneUIGroupItem> _insightItems(SubscriptionStore store, List<Subscription> subs, DateTime now) {
    final currency = store.currency;
    final ranked = SpendingInsights.ranked(subs);
    final top = SpendingInsights.topExpense(subs);
    final concentration = SpendingInsights.concentration(subs);
    final heaviest = SpendingInsights.heaviestMonthAhead(subs, now: now);
    final yearly = SpendingInsights.yearlyRenewalsSoon(subs, now: now);

    return [
      if (top != null && ranked.length > 1)
        OneUIGroupItem(
          leading: _badge(Icons.star_rounded, OneUITheme.accentAmber),
          title: 'Top expense',
          subtitle: '${top.subscription.name} is ${_percent(top.share)} of your spending · '
              '${_money(currency, top.subscription.monthlyCost)}/mo',
          subtitleColor: OneUITheme.textSecondary,
          onTap: () => _openSubscription(top.subscription),
        ),
      if (concentration != null)
        OneUIGroupItem(
          leading: _badge(Icons.donut_large_rounded, OneUITheme.accentPurple),
          title: 'Where it adds up',
          subtitle: 'Your top ${concentration.count} subscriptions make up ${_percent(concentration.share)} of spending',
          subtitleColor: OneUITheme.textSecondary,
          trailing: const SizedBox.shrink(), // Informational: no chevron.
        ),
      if (heaviest != null)
        OneUIGroupItem(
          leading: _badge(Icons.calendar_month_rounded, OneUITheme.accentTeal),
          title: 'Heaviest month ahead',
          subtitle: '${_monthName.format(heaviest.month)} · ${_money(currency, heaviest.total)}'
              '${heaviest.charges.length > 1 ? ', including ${heaviest.charges.first.subscription.name} '
                  '${_money(currency, heaviest.charges.first.amount)}' : ''}',
          subtitleColor: OneUITheme.textSecondary,
          trailing: const SizedBox.shrink(),
        ),
      if (yearly != null)
        OneUIGroupItem(
          leading: _badge(Icons.event_repeat_rounded, OneUITheme.accentBlue),
          title: '${_plural(yearly.count, 'yearly renewal')} soon',
          subtitle: '${_money(currency, yearly.total)} in the next 90 days · '
              'next: ${yearly.charges.first.subscription.name}, ${_monthDay.format(yearly.charges.first.date)}',
          subtitleColor: OneUITheme.textSecondary,
          onTap: () => _openSubscription(yearly.charges.first.subscription),
        ),
    ];
  }

  /// 36dp solid circle list badge (see `docs/design-language.md`).
  Widget _badge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // --- Categories ------------------------------------------------------------

  Widget _categorySection(String currency, List<CategorySpend> categories) {
    final selectedIndex = _category == null ? null : categories.indexWhere((c) => c.category == _category);
    final focus = selectedIndex != null && selectedIndex >= 0 ? categories[selectedIndex] : categories.first;
    final total = categories.fold(0.0, (sum, c) => sum + c.monthly);

    return OneUISection(
      title: 'Spending by category',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: OneUITheme.cardColor,
              borderRadius: OneUITheme.cardBorderRadius,
              border: OneUITheme.cardBorder,
              boxShadow: OneUITheme.cardShadow,
            ),
            child: Row(
              children: [
                OneUICategoryRing(
                  segments: [for (final c in categories) (color: c.category.color, value: c.monthly)],
                  highlightedIndex: selectedIndex,
                  centerValue: compactMoney(currency, total),
                  centerLabel: 'per month',
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _category == null ? 'Largest category' : 'Selected',
                        style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: focus.category.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              focus.category.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_money(currency, focus.monthly)}/mo · ${_percent(focus.share)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${categories.length} ${categories.length == 1 ? 'category' : 'categories'} · tap one to focus',
                        maxLines: 2,
                        style: const TextStyle(fontSize: 12, color: OneUITheme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              for (final c in categories) _categoryItem(currency, c),
            ],
          ),
        ],
      ),
    );
  }

  OneUIGroupItem _categoryItem(String currency, CategorySpend c) {
    final isSelected = _category == c.category;
    final dimmed = _category != null && !isSelected;
    return OneUIGroupItem(
      leading: Opacity(
        opacity: dimmed ? 0.4 : 1,
        child: _badge(c.category.icon, c.category.color),
      ),
      title: c.category.label,
      customSubtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_plural(c.count, 'subscription')} · ${_percent(c.share)}',
              style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: c.share.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: OneUITheme.surfacePill,
                color: c.category.color.withValues(alpha: dimmed ? 0.35 : 1),
              ),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_money(currency, c.monthly)}/mo',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: dimmed ? OneUITheme.textSecondary : OneUITheme.textPrimary,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, size: 20, color: OneUITheme.accentBlue),
          ],
        ],
      ),
      onTap: () => _setCategory(isSelected ? null : c.category),
    );
  }

  Widget _filterPill(SubscriptionCategory category) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: 'Clear ${category.label} filter',
        child: Material(
          color: OneUITheme.accentBlue.withValues(alpha: 0.16),
          borderRadius: OneUITheme.pillBorderRadius,
          child: InkWell(
            borderRadius: OneUITheme.pillBorderRadius,
            onTap: () => _setCategory(null),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
                    child: Icon(category.icon, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.close_rounded, size: 16, color: OneUITheme.accentBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Top subscriptions -------------------------------------------------------

  Widget _topSection(String currency, List<Subscription> ranked, double monthly) {
    final visible = _showAllTop ? ranked : ranked.take(_topLimit).toList();
    return OneUISection(
      title: _category == null ? 'Top subscriptions' : 'Subscriptions',
      child: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          for (final sub in visible)
            OneUIGroupItem(
              leading: OneUIBrandIcon(subscription: sub, size: 42, borderRadius: 13),
              title: sub.name,
              customSubtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${sub.billingCycle.label} · ${_money(sub.currency, sub.price)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: monthly <= 0 ? 0 : (sub.monthlyCost / monthly).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: OneUITheme.surfacePill,
                        color: sub.category.color,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                '${_money(currency, sub.monthlyCost)}/mo',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
              ),
              onTap: () => _openSubscription(sub),
            ),
          if (ranked.length > _topLimit)
            OneUIGroupItem(
              title: _showAllTop ? 'Show less' : 'Show all (${ranked.length})',
              trailing: Icon(
                _showAllTop ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: OneUITheme.textSecondary,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showAllTop = !_showAllTop);
              },
            ),
        ],
      ),
    );
  }

  // --- Billing cycles ----------------------------------------------------------

  Widget _cycleSection(String currency, List<Subscription> subs, List<CycleSpend> cycles) {
    final billed = <BillingCycle, double>{};
    for (final s in SubscriptionStats.billable(subs)) {
      billed[s.billingCycle] = (billed[s.billingCycle] ?? 0) + s.price;
    }
    final total = cycles.fold(0.0, (sum, c) => sum + c.monthly);
    String per(BillingCycle cycle) => switch (cycle) {
          BillingCycle.weekly => 'wk',
          BillingCycle.monthly => 'mo',
          BillingCycle.quarterly => 'qtr',
          BillingCycle.yearly => 'yr',
        };

    return OneUISection(
      title: 'Billing cycles',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        decoration: BoxDecoration(
          color: OneUITheme.cardColor,
          borderRadius: OneUITheme.cardBorderRadius,
          border: OneUITheme.cardBorder,
          boxShadow: OneUITheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: OneUIAnalyticsHeroCard.trackBackground,
                borderRadius: BorderRadius.circular(100),
              ),
              clipBehavior: Clip.antiAlias,
              child: total <= 0
                  ? null
                  : Row(
                      children: [
                        for (final (i, c) in cycles.indexed)
                          Expanded(
                            flex: (c.monthly / total * 1000).round().clamp(1, 1000),
                            child: Container(
                              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                              color: _cycleColors[c.cycle],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            for (final c in cycles)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: _cycleColors[c.cycle], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.cycle.label,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_plural(c.count, 'subscription')} · billed ${_money(currency, billed[c.cycle] ?? 0)}/${per(c.cycle)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_money(currency, c.monthly)}/mo',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _percent(c.share),
                          style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Payments ------------------------------------------------------------------

  Widget _paymentsSection(SubscriptionStore store, List<Subscription> subs, DateTime now) {
    final payments = SpendingInsights.recentPayments(subs);
    final paidThisMonth = payments
        .where((p) => p.date.year == now.year && p.date.month == now.month)
        .fold(0.0, (sum, p) => sum + p.subscription.price);

    return OneUISection(
      title: 'Recent payments',
      trailing: paidThisMonth > 0
          ? Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_money(store.currency, paidThisMonth)} this month',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: OneUITheme.accentGreen),
              ),
            )
          : null,
      child: payments.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: OneUITheme.cardColor,
                borderRadius: OneUITheme.cardBorderRadius,
                border: OneUITheme.cardBorder,
                boxShadow: OneUITheme.cardShadow,
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_rounded, size: 36, color: OneUITheme.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'No payments logged yet',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: OneUITheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mark renewals as paid on the Upcoming tab to build your payment history',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: OneUITheme.textSecondary),
                  ),
                ],
              ),
            )
          : OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                for (final p in payments.take(_paymentsLimit))
                  OneUIGroupItem(
                    leading: OneUIBrandIcon(subscription: p.subscription, size: 42, borderRadius: 13),
                    title: p.subscription.name,
                    subtitle: () {
                      final card = store.getPaymentMethod(p.subscription.paymentMethodId);
                      final date = _monthDayYear.format(p.date);
                      return card == null ? date : '$date · ${card.displayName}';
                    }(),
                    subtitleColor: OneUITheme.textSecondary,
                    trailing: Text(
                      _money(p.subscription.currency, p.subscription.price),
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.paymentHistory(p.subscription.id));
                    },
                  ),
              ],
            ),
    );
  }

  // --- Empty state & helpers -----------------------------------------------------

  Widget _noSubscriptionsSliver() {
    return _padded(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: OneUITheme.cardColor,
          borderRadius: OneUITheme.cardBorderRadius,
          border: OneUITheme.cardBorder,
          boxShadow: OneUITheme.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.pie_chart_outline_rounded, size: 48, color: OneUITheme.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No spending data yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OneUITheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add subscriptions to see your spending trajectory, categories and insights',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
            ),
            const SizedBox(height: 18),
            Material(
              color: OneUITheme.accentBlue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(100),
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.addSubscription);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Text(
                    'Add subscription',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      top: 14,
    );
  }

  Widget _padded(Widget child, {double top = 8}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}
