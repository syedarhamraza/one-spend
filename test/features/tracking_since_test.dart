import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final ref = DateTime(2026, 10, 15);
  Subscription sub(String id, {List<DateTime> history = const []}) => Subscription(
        id: id,
        name: id,
        description: '',
        price: 10,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 10, 25),
        paymentHistory: history,
      );

  group('SpendingTrendsEngine with trackingSince', () {
    test('no clamping when the tracking start is unknown', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('a')],
        horizon: SpendingTrendHorizon.oneYear,
        referenceDate: ref,
      );
      expect(points, hasLength(SpendingTrendHorizon.oneYear.monthCount));
    });

    test('a new user sees no invented past months, only now and the forecast', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('a')],
        horizon: SpendingTrendHorizon.oneYear,
        referenceDate: ref,
        trackingSince: DateTime(2026, 10, 2),
      );
      expect(points.first.isCurrent, isTrue);
      expect(points, hasLength(1 + SpendingTrendHorizon.oneYear.futureMonths));
    });

    test('logged payments before the tracking start extend the history back', () {
      final points = SpendingTrendsEngine.calculateTrends(
        subscriptions: [sub('a', history: [DateTime(2026, 8, 25)])],
        horizon: SpendingTrendHorizon.oneYear,
        referenceDate: ref,
        trackingSince: DateTime(2026, 10, 2),
      );
      expect(points.first.month, DateTime(2026, 8, 1));
      expect(points.first.amount, 10);
    });
  });

  group('SubscriptionController.trackingSince', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('is recorded (and persisted) when the first subscription is added', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      setupDependencies(database: db);
      final store = SubscriptionStore.instance;
      store.resetForTesting();
      store.clearAllData();
      expect(store.trackingSince, isNull);

      store.addSubscription(sub('first'));
      final now = DateTime.now();
      expect(store.trackingSince, DateTime(now.year, now.month, now.day));

      await store.pendingWrites;
      final reloaded = SubscriptionController(
        subscriptionRepository: sl(),
        paymentMethodRepository: sl(),
        settingsRepository: sl(),
      );
      await reloaded.load();
      expect(reloaded.trackingSince, store.trackingSince);
    });

    test('existing data without it starts at the oldest logged payment', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      setupDependencies(database: db);
      final store = SubscriptionStore.instance;
      store.resetForTesting(); // demo data, no tracking start recorded
      store.updateSubscription(store.subscriptions.first.copyWith(paymentHistory: [DateTime(2026, 3, 9, 14)]));
      await store.pendingWrites;

      final reloaded = SubscriptionController(
        subscriptionRepository: sl(),
        paymentMethodRepository: sl(),
        settingsRepository: sl(),
      );
      await reloaded.load();
      expect(reloaded.trackingSince, DateTime(2026, 3, 9));
    });
  });
}
