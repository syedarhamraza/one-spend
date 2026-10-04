import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/fixtures/popular_catalog.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:onespend/models/spending_trend.dart';

/// View-only changes (search history, dismissed insights, grouping, sort order) must not
/// throw away cached totals, trends and schedules; data changes must.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SubscriptionController store;
  var notifications = 0;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = SubscriptionController(
      subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
      paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
      settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
    );
    await store.load();
    store.batchAdd(popularCatalog.take(4).toList());
    notifications = 0;
    store.addListener(() => notifications++);
  });

  tearDown(() async {
    await store.pendingWrites;
    await db.close();
  });

  test('view-only changes notify but keep the revision and cached values', () {
    final revision = store.revision;
    final trends = store.getSpendingTrends(SpendingTrendHorizon.values.first);
    final upcoming = store.upcomingDue;

    store.addRecentSearch('netflix');
    store.removeRecentSearch('netflix');
    store.addRecentSearch('spotify');
    store.clearRecentSearches();
    store.dismissInsight('a');
    store.undismissInsight('a');
    store.dismissInsight('b');
    store.restoreDismissedInsights();
    store.setGroupByDate(!store.groupByDate);

    expect(notifications, 9);
    expect(store.revision, revision);
    expect(identical(store.getSpendingTrends(SpendingTrendHorizon.values.first), trends), isTrue);
    expect(identical(store.upcomingDue, upcoming), isTrue);
  });

  test('a new sort order re-sorts the list but keeps the other caches', () {
    final revision = store.revision;
    final upcoming = store.upcomingDue;
    store.setSortOption(SubscriptionSortOption.nameAsc);
    final byName = store.sortedSubscriptions.map((s) => s.name).toList();
    store.setSortOption(SubscriptionSortOption.nameDesc);

    expect(store.sortedSubscriptions.map((s) => s.name).toList(), byName.reversed.toList());
    expect(store.revision, revision);
    expect(identical(store.upcomingDue, upcoming), isTrue);
  });

  test('data changes bump the revision and recompute', () {
    final revision = store.revision;
    final total = store.totalMonthlySpend;
    final sub = store.subscriptions.first;

    store.updateSubscription(sub.copyWith(price: sub.price + 10));

    expect(store.revision, greaterThan(revision));
    expect(store.totalMonthlySpend, greaterThan(total));
  });
}
