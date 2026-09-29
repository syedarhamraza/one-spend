import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/router/app_router.dart';
import '../features/notifications/domain/notification_planner.dart';
import '../features/subscriptions/data/ics_exporter.dart';
import '../features/subscriptions/domain/services/charge_schedule.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/reminder_format.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_month_calendar.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_segmented_pills.dart';
import '../widgets/one_ui_toast.dart';

/// How far ahead the Upcoming timeline looks.
enum UpcomingHorizon {
  week(7, '7 days', 'next 7 days'),
  month(30, '30 days', 'next 30 days'),
  quarter(90, '3 months', 'next 3 months'),
  year(365, '12 months', 'next 12 months');

  final int days;
  final String label;
  final String phrase;

  const UpcomingHorizon(this.days, this.label, this.phrase);
}

/// Upcoming tab: answers "when is money leaving, how much, and from which card?".
///
/// Two views (remembered in [OneUIEffectsController.upcomingViewMode]):
/// - **Timeline**: every charge in the chosen horizon grouped by day, with insights and a
///   per-card breakdown that filters the list.
/// - **Calendar**: a month grid with brand-colour dots; tap a day to list its charges.
class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

/// Sentinel id used for the "No card" payment-method filter.
const String _noCardFilter = '__no_card__';

class _UpcomingScreenState extends State<UpcomingScreen> {
  static final DateFormat _weekdayMonthDay = DateFormat('EEE, MMM d');
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _monthYear = DateFormat('MMMM');

  final GlobalKey _headerActionsKey = GlobalKey();

  UpcomingHorizon _horizon = UpcomingHorizon.month;

  /// Payment method id to filter by; [_noCardFilter] for charges without a card.
  String? _cardFilter;

  DateTime? _selectedDay;
  DateTime? _calendarMonth;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _money(String currency, double amount) => '$currency${amount.toStringAsFixed(2)}';

  bool _matchesCard(UpcomingCharge c) {
    final filter = _cardFilter;
    if (filter == null) return true;
    return filter == _noCardFilter ? c.paymentMethodId == null : c.paymentMethodId == filter;
  }

  String _cardName(SubscriptionStore store, String? methodId) {
    if (methodId == null || methodId == _noCardFilter) return 'No card';
    return store.getPaymentMethod(methodId)?.displayName ?? 'Removed card';
  }

  String _dayLabel(DateTime day, DateTime today) {
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return _weekdayMonthDay.format(day);
  }

  // --- Actions -------------------------------------------------------------

  void _markPaid(SubscriptionStore store, Subscription sub) {
    HapticFeedback.mediumImpact();
    final snapshot = store.getSubscription(sub.id) ?? sub;
    store.markSubscriptionPaid(sub.id);
    OneUIToast.show(
      context,
      '${sub.name} marked as paid',
      actionLabel: 'Undo',
      onAction: () => store.updateSubscription(snapshot),
    );
  }

  void _skipCycle(SubscriptionStore store, Subscription sub) {
    HapticFeedback.mediumImpact();
    final snapshot = store.getSubscription(sub.id) ?? sub;
    store.skipSubscriptionCycle(sub.id);
    final next = store.getSubscription(sub.id)?.nextBillingDate;
    OneUIToast.show(
      context,
      next == null ? 'Skipped ${sub.name}' : 'Skipped · next ${_monthDay.format(next)}',
      actionLabel: 'Undo',
      onAction: () => store.updateSubscription(snapshot),
    );
  }

