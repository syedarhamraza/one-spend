import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/router/app_router.dart';
import '../features/subscriptions/domain/services/annual_savings.dart';
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
import '../widgets/one_ui_subpage.dart';
import '../widgets/one_ui_toast.dart';
import '../features/reports/data/text_report.dart';
import '../features/reports/presentation/export_share_screen.dart';
import '../core/haptics/haptics.dart';

/// Analytics tab: answers "what am I spending, where is it going, and what's next?".
///
/// One glass hero holds the headline figures; every card below it sits under a section title
/// and shows each figure once. Tapping a category filters the whole page (hero, trend,
/// insights, lists) until the filter pill is dismissed.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  /// Plain-text report for sharing; [category] narrows it to one category.
  static String buildReport(SubscriptionStore store, {SubscriptionCategory? category, DateTime? now}) =>
      TextReport.build(store, category: category, now: now);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static final DateFormat _monthDayYear = DateFormat('MMM d, y');
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _shortMonth = DateFormat('MMM');

  static const int _topLimit = 5;
  static const int _paymentsLimit = 6;

  static const Map<BillingCycle, IconData> _cycleIcons = {
    BillingCycle.weekly: Icons.view_week_rounded,
    BillingCycle.monthly: Icons.calendar_month_rounded,
    BillingCycle.quarterly: Icons.date_range_rounded,
    BillingCycle.yearly: Icons.event_repeat_rounded,
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
    Haptics.tap();
    context.push(AppRoutes.subscriptionDetail(sub.id));
  }

  // --- Report ----------------------------------------------------------------

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
        OneUIFloatingMenuItem(label: 'Export & share', onTap: () => ExportShareScreen.open(context, category: _category)),
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

  /// Top to bottom: the overview, how it changes over time, where it goes, what to do
  /// about it, and what was paid.
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
      trackingSince: store.trackingSince,
    ).where((c) => !store.dismissedInsights.contains(c.key)).toList();

    return [
      if (_category != null) _padded(_filterPill(_category!), top: 6, key: const ValueKey('filter')),
      _padded(_insightCard(store, insights), top: _category != null ? 12 : 6, key: const ValueKey('insight')),
      _padded(_hero(store, subs, monthly, now), top: 0, key: const ValueKey('hero')),
      _padded(
        OneUISection(
          key: _trajectoryKey,
          title: 'Spending trend',
          child: OneUISpendingTrendsCard(
            subscriptions: subs,
            currency: currency,
            // The budget covers all spending, so it's only a fair guide when unfiltered.
            monthlyBudget: _category == null ? store.monthlyBudget : 0,
            onOpenSubscription: _openSubscription,
          ),
        ),
        key: const ValueKey('trend'),
      ),
      // Filtering resizes the cards above; keep the category card still under the finger.
      if (allCategories.isNotEmpty)
        OneUISliverScrollAnchor(key: const ValueKey('category-anchor'), controller: _categoryAnchor),
      if (allCategories.isNotEmpty)
        _padded(
          OneUISection(
            title: 'By category',
            child: OneUICategoryBreakdownCard(
              categories: allCategories,
              currency: currency,
              selected: _category,
              onSelect: (category) {
                _categoryAnchor.hold();
                _setCategory(category);
              },
            ),
          ),
          key: const ValueKey('categories'),
        ),
      if (ranked.isNotEmpty)
        _padded(
          KeyedSubtree(key: _topSubscriptionsKey, child: _topSection(currency, ranked, monthly)),
          key: const ValueKey('top'),
        ),
      // A single cycle would only say "100% monthly".
      if (cycles.length > 1) _padded(_cycleSection(currency, subs, cycles), key: const ValueKey('cycles')),
      if (AnnualSavings.potential(subs, store.toMain) case final annual when annual.savings.isNotEmpty)
        _padded(_annualSection(currency, annual), key: const ValueKey('annual')),
      _padded(_paymentsSection(store, subs, now), key: const ValueKey('payments')),
    ];
  }

  // --- Hero ------------------------------------------------------------------

  Widget _hero(SubscriptionStore store, List<Subscription> subs, double monthly, DateTime now) {
    final currency = store.currency;
    final category = _category;
    final paused = SpendingInsights.pausedSavings(subs, store.toMain);
    final budget = store.monthlyBudget;
    final categories = SpendingInsights.byCategory(subs, store.toMain);

    final rows = <AnalyticsHeroRow>[
      AnalyticsHeroRow(
        label: 'Per month',
        value: _money(currency, monthly),
        caption: 'about ${_money(currency, monthly * 12 / 365)} a day',
      ),
      if (category != null && store.totalMonthlySpend > 0)
        AnalyticsHeroRow(
          label: 'Share of spend',
          value: _percent(monthly / store.totalMonthlySpend),
          caption: 'of ${_money(currency, store.totalMonthlySpend)}/mo in total',
        )
      else if (category == null && budget > 0.01)
        AnalyticsHeroRow(
          label: 'Budget',
          value: monthly <= budget
              ? '${_money(currency, budget - monthly)} left'
              : '${_money(currency, monthly - budget)} over',
          caption: 'of ${_money(currency, budget)} a month',
          valueColor: monthly <= budget ? OneUITheme.accentGreen : OneUITheme.accentRed,
        ),
      if (paused.count > 0)
        AnalyticsHeroRow(
          label: 'Paused',
          value: '${_money(currency, paused.monthly)}/mo saved',
          caption: _plural(paused.count, 'paused subscription'),
        ),
      _yearEndRow(store, subs, now),
    ];

    return OneUIAnalyticsHeroCard(
      title: category == null ? 'Yearly cost' : '${category.label} · yearly',
      amount: _money(currency, monthly * 12),
      badge: '${SubscriptionStats.billable(subs).length} active',
      segments: [for (final c in categories) (color: c.category.color, total: c.monthly)],
      rows: rows,
      // Glow in the colour of the biggest category (the selected one when filtered).
      glowColor: categories.isEmpty ? OneUITheme.glowDefault : OneUITheme.glowTint(categories.first.category.color),
    );
  }

  /// What this calendar year adds up to (paid so far plus what's still due).
  AnalyticsHeroRow _yearEndRow(SubscriptionStore store, List<Subscription> subs, DateTime now) {
    // The budget covers all spending, so it's only a fair guide when unfiltered.
    final projection = SpendingTrendsEngine.projectYear(
      subscriptions: subs,
      referenceDate: now,
      toMain: store.toMain,
      trackingSince: store.trackingSince,
      monthlyBudget: _category == null ? store.monthlyBudget : 0,
    );
    // Tracking that started mid-year only covers part of it, so name the months rather than
    // implying a whole year next to the yearly cost.
    final from = projection.fromMonth.month;
    final label = from == 1
        ? 'On track for ${projection.year}'
        : from == 12
            ? 'Dec ${projection.year}'
            : '${_shortMonth.format(projection.fromMonth)} – Dec ${projection.year}';
    return AnalyticsHeroRow(
      label: label,
      value: _money(store.currency, projection.total),
      caption: '${projection.isEstimated ? 'about ' : ''}${_money(store.currency, projection.spentSoFar)} spent so far',
      valueColor: projection.budgetForYear > 0 && projection.overBudget > 0 ? OneUITheme.accentRed : null,
    );
  }

  // --- Insight card ---------------------------------------------------------

  /// Dismissed tips come back via the ⋮ menu's "Show dismissed tips".
  void _dismissInsight(SubscriptionStore store, InsightCardData card) {
    Haptics.select();
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
              Haptics.select();
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
              subtitle: '${sub.billingCycle.label} · ${formatMoney(sub.price, sub.currency)}',
              trailing: _rowValue(
                '${_money(currency, _mainMonthly(sub))}/mo',
                caption: monthly <= 0 ? null : _percent(_mainMonthly(sub) / monthly),
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
                Haptics.select();
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
    String per(BillingCycle cycle) => switch (cycle) {
          BillingCycle.weekly => 'wk',
          BillingCycle.monthly => 'mo',
          BillingCycle.quarterly => 'qtr',
          BillingCycle.yearly => 'yr',
        };

    return OneUISection(
      title: 'Billing cycles',
      child: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          for (final c in cycles)
            OneUIGroupItem(
              leading: OneUIIconBadge(_cycleIcons[c.cycle]!, OneUITheme.accentTeal),
              title: c.cycle.label,
              // Monthly plans already show their bill on the right.
              subtitle: c.cycle == BillingCycle.monthly
                  ? _plural(c.count, 'subscription')
                  : '${_plural(c.count, 'subscription')} · ${_money(currency, billed[c.cycle] ?? 0)}/${per(c.cycle)}',
              trailing: _rowValue('${_money(currency, c.monthly)}/mo', caption: _percent(c.share)),
            ),
        ],
      ),
    );
  }

  // --- Switch to yearly -------------------------------------------------------------

  Widget _annualSection(String currency, ({double total, List<AnnualSaving> savings}) annual) {
    return OneUISection(
      title: 'Switch to yearly',
      trailing: _sectionNote('Save ${_money(currency, annual.total)} a year'),
      child: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          for (final s in annual.savings)
            OneUIGroupItem(
              leading: OneUIBrandIcon(subscription: s.subscription, size: 42, borderRadius: 13),
              title: s.subscription.name,
              subtitle: '${formatMoney(s.annualPlan, s.subscription.currency)}/yr instead of '
                  '${formatMoney(s.currentYearly, s.subscription.currency)}',
              trailing: _rowValue(
                '−${formatMoney(s.currentYearly - s.annualPlan, s.subscription.currency)}',
                caption: '${_percent(s.percent)} less',
                color: OneUITheme.accentGreen,
              ),
              onTap: () => _openSubscription(s.subscription),
            ),
        ],
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
      trailing: paidThisMonth > 0 ? _sectionNote('${_money(store.currency, paidThisMonth)} this month') : null,
      child: payments.isEmpty
          ? const OneUIEmptyCard(
              icon: Icons.history_rounded,
              title: 'No payments logged yet',
              message: 'Mark renewals as paid on the Upcoming tab to build your payment history',
            )
          : OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                for (final p in payments.take(_paymentsLimit))
                  OneUIGroupItem(
                    leading: OneUIBrandIcon(subscription: p.subscription, size: 42, borderRadius: 13),
                    title: p.subscription.name,
                    subtitle: (p.date.year == now.year ? _monthDay : _monthDayYear).format(p.date),
                    trailing: _rowValue(formatMoney(p.subscription.price, p.subscription.currency)),
                    onTap: () {
                      Haptics.tap();
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
      OneUIEmptyCard(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No spending data yet',
        message: 'Add subscriptions to see your spending trend, categories and insights',
        actionLabel: 'Add subscription',
        onAction: () {
          Haptics.tap();
          context.push(AppRoutes.addSubscription);
        },
      ),
      top: 14,
    );
  }

  /// Right-hand value of every list row: a bold amount over an optional grey caption.
  Widget _rowValue(String value, {String? caption, Color color = OneUITheme.textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(caption, style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary)),
        ],
      ],
    );
  }

  /// Small grey figure on the right of a section title.
  Widget _sectionNote(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
      ),
    );
  }

  /// Sections are keyed so one appearing or disappearing (e.g. Billing cycles under a
  /// filter) doesn't remount its neighbours or the scroll anchor.
  Widget _padded(Widget child, {double top = 8, Key? key}) {
    return SliverPadding(
      key: key,
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}
