import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';

/// Pure billing-date arithmetic for advancing subscriptions through their cycles.
class BillingSchedule {
  const BillingSchedule._();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// First billing date after [sub]'s current one that is not before today.
  static DateTime nextDueDate(Subscription sub, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    var next = sub.calculateNextDateFrom(sub.nextBillingDate);
    while (next.isBefore(today)) {
      next = sub.calculateNextDateFrom(next);
    }
    return next;
  }

  /// Marks the current cycle as paid: logs one payment and advances to the next due date.
  static Subscription markPaid(Subscription sub, {DateTime? paymentDate, DateTime? now}) {
    final current = now ?? DateTime.now();
    final dateToLog = paymentDate ?? (sub.nextBillingDate.isBefore(current) ? sub.nextBillingDate : current);
    final history = List<DateTime>.from(sub.paymentHistory)
      ..add(dateToLog)
      ..sort((a, b) => b.compareTo(a));
    return sub.copyWith(
      nextBillingDate: nextDueDate(sub, now: current),
      paymentHistory: history,
    );
  }

  /// Skips the current cycle without logging a payment.
  static Subscription skipCycle(Subscription sub, {DateTime? now}) {
    return sub.copyWith(nextBillingDate: nextDueDate(sub, now: now));
  }

  /// Whether [sub] auto-renews and has a billing date strictly before today.
  static bool isAutoRenewDue(Subscription sub, {DateTime? now}) {
    if (!sub.autoRenew || sub.status == SubscriptionStatus.paused) return false;
    return _dateOnly(sub.nextBillingDate).isBefore(_dateOnly(now ?? DateTime.now()));
  }

  /// Records one payment for every billing date that elapsed before today and
  /// advances to the first date that is today or later.
  static Subscription applyAutoRenewal(Subscription sub, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final history = List<DateTime>.from(sub.paymentHistory);
    var due = sub.nextBillingDate;
    while (_dateOnly(due).isBefore(today)) {
      history.add(due);
      due = sub.calculateNextDateFrom(due);
    }
    history.sort((a, b) => b.compareTo(a));
    return sub.copyWith(nextBillingDate: due, paymentHistory: history);
  }
}