  void _showChargeActions(SubscriptionStore store, UpcomingCharge charge, {required bool isNextCharge}) {
    HapticFeedback.mediumImpact();
    final sub = charge.subscription;
    OneUIFloatingModal.show<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sub.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_money(sub.currency, sub.price)} · ${_weekdayMonthDay.format(charge.date)}',
            style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 14),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              if (isNextCharge && !charge.isPaid) ...[
                OneUIGroupItem(
                  leading: _actionBadge(Icons.check_rounded, OneUITheme.accentGreen),
                  title: 'Mark as paid',
                  subtitle: 'Logs the payment and moves to the next cycle',
                  onTap: () {
                    Navigator.pop(ctx);
                    _markPaid(store, sub);
                  },
                ),
                OneUIGroupItem(
                  leading: _actionBadge(Icons.redo_rounded, OneUITheme.accentAmber),
                  title: 'Skip this cycle',
                  subtitle: 'Moves to the next cycle without logging a payment',
                  onTap: () {
                    Navigator.pop(ctx);
                    _skipCycle(store, sub);
                  },
                ),
              ],
              OneUIGroupItem(
                leading: _actionBadge(Icons.open_in_new_rounded, OneUITheme.accentBlue),
                title: 'View details',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.subscriptionDetail(sub.id));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCalendar(SubscriptionStore store) async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final charges = ChargeSchedule.between(
      store.subscriptions,
      from: today,
      to: today.add(const Duration(days: 365)),
      now: now,
      includePaid: false,
    );
    if (charges.isEmpty) {
      OneUIToast.show(context, 'No upcoming renewals to export');
      return;
    }
    final ics = IcsExporter.build(
      charges,
      now: now,
      paymentMethodName: (id) => id == null ? null : store.getPaymentMethod(id)?.displayName,
      reminderTimeMinutes: store.notificationsEnabled ? store.defaultReminderTimeMinutes : null,
    );
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'onespend-renewals.ics'));
      await file.writeAsString(ics);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/calendar')],
          subject: 'OneSpend renewals',
        ),
      );
    } catch (_) {
      if (mounted) OneUIToast.show(context, 'Couldn\'t open the share sheet');
    }
  }

  void _showMoreMenu(SubscriptionStore store) {
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _headerActionsKey,
      fallbackTop: MediaQuery.of(context).padding.top + 6.0,
      width: 220,
      items: [
        OneUIFloatingMenuItem(label: 'Add to calendar', onTap: () => _exportToCalendar(store)),
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
        final effects = OneUIEffectsController.instance;
        final isCalendar = effects.upcomingViewMode == UpcomingViewMode.calendar;

        final now = DateTime.now();
        final today = _dateOnly(now);
        final horizonEnd = today.add(Duration(days: _horizon.days));

        final overdue = ChargeSchedule.between(
          store.subscriptions,
          from: DateTime(1970),
          to: today.subtract(const Duration(days: 1)),
          now: now,
          includePaid: false,
        ).where(_matchesCard).toList();
        final unfilteredWindow = ChargeSchedule.between(store.subscriptions, from: today, to: horizonEnd, now: now);
        final window = unfilteredWindow.where(_matchesCard).toList();
        final dueTotal = overdue.dueTotal + window.dueTotal;

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
                      title: 'Upcoming',
                      subtitle: '${_money(store.currency, dueTotal)} due in the ${_horizon.phrase}',
                      hasBigHeader: true,
                      expandedHeight: 270.0,
                      actionsPillKey: _headerActionsKey,
                      actions: [
                        OneUIHeaderAction(
                          icon: isCalendar ? Icons.view_agenda_outlined : Icons.calendar_month_outlined,
                          tooltip: isCalendar ? 'Timeline view' : 'Calendar view',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            effects.upcomingViewMode = isCalendar ? UpcomingViewMode.timeline : UpcomingViewMode.calendar;
                          },
                        ),
                        OneUIHeaderAction(
                          icon: Icons.more_vert_rounded,
                          tooltip: 'More options',
                          onTap: () => _showMoreMenu(store),
                        ),
                      ],
                    ),
                  ),
                  if (store.subscriptions.isEmpty)
                    _noSubscriptionsSliver()
                  else if (isCalendar)
                    ..._calendarSlivers(store, now, today)
                  else
                    ..._timelineSlivers(store, now, today, overdue, window, unfilteredWindow),
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

  // --- Timeline --------------------------------------------------------------

  List<Widget> _timelineSlivers(
    SubscriptionStore store,
    DateTime now,
    DateTime today,
    List<UpcomingCharge> overdue,
    List<UpcomingCharge> window,
    List<UpcomingCharge> unfilteredWindow,
  ) {
    final days = window.byDay();
    final byCard = [...overdue, ...unfilteredWindow].byPaymentMethod();

    return [
      _padded(
        OneUISegmentedPills<UpcomingHorizon>(
          segments: [for (final h in UpcomingHorizon.values) (value: h, label: h.label)],
          selected: _horizon,
          onChanged: (h) => setState(() => _horizon = h),
        ),
        top: 6,
      ),
      if (_cardFilter != null) _padded(_filterPill(store), top: 10),
      if (window.unpaid.isNotEmpty || overdue.isNotEmpty)
        SliverToBoxAdapter(child: _insightStrip(store, now, [...overdue, ...window])),
      if (_cardFilter == null && byCard.isNotEmpty) _padded(_byCardSection(store, byCard), top: 4),
      if (overdue.isNotEmpty)
        _padded(
          OneUISection(
            title: 'Overdue (${overdue.length})',
            trailing: _sectionAmount(_money(store.currency, overdue.dueTotal), color: OneUITheme.accentRed),
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [for (final c in overdue) _chargeItem(store, c, now, today)],
            ),
          ),
        ),
      for (final entry in days.entries)
        _padded(
          OneUISection(
            title: _dayLabel(entry.key, today),
            trailing: entry.value.dueTotal > 0 ? _sectionAmount(_money(store.currency, entry.value.dueTotal)) : null,
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [for (final c in entry.value) _chargeItem(store, c, now, today)],
            ),
          ),
        ),
      if (days.isEmpty && overdue.isEmpty) _padded(_nothingDueCard(), top: 14),
    ];
  }

  Widget _filterPill(SubscriptionStore store) {
    final method = _cardFilter == _noCardFilter ? null : store.getPaymentMethod(_cardFilter);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: OneUITheme.accentBlue.withValues(alpha: 0.16),
        borderRadius: OneUITheme.pillBorderRadius,
        child: InkWell(
          borderRadius: OneUITheme.pillBorderRadius,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _cardFilter = null);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (method != null) ...[
                  OneUIPaymentBrandIcon(brand: method.brand, width: 26, height: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    _cardName(store, _cardFilter),
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
    );
  }

  Widget _insightStrip(SubscriptionStore store, DateTime now, List<UpcomingCharge> charges) {
    final biggest = charges.biggest;
    final busiest = charges.busiestWeek();
    final annual = ChargeSchedule.annualRenewalsWithin(store.subscriptions, now: now).where(_matchesCard).toList();
    final cards = <Widget>[
      _insightCard(
        icon: Icons.payments_rounded,
        color: OneUITheme.accentTeal,
        label: 'Total due',
        value: _money(store.currency, charges.dueTotal),
        caption: '${charges.unpaid.length} charge${charges.unpaid.length == 1 ? '' : 's'}',
      ),
      if (biggest != null)
        _insightCard(
          leading: OneUIBrandIcon(subscription: biggest.subscription, size: 30, borderRadius: 9),
          label: 'Biggest charge',
          value: _money(biggest.currency, biggest.amount),
          caption: '${biggest.subscription.name} · ${_monthDay.format(biggest.date)}',
          onTap: () => context.push(AppRoutes.subscriptionDetail(biggest.subscription.id)),
        ),
      if (busiest != null && busiest.count > 1)
        _insightCard(
          icon: Icons.local_fire_department_rounded,
          color: OneUITheme.accentOrange,
          label: 'Busiest week',
          value: _money(store.currency, busiest.total),
          caption:
              '${_monthDay.format(busiest.start)} – ${_monthDay.format(busiest.start.add(const Duration(days: 6)))} · ${busiest.count} charges',
        ),
      if (annual.isNotEmpty)
        _insightCard(
          icon: Icons.event_repeat_rounded,
          color: OneUITheme.accentPurple,
          label: 'Yearly renewal soon',
          value: _money(annual.first.currency, annual.first.amount),
          caption: '${annual.first.subscription.name} · ${_monthDay.format(annual.first.date)}',
          onTap: () => context.push(AppRoutes.subscriptionDetail(annual.first.subscription.id)),
        ),
    ];

    // Height grows with the user's font size so card text never overflows.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 84 + 64 * textScale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }

  Widget _insightCard({
    IconData? icon,
    Color? color,
    Widget? leading,
    required String label,
    required String value,
    required String caption,
    VoidCallback? onTap,
  }) {
    return Material(
      color: OneUITheme.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: OneUITheme.cardBorder,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  leading ??
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color!.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 17, color: color),
                      ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: OneUITheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: OneUITheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _byCardSection(SubscriptionStore store, Map<String?, ({double total, int count})> byCard) {
    final grandTotal = byCard.values.fold(0.0, (sum, v) => sum + v.total);
    return OneUISection(
      title: 'By payment method',
      child: OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          for (final entry in byCard.entries)
            OneUIGroupItem(
              leading: () {
                final method = store.getPaymentMethod(entry.key);
                return method != null
                    ? OneUIPaymentBrandIcon(brand: method.brand, width: 42, height: 28)
                    : Container(
                        width: 42,
                        height: 28,
                        decoration: BoxDecoration(
                          color: OneUITheme.surfacePill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.credit_card_off_outlined, size: 16, color: OneUITheme.textSecondary),
                      );
              }(),
              title: _cardName(store, entry.key),
              customSubtitle: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.value.count} charge${entry.value.count == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: grandTotal <= 0 ? 0 : entry.value.total / grandTotal,
                        minHeight: 4,
                        backgroundColor: OneUITheme.surfacePill,
                        color: OneUITheme.accentBlue,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                _money(store.currency, entry.value.total),
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _cardFilter = entry.key ?? _noCardFilter);
              },
            ),
        ],
      ),
    );
  }

  Widget _nothingDueCard() {
    final next = UpcomingHorizon.values.where((h) => h.days > _horizon.days).firstOrNull;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded, size: 44, color: OneUITheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Nothing due in the ${_horizon.phrase}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            _pillButton('Show ${next.label}', () => setState(() => _horizon = next)),
          ],
        ],
      ),
    );
  }

  // --- Calendar --------------------------------------------------------------

  List<Widget> _calendarSlivers(SubscriptionStore store, DateTime now, DateTime today) {
    final firstMonth = DateTime(today.year, today.month - 6);
    final lastMonth = DateTime(today.year, today.month + 12);
    final charges = ChargeSchedule.between(
      store.subscriptions,
      from: firstMonth,
      to: DateTime(lastMonth.year, lastMonth.month + 1, 0),
      now: now,
    ).where(_matchesCard).toList();
    final byDay = charges.byDay();

    final markers = {
      for (final entry in byDay.entries)
        entry.key: CalendarDayMarker(
          dotColors: [for (final c in entry.value) Color(c.subscription.brandColorValue)],
          amount: entry.value.dueTotal,
          settled: entry.value.every((c) => c.isPaid),
        ),
    };

    final selected = _selectedDay ?? today;
    final visibleMonth = _calendarMonth ?? DateTime(today.year, today.month);
    final monthCharges = charges
        .where((c) => c.date.year == visibleMonth.year && c.date.month == visibleMonth.month)
        .toList();
    final dayCharges = byDay[selected] ?? const <UpcomingCharge>[];

    return [
      if (_cardFilter != null) _padded(_filterPill(store), top: 6),
      _padded(
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          child: OneUIMonthCalendar(
            firstMonth: firstMonth,
            lastMonth: lastMonth,
            initialMonth: visibleMonth,
            today: today,
            selectedDay: selected,
            markers: markers,
            onDaySelected: (day) => setState(() => _selectedDay = day),
            onMonthChanged: (month) => setState(() {
              _calendarMonth = month;
              // Keep the selection inside the visible month.
              _selectedDay = month.year == today.year && month.month == today.month ? today : month;
            }),
          ),
        ),
        top: 6,
      ),
      _padded(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            '${_monthYear.format(visibleMonth)} · ${_money(store.currency, monthCharges.dueTotal)} due'
            '${monthCharges.any((c) => c.isPaid) ? ' · ${_money(store.currency, monthCharges.where((c) => c.isPaid).fold(0.0, (s, c) => s + c.amount))} paid' : ''}',
            style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
          ),
        ),
        top: 10,
      ),
      _padded(
        OneUISection(
          title: _dayLabel(selected, today),
          trailing: dayCharges.dueTotal > 0 ? _sectionAmount(_money(store.currency, dayCharges.dueTotal)) : null,
          child: dayCharges.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: OneUITheme.cardColor,
                    borderRadius: OneUITheme.cardBorderRadius,
                    border: OneUITheme.cardBorder,
                  ),
                  child: const Center(
                    child: Text('No charges on this day', style: TextStyle(fontSize: 14, color: OneUITheme.textSecondary)),
                  ),
                )
              : OneUIGroupCard(
                  margin: EdgeInsets.zero,
                  items: [for (final c in dayCharges) _chargeItem(store, c, now, today)],
                ),
        ),
      ),
    ];
  }

  // --- Rows & helpers ----------------------------------------------------------

  OneUIGroupItem _chargeItem(SubscriptionStore store, UpcomingCharge charge, DateTime now, DateTime today) {
    final sub = charge.subscription;
    final current = store.getSubscription(sub.id) ?? sub;
    // Only the subscription's current due date can be marked paid or skipped.
    final isNextCharge = !charge.isPaid && charge.date == _dateOnly(current.nextBillingDate);
    final days = charge.date.difference(today).inDays;

    final (String statusText, Color statusColor) = switch (charge.status) {
      ChargeStatus.paid => ('Paid', OneUITheme.accentGreen),
      ChargeStatus.overdue => ('Overdue by ${-days} day${days == -1 ? '' : 's'}', OneUITheme.accentRed),
      ChargeStatus.upcoming when days == 0 => ('Due today', OneUITheme.accentRed),
      ChargeStatus.upcoming when days == 1 => ('Due tomorrow', OneUITheme.accentAmber),
      ChargeStatus.upcoming when days <= 5 => ('In $days days', OneUITheme.accentAmber),
      ChargeStatus.upcoming => ('In $days days', OneUITheme.accentBlue),
    };
    final card = sub.paymentMethodId == null ? null : store.getPaymentMethod(sub.paymentMethodId);

    return OneUIGroupItem(
      leading: Opacity(
        opacity: charge.isPaid ? 0.5 : 1,
        child: OneUIBrandIcon(subscription: sub, size: 42, borderRadius: 13),
      ),
      title: sub.name,
      customSubtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card == null ? statusText : '$statusText · ${card.displayName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: statusColor),
          ),
          if (!charge.isPaid) _reminderLine(store, sub, charge.date, now),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _money(sub.currency, sub.price),
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: charge.isPaid ? OneUITheme.textSecondary : OneUITheme.textPrimary,
              decoration: charge.isPaid ? TextDecoration.lineThrough : null,
              decorationColor: OneUITheme.textSecondary,
            ),
          ),
          if (charge.isPaid || isNextCharge) const SizedBox(width: 8),
          if (charge.isPaid)
            const Icon(Icons.check_circle_rounded, color: OneUITheme.accentGreen, size: 22)
          else if (isNextCharge)
            Semantics(
              button: true,
              label: 'Mark ${sub.name} as paid',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _markPaid(store, sub),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: OneUITheme.accentGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: OneUITheme.accentGreen, size: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.subscriptionDetail(sub.id));
      },
      onLongPress: () => _showChargeActions(store, charge, isNextCharge: isNextCharge),
    );
  }

  /// "🔔 Oct 27 · 9:00 AM" for the reminder of this charge, or "Reminders off".
  Widget _reminderLine(SubscriptionStore store, Subscription sub, DateTime chargeDate, DateTime now) {
    final String text;
    if (!store.notificationsEnabled) {
      text = 'Reminders off';
    } else {
      final minutes = NotificationPlanner.effectiveReminderMinutes(sub, store.defaultReminderTimeMinutes);
      final fireDay = DateTime(chargeDate.year, chargeDate.month, chargeDate.day - sub.reminderDays);
      final fireAt = DateTime(fireDay.year, fireDay.month, fireDay.day, minutes ~/ 60, minutes % 60);
      if (!fireAt.isAfter(now)) return const SizedBox.shrink();
      text = '${_monthDay.format(fireAt)} · ${formatReminderTime(minutes)}';
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            store.notificationsEnabled ? Icons.notifications_rounded : Icons.notifications_off_outlined,
            size: 12.5,
            color: OneUITheme.textTertiary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: OneUITheme.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

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
            const Icon(Icons.event_available_rounded, size: 48, color: OneUITheme.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No upcoming renewals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: OneUITheme.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Active subscriptions will appear here automatically',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
            ),
            const SizedBox(height: 18),
            _pillButton('Add subscription', () => context.push(AppRoutes.addSubscription)),
          ],
        ),
      ),
      top: 14,
    );
  }

  Widget _pillButton(String label, VoidCallback onTap) {
    return Material(
      color: OneUITheme.accentBlue.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: OneUITheme.accentBlue),
          ),
        ),
      ),
    );
  }

  Widget _sectionAmount(String text, {Color color = OneUITheme.textSecondary}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _actionBadge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _padded(Widget child, {double top = 8}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}
