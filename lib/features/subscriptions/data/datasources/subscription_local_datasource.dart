import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/subscription_model.dart';

/// Abstract Local DataSource contract for Subscription data.
/// Cleanly decoupled so Drift/SQLite can replace SharedPreferences in the future.
abstract class SubscriptionLocalDataSource {
  Future<List<SubscriptionModel>> loadSubscriptions();
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions);

  Future<double> getMonthlyBudget();
  Future<void> setMonthlyBudget(double amount);

  Future<String> getCurrency();
  Future<void> setCurrency(String currency);

  Future<({String name, String email})> getUserProfile();
  Future<void> setUserProfile(String name, String email);

  Future<int> getDefaultReminderDays();
  Future<void> setDefaultReminderDays(int days);

  Future<String?> getSortOptionName();
  Future<void> setSortOptionName(String name);

  Future<bool> getGroupByDate();
  Future<void> setGroupByDate(bool value);
}

/// SharedPreferences implementation of SubscriptionLocalDataSource
class SubscriptionPreferencesDataSource implements SubscriptionLocalDataSource {
  SharedPreferences? _prefs;

  static const String keySubs = 'onespend_subscriptions';
  static const String keyBudget = 'onespend_monthly_budget';
  static const String keyCurrency = 'onespend_currency';
  static const String keyUserName = 'onespend_user_name';
  static const String keyUserEmail = 'onespend_user_email';
  static const String keyDefaultReminder = 'onespend_default_reminder';
  static const String keySortOption = 'onespend_sort_option';
  static const String keyGroupByDate = 'onespend_group_by_date';

  SubscriptionPreferencesDataSource([this._prefs]);

  Future<SharedPreferences> get _getPrefs async => _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<List<SubscriptionModel>> loadSubscriptions() async {
    try {
      final prefs = await _getPrefs;
      final subsJson = prefs.getString(keySubs);
      if (subsJson == null || subsJson.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(subsJson) as List<dynamic>;
      return decoded.map((item) => SubscriptionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw StorageException('Failed to read subscriptions from storage', e);
    }
  }

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async {
    try {
      final prefs = await _getPrefs;
      final jsonStr = jsonEncode(subscriptions.map((s) => s.toJson()).toList());
      await prefs.setString(keySubs, jsonStr);
    } catch (e) {
      throw StorageException('Failed to save subscriptions to storage', e);
    }
  }

  @override
  Future<double> getMonthlyBudget() async => (await _getPrefs).getDouble(keyBudget) ?? 150.0;

  @override
  Future<void> setMonthlyBudget(double amount) async => await (await _getPrefs).setDouble(keyBudget, amount);

  @override
  Future<String> getCurrency() async => (await _getPrefs).getString(keyCurrency) ?? '\$';

  @override
  Future<void> setCurrency(String currency) async => await (await _getPrefs).setString(keyCurrency, currency);

  @override
  Future<({String name, String email})> getUserProfile() async {
    final prefs = await _getPrefs;
    final name = prefs.getString(keyUserName) ?? 'Syed Arham Raza';
    final email = prefs.getString(keyUserEmail) ?? 'syed@onespend.app';
    return (name: name, email: email);
  }

  @override
  Future<void> setUserProfile(String name, String email) async {
    final prefs = await _getPrefs;
    await prefs.setString(keyUserName, name);
    await prefs.setString(keyUserEmail, email);
  }

  @override
  Future<int> getDefaultReminderDays() async => (await _getPrefs).getInt(keyDefaultReminder) ?? 2;

  @override
  Future<void> setDefaultReminderDays(int days) async => await (await _getPrefs).setInt(keyDefaultReminder, days);

  @override
  Future<String?> getSortOptionName() async => (await _getPrefs).getString(keySortOption);

  @override
  Future<void> setSortOptionName(String name) async => await (await _getPrefs).setString(keySortOption, name);

  @override
  Future<bool> getGroupByDate() async => (await _getPrefs).getBool(keyGroupByDate) ?? false;

  @override
  Future<void> setGroupByDate(bool value) async => await (await _getPrefs).setBool(keyGroupByDate, value);
}
