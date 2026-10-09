import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/router/app_router.dart';
import '../features/notifications/domain/notification_planner.dart';
import '../features/subscriptions/data/ics_exporter.dart';
import '../features/subscriptions/domain/services/billing_schedule.dart';
import '../features/subscriptions/domain/services/charge_schedule.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/reminder_format.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_fit_amount.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_month_calendar.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_segmented_pills.dart';
import '../widgets/one_ui_selection_header_pills.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_upcoming_hero_card.dart';
import 'home_screen.dart';
import '../core/telemetry/events.dart';
import '../core/telemetry/telemetry.dart';
import '../core/haptics/haptics.dart';
import '../theme/one_ui_scroll.dart';

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

  /// Multi-select mode (entered by long-pressing a charge). Selection is by subscription id,
  /// because actions apply to a subscription's current due date.
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  late final VoidCallback _shellBackHandler = _exitSelectionMode;

  /// Whether this screen sits in the tab shell, whose nav bar hosts the selection
  /// actions (see [HomeShellScope]).
  bool _dockInShell = false;

  @override
  void initState() {
    super.initState();
    HomeChrome.backHandlers[1] = _shellBackHandler;
  }

  @override
  void dispose() {
    if (HomeChrome.backHandlers[1] == _shellBackHandler) HomeChrome.backHandlers.remove(1);
    if (_dockInShell) HomeChrome.dockBottomBar(1, null);
    HomeChrome.upcomingSelectionActive.value = false;
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Charge schedules for this build, reused until the data or the day changes, so
  // selection taps and appearance changes don't re-project every subscription.
  final Map<(DateTime, DateTime, bool), List<UpcomingCharge>> _chargeMemo = {};
  SubscriptionStore? _memoStore;
  int _memoRevision = -1;
  DateTime? _memoDay;

  /// [ChargeSchedule.between] for [from]..[to], memoized per data revision and day.
  List<UpcomingCharge> _charges(
    SubscriptionStore store, {
    required DateTime from,
    required DateTime to,
    required DateTime now,
    bool includePaid = true,
  }) {
    final today = _dateOnly(now);
    if (!identical(_memoStore, store) || _memoRevision != store.revision || _memoDay != today) {
      _chargeMemo.clear();
      _memoStore = store;
      _memoRevision = store.revision;
      _memoDay = today;
    } else if (_chargeMemo.length > 24) {
      _chargeMemo.clear(); // e.g. many calendar days tapped
    }
    return _chargeMemo.putIfAbsent(
      (from, to, includePaid),
      () => ChargeSchedule.between(store.subscriptions, from: from, to: to, now: now, includePaid: includePaid),
    );
  }

  int _pruneRevision = -1;

  /// Totals (prices use [formatMoney] directly).
  String _money(String currency, double amount) => formatMoney(amount, currency, style: MoneyStyle.summary);

  /// Distinct, high-contrast colours for the per-card split (in rank order); "No card" is grey.
  static const List<Color> _cardPalette = [
    OneUITheme.accentBlue,
    OneUITheme.accentTeal,
    OneUITheme.accentPurple,
    OneUITheme.accentAmber,
    Color(0xFFEF6C9A), // Rose
    OneUITheme.accentGreen,
  ];
  static const Color _noCardColor = Color(0xFF6A6A70);

  /// A charge's card id if that card still exists; deleted or unknown cards count as "no card".
  String? _cardKey(String? methodId) =>
      methodId != null && SubscriptionStore.instance.getPaymentMethod(methodId) != null ? methodId : null;

  bool _matchesCard(UpcomingCharge c) {
    final filter = _cardFilter;
    if (filter == null) return true;
    final key = _cardKey(c.paymentMethodId);
    return filter == _noCardFilter ? key == null : key == filter;
  }

  String _cardName(SubscriptionStore store, String? methodId) {
    if (methodId == null || methodId == _noCardFilter) return 'No card';
    return store.getPaymentMethod(methodId)?.displayName ?? 'No card';
  }

  /// Colour per card key, assigned by share of spend so the biggest card is always blue.
  Map<String?, Color> _cardColors(Map<String?, ({double total, int count})> byCard) {
    var next = 0;
    return {
      for (final key in byCard.keys)
        key: key == null ? _noCardColor : _cardPalette[next++ % _cardPalette.length],
    };
  }

  String _dayLabel(DateTime day, DateTime today) {
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return _weekdayMonthDay.format(day);
  }

  // --- Actions -------------------------------------------------------------

  String _plural(int count, String noun) => '$count $noun${count == 1 ? '' : 's'}';

  /// ✓ on a row: confirm, then log the payment and move to the next cycle.
  void _confirmMarkPaid(SubscriptionStore store, Subscription sub) {
    Haptics.tap();
    final next = BillingSchedule.nextDueDate(sub);
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Mark ${sub.name} as paid?',
      message: 'Logs a ${formatMoney(sub.price, sub.currency)} payment and moves the next renewal to '
          '${_monthDay.format(next)}.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Mark paid',
      confirmTextColor: OneUITheme.accentGreen,
      onConfirm: () {
        Haptics.confirm();
        final paid = store.markSubscriptionPaid(sub.id);
        OneUIToast.show(context, paid ? '${sub.name} marked as paid' : '${sub.name} was already marked paid today');
      },
    );
  }

  // --- Selection mode --------------------------------------------------------

  void _setSelectionMode(bool active) {
    _isSelectionMode = active;
    HomeChrome.upcomingSelectionActive.value = active;
  }

  void _enterSelectionMode(String subscriptionId) {
    Haptics.longPress();
    setState(() {
      _setSelectionMode(true);
      _selectedIds
        ..clear()
        ..add(subscriptionId);
    });
  }

  void _exitSelectionMode() {
    if (!_isSelectionMode) return;
    setState(() {
      _setSelectionMode(false);
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String subscriptionId) {
    Haptics.select();
    setState(() {
      if (!_selectedIds.remove(subscriptionId)) _selectedIds.add(subscriptionId);
    });
  }

  void _toggleSelectAll(Set<String> visibleIds) {
    setState(() {
      if (_selectedIds.length == visibleIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(visibleIds);
      }
    });
  }

  List<Subscription> _selectedSubscriptions(SubscriptionStore store) => [
        for (final id in _selectedIds) ?store.getSubscription(id),
      ];

  void _markSelectedPaid(SubscriptionStore store) {
    final subs = _selectedSubscriptions(store);
    if (subs.isEmpty) return;
    final total = subs.fold(0.0, (sum, s) => sum + store.toMain(s.price, s.currency));
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Mark ${_plural(subs.length, 'subscription')} as paid?',
      message: 'Logs a payment for each (${_money(store.currency, total)} in total) and moves them to their next '
          'renewal.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Mark paid',
      confirmTextColor: OneUITheme.accentGreen,
      onConfirm: () {
        Haptics.confirm();
        // Subscriptions already paid today are skipped rather than paid twice.
        var paid = 0;
        for (final sub in subs) {
          if (store.markSubscriptionPaid(sub.id)) paid++;
        }
        final skipped = subs.length - paid;
        _exitSelectionMode();
        OneUIToast.show(
          context,
          paid == 0
              ? 'Already marked paid today'
              : '${_plural(paid, 'subscription')} marked as paid${skipped > 0 ? ' · $skipped already paid today' : ''}',
        );
      },
    );
  }

  void _skipSelected(SubscriptionStore store) {
    final subs = _selectedSubscriptions(store);
    if (subs.isEmpty) return;
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Skip the current cycle?',
      message: '${_plural(subs.length, 'subscription')} will move to their next renewal without logging a payment.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Skip',
      confirmTextColor: OneUITheme.accentAmber,
      onConfirm: () {
        Haptics.confirm();
        for (final sub in subs) {
          store.skipSubscriptionCycle(sub.id);
        }
        _exitSelectionMode();
        OneUIToast.show(context, 'Skipped ${_plural(subs.length, 'subscription')}');
      },
    );
  }

  void _pauseSelected(SubscriptionStore store) {
    final count = _selectedIds.length;
    if (count == 0) return;
    Haptics.confirm();
    store.batchTogglePause(Set.of(_selectedIds));
    _exitSelectionMode();
  }

  void _deleteSelected(SubscriptionStore store) {
    final ids = Set.of(_selectedIds);
    if (ids.isEmpty) return;
    Haptics.warn();
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete ${_plural(ids.length, 'subscription')}?',
      message: 'These subscriptions will be permanently deleted from your spend list.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () {
        Haptics.warn();
        store.batchDelete(ids);
        _exitSelectionMode();
        OneUIToast.show(context, 'Deleted ${_plural(ids.length, 'subscription')}');
      },
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
      final file = File(p.join(dir.path, 'One-Spend-renewals.ics'));
      AppLog.event(TelemetryEvent.exportShared(format: 'calendar', scope: 'upcoming'));
      await file.writeAsString(ics);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/calendar')],
          subject: 'One Spend renewals',
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

        final overdue = _charges(
          store,
          from: DateTime(1970),
          to: today.subtract(const Duration(days: 1)),
          now: now,
          includePaid: false,
        ).where(_matchesCard).toList();
        final unfilteredWindow = _charges(store, from: today, to: horizonEnd, now: now);
        final window = unfilteredWindow.where(_matchesCard).toList();
        final dueTotal = overdue.dueTotal(store.toMain) + window.dueTotal(store.toMain);

        // Drop selections whose subscriptions were deleted or paused elsewhere (only
        // needed when the data changed).
        if (_pruneRevision != store.revision) {
          _pruneRevision = store.revision;
          _selectedIds.removeWhere((id) => store.getSubscription(id) == null);
        }
        final selectedDay = _selectedDay ?? today;
        final visibleIds = <String>{
          for (final c in isCalendar
              ? _charges(store, from: selectedDay, to: selectedDay, now: now).where(_matchesCard)
              : [...overdue, ...window])
            // Paid charges are settled history: "select all" never picks them.
            if (!c.isPaid) c.subscription.id,
        };

        // Inside the tab shell, the nav bar morphs into the selection actions.
        _dockInShell = HomeShellScope.isHosted(context);
        if (_dockInShell) {
          final actions = _selectionActions(store);
          HomeChrome.dockBottomBar(
            1,
            _isSelectionMode ? OneUIFloatingActionBar(docked: true, items: actions) : null,
          );
        }

        return PopScope(
          // System back leaves selection mode before leaving the tab.
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _exitSelectionMode();
          },
          child: Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: OneUIScrollPhysics.bigHeader,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: 'Upcoming',
                      subtitle: _isSelectionMode
                          ? (_selectedIds.length == visibleIds.length
                              ? 'All selected • Tap (O) to deselect'
                              : 'Tap (O) to select all')
                          : '${_money(store.currency, dueTotal)} due in the ${_horizon.phrase}',
                      hasBigHeader: true,
                      expandedHeight: 270.0,
                      actionsPillKey: _headerActionsKey,
                      isSelectionMode: _isSelectionMode,
                      selectionLeading: _isSelectionMode
                          ? OneUISelectionCountPill(
                              selectedCount: _selectedIds.length,
                              totalCount: visibleIds.length,
                              onToggleSelectAll: () => _toggleSelectAll(visibleIds),
                            )
                          : null,
                      onSelectionCancel: _isSelectionMode ? _exitSelectionMode : null,
                      actions: _isSelectionMode ? null : [
                        OneUIHeaderAction(
                          icon: isCalendar ? Icons.view_agenda_outlined : Icons.calendar_month_outlined,
                          tooltip: isCalendar ? 'Timeline view' : 'Calendar view',
                          onTap: () {
                            Haptics.tap();
                            _exitSelectionMode();
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

              // Floating selection action bar (inside the tab shell the nav bar morphs
              // into these actions instead).
              if (!_dockInShell)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: _isSelectionMode ? 0 : -120,
                child: IgnorePointer(
                  ignoring: !_isSelectionMode,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    opacity: _isSelectionMode ? 1.0 : 0.0,
                    child: Center(
                      child: OneUIFloatingActionBar(
                        items: _selectionActions(store),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  List<OneUIFloatingActionBarItem> _selectionActions(SubscriptionStore store) => [
    OneUIFloatingActionBarItem(
      label: 'Mark paid',
      icon: Icons.check_circle_outline_rounded,
      color: OneUITheme.accentGreen,
      isEnabled: _selectedIds.isNotEmpty,
      onTap: () => _markSelectedPaid(store),
    ),
    OneUIFloatingActionBarItem(
      label: 'Skip',
      icon: Icons.redo_rounded,
      isEnabled: _selectedIds.isNotEmpty,
      onTap: () => _skipSelected(store),
    ),
    OneUIFloatingActionBarItem(
      label: 'Pause',
      icon: Icons.pause_circle_outline_rounded,
      isEnabled: _selectedIds.isNotEmpty,
      onTap: () => _pauseSelected(store),
    ),
    OneUIFloatingActionBarItem(
      label: 'Delete',
      icon: Icons.delete_outline_rounded,
      color: OneUITheme.accentRed,
      isEnabled: _selectedIds.isNotEmpty,
      onTap: () => _deleteSelected(store),
    ),
  ];

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
    final byCard = [...overdue, ...unfilteredWindow].byPaymentMethod(normalizeId: _cardKey, toMain: store.toMain);
    final cardColors = _cardColors(byCard);
    final filteredByCard = [...overdue, ...window].byPaymentMethod(normalizeId: _cardKey, toMain: store.toMain);

    return [
      _padded(
        OneUISegmentedPills<UpcomingHorizon>(
          segments: [for (final h in UpcomingHorizon.values) (value: h, label: h.label)],
          selected: _horizon,
          onChanged: (h) {
            _exitSelectionMode();
            setState(() => _horizon = h);
          },
        ),
        top: 6,
      ),
      if (_cardFilter != null) _padded(_filterPill(store), top: 10),
      if (window.unpaid.isNotEmpty || overdue.isNotEmpty)
        _padded(
          OneUIUpcomingHeroCard(
            horizonPhrase: _horizon.phrase,
            charges: [...overdue, ...window],
            annualSoon: ChargeSchedule.annualRenewalsWithin(store.subscriptions, now: now).where(_matchesCard).toList(),
            currency: store.currency,
            toMain: store.toMain,
            cardSegments: [
              for (final entry in filteredByCard.entries)
                (color: cardColors[entry.key] ?? _noCardColor, total: entry.value.total),
            ],
            onOpenSubscription: _isSelectionMode ? null : (sub) => context.push(AppRoutes.subscriptionDetail(sub.id)),
          ),
          top: 14,
        ),
      if (_cardFilter == null && byCard.isNotEmpty) _padded(_byCardSection(store, byCard, cardColors), top: 4),
      if (overdue.isNotEmpty)
        _padded(
          OneUISection(
            title: 'Overdue (${overdue.length})',
            trailing: _sectionAmount(_money(store.currency, overdue.dueTotal(store.toMain)), color: OneUITheme.accentRed),
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
            trailing: entry.value.dueTotal(store.toMain) > 0
                ? _sectionAmount(_money(store.currency, entry.value.dueTotal(store.toMain)))
                : null,
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
            Haptics.select();
            _exitSelectionMode();
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

  Widget _byCardSection(
    SubscriptionStore store,
    Map<String?, ({double total, int count})> byCard,
    Map<String?, Color> cardColors,
  ) {
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
                        // Same colour as this card's segment in the hero card's split bar.
                        color: cardColors[entry.key] ?? _noCardColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: OneUIFitAmount(
                _money(store.currency, entry.value.total),
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
              ),
              onTap: () {
                Haptics.select();
                _exitSelectionMode();
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
    final charges = _charges(
      store,
      from: firstMonth,
      to: DateTime(lastMonth.year, lastMonth.month + 1, 0),
      now: now,
    ).where(_matchesCard).toList();
    final byDay = charges.byDay();

    final markers = {
      for (final entry in byDay.entries)
        entry.key: CalendarDayMarker(
          dotColors: [for (final c in entry.value) Color(c.subscription.brandColorValue)],
          amount: entry.value.dueTotal(store.toMain),
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
            '${_monthYear.format(visibleMonth)} · ${_money(store.currency, monthCharges.dueTotal(store.toMain))} due'
            '${monthCharges.any((c) => c.isPaid) ? ' · ${_money(store.currency, monthCharges.paidTotal(store.toMain))} paid' : ''}',
            style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
          ),
        ),
        top: 10,
      ),
      _padded(
        OneUISection(
          title: _dayLabel(selected, today),
          trailing: dayCharges.dueTotal(store.toMain) > 0
              ? _sectionAmount(_money(store.currency, dayCharges.dueTotal(store.toMain)))
              : null,
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
          OneUIFitAmount(
            formatMoney(sub.price, sub.currency),
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: charge.isPaid ? OneUITheme.textSecondary : OneUITheme.textPrimary,
              decoration: charge.isPaid ? TextDecoration.lineThrough : null,
              decorationColor: OneUITheme.textSecondary,
            ),
          ),
          // Paid charges can't be selected (selecting one would pay the
          // subscription's *next* renewal again), so they keep their check.
          if (_isSelectionMode && !charge.isPaid) ...[
            const SizedBox(width: 10),
            _selectionCircle(isSelected: _selectedIds.contains(sub.id), name: sub.name),
          ] else if (charge.isPaid || isNextCharge)
            const SizedBox(width: 8),
          if (_isSelectionMode && !charge.isPaid)
            const SizedBox.shrink()
          else if (charge.isPaid)
            const Icon(Icons.check_circle_rounded, color: OneUITheme.accentGreen, size: 22)
          else if (isNextCharge)
            Semantics(
              button: true,
              label: 'Mark ${sub.name} as paid',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _confirmMarkPaid(store, sub),
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
        if (_isSelectionMode) {
          if (!charge.isPaid) _toggleSelected(sub.id);
          return;
        }
        Haptics.tap();
        context.push(AppRoutes.subscriptionDetail(sub.id));
      },
      // Paid charges ignore long-press (no selection, and no accidental tap-through).
      onLongPress: charge.isPaid
          ? () {}
          : () => _isSelectionMode ? _toggleSelected(sub.id) : _enterSelectionMode(sub.id),
    );
  }

  /// One UI selection circle shown in place of row actions while selecting.
  Widget _selectionCircle({required bool isSelected, required String name}) {
    return Semantics(
      container: true,
      checked: isSelected,
      label: isSelected ? '$name selected' : 'Select $name',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFF2C69FF) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF2C69FF) : Colors.white.withValues(alpha: 0.45),
            width: 2,
          ),
        ),
        child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
      ),
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
          Haptics.tap();
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
      child: OneUIFitAmount(
        text,
        maxWidth: 160,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _padded(Widget child, {double top = 8}) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}
