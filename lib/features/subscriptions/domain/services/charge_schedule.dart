import 'package:equatable/equatable.dart';
import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';

enum ChargeStatus { upcoming, overdue, paid }

/// One concrete charge of a subscription on a specific day.
class UpcomingCharge extends Equatable {
  final Subscription subscription;

  /// Calendar day of the charge (no time part).
  final DateTime date;
  final ChargeStatus status;

  const UpcomingCharge({required this.subscription, required this.date, required this.status});

  double get amount => subscription.price;
  String get currency => subscription.currency;
  String? get paymentMethodId => subscription.paymentMethodId;
  bool get isPaid => status == ChargeStatus.paid;

  @override
  List<Object?> get props => [subscription.id, date, status];
}

/// Expands subscriptions into their individual charges over a date range.
///
/// Uses the same [Subscription.calculateNextDateFrom] stepping as billing and notifications,
/// so weekly subscriptions appear on every billing day and month-end dates clamp identically.
class ChargeSchedule {
  const ChargeSchedule._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Every charge in `[from, to]` (inclusive, by calendar day), sorted by date then name.
  ///
  /// - Paused subscriptions are skipped.
  /// - Projected charges come from `nextBillingDate` onwards. An unpaid `nextBillingDate`
  ///   before today is a single **overdue** charge; projection then resumes from today.
  /// - With [includePaid], logged `paymentHistory` entries in range are included as **paid**.
  static List<UpcomingCharge> between(
    Iterable<Subscription> subscriptions, {
    required DateTime from,
    required DateTime to,
    required DateTime now,
    bool includePaid = true,
  }) {
    final start = dateOnly(from);
    final end = dateOnly(to);
    final today = dateOnly(now);
    bool inRange(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

    final charges = <UpcomingCharge>[];
    for (final sub in subscriptions) {
      if (sub.status == SubscriptionStatus.paused) continue;

      if (includePaid) {
        for (final paid in sub.paymentHistory) {
          final day = dateOnly(paid);
          if (inRange(day)) charges.add(UpcomingCharge(subscription: sub, date: day, status: ChargeStatus.paid));
        }
      }

      var due = dateOnly(sub.nextBillingDate);
      if (due.isBefore(today)) {
        if (inRange(due)) charges.add(UpcomingCharge(subscription: sub, date: due, status: ChargeStatus.overdue));
        // Missed cycles aren't repeated: marking paid jumps straight to the next future date.
        for (var i = 0; i < 1000 && due.isBefore(today); i++) {
          due = dateOnly(sub.calculateNextDateFrom(due));
        }
      }
      for (var i = 0; i < 1000 && !due.isAfter(end); i++) {
        if (inRange(due)) charges.add(UpcomingCharge(subscription: sub, date: due, status: ChargeStatus.upcoming));
        due = dateOnly(sub.calculateNextDateFrom(due));
      }
    }

    charges.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.subscription.name.toLowerCase().compareTo(b.subscription.name.toLowerCase());
    });
    return charges;
  }

  /// Yearly subscriptions whose next charge falls within [days] of [now], soonest first.
  static List<UpcomingCharge> annualRenewalsWithin(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    int days = 90,
  }) {
    final yearly = subscriptions.where((s) => s.billingCycle == BillingCycle.yearly);
    final charges = between(yearly, from: now, to: dateOnly(now).add(Duration(days: days)), now: now, includePaid: false);
    final seen = <String>{};
    return [
      for (final c in charges)
        if (seen.add(c.subscription.id)) c,
    ];
  }
}

/// Aggregates over a list of charges.
extension ChargeListSummary on List<UpcomingCharge> {
  /// Charges still to be paid (upcoming + overdue).
  List<UpcomingCharge> get unpaid => where((c) => !c.isPaid).toList();

  /// Sum of unpaid charge amounts.
  double get dueTotal => unpaid.fold(0.0, (sum, c) => sum + c.amount);

  /// Charges grouped by calendar day, in date order.
  Map<DateTime, List<UpcomingCharge>> byDay() {
    final map = <DateTime, List<UpcomingCharge>>{};
    for (final c in this) {
      (map[c.date] ??= []).add(c);
    }
    return map;
  }

  /// Unpaid totals per payment method id (null = no card), largest first.
  ///
  /// [normalizeId] maps raw ids before grouping, e.g. so ids of deleted cards fold into null.
  Map<String?, ({double total, int count})> byPaymentMethod({String? Function(String? id)? normalizeId}) {
    final totals = <String?, ({double total, int count})>{};
    for (final c in unpaid) {
      final key = normalizeId == null ? c.paymentMethodId : normalizeId(c.paymentMethodId);
      final current = totals[key] ?? (total: 0.0, count: 0);
      totals[key] = (total: current.total + c.amount, count: current.count + 1);
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.total.compareTo(a.value.total));
    return Map.fromEntries(entries);
  }

  /// The largest unpaid charge (earliest on ties).
  UpcomingCharge? get biggest {
    UpcomingCharge? best;
    for (final c in unpaid) {
      if (best == null || c.amount > best.amount) best = c;
    }
    return best;
  }

  /// The 7-day window (starting on a charge day) with the highest unpaid total.
  ({DateTime start, double total, int count})? busiestWeek() {
    final charges = unpaid;
    ({DateTime start, double total, int count})? best;
    for (final anchor in charges) {
      final windowEnd = anchor.date.add(const Duration(days: 6));
      final inWindow = charges.where((c) => !c.date.isBefore(anchor.date) && !c.date.isAfter(windowEnd));
      final total = inWindow.fold(0.0, (sum, c) => sum + c.amount);
      if (best == null || total > best.total) {
        best = (start: anchor.date, total: total, count: inWindow.length);
      }
    }
    return best;
  }
}
