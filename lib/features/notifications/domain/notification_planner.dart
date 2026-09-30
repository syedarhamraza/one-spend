import 'package:intl/intl.dart';
import '../../currency/domain/exchange_rates.dart';
import '../../currency/domain/money_format.dart';
import '../../payment_methods/domain/entities/payment_method.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
import '../../subscriptions/domain/services/charge_schedule.dart';
import '../../subscriptions/domain/services/subscription_stats.dart';
import 'planned_notification.dart';

/// Pure computation of every local notification the app should have scheduled right now.
///
/// The result only covers a rolling [window] and is capped at [maxCount]; the scheduler
/// re-plans on every data change and app resume, so the window keeps moving forward.
class NotificationPlanner {
  const NotificationPlanner._();

  static const Duration window = Duration(days: 60);
  static const int maxCount = 50;

  static final DateFormat _dayFormat = DateFormat('MMM d');
  static final DateFormat _monthFormat = DateFormat('MMMM');

  static List<PlannedNotification> plan({
    required List<Subscription> subscriptions,
    required List<PaymentMethod> paymentMethods,
    required double monthlyBudget,
    required String currency,
    required int defaultReminderTimeMinutes,
    required DateTime now,
    ToMainCurrency toMain = sameCurrency,
  }) {
    final horizon = now.add(window);
    final planned = <PlannedNotification>[
      for (final sub in subscriptions)
        ..._subscriptionReminders(sub, defaultReminderTimeMinutes, now, horizon),
      for (final method in paymentMethods)
        ?_cardExpiry(method, defaultReminderTimeMinutes, now, horizon),
      ..._budgetAlerts(subscriptions, monthlyBudget, currency, toMain, defaultReminderTimeMinutes, now, horizon),
    ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return planned.length > maxCount ? planned.sublist(0, maxCount) : planned;
  }

  /// The reminder time for [sub], falling back to the global default.
  static int effectiveReminderMinutes(Subscription sub, int defaultMinutes) =>
      sub.reminderTimeMinutes ?? defaultMinutes;

  static DateTime _at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  static String _relativeDay(int days) => switch (days) {
        0 => 'today',
        1 => 'tomorrow',
        _ => 'in $days days',
      };

  static Iterable<PlannedNotification> _subscriptionReminders(
    Subscription sub,
    int defaultMinutes,
    DateTime now,
    DateTime horizon,
  ) sync* {
    if (sub.status == SubscriptionStatus.paused) return;
    final minutes = effectiveReminderMinutes(sub, defaultMinutes);
    final price = formatMoney(sub.price, sub.currency);

    var due = sub.nextBillingDate;
    // Bounded loop: billing dates only move forward, and we stop once past the horizon.
    for (var i = 0; i < 400; i++, due = sub.calculateNextDateFrom(due)) {
      final fireAt = _at(DateTime(due.year, due.month, due.day - sub.reminderDays), minutes);
      if (fireAt.isAfter(horizon)) return;
      if (!fireAt.isAfter(now)) continue;

      final dueKey = DateFormat('yyyy-MM-dd').format(due);
      yield PlannedNotification(
        id: PlannedNotification.stableId('renewal|${sub.id}|$dueKey'),
        kind: NotificationKind.renewal,
        fireAt: fireAt,
        title: '${sub.name} renews ${_relativeDay(sub.reminderDays)}',
        body: '$price will be charged on ${_dayFormat.format(due)}.',
        subjectId: sub.id,
      );
    }
  }

  static PlannedNotification? _cardExpiry(PaymentMethod method, int minutes, DateTime now, DateTime horizon) {
    final month = method.expiryMonth;
    final year = method.expiryYear;
    if (month == null || year == null || month < 1 || month > 12) return null;
    // Expired relative to [now] (not the wall clock) so planning stays deterministic.
    if (year < now.year || (year == now.year && month < now.month)) return null;

    // Warn on the 1st of the month before expiry; if that has passed, on the 1st of the expiry month.
    final monthBefore = _at(DateTime(year, month - 1, 1), minutes);
    final expiryMonth = _at(DateTime(year, month, 1), minutes);
    final fireAt = monthBefore.isAfter(now) ? monthBefore : expiryMonth;
    if (!fireAt.isAfter(now) || fireAt.isAfter(horizon)) return null;

    return PlannedNotification(
      id: PlannedNotification.stableId('card|${method.id}|${method.expiryDate}'),
      kind: NotificationKind.card,
      fireAt: fireAt,
      title: 'Card expiring soon',
      body: '${method.displayName} expires ${method.expiryDate}. Update the subscriptions that use it.',
      subjectId: method.id,
    );
  }

  static Iterable<PlannedNotification> _budgetAlerts(
    List<Subscription> subscriptions,
    double budget,
    String currency,
    ToMainCurrency toMain,
    int minutes,
    DateTime now,
    DateTime horizon,
  ) sync* {
    if (budget <= 0) return;
    final billable = SubscriptionStats.billable(subscriptions).toList();

    for (var offset = 0; offset < 2; offset++) {
      final monthStart = DateTime(now.year, now.month + offset, 1);
      final monthLastDay = DateTime(monthStart.year, monthStart.month + 1, 0);

      // Charges already paid this month (history) plus projected and overdue billing dates.
      final charges = ChargeSchedule.between(billable, from: monthStart, to: monthLastDay, now: now);

      var total = 0.0;
      for (final charge in charges) {
        total += toMain(charge.amount, charge.currency);
        if (total <= budget) continue;
        // Only alert about a crossing that is still ahead of us.
        final fireAt = _at(charge.date, minutes);
        if (fireAt.isAfter(now) && !fireAt.isAfter(horizon)) {
          final monthKey = DateFormat('yyyy-MM').format(monthStart);
          yield PlannedNotification(
            id: PlannedNotification.stableId('budget|$monthKey'),
            kind: NotificationKind.budget,
            fireAt: fireAt,
            title: 'Over budget on ${_dayFormat.format(charge.date)}',
            body: '${charge.subscription.name} (${formatMoney(charge.amount, charge.currency)}) takes '
                '${_monthFormat.format(monthStart)} spending to ${formatMoney(total, currency, style: MoneyStyle.summary)}, '
                'over your ${formatMoney(budget, currency, style: MoneyStyle.summary)} budget.',
            subjectId: monthKey,
          );
        }
        break;
      }
    }
  }
}
