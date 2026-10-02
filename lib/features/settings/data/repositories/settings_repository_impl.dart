import '../../../subscriptions/domain/entities/subscription_enums.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_drift_datasource.dart';

/// Concrete Repository for user preferences, mapping raw stored values to domain types.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDriftDataSource _dataSource;

  const SettingsRepositoryImpl(this._dataSource);

  @override
  Future<double> getMonthlyBudget() => _dataSource.getMonthlyBudget();

  @override
  Future<void> setMonthlyBudget(double budget) => _dataSource.setMonthlyBudget(budget);

  @override
  Future<String> getCurrency() => _dataSource.getCurrency();

  @override
  Future<void> setCurrency(String currency) => _dataSource.setCurrency(currency);

  @override
  Future<({String name, String email})> getUserProfile() => _dataSource.getUserProfile();

  @override
  Future<void> setUserProfile(String name, String email) => _dataSource.setUserProfile(name, email);

  @override
  Future<int> getDefaultReminderDays() => _dataSource.getDefaultReminderDays();

  @override
  Future<void> setDefaultReminderDays(int days) => _dataSource.setDefaultReminderDays(days);

  @override
  Future<SubscriptionSortOption> getSortOption() async {
    final name = await _dataSource.getSortOptionName();
    if (name != null) return SubscriptionSortOption.fromString(name);
    return SubscriptionSortOption.renewalAsc;
  }

  @override
  Future<void> setSortOption(SubscriptionSortOption option) => _dataSource.setSortOptionName(option.name);

  @override
  Future<bool> getGroupByDate() => _dataSource.getGroupByDate();

  @override
  Future<void> setGroupByDate(bool value) => _dataSource.setGroupByDate(value);

  @override
  Future<bool> getNotificationsEnabled() => _dataSource.getNotificationsEnabled();

  @override
  Future<void> setNotificationsEnabled(bool value) => _dataSource.setNotificationsEnabled(value);

  @override
  Future<int> getDefaultReminderTimeMinutes() => _dataSource.getDefaultReminderTimeMinutes();

  @override
  Future<void> setDefaultReminderTimeMinutes(int minutes) => _dataSource.setDefaultReminderTimeMinutes(minutes);

  @override
  Future<List<String>> getRecentSearches() => _dataSource.getRecentSearches();

  @override
  Future<void> saveRecentSearches(List<String> searches) => _dataSource.saveRecentSearches(searches);

  @override
  Future<List<String>> getDismissedInsights() => _dataSource.getDismissedInsights();

  @override
  Future<void> setDismissedInsights(List<String> keys) => _dataSource.setDismissedInsights(keys);

  @override
  Future<DateTime?> getLastBackupAt() => _dataSource.getLastBackupAt();

  @override
  Future<void> setLastBackupAt(DateTime value) => _dataSource.setLastBackupAt(value);

  @override
  Future<DateTime?> getTrackingSince() => _dataSource.getTrackingSince();

  @override
  Future<void> setTrackingSince(DateTime value) => _dataSource.setTrackingSince(value);

  @override
  Future<Map<String, String>> getAppearanceSettings() => _dataSource.getAppearanceSettings();

  @override
  Future<void> setAppearanceSettings(Map<String, String> values) => _dataSource.setAppearanceSettings(values);
}
