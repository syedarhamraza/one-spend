import 'package:intl/intl.dart';
import '../../payment_methods/domain/entities/payment_method.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';
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
  }) {
    final horizon = now.add(window);
    final planned = <PlannedNotification>[
      for (final sub in subscriptions)
        ..._subscriptionReminders(sub, defaultReminderTimeMinutes, now, horizon),
      for (final method in paymentMethods)
        ?_cardExpiry(method, defaultReminderTimeMinutes, now, horizon),
      ..._budgetAlerts(subscriptions, monthlyBudget, currency, defaultReminderTimeMinutes, now, horizon),
    ]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return planned.length > maxCount ? planned.sublist(0, maxCount) : planned;
  }

  /// The reminder time for [sub], falling back to the global default.
  static int effectiveReminderMinutes(Subscription sub, int defaultMinutes) =>
      sub.reminderTimeMinutes ?? defaultMinutes;

  static DateTime _at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  static String _money(String currency, double amount) => '$currency${amount.toStringAsFixed(2)}';

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
    final isTrial = sub.status == SubscriptionStatus.trial;
    final price = _money(sub.currency, sub.price);

    var due = sub.nextBillingDate;
    // Bounded loop: billing dates only move forward, and we stop once past the horizon.
    for (var i = 0; i < 400; i++, due = sub.calculateNextDateFrom(due)) {
      final fireAt = _at(DateTime(due.year, due.month, due.day - sub.reminderDays), minutes);
      if (fireAt.isAfter(horizon)) return;
      if (!fireAt.isAfter(now)) continue;

      final dueKey = DateFormat('yyyy-MM-dd').format(due);
      final when = _relativeDay(sub.reminderDays);
      if (isTrial) {
        // A trial converts once: warn about the first upcoming charge only.
        yield PlannedNotification(
          id: PlannedNotification.stableId('trial|${sub.id}|$dueKey'),
          kind: NotificationKind.trial,
          fireAt: fireAt,
          title: '${sub.name} trial ends $when',
          body: 'Cancel before ${_dayFormat.format(due)} or you\'ll be charged $price.',
          subjectId: sub.id,
        );
        return;
      }
      yield PlannedNotification(
        id: PlannedNotification.stableId('renewal|${sub.id}|$dueKey'),
        kind: NotificationKind.renewal,
        fireAt: fireAt,
        title: '${sub.name} renews $when',
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
    int minutes,
    DateTime now,
    DateTime horizon,
  ) sync* {
    if (budget <= 0) return;
    final billable = SubscriptionStats.billable(subscriptions).toList();

    for (var offset = 0; offset < 2; offset++) {
      final monthStart = DateTime(now.year, now.month + offset, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);
      bool inMonth(DateTime d) => !d.isBefore(monthStart) && d.isBefore(monthEnd);

      // Charges already paid this month (history) plus projected billing dates.
      final charges = <({DateTime date, Subscription sub})>[];
      for (final sub in billable) {
        for (final paid in sub.paymentHistory.where(inMonth)) {
          charges.add((date: paid, sub: sub));
        }
        var due = sub.nextBillingDate;
        for (var i = 0; i < 60 && due.isBefore(monthEnd); i++, due = sub.calculateNextDateFrom(due)) {
          if (inMonth(due)) charges.add((date: due, sub: sub));
        }
      }
      charges.sort((a, b) => a.date.compareTo(b.date));

      var total = 0.0;
      for (final charge in charges) {
        total += charge.sub.price;
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
            body: '${charge.sub.name} (${_money(currency, charge.sub.price)}) takes '
                '${_monthFormat.format(monthStart)} spending to ${_money(currency, total)}, '
                'over your ${_money(currency, budget)} budget.',
            subjectId: monthKey,
          );
        }
        break;
      }
    }
  }
}
