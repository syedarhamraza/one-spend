import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/router/app_router.dart';
import '../features/subscriptions/domain/services/insight_cards.dart';
import '../features/subscriptions/domain/services/spending_insights.dart';
import '../features/subscriptions/domain/services/subscription_stats.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_analytics_hero_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_category_breakdown_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_insight_card.dart';
import '../widgets/one_ui_sliver_scroll_anchor.dart';
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

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static final DateFormat _monthDayYear = DateFormat('MMM d, y');

  static const int _topLimit = 5;
  static const int _paymentsLimit = 6;

  static const Map<BillingCycle, Color> _cycleColors = {
    BillingCycle.monthly: OneUITheme.accentBlue,
    BillingCycle.yearly: OneUITheme.accentGreen,
    BillingCycle.quarterly: OneUITheme.accentPurple,
    BillingCycle.weekly: OneUITheme.accentAmber,
  };

  /// Height of the pinned header once collapsed (see [OneUICollapsibleHeaderDelegate]).
  static const double _collapsedHeaderHeight = 92.0;

  final GlobalKey _headerActionsKey = GlobalKey();
  final GlobalKey _trajectoryKey = GlobalKey();
  final GlobalKey _topSubscriptionsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final OneUIScrollAnchorController _categoryAnchor = OneUIScrollAnchorController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  SubscriptionCategory? _category;
  bool _showAllTop = false;

  /// Totals and headline figures (prices use [formatMoney] directly).
  String _money(String currency, double amount) => formatMoney(amount, currency, style: MoneyStyle.summary);

  double _toMain(double amount, String currency) => SubscriptionStore.instance.toMain(amount, currency);

  double _mainMonthly(Subscription sub) => SubscriptionStore.instance.monthlyCostInMain(sub);
  String _percent(double share) => '${(share * 100).round()}%';
  String _plural(int count, String noun) => '$count $noun${count == 1 ? '' : 's'}';

  void _setCategory(SubscriptionCategory? category) {
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
    OneUIToast.copied(context, 'Report copied to clipboard');
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
        if (store.dismissedInsights.isNotEmpty)
          OneUIFloatingMenuItem(
            label: 'Show dismissed tips',
            onTap: () {
              store.restoreDismissedInsights();
              OneUIToast.show(context, 'Dismissed tips restored');
            },
          ),
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
        final monthly = SubscriptionStats.totalMonthlySpend(subs, store.toMain);

        final subtitle = category == null
            ? '${_money(store.currency, monthly)}/mo · ${store.totalActiveCount} active'
            : '${category.label} · ${_money(store.currency, monthly)}/mo';

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
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
                  OneUISliverScrollAnchorSpacer(controller: _categoryAnchor),
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
    final allCategories = SpendingInsights.byCategory(store.subscriptions, store.toMain);
    final ranked = SpendingInsights.ranked(subs, store.toMain);
    final cycles = SpendingInsights.byCycle(subs, store.toMain);
    final insights = InsightCards.build(
      subs,
      now: now,
      currency: currency,
      toMain: store.toMain,
      monthlyBudget: store.monthlyBudget,
      includeBudget: _category == null,
      categoryLabel: _category?.label,
    ).where((c) => !store.dismissedInsights.contains(c.key)).toList();

    return [
      if (_category != null) _padded(_filterPill(_category!), top: 6),
      _padded(_insightCard(store, insights), top: _category != null ? 12 : 6),
      _padded(_hero(store, subs, monthly), top: 0),
      _padded(
        KeyedSubtree(
          key: _trajectoryKey,
          child: OneUISpendingTrendsCard(
            subscriptions: subs,
            currency: currency,
            // The budget covers all spending, so it's only a fair guide when unfiltered.
            monthlyBudget: _category == null ? store.monthlyBudget : 0,
            onOpenSubscription: _openSubscription,
          ),
        ),
        top: 12,
      ),
      // Filtering resizes the cards above; keep the category card still under the finger.
      if (allCategories.isNotEmpty) OneUISliverScrollAnchor(controller: _categoryAnchor),
      if (allCategories.isNotEmpty)
        _padded(
          OneUICategoryBreakdownCard(
            categories: allCategories,
            currency: currency,
            selected: _category,
            onSelect: (category) {
              _categoryAnchor.hold();
              _setCategory(category);
            },
          ),
          top: 12,
        ),
      if (ranked.isNotEmpty)
        _padded(KeyedSubtree(key: _topSubscriptionsKey, child: _topSection(currency, ranked, monthly))),
      if (cycles.isNotEmpty) _padded(_cycleSection(currency, subs, cycles)),
      _padded(_paymentsSection(store, subs, now)),
    ];
  }

  // --- Hero ------------------------------------------------------------------

  Widget _hero(SubscriptionStore store, List<Subscription> subs, double monthly) {
    final currency = store.currency;
    final category = _category;
    final paused = SpendingInsights.pausedSavings(subs, store.toMain);
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
        for (final c in SpendingInsights.byCategory(subs, store.toMain)) (color: c.category.color, total: c.monthly),
      ],
      rows: rows,
      // Glow in the colour of the biggest category (the selected one when filtered).
      glowColor: () {
        final categories = SpendingInsights.byCategory(subs, store.toMain);
        return categories.isEmpty ? OneUITheme.glowDefault : OneUITheme.glowTint(categories.first.category.color);
      }(),
    );
  }

  // --- Insight card ---------------------------------------------------------

  /// Dismissed tips come back via the ⋮ menu's "Show dismissed tips".
  void _dismissInsight(SubscriptionStore store, InsightCardData card) {
    HapticFeedback.selectionClick();
    store.dismissInsight(card.key);
  }

  void _runInsightAction(SubscriptionStore store, InsightCardData card) {
    switch (card.action) {
      case InsightAction.openSubscription:
        if (card.subscription != null) context.push(AppRoutes.subscriptionDetail(card.subscription!.id));
      case InsightAction.openUpcoming:
        context.go(AppRoutes.upcoming);
      case InsightAction.showTrajectory:
        _scrollTo(_trajectoryKey);
      case InsightAction.showTopSubscriptions:
        _scrollTo(_topSubscriptionsKey);
      case InsightAction.acknowledge:
        store.dismissInsight(card.key);
    }
  }

  /// Scrolls so [key]'s section sits just under the collapsed header, building it first if
  /// it is still off-screen (slivers are built lazily).
  Future<void> _scrollTo(GlobalKey key) async {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    for (var i = 0; i < 12 && key.currentContext == null && position.pixels < position.maxScrollExtent; i++) {
      _scrollController.jumpTo((position.pixels + position.viewportDimension).clamp(0.0, position.maxScrollExtent));
      await WidgetsBinding.instance.endOfFrame;
    }
    final object = key.currentContext?.findRenderObject();
    if (object == null || !mounted) return;
    final reveal = RenderAbstractViewport.of(object).getOffsetToReveal(object, 0).offset;
    await _scrollController.animateTo(
      (reveal - _collapsedHeaderHeight - 8).clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _insightCard(SubscriptionStore store, List<InsightCardData> cards) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: cards.isEmpty
          ? const SizedBox(width: double.infinity)
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              // Only the incoming card is laid out: the outgoing one has already flown away.
              layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(animation), child: child),
              ),
              child: Padding(
                key: ValueKey(cards.first.key),
                padding: const EdgeInsets.only(bottom: 12),
                child: OneUIInsightCard(
                  data: cards.first,
                  total: cards.length,
                  onAction: () => _runInsightAction(store, cards.first),
                  onDismiss: () => _dismissInsight(store, cards.first),
                ),
              ),
            ),
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
            onTap: () {
              HapticFeedback.selectionClick();
              _setCategory(null);
            },
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
                      '${sub.billingCycle.label} · ${formatMoney(sub.price, sub.currency)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: monthly <= 0 ? 0 : (_mainMonthly(sub) / monthly).clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: OneUITheme.surfacePill,
                        color: sub.category.color,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                '${_money(currency, _mainMonthly(sub))}/mo',
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
      billed[s.billingCycle] = (billed[s.billingCycle] ?? 0) + _toMain(s.price, s.currency);
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
                            // Monthly plans already show their bill on the right.
                            c.cycle == BillingCycle.monthly
                                ? _plural(c.count, 'subscription')
                                : '${_plural(c.count, 'subscription')} · ${_money(currency, billed[c.cycle] ?? 0)}/${per(c.cycle)}',
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
        .fold(0.0, (sum, p) => sum + store.toMain(p.subscription.price, p.subscription.currency));

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
                      formatMoney(p.subscription.price, p.subscription.currency),
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
