import '../entities/subscription.dart';
import '../entities/subscription_enums.dart';

/// Pure Domain Repository contract for Subscriptions and user preference storage.
/// Decoupled from any storage engine (SharedPreferences, Drift, SQLite, Cloud).
abstract class SubscriptionRepository {
  Future<List<Subscription>> getSubscriptions();
  Future<void> saveSubscriptions(List<Subscription> subscriptions);
  Future<void> addSubscription(Subscription subscription);
  Future<void> updateSubscription(Subscription subscription);
  Future<void> deleteSubscription(String id);

  Future<double> getMonthlyBudget();
  Future<void> setMonthlyBudget(double budget);

  Future<String> getCurrency();
  Future<void> setCurrency(String currency);

  Future<({String name, String email})> getUserProfile();
  Future<void> setUserProfile(String name, String email);

  Future<int> getDefaultReminderDays();
  Future<void> setDefaultReminderDays(int days);

  Future<SubscriptionSortOption> getSortOption();
  Future<void> setSortOption(SubscriptionSortOption option);

  Future<bool> getGroupByDate();
  Future<void> setGroupByDate(bool value);

  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearches(List<String> searches);
}
