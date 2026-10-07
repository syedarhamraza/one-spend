import 'dart:convert';
import '../../../../core/database/app_database.dart';
import '../../../currency/domain/currency.dart';

/// Drift SQLite key/value storage for user preferences, backed by the app_settings table.
class SettingsDriftDataSource {
  final AppDatabase db;

  static const String keyBudget = 'onespend_monthly_budget';
  static const String keyCurrency = 'onespend_currency';
  static const String keyUserName = 'onespend_user_name';
  static const String keyUserEmail = 'onespend_user_email';
  static const String keyDefaultReminder = 'onespend_default_reminder';
  static const String keySortOption = 'onespend_sort_option';
  static const String keyGroupByDate = 'onespend_group_by_date';
  static const String keyRecentSearches = 'onespend_recent_searches';
  static const String keyDismissedInsights = 'onespend_dismissed_insights';
  static const String keyLastBackupAt = 'onespend_last_backup_at';
  static const String keyTrackingSince = 'onespend_tracking_since';
  static const String keyOnboardingDone = 'onespend_onboarding_done';
  static const String keyNotificationsEnabled = 'onespend_notifications_enabled';
  static const String keyAutoUpdateCheck = 'onespend_auto_update_check';
  static const String keyReminderTime = 'onespend_reminder_time_minutes';
  static const String keyHapticsEnabled = 'onespend_haptics_enabled';
  static const String keyNotificationVibration = 'onespend_notification_vibration';
  static const int defaultReminderTimeMinutes = 9 * 60;
  static const String appearancePrefix = 'appearance.';

  const SettingsDriftDataSource(this.db);

  Future<double> getMonthlyBudget() async {
    final val = await db.getSetting(keyBudget);
    if (val == null) return 150.0;
    return double.tryParse(val) ?? 150.0;
  }

  Future<void> setMonthlyBudget(double amount) async {
    await db.setSetting(keyBudget, amount.toString());
  }

  Future<String> getCurrency() async {
    return CurrencyCatalog.normalize(await db.getSetting(keyCurrency));
  }

  Future<void> setCurrency(String currency) async {
    await db.setSetting(keyCurrency, currency);
  }

  Future<({String name, String email})> getUserProfile() async {
    final name = (await db.getSetting(keyUserName)) ?? '';
    final email = (await db.getSetting(keyUserEmail)) ?? '';
    return (name: name, email: email);
  }

  Future<void> setUserProfile(String name, String email) async {
    await db.setSetting(keyUserName, name);
    await db.setSetting(keyUserEmail, email);
  }

  Future<int> getDefaultReminderDays() async {
    final val = await db.getSetting(keyDefaultReminder);
    if (val == null) return 2;
    return int.tryParse(val) ?? 2;
  }

  Future<void> setDefaultReminderDays(int days) async {
    await db.setSetting(keyDefaultReminder, days.toString());
  }

  Future<String?> getSortOptionName() async {
    return await db.getSetting(keySortOption);
  }

  Future<void> setSortOptionName(String name) async {
    await db.setSetting(keySortOption, name);
  }

  Future<bool> getGroupByDate() async {
    final val = await db.getSetting(keyGroupByDate);
    if (val == null) return false;
    return val.toLowerCase() == 'true';
  }

  Future<void> setGroupByDate(bool value) async {
    await db.setSetting(keyGroupByDate, value.toString());
  }

  Future<bool> getNotificationsEnabled() async {
    final val = await db.getSetting(keyNotificationsEnabled);
    return val == null || val.toLowerCase() == 'true';
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await db.setSetting(keyNotificationsEnabled, value.toString());
  }

  Future<int> getDefaultReminderTimeMinutes() async {
    final val = int.tryParse(await db.getSetting(keyReminderTime) ?? '');
    if (val == null || val < 0 || val >= 24 * 60) return defaultReminderTimeMinutes;
    return val;
  }

  Future<void> setDefaultReminderTimeMinutes(int minutes) async {
    await db.setSetting(keyReminderTime, minutes.toString());
  }

  Future<List<String>> getRecentSearches() async {
    final val = await db.getSetting(keyRecentSearches);
    if (val == null || val.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(val) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentSearches(List<String> searches) async {
    await db.setSetting(keyRecentSearches, jsonEncode(searches));
  }

  Future<List<String>> getDismissedInsights() async {
    final val = await db.getSetting(keyDismissedInsights);
    if (val == null || val.isEmpty) return [];
    try {
      return (jsonDecode(val) as List<dynamic>).map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setDismissedInsights(List<String> keys) async {
    await db.setSetting(keyDismissedInsights, jsonEncode(keys));
  }

  Future<DateTime?> getLastBackupAt() async {
    final val = await db.getSetting(keyLastBackupAt);
    return val == null ? null : DateTime.tryParse(val);
  }

  Future<void> setLastBackupAt(DateTime value) async {
    await db.setSetting(keyLastBackupAt, value.toIso8601String());
  }

  Future<String?> getAutoUpdateCheck() => db.getSetting(keyAutoUpdateCheck);

  Future<void> setAutoUpdateCheck(String value) async {
    await db.setSetting(keyAutoUpdateCheck, value);
  }

  Future<DateTime?> getTrackingSince() async {
    final val = await db.getSetting(keyTrackingSince);
    return val == null ? null : DateTime.tryParse(val);
  }

  Future<void> setTrackingSince(DateTime value) async {
    await db.setSetting(keyTrackingSince, value.toIso8601String());
  }

  Future<bool> getOnboardingDone() async => (await db.getSetting(keyOnboardingDone)) == 'true';

  Future<void> setOnboardingDone(bool value) async {
    await db.setSetting(keyOnboardingDone, value.toString());
  }

  Future<bool> getHapticsEnabled() async => (await db.getSetting(keyHapticsEnabled)) != 'false';

  Future<void> setHapticsEnabled(bool value) async {
    await db.setSetting(keyHapticsEnabled, value.toString());
  }

  Future<bool> getNotificationVibration() async => (await db.getSetting(keyNotificationVibration)) != 'false';

  Future<void> setNotificationVibration(bool value) async {
    await db.setSetting(keyNotificationVibration, value.toString());
  }

  Future<Map<String, String>> getAppearanceSettings() {
    return db.getSettingsWithPrefix(appearancePrefix);
  }

  Future<void> setAppearanceSettings(Map<String, String> values) async {
    if (values.isEmpty) return;
    await db.transaction(() async {
      for (final entry in values.entries) {
        await db.setSetting('$appearancePrefix${entry.key}', entry.value);
      }
    });
  }
}
