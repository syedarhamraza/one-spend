import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';

/// Pure aggregate calculations over a list of subscriptions.
class SubscriptionStats {
  const SubscriptionStats._();

  /// Subscriptions that count toward spend (excludes paused and free trials).
  static Iterable<Subscription> billable(Iterable<Subscription> subs) {
    return subs.where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial);
  }

  static double totalMonthlySpend(Iterable<Subscription> subs) {
    return billable(subs).fold<double>(0.0, (acc, sub) => acc + sub.monthlyCost);
  }

  static int activeCount(Iterable<Subscription> subs) {
    return subs.where((s) => s.status == SubscriptionStatus.active || s.status == SubscriptionStatus.dueSoon).length;
  }

  static int pausedCount(Iterable<Subscription> subs) {
    return subs.where((s) => s.status == SubscriptionStatus.paused).length;
  }

  static List<Subscription> upcomingDue(Iterable<Subscription> subs) {
    return subs.where((s) => s.status != SubscriptionStatus.paused).toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  static List<Subscription> sorted(Iterable<Subscription> subs, SubscriptionSortOption option) {
    final list = List<Subscription>.from(subs);
    switch (option) {
      case SubscriptionSortOption.renewalAsc:
        list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      case SubscriptionSortOption.renewalDesc:
        list.sort((a, b) => b.nextBillingDate.compareTo(a.nextBillingDate));
      case SubscriptionSortOption.priceDesc:
        list.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
      case SubscriptionSortOption.priceAsc:
        list.sort((a, b) => a.monthlyCost.compareTo(b.monthlyCost));
      case SubscriptionSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SubscriptionSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return list;
  }

  static Subscription? highestCost(Iterable<Subscription> subs) {
    Subscription? highest;
    for (final sub in billable(subs)) {
      if (highest == null || sub.monthlyCost > highest.monthlyCost) highest = sub;
    }
    return highest;
  }

  static Map<SubscriptionCategory, double> categorySpend(Iterable<Subscription> subs) {
    final map = <SubscriptionCategory, double>{};
    for (final sub in billable(subs)) {
      map[sub.category] = (map[sub.category] ?? 0.0) + sub.monthlyCost;
    }
    return map;
  }
}
