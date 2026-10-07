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

  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool value);

  /// Default reminder time of day, in minutes after midnight.
  Future<int> getDefaultReminderTimeMinutes();
  Future<void> setDefaultReminderTimeMinutes(int minutes);

  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearches(List<String> searches);

  /// Keys of Analytics insight cards the user dismissed, oldest first.
  Future<List<String>> getDismissedInsights();
  Future<void> setDismissedInsights(List<String> keys);

  /// When a backup was last saved to the device, if ever.
  Future<DateTime?> getLastBackupAt();
  Future<void> setLastBackupAt(DateTime value);

  /// When the user started tracking (their first subscription was added), if known.
  /// Spending history before this is not estimated.
  Future<DateTime?> getTrackingSince();
  Future<void> setTrackingSince(DateTime value);

  /// Whether the first-run welcome (onboarding) has been completed or skipped.
  Future<bool> getOnboardingDone();
  Future<void> setOnboardingDone(bool value);

  /// When One Spend checks Google Play for updates at launch (an `AutoUpdateCheck` name), if set.
  Future<String?> getAutoUpdateCheck();
  Future<void> setAutoUpdateCheck(String value);

  /// Settings › Vibration › Haptic feedback: taps vibrate (following the phone's own
  /// touch feedback setting). On by default.
  Future<bool> getHapticsEnabled();
  Future<void> setHapticsEnabled(bool value);

  /// Settings › Vibration › Vibrate for notifications. On by default.
  Future<bool> getNotificationVibration();
  Future<void> setNotificationVibration(bool value);

  /// Raw appearance (card studio / effects) values, keyed by setting name.
  Future<Map<String, String>> getAppearanceSettings();
  Future<void> setAppearanceSettings(Map<String, String> values);
}
