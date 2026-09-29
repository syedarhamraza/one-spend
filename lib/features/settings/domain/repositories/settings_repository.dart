import '../../../subscriptions/domain/entities/subscription_enums.dart';

/// Pure Domain Repository contract for user preferences and appearance settings.
abstract class SettingsRepository {
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

  /// Raw appearance (card studio / effects) values, keyed by setting name.
  Future<Map<String, String>> getAppearanceSettings();
  Future<void> setAppearanceSettings(Map<String, String> values);
}
