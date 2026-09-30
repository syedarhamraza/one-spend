import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/features/currency/data/exchange_rate_repository.dart';
import 'package:onespend/features/currency/data/rates_remote_datasource.dart';
import 'package:onespend/features/currency/domain/currency.dart';
import 'package:onespend/features/currency/domain/exchange_rates.dart';
import 'package:onespend/features/currency/domain/money_format.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/presentation/controllers/subscription_controller.dart';

class _FakeRemote implements RatesRemoteDataSource {
  Map<String, double>? rates;
  int calls = 0;

  _FakeRemote([this.rates]);

  @override
  Future<ExchangeRateSnapshot> fetchUsdRates() async {
    calls++;
    final r = rates;
    if (r == null) throw Exception('offline');
    return ExchangeRateSnapshot(rates: r, fetchedAt: DateTime.now(), provider: 'fake');
  }
}

Subscription _sub(String id, double price, String currency, {BillingCycle cycle = BillingCycle.monthly}) => Subscription(
      id: id,
      name: id,
      description: '',
      price: price,
      currency: currency,
      billingCycle: cycle,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime(2030, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('formatMoney', () {
    test('uses each currency\'s decimals, grouping and symbol position', () {
      expect(formatMoney(1299.49, 'USD'), '\$1,299.49');
      expect(formatMoney(4300, 'PKR'), 'Rs 4,300');
      expect(formatMoney(4337.62, 'PKR'), 'Rs 4,338', reason: 'rupees are shown whole');
      expect(formatMoney(1500.4, 'JPY'), '¥1,500');
      expect(formatMoney(99.5, 'SEK'), '99.50 kr');
      expect(formatMoney(1.2346, 'KWD'), 'KD 1.235');
      expect(formatMoney(-5.25, 'EUR'), '-€5.25');
      expect(formatMoney(-0.001, 'EUR'), '€0');
      expect(formatMoney(150.4, 'USD', decimals: 0), '\$150');
    });

    test('exact prices keep cents but never show .00', () {
      expect(formatMoney(15.49, 'USD'), '\$15.49');
      expect(formatMoney(15, 'USD'), '\$15');
      expect(formatMoney(14.999, 'USD'), '\$15');
      expect(formatMoney(2045.45, 'USD'), '\$2,045.45');
    });

    test('summaries drop cents from 1,000 up; estimates from 10 up', () {
      expect(formatMoney(2045.45, 'USD', style: MoneyStyle.summary), '\$2,045');
      expect(formatMoney(83.96, 'USD', style: MoneyStyle.summary), '\$83.96');
      expect(formatMoney(42.37, 'USD', style: MoneyStyle.approximate), '\$42');
      expect(formatMoney(0.53, 'USD', style: MoneyStyle.approximate), '\$0.53');
    });
  });

  group('CurrencyCatalog.normalize', () {
    test('maps legacy symbols to ISO codes and keeps codes', () {
      expect(CurrencyCatalog.normalize('\$'), 'USD');
      expect(CurrencyCatalog.normalize('Rs'), 'PKR');
      expect(CurrencyCatalog.normalize('£'), 'GBP');
      expect(CurrencyCatalog.normalize('eur'), 'EUR');
      expect(CurrencyCatalog.normalize(null), 'USD');
      expect(CurrencyCatalog.normalize('???'), 'USD');
    });
  });

  group('CurrencyConverter', () {
    const builtIn = {'USD': 1.0, 'PKR': 280.0, 'EUR': 0.8};

    test('converts across currencies via USD', () {
      const c = CurrencyConverter(builtIn: builtIn);
      expect(c.convert(10, 'USD', 'PKR'), closeTo(2800, 1e-9));
      expect(c.convert(8, 'EUR', 'USD'), closeTo(10, 1e-9));
      expect(c.convert(8, 'EUR', 'PKR'), closeTo(2800, 1e-9));
      expect(c.convert(5, 'PKR', 'PKR'), 5);
    });

    test('live rates beat built-in, and a pinned rate beats both', () {
      final live = ExchangeRateSnapshot(rates: const {'USD': 1, 'PKR': 300}, fetchedAt: DateTime(2026), provider: 't');
      final c = CurrencyConverter(builtIn: builtIn, live: live);
      expect(c.convert(1, 'USD', 'PKR'), 300);
      expect(c.sourceOf('PKR'), RateSource.live);
      expect(c.sourceOf('EUR'), RateSource.builtIn);

      final pinned = CurrencyConverter(
        builtIn: builtIn,
        live: live,
        overrides: const {'USD': RateOverride(base: 'PKR', rate: 285)},
      );
      expect(pinned.convert(2, 'USD', 'PKR'), 570);
      expect(pinned.convert(570, 'PKR', 'USD'), closeTo(2, 1e-9));
      expect(pinned.sourceOf('USD'), RateSource.custom);
    });

    test('a missing rate gives null', () {
      const c = CurrencyConverter(builtIn: builtIn);
      expect(c.convert(1, 'XYZ', 'USD'), isNull);
      expect(c.sourceOf('XYZ'), isNull);
    });
  });

  group('ExchangeRateRepository', () {
    late AppDatabase db;
    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('caches downloaded rates and pinned rates across instances', () async {
      final remote = _FakeRemote({'USD': 1, 'PKR': 300});
      final repo = ExchangeRateRepository(database: db, remote: remote);
      await repo.load();
      expect(repo.lastUpdated, isNull);
      expect(await repo.refresh(), isTrue);
      await repo.setOverride('EUR', rate: 330, base: 'PKR');

      final reloaded = ExchangeRateRepository(database: db, remote: _FakeRemote());
      await reloaded.load();
      expect(reloaded.converter.convert(1, 'USD', 'PKR'), 300);
      expect(reloaded.converter.convert(1, 'EUR', 'PKR'), 330);
      expect(reloaded.isStale, isFalse);
    });

    test('skips the download while fresh, and falls back to built-in when offline', () async {
      final remote = _FakeRemote({'USD': 1, 'PKR': 300});
      final repo = ExchangeRateRepository(database: db, remote: remote);
      await repo.refresh();
      await repo.refresh();
      expect(remote.calls, 1);

      final offline = ExchangeRateRepository(database: AppDatabase.forTesting(NativeDatabase.memory()));
      expect(await offline.refresh(), isFalse);
      expect(offline.lastRefreshFailed, isTrue);
      expect(offline.converter.convert(1, 'USD', 'PKR'), isNotNull, reason: 'built-in rates');
    });
  });

  group('SubscriptionController in several currencies', () {
    late AppDatabase db;
    late SubscriptionController controller;
    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final rates = ExchangeRateRepository(database: db, remote: _FakeRemote({'USD': 1, 'PKR': 280, 'EUR': 0.8}));
      await rates.refresh();
      controller = SubscriptionController(
        subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
        paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
        settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
        rates: rates,
      );
      await controller.load();
    });
    tearDown(() async {
      await controller.pendingWrites;
      await db.close();
    });

    test('totals convert each subscription to the main currency', () {
      controller.setCurrency('PKR');
      controller.batchAdd([
        _sub('netflix', 10, 'USD'),
        _sub('gym', 2800, 'PKR'),
        _sub('cloud', 96, 'EUR', cycle: BillingCycle.yearly),
      ]);
      // 10 USD = 2800 PKR; 96 EUR/yr = 8 EUR/mo = 10 USD = 2800 PKR.
      expect(controller.totalMonthlySpend, closeTo(8400, 1e-6));
      expect(controller.approxInMain(10, 'USD'), '≈ Rs 2,800');
      expect(controller.approxInMain(10, 'PKR'), isNull);
      expect(controller.currenciesInUse.first, 'PKR');
    });

    test('changing the main currency converts the budget and keeps subscriptions', () async {
      controller.setMonthlyBudget(150);
      controller.addSubscription(_sub('netflix', 10, 'USD'));
      controller.setCurrency('PKR');
      expect(controller.currency, 'PKR');
      expect(controller.monthlyBudget, 42000, reason: '150 USD × 280, rounded');
      expect(controller.subscriptions.single.currency, 'USD');

      await controller.pendingWrites;
      final settings = SettingsDriftDataSource(db);
      expect(await settings.getCurrency(), 'PKR');
      expect(await settings.getMonthlyBudget(), 42000);
    });

    test('stored legacy symbols read back as ISO codes', () async {
      controller.addSubscription(_sub('old', 5, 'USD'));
      await controller.pendingWrites;
      await db.customStatement("UPDATE subscriptions SET currency = 'Rs'");
      final loaded = await SubscriptionDriftDataSource(db).loadSubscriptions();
      expect(loaded.single.currency, 'PKR');
    });
  });
}
