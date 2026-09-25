import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/subscription_enums.dart';
import '../models/subscription_model.dart';
import 'subscription_local_datasource.dart';

/// Drift SQLite implementation of SubscriptionLocalDataSource.
class SubscriptionDriftDataSource implements SubscriptionLocalDataSource {
  final AppDatabase db;

  static const String keyBudget = 'onespend_monthly_budget';
  static const String keyCurrency = 'onespend_currency';
  static const String keyUserName = 'onespend_user_name';
  static const String keyUserEmail = 'onespend_user_email';
  static const String keyDefaultReminder = 'onespend_default_reminder';
  static const String keySortOption = 'onespend_sort_option';
  static const String keyGroupByDate = 'onespend_group_by_date';

  const SubscriptionDriftDataSource(this.db);

  @override
  Future<List<SubscriptionModel>> loadSubscriptions() async {
    try {
      final rows = await db.select(db.subscriptionsTable).get();
      return rows.map((row) {
        return SubscriptionModel(
          id: row.id,
          name: row.name,
          description: row.description,
          price: row.price,
          currency: row.currency,
          billingCycle: BillingCycle.fromString(row.billingCycle),
          category: SubscriptionCategory.fromString(row.category),
          brandColorValue: row.brandColorValue,
          iconCodePoint: row.iconCodePoint,
          iconFontFamily: row.iconFontFamily,
          nextBillingDate: row.nextBillingDate,
          status: SubscriptionStatus.fromString(row.status),
          paymentMethod: row.paymentMethod,
          paymentMethodId: row.paymentMethodId,
          reminderDays: row.reminderDays,
          isPopular: row.isPopular,
          notes: row.notes,
          paymentHistory: row.paymentHistory,
          accountUrl: row.accountUrl,
          logoUrl: row.logoUrl,
          brandPresetId: row.brandPresetId,
          autoRenew: row.autoRenew,
          anchorDay: row.anchorDay,
        );
      }).toList();
    } catch (e) {
      throw StorageException('Failed to read subscriptions from SQLite', e);
    }
  }

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async {
    try {
      await db.transaction(() async {
        await db.delete(db.subscriptionsTable).go();
        if (subscriptions.isNotEmpty) {
          final companions = subscriptions.map((s) {
            return SubscriptionsTableCompanion.insert(
              id: s.id,
              name: s.name,
              description: s.description,
              price: s.price,
              currency: Value(s.currency),
              billingCycle: s.billingCycle.name,
              category: s.category.name,
              brandColorValue: s.brandColorValue,
              iconCodePoint: Value(s.iconCodePoint),
              iconFontFamily: Value(s.iconFontFamily),
              nextBillingDate: s.nextBillingDate,
              status: s.status.name,
              paymentMethod: s.paymentMethod,
              paymentMethodId: Value(s.paymentMethodId),
              reminderDays: Value(s.reminderDays),
              isPopular: Value(s.isPopular),
              notes: Value(s.notes),
              paymentHistory: Value(s.paymentHistory),
              accountUrl: Value(s.accountUrl),
              logoUrl: Value(s.logoUrl),
              brandPresetId: Value(s.brandPresetId),
              autoRenew: Value(s.autoRenew),
              anchorDay: Value(s.anchorDay),
            );
          }).toList();
          await db.batch((batch) {
            batch.insertAll(db.subscriptionsTable, companions);
          });
        }
      });
    } catch (e) {
      throw StorageException('Failed to save subscriptions to SQLite', e);
    }
  }

  @override
  Future<double> getMonthlyBudget() async {
    final val = await db.getSetting(keyBudget);
    if (val == null) return 150.0;
    return double.tryParse(val) ?? 150.0;
  }

  @override
  Future<void> setMonthlyBudget(double amount) async {
    await db.setSetting(keyBudget, amount.toString());
  }

  @override
  Future<String> getCurrency() async {
    return (await db.getSetting(keyCurrency)) ?? '\$';
  }

  @override
  Future<void> setCurrency(String currency) async {
    await db.setSetting(keyCurrency, currency);
  }

  @override
  Future<({String name, String email})> getUserProfile() async {
    final name = (await db.getSetting(keyUserName)) ?? 'Syed Arham Raza';
    final email = (await db.getSetting(keyUserEmail)) ?? 'syed@onespend.app';
    return (name: name, email: email);
  }

  @override
  Future<void> setUserProfile(String name, String email) async {
    await db.setSetting(keyUserName, name);
    await db.setSetting(keyUserEmail, email);
  }

  @override
  Future<int> getDefaultReminderDays() async {
    final val = await db.getSetting(keyDefaultReminder);
    if (val == null) return 2;
    return int.tryParse(val) ?? 2;
  }

  @override
  Future<void> setDefaultReminderDays(int days) async {
    await db.setSetting(keyDefaultReminder, days.toString());
  }

  @override
  Future<String?> getSortOptionName() async {
    return await db.getSetting(keySortOption);
  }

  @override
  Future<void> setSortOptionName(String name) async {
    await db.setSetting(keySortOption, name);
  }

  @override
  Future<bool> getGroupByDate() async {
    final val = await db.getSetting(keyGroupByDate);
    if (val == null) return false;
    return val.toLowerCase() == 'true';
  }

  @override
  Future<void> setGroupByDate(bool value) async {
    await db.setSetting(keyGroupByDate, value.toString());
  }
}
