import '../../../currency/domain/exchange_rates.dart';
import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';

/// Pure aggregate calculations over a list of subscriptions.
///
/// Money results are in the main currency: [toMain] converts each subscription's
/// own-currency amount (identity by default).
class SubscriptionStats {
  const SubscriptionStats._();

  /// Subscriptions that count toward spend (excludes paused and free trials).
  static Iterable<Subscription> billable(Iterable<Subscription> subs) {
    return subs.where((s) => s.status != SubscriptionStatus.paused && s.status != SubscriptionStatus.trial);
  }

  /// [sub]'s monthly cost in the main currency.
  static double monthlyCost(Subscription sub, [ToMainCurrency toMain = sameCurrency]) =>
      toMain(sub.monthlyCost, sub.currency);

  static double totalMonthlySpend(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    return billable(subs).fold<double>(0.0, (acc, sub) => acc + monthlyCost(sub, toMain));
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

  static List<Subscription> sorted(
    Iterable<Subscription> subs,
    SubscriptionSortOption option, [
    ToMainCurrency toMain = sameCurrency,
  ]) {
    final list = List<Subscription>.from(subs);
    switch (option) {
      case SubscriptionSortOption.renewalAsc:
        list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      case SubscriptionSortOption.renewalDesc:
        list.sort((a, b) => b.nextBillingDate.compareTo(a.nextBillingDate));
      case SubscriptionSortOption.priceDesc:
        list.sort((a, b) => monthlyCost(b, toMain).compareTo(monthlyCost(a, toMain)));
      case SubscriptionSortOption.priceAsc:
        list.sort((a, b) => monthlyCost(a, toMain).compareTo(monthlyCost(b, toMain)));
      case SubscriptionSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SubscriptionSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return list;
  }

  static Subscription? highestCost(Iterable<Subscription> subs, [ToMainCurrency toMain = sameCurrency]) {
    Subscription? highest;
    double highestCost = 0;
    for (final sub in billable(subs)) {
      final cost = monthlyCost(sub, toMain);
      if (highest == null || cost > highestCost) {
        highest = sub;
        highestCost = cost;
      }
    }
    return highest;
  }

  static Map<SubscriptionCategory, double> categorySpend(
    Iterable<Subscription> subs, [
    ToMainCurrency toMain = sameCurrency,
  ]) {
    final map = <SubscriptionCategory, double>{};
    for (final sub in billable(subs)) {
      map[sub.category] = (map[sub.category] ?? 0.0) + monthlyCost(sub, toMain);
    }
    return map;
  }
}
