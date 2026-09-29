import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/payment_methods/data/models/payment_method_model.dart';
import '../../../features/subscriptions/data/models/subscription_model.dart';
import '../app_database.dart';

/// One-time migrator from legacy SharedPreferences JSON storage to Drift SQLite.
class SharedPreferencesMigrator {
  final SharedPreferences prefs;
  final AppDatabase db;

  static const String keyMigrated = 'drift_migrated_v1';
  static const String keyAppearanceMigrated = 'appearance_migrated_v1';
  static const String appearancePrefix = 'appearance.';

  /// Legacy card studio / effects keys written directly to SharedPreferences.
  static const List<String> appearanceKeys = [
    'card3dEffect', 'floating3dEffect', 'navbar3dEffect', 'bottomVignetteEffect',
    'cardBackground', 'customCardBackgroundColorValue', 'cardLayout', 'brandAccent',
    'priceMode', 'renewalBadgeMode', 'paymentBadgeStyle', 'upcomingStyle',
    'showCycleProgress', 'showPaymentMethodChip', 'showCategoryChip', 'showBillingCycle',
    'showDailyEquivalent', 'detailShowItemIcons', 'detailIconShape',
    'detailHighlightSelectable', 'detailPaymentIconStyle', 'detailShowInlineCardBrand',
  ];

  // Legacy keys
  static const String keySubs = 'onespend_subscriptions';
  static const String keyPaymentMethods = 'onespend_payment_methods';
  static const String keyBudget = 'onespend_monthly_budget';
  static const String keyCurrency = 'onespend_currency';
  static const String keyUserName = 'onespend_user_name';
  static const String keyUserEmail = 'onespend_user_email';
  static const String keyDefaultReminder = 'onespend_default_reminder';
  static const String keySortOption = 'onespend_sort_option';
  static const String keyGroupByDate = 'onespend_group_by_date';

  SharedPreferencesMigrator({required this.prefs, required this.db});

  Future<void> checkAndMigrate() async {
    await _migrateDomainData();
    await _migrateAppearance();
  }

  Future<void> _migrateDomainData() async {
    final isMigrated = prefs.getBool(keyMigrated) ?? false;
    if (isMigrated) return;

    try {
      await db.transaction(() async {
        // 1. Migrate Subscriptions
        final subsJson = prefs.getString(keySubs);
        if (subsJson != null && subsJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(subsJson) as List<dynamic>;
          final models = decoded
              .map((e) => SubscriptionModel.fromJson(e as Map<String, dynamic>))
              .toList();

          for (final m in models) {
            await db.into(db.subscriptionsTable).insertOnConflictUpdate(
              SubscriptionsTableCompanion.insert(
                id: m.id,
                name: m.name,
                description: m.description,
                price: m.price,
                currency: Value(m.currency),
                billingCycle: m.billingCycle.name,
                category: m.category.name,
                brandColorValue: m.brandColorValue,
                iconCodePoint: Value(m.iconCodePoint),
                iconFontFamily: Value(m.iconFontFamily),
                nextBillingDate: m.nextBillingDate,
                status: m.status.name,
                paymentMethod: m.paymentMethod,
                paymentMethodId: Value(m.paymentMethodId),
                reminderDays: Value(m.reminderDays),
                isPopular: Value(m.isPopular),
                notes: Value(m.notes),
                paymentHistory: Value(m.paymentHistory),
                accountUrl: Value(m.accountUrl),
                logoUrl: Value(m.logoUrl),
                brandPresetId: Value(m.brandPresetId),
                autoRenew: Value(m.autoRenew),
                anchorDay: Value(m.anchorDay),
                reminderTimeMinutes: Value(m.reminderTimeMinutes),
              ),
            );
          }
        }

        // 2. Migrate Payment Methods
        final methodsJson = prefs.getString(keyPaymentMethods);
        if (methodsJson != null && methodsJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(methodsJson) as List<dynamic>;
          final models = decoded
              .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
              .toList();

          for (final m in models) {
            await db.into(db.paymentMethodsTable).insertOnConflictUpdate(
              PaymentMethodsTableCompanion.insert(
                id: m.id,
                nickname: m.nickname,
                type: m.type.name,
                brand: m.brand.name,
                last4: Value(m.last4),
                expiryDate: Value(m.expiryDate),
                cardColorValue: Value(m.cardColorValue),
                isDefault: Value(m.isDefault),
                statementDay: Value(m.statementDay),
              ),
            );
          }
        }

        // 3. Migrate App Settings
        final budget = prefs.getDouble(keyBudget);
        if (budget != null) {
          await db.setSetting(keyBudget, budget.toString());
        }

        final currency = prefs.getString(keyCurrency);
        if (currency != null) {
          await db.setSetting(keyCurrency, currency);
        }

        final userName = prefs.getString(keyUserName);
        if (userName != null) {
          await db.setSetting(keyUserName, userName);
        }

        final userEmail = prefs.getString(keyUserEmail);
        if (userEmail != null) {
          await db.setSetting(keyUserEmail, userEmail);
        }

        final defaultReminder = prefs.getInt(keyDefaultReminder);
        if (defaultReminder != null) {
          await db.setSetting(keyDefaultReminder, defaultReminder.toString());
        }

        final sortOption = prefs.getString(keySortOption);
        if (sortOption != null) {
          await db.setSetting(keySortOption, sortOption);
        }

        final groupByDate = prefs.getBool(keyGroupByDate);
        if (groupByDate != null) {
          await db.setSetting(keyGroupByDate, groupByDate.toString());
        }
      });

      // Clear legacy domain keys from SharedPreferences to reclaim disk space
      await prefs.remove(keySubs);
      await prefs.remove(keyPaymentMethods);
      await prefs.remove(keyBudget);
      await prefs.remove(keyCurrency);
      await prefs.remove(keyUserName);
      await prefs.remove(keyUserEmail);
      await prefs.remove(keyDefaultReminder);
      await prefs.remove(keySortOption);
      await prefs.remove(keyGroupByDate);

      // Mark migration complete
      await prefs.setBool(keyMigrated, true);
      debugPrint('OneSpend: Successfully migrated data from SharedPreferences to Drift SQLite.');
    } catch (e, stack) {
      debugPrint('OneSpend: SharedPreferences migration failed: $e\n$stack');
    }
  }

  /// Copies card studio / effects preferences into the Drift app_settings table.
  Future<void> _migrateAppearance() async {
    if (prefs.getBool(keyAppearanceMigrated) ?? false) return;
    try {
      await db.transaction(() async {
        for (final key in appearanceKeys) {
          final value = prefs.get(key);
          if (value != null) {
            await db.setSetting('$appearancePrefix$key', value.toString());
          }
        }
      });
      for (final key in appearanceKeys) {
        await prefs.remove(key);
      }
      await prefs.setBool(keyAppearanceMigrated, true);
    } catch (e, stack) {
      debugPrint('OneSpend: Appearance settings migration failed: $e\n$stack');
    }
  }
}
