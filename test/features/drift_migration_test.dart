import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/database/converters/date_time_list_converter.dart';
import 'package:onespend/core/database/migration/shared_preferences_migrator.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/models/payment_method_model.dart';
import 'package:onespend/features/payment_methods/domain/entities/payment_method.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/models/subscription_model.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Subscriptions DataSource CRUD', () {
    test('save and load subscriptions cleanly via SQLite', () async {
      final dataSource = SubscriptionDriftDataSource(db);

      final initial = await dataSource.loadSubscriptions();
      expect(initial, isEmpty);

      final testSub = SubscriptionModel(
        id: 'drift_sub_1',
        name: 'GitHub Copilot',
        description: 'AI Code Assistant',
        price: 10.0,
        currency: '\$',
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.cloud,
        brandColorValue: 0xFF24292E,
        nextBillingDate: DateTime(2026, 10, 1),
        paymentHistory: [DateTime(2026, 9, 1), DateTime(2026, 8, 1)],
      );

      await dataSource.saveSubscriptions([testSub]);

      final loaded = await dataSource.loadSubscriptions();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('drift_sub_1'));
      expect(loaded.first.name, equals('GitHub Copilot'));
      expect(loaded.first.price, equals(10.0));
      expect(loaded.first.category, equals(SubscriptionCategory.cloud));
      expect(loaded.first.paymentHistory.length, equals(2));
      expect(loaded.first.paymentHistory.first, equals(DateTime(2026, 9, 1)));
    });

    test('overwriting subscriptions in SQLite replaces table contents atomically', () async {
      final dataSource = SubscriptionDriftDataSource(db);

      final sub1 = SubscriptionModel(
        id: 'sub_1',
        name: 'Service A',
        description: 'Plan A',
        price: 5.0,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        brandColorValue: 0xFF000000,
        nextBillingDate: DateTime(2026, 11, 1),
      );

      final sub2 = SubscriptionModel(
        id: 'sub_2',
        name: 'Service B',
        description: 'Plan B',
        price: 15.0,
        billingCycle: BillingCycle.yearly,
        category: SubscriptionCategory.productivity,
        brandColorValue: 0xFFFFFFFF,
        nextBillingDate: DateTime(2027, 1, 1),
      );

      await dataSource.saveSubscriptions([sub1, sub2]);
      var loaded = await dataSource.loadSubscriptions();
      expect(loaded.length, equals(2));

      // Save only sub2
      await dataSource.saveSubscriptions([sub2]);
      loaded = await dataSource.loadSubscriptions();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('sub_2'));
    });
  });

  group('Drift Payment Methods DataSource CRUD', () {
    test('save and load payment methods cleanly via SQLite', () async {
      final dataSource = PaymentMethodDriftDataSource(db);

      final initial = await dataSource.loadPaymentMethods();
      expect(initial, isEmpty);

      const testCard = PaymentMethodModel(
        id: 'card_drift_1',
        nickname: 'Chase Sapphire',
        type: PaymentMethodType.creditCard,
        brand: CardBrand.visa,
        last4: '4242',
        expiryDate: '12/28',
        cardColorValue: 0xFF1A365D,
        isDefault: true,
        statementDay: 15,
      );

      await dataSource.savePaymentMethods([testCard]);

      final loaded = await dataSource.loadPaymentMethods();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('card_drift_1'));
      expect(loaded.first.nickname, equals('Chase Sapphire'));
      expect(loaded.first.brand, equals(CardBrand.visa));
      expect(loaded.first.last4, equals('4242'));
      expect(loaded.first.isDefault, isTrue);
      expect(loaded.first.statementDay, equals(15));
    });
  });

  group('Drift Settings persistence', () {
    test('stores and retrieves user preferences with defaults', () async {
      final dataSource = SettingsDriftDataSource(db);

      // Default values
      expect(await dataSource.getMonthlyBudget(), equals(150.0));
      expect(await dataSource.getCurrency(), equals('\$'));
      final defaultProfile = await dataSource.getUserProfile();
      expect(defaultProfile.name, isEmpty);
      expect(defaultProfile.email, isEmpty);
      expect(await dataSource.getDefaultReminderDays(), equals(2));
      expect(await dataSource.getSortOptionName(), isNull);
      expect(await dataSource.getGroupByDate(), isFalse);

      // Mutate
      await dataSource.setMonthlyBudget(300.0);
      await dataSource.setCurrency('€');
      await dataSource.setUserProfile('Jane Doe', 'jane@example.com');
      await dataSource.setDefaultReminderDays(5);
      await dataSource.setSortOptionName('priceDesc');
      await dataSource.setGroupByDate(true);

      // Verify persistence
      expect(await dataSource.getMonthlyBudget(), equals(300.0));
      expect(await dataSource.getCurrency(), equals('€'));
      final updatedProfile = await dataSource.getUserProfile();
      expect(updatedProfile.name, equals('Jane Doe'));
      expect(updatedProfile.email, equals('jane@example.com'));
      expect(await dataSource.getDefaultReminderDays(), equals(5));
      expect(await dataSource.getSortOptionName(), equals('priceDesc'));
      expect(await dataSource.getGroupByDate(), isTrue);
    });
  });

  group('DateTimeListConverter', () {
    test('serializes and deserializes DateTime lists', () {
      const converter = DateTimeListConverter();
      final dates = [
        DateTime(2026, 1, 15, 10, 0),
        DateTime(2026, 2, 15, 10, 0),
      ];

      final sql = converter.toSql(dates);
      expect(sql, contains('2026-01-15'));
      expect(sql, contains('2026-02-15'));

      final fromDb = converter.fromSql(sql);
      expect(fromDb.length, equals(2));
      expect(fromDb[0], equals(dates[0]));
      expect(fromDb[1], equals(dates[1]));

      // Empty string gracefully returns empty list
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('invalid json'), isEmpty);
    });
  });

  group('SharedPreferences Legacy Migrator', () {
    test('migrates legacy JSON data into Drift SQLite and cleans up legacy storage', () async {
      final legacySubs = [
        {
          'id': 'legacy_sub_1',
          'name': 'Netflix 4K',
          'description': 'Family Plan',
          'price': 22.99,
          'currency': '\$',
          'billingCycle': 'monthly',
          'category': 'entertainment',
          'brandColor': 0xFFE50914,
          'nextBillingDate': '2026-10-15T00:00:00.000',
          'status': 'active',
          'paymentMethod': 'Visa 9124',
          'paymentHistory': ['2026-09-15T00:00:00.000'],
        }
      ];

      final legacyCards = [
        {
          'id': 'legacy_card_1',
          'nickname': 'Main Card',
          'type': 'creditCard',
          'brand': 'mastercard',
          'last4': '8888',
          'expiryDate': '05/27',
          'cardColor': 0xFF2C3440,
          'isDefault': true,
        }
      ];

      SharedPreferences.setMockInitialValues({
        'onespend_subscriptions': jsonEncode(legacySubs),
        'onespend_payment_methods': jsonEncode(legacyCards),
        'onespend_monthly_budget': 200.0,
        'onespend_currency': '£',
        'onespend_user_name': 'Legacy User',
        'onespend_user_email': 'legacy@onespend.app',
        'onespend_default_reminder': 3,
        'onespend_sort_option': 'renewalAsc',
        'onespend_group_by_date': true,
      });

      final prefs = await SharedPreferences.getInstance();
      final migrator = SharedPreferencesMigrator(prefs: prefs, db: db);

      // Run migration
      await migrator.checkAndMigrate();

      // Verify Drift DB now contains the migrated subscription
      final subDs = SubscriptionDriftDataSource(db);
      final subs = await subDs.loadSubscriptions();
      expect(subs.length, equals(1));
      expect(subs.first.id, equals('legacy_sub_1'));
      expect(subs.first.name, equals('Netflix 4K'));
      expect(subs.first.price, equals(22.99));
      expect(subs.first.paymentHistory.length, equals(1));

      // Verify Drift DB contains the migrated payment method
      final payDs = PaymentMethodDriftDataSource(db);
      final cards = await payDs.loadPaymentMethods();
      expect(cards.length, equals(1));
      expect(cards.first.id, equals('legacy_card_1'));
      expect(cards.first.nickname, equals('Main Card'));
      expect(cards.first.brand, equals(CardBrand.mastercard));

      // Verify Drift DB contains the migrated settings
      final settingsDs = SettingsDriftDataSource(db);
      expect(await settingsDs.getMonthlyBudget(), equals(200.0));
      expect(await settingsDs.getCurrency(), equals('£'));
      final profile = await settingsDs.getUserProfile();
      expect(profile.name, equals('Legacy User'));
      expect(profile.email, equals('legacy@onespend.app'));
      expect(await settingsDs.getDefaultReminderDays(), equals(3));
      expect(await settingsDs.getSortOptionName(), equals('renewalAsc'));
      expect(await settingsDs.getGroupByDate(), isTrue);

      // Verify legacy JSON was removed from SharedPreferences to save space
      expect(prefs.containsKey('onespend_subscriptions'), isFalse);
      expect(prefs.containsKey('onespend_payment_methods'), isFalse);
      expect(prefs.containsKey('onespend_monthly_budget'), isFalse);
      expect(prefs.containsKey('onespend_currency'), isFalse);

      // Verify migration flag is set
      expect(prefs.getBool('drift_migrated_v1'), isTrue);

      // Running again is an idempotent no-op
      await migrator.checkAndMigrate();
      final subsAfter = await subDs.loadSubscriptions();
      expect(subsAfter.length, equals(1));
    });
  });
}
