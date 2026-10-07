import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/features/backup/domain/backup_codec.dart';
import 'package:onespend/features/backup/domain/backup_merge.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/datasources/custom_category_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/models/subscription_model.dart';
import 'package:onespend/features/subscriptions/data/repositories/custom_category_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/models/subscription.dart';

SubscriptionController _controllerFor(AppDatabase db) => SubscriptionController(
      subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
      paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
      settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
      customCategoryRepository: CustomCategoryRepositoryImpl(CustomCategoryDriftDataSource(db)),
    );

Subscription _sub(String id, SubscriptionCategory category, {double price = 10}) => Subscription(
      id: id,
      name: id,
      description: '',
      price: price,
      billingCycle: BillingCycle.monthly,
      category: category,
      nextBillingDate: DateTime(2026, 11, 1),
    );

const _kids = CustomCategory(
  id: 'c_kids',
  name: 'Kids',
  iconCodePoint: 0xe4a1, // any code point; unknown ones fall back to a neutral icon
  colorValue: 0xFF48B5A0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDown(() => CustomCategoryRegistry.replaceAll(const []));

  group('SubscriptionCategory', () {
    test('built-ins keep their names, labels and order', () {
      expect(SubscriptionCategory.values, hasLength(10));
      expect(SubscriptionCategory.fromString('music'), same(SubscriptionCategory.music));
      expect(SubscriptionCategory.music.label, 'Music & Audio');
      expect(SubscriptionCategory.fromString('nonsense'), same(SubscriptionCategory.entertainment));
      expect(SubscriptionCategory.fromString(null), same(SubscriptionCategory.entertainment));
    });

    test('custom categories are canonical and resolve through the registry', () {
      CustomCategoryRegistry.replaceAll([_kids]);
      final kids = SubscriptionCategory.fromString('c_kids');
      expect(kids, same(SubscriptionCategory.custom('c_kids')));
      expect(kids.isCustom, isTrue);
      expect(kids.label, 'Kids');
      expect(kids.color, const Color(0xFF48B5A0));
      expect(SubscriptionCategory.all.last, same(kids));

      final map = {kids: 1, SubscriptionCategory.music: 2};
      expect(map[SubscriptionCategory.fromString('c_kids')], 1);
    });

    test('a deleted custom category reads "Other"', () {
      expect(SubscriptionCategory.custom('c_gone').label, 'Other');
      expect(SubscriptionCategory.custom('c_gone').icon, Icons.label_rounded);
    });

    test('survives a subscription JSON round trip', () {
      CustomCategoryRegistry.replaceAll([_kids]);
      final restored = Subscription.fromJson(_sub('a', SubscriptionCategory.custom('c_kids')).toJson());
      expect(restored.category, same(SubscriptionCategory.custom('c_kids')));
    });
  });

  group('SubscriptionController custom categories', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('add, assign, update and reload', () async {
      final controller = _controllerFor(db);
      await controller.load();
      final kids = controller.addCustomCategory(name: '  Kids ', iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 0xFF5390F5);
      controller.addSubscription(_sub('a', kids));
      controller.addSubscription(_sub('b', SubscriptionCategory.music, price: 5));
      expect(kids.label, 'Kids');
      expect(controller.categorySpendMap[kids], 10);

      controller.updateCustomCategory(controller.customCategories.single.copyWith(name: 'Family'));
      await controller.pendingWrites;

      CustomCategoryRegistry.replaceAll(const []);
      final reloaded = _controllerFor(db);
      await reloaded.load();
      expect(reloaded.customCategories.single.name, 'Family');
      final sub = reloaded.subscriptions.firstWhere((s) => s.id == 'a');
      expect(sub.category, same(kids));
      expect(sub.category.label, 'Family');
      expect(sub.category.icon, Icons.pets_rounded);
    });

    test('delete moves its subscriptions and persists', () async {
      final controller = _controllerFor(db);
      await controller.load();
      final kids = controller.addCustomCategory(name: 'Kids', iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 0xFF5390F5);
      controller.addSubscription(_sub('a', kids));
      controller.deleteCustomCategory(kids.name, moveTo: SubscriptionCategory.health);
      await controller.pendingWrites;

      expect(controller.customCategories, isEmpty);
      expect(controller.subscriptions.single.category, same(SubscriptionCategory.health));

      final reloaded = _controllerFor(db);
      await reloaded.load();
      expect(reloaded.customCategories, isEmpty);
      expect(reloaded.subscriptions.single.category, same(SubscriptionCategory.health));
    });

    test('several delete at once; moving into one of them falls back to Utilities', () async {
      final controller = _controllerFor(db);
      await controller.load();
      final a = controller.addCustomCategory(name: 'A', iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 1);
      final b = controller.addCustomCategory(name: 'B', iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 2);
      controller.addCustomCategory(name: 'C', iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 3);
      controller.addSubscription(_sub('x', a));
      controller.addSubscription(_sub('y', b));
      controller.deleteCustomCategories({a.name, b.name}, moveTo: b);
      await controller.pendingWrites;

      expect(controller.customCategories.map((c) => c.name), ['C']);
      expect(controller.subscriptions.map((s) => s.category).toSet(), {SubscriptionCategory.utilities});

      final reloaded = _controllerFor(db);
      await reloaded.load();
      expect(reloaded.customCategories.map((c) => c.name), ['C']);
    });

    test('reorder sets the order pickers use, and it survives a reload', () async {
      final controller = _controllerFor(db);
      await controller.load();
      for (final name in ['A', 'B', 'C']) {
        controller.addCustomCategory(name: name, iconCodePoint: Icons.pets_rounded.codePoint, colorValue: 1);
      }
      final ids = {for (final c in controller.customCategories) c.name: c.id};
      controller.reorderCustomCategories([ids['C']!, ids['A']!, ids['B']!]);
      expect(controller.customCategories.map((c) => c.name), ['C', 'A', 'B']);
      expect(SubscriptionCategory.all.skip(SubscriptionCategory.values.length).map((c) => c.label), ['C', 'A', 'B']);
      await controller.pendingWrites;

      CustomCategoryRegistry.replaceAll(const []);
      final reloaded = _controllerFor(db);
      await reloaded.load();
      expect(reloaded.customCategories.map((c) => c.name), ['C', 'A', 'B']);
    });
  });

  group('Backups', () {
    BackupSnapshot snapshot({List<CustomCategory>? categories}) => BackupSnapshot(
          createdAt: DateTime(2026, 10, 2),
          appVersion: '1.0.0 (1)',
          subscriptions: [_sub('a', SubscriptionCategory.custom('c_kids'))],
          paymentMethods: const [],
          customCategories: categories,
        );

    test('v2 round trip keeps custom categories', () {
      final decoded = BackupCodec.decode(BackupCodec.encode(snapshot(categories: [_kids])));
      expect(decoded.customCategories, [_kids]);
      expect(decoded.subscriptions.single.category, same(SubscriptionCategory.custom('c_kids')));
    });

    test('a v1 backup without categories still restores', () {
      final v1 = BackupCodec.encode(snapshot()).replaceFirst('"version": 2', '"version": 1');
      final decoded = BackupCodec.decode(v1);
      expect(decoded.customCategories, isNull);
      expect(decoded.subscriptions, hasLength(1));
    });

    test('"Add missing" brings over only categories that are not present', () {
      const other = CustomCategory(id: 'c_home', name: 'Home', iconCodePoint: 1, colorValue: 2);
      final missing = BackupMerge.missingItems(
        currentSubscriptions: const [],
        currentPaymentMethods: const [],
        currentCustomCategories: const [_kids],
        backup: snapshot(categories: [_kids, other]),
      );
      expect(missing.customCategories, [other]);
    });
  });

  group('Schema v5 migration', () {
    test('upgrades a v4 database: keeps rows, adds the annual price column and categories table', () async {
      final dir = Directory.systemTemp.createTempSync('onespend_v5');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/v4.sqlite');

      final v4 = AppDatabase.forTesting(NativeDatabase(file));
      await SubscriptionDriftDataSource(v4).saveSubscriptions([SubscriptionModel.fromEntity(_sub('a', SubscriptionCategory.music))]);
      await v4.customStatement('ALTER TABLE subscriptions DROP COLUMN annual_plan_price');
      await v4.customStatement('DROP TABLE custom_categories');
      await v4.customStatement('PRAGMA user_version = 4');
      await v4.close();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(upgraded.close);
      final subs = await SubscriptionDriftDataSource(upgraded).loadSubscriptions();
      expect(subs.single.category, same(SubscriptionCategory.music));
      expect(subs.single.annualPlanPrice, isNull);

      final categories = CustomCategoryDriftDataSource(upgraded);
      await categories.upsert([_kids]);
      expect(await categories.load(), [_kids]);
    });
  });
}
