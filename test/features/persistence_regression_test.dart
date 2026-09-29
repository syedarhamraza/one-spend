import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/database/migration/shared_preferences_migrator.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/fixtures/popular_catalog.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/domain/services/billing_schedule.dart';
import 'package:onespend/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

SubscriptionController _controllerFor(AppDatabase db) {
  return SubscriptionController(
    subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
    paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
    settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SubscriptionController persistence', () {
    test('fresh install loads empty with a blank profile', () async {
      final controller = _controllerFor(db);
      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.subscriptions, isEmpty);
      expect(controller.paymentMethods, isEmpty);
      expect(controller.userName, isEmpty);
      expect(controller.userEmail, isEmpty);
    });

    test('cleared subscriptions stay cleared after relaunch', () async {
      final first = _controllerFor(db);
      first.resetForTesting();
      expect(first.subscriptions, isNotEmpty);
      first.clearAllData();
      await first.pendingWrites;

      final relaunched = _controllerFor(db);
      await relaunched.load();
      expect(relaunched.subscriptions, isEmpty);
      expect(relaunched.paymentMethods, isNotEmpty);
    });

    test('deleting the last subscription does not resurrect demo data', () async {
      final first = _controllerFor(db);
      await first.load();
      first.addSubscription(popularCatalog[0]);
      first.removeSubscription(popularCatalog[0].id);
      await first.pendingWrites;

      final relaunched = _controllerFor(db);
      await relaunched.load();
      expect(relaunched.subscriptions, isEmpty);
    });

    test('granular mutations persist in order and survive relaunch', () async {
      final first = _controllerFor(db);
      await first.load();
      first.batchAdd(popularCatalog.take(3));
      first.updateSubscription(popularCatalog[1].copyWith(price: 42.0));
      first.batchDelete([popularCatalog[2].id]);
      first.setCurrency('€');
      first.setUserProfile('Test User', 'test@example.com');
      await first.pendingWrites;

      final relaunched = _controllerFor(db);
      await relaunched.load();
      expect(relaunched.subscriptions.map((s) => s.id).toSet(), {popularCatalog[0].id, popularCatalog[1].id});
      expect(relaunched.getSubscription(popularCatalog[1].id)!.price, 42.0);
      expect(relaunched.currency, '€');
      expect(relaunched.userName, 'Test User');
    });

    test('making a card default demotes and persists the previous default', () async {
      final first = _controllerFor(db);
      first.resetForTesting();
      final previousDefault = first.defaultPaymentMethod!;
      final other = first.paymentMethods.firstWhere((m) => m.id != previousDefault.id);
      first.updatePaymentMethod(other.copyWith(isDefault: true));
      await first.pendingWrites;

      final relaunched = _controllerFor(db);
      await relaunched.load();
      expect(relaunched.paymentMethods.where((m) => m.isDefault).map((m) => m.id), [other.id]);
    });
  });

  group('BillingSchedule', () {
    final base = popularCatalog[0].copyWith(
      billingCycle: BillingCycle.monthly,
      nextBillingDate: DateTime(2026, 1, 10),
      paymentHistory: const [],
      autoRenew: true,
      status: SubscriptionStatus.active,
    );

    test('auto-renewal logs one payment per missed cycle', () {
      final now = DateTime(2026, 4, 15);
      expect(BillingSchedule.isAutoRenewDue(base, now: now), isTrue);

      final renewed = BillingSchedule.applyAutoRenewal(base, now: now);
      expect(renewed.paymentHistory, [
        DateTime(2026, 4, 10),
        DateTime(2026, 3, 10),
        DateTime(2026, 2, 10),
        DateTime(2026, 1, 10),
      ]);
      expect(renewed.nextBillingDate, DateTime(2026, 5, 10));
      expect(BillingSchedule.isAutoRenewDue(renewed, now: now), isFalse);
    });

    test('paused subscriptions are never auto-renewed', () {
      final paused = base.copyWith(status: SubscriptionStatus.paused);
      expect(BillingSchedule.isAutoRenewDue(paused, now: DateTime(2026, 4, 15)), isFalse);
    });

    test('markPaid logs a single payment and advances past today', () {
      final paid = BillingSchedule.markPaid(base, now: DateTime(2026, 4, 15));
      expect(paid.paymentHistory, [DateTime(2026, 1, 10)]);
      expect(paid.nextBillingDate, DateTime(2026, 5, 10));
    });
  });

  group('Appearance settings', () {
    test('legacy SharedPreferences effects migrate into Drift and load', () async {
      SharedPreferences.setMockInitialValues({
        'card3dEffect': true,
        'cardLayout': 'compact',
        'customCardBackgroundColorValue': 0xFF112233,
      });
      final prefs = await SharedPreferences.getInstance();
      await SharedPreferencesMigrator(prefs: prefs, db: db).checkAndMigrate();

      expect(prefs.containsKey('card3dEffect'), isFalse);
      expect(prefs.getBool(SharedPreferencesMigrator.keyAppearanceMigrated), isTrue);

      setupDependencies(database: db);
      final effects = OneUIEffectsController.instance;
      await effects.init();
      expect(effects.card3dEffect, isTrue);
      expect(effects.cardLayout, SubscriptionCardLayout.compact);
      expect(effects.customCardBackgroundColorValue, 0xFF112233);

      effects.resetCardStyle();
      effects.card3dEffect = false;
    });
  });
}
