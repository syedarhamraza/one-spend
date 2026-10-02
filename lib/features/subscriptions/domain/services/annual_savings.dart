import '../../../currency/domain/exchange_rates.dart';
import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';
import 'subscription_stats.dart';

/// Switching one subscription to yearly billing, in its own currency.
/// [saving] is negative when the yearly plan costs more.
typedef AnnualSaving = ({Subscription subscription, double currentYearly, double annualPlan, double saving, double percent});

/// Pure logic behind the annual vs. monthly calculator (Pro).
class AnnualSavings {
  const AnnualSavings._();

  /// The comparison for [sub], or null when it doesn't apply: already yearly, no annual
  /// price set, or not being billed (paused or a free trial).
  static AnnualSaving? forSubscription(Subscription sub) {
    final annualPlan = sub.annualPlanPrice;
    if (annualPlan == null || annualPlan <= 0) return null;
    if (sub.billingCycle == BillingCycle.yearly) return null;
    if (!SubscriptionStats.billable([sub]).contains(sub)) return null;
    final currentYearly = sub.price * sub.billingCycle.occurrencesPerYear;
    if (currentYearly <= 0) return null;
    final saving = currentYearly - annualPlan;
    return (
      subscription: sub,
      currentYearly: currentYearly,
      annualPlan: annualPlan,
      saving: saving,
      percent: saving / currentYearly,
    );
  }

  /// Subscriptions that would cost less billed yearly, biggest saving first, and the
  /// total saving per year in the main currency.
  static ({double total, List<AnnualSaving> savings}) potential(
    Iterable<Subscription> subs, [
    ToMainCurrency toMain = sameCurrency,
  ]) {
    final savings = [
      for (final sub in subs)
        if (forSubscription(sub) case final s? when s.saving > 0) s,
    ]..sort((a, b) => toMain(b.saving, b.subscription.currency).compareTo(toMain(a.saving, a.subscription.currency)));
    final total = savings.fold(0.0, (sum, s) => sum + toMain(s.saving, s.subscription.currency));
    return (total: total, savings: savings);
  }
}
