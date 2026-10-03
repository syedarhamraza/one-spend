import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/subscriptions/domain/services/charge_schedule.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/screens/subscriptions_screen.dart';
import 'package:onespend/screens/upcoming_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_analytics_hero_card.dart';
import 'package:onespend/widgets/one_ui_budget_card.dart';
import 'package:onespend/widgets/one_ui_key_value_row.dart';
import 'package:onespend/widgets/one_ui_upcoming_hero_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// Big-number currencies (IDR, VND) must fit on a narrow phone without overflowing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    SubscriptionStore.instance
      ..resetForTesting()
      ..clearAllData();
  });

  Subscription sub(String id, double price, String currency) => Subscription(
        id: id,
        name: 'Premium family plan $id',
        description: '',
        price: price,
        currency: currency,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 3)),
      );

  Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400); // 360 x 800 dp
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
    ));
    await tester.pumpAndSettle();
  }

  for (final (code, price, budget) in [('IDR', 248000000.0, 300000000.0), ('VND', 999000000.0, 950000000.0)]) {
    testWidgets('budget card fits a $code total at 360dp', (tester) async {
      final store = SubscriptionStore.instance;
      store.setCurrency(code);
      store.setMonthlyBudget(budget);
      store.addSubscription(sub('a', price, code));
      await pumpNarrow(tester, OneUIBudgetCard(store: store, upcomingSubs: store.subscriptions, onTap: () {}));
      expect(tester.takeException(), isNull);
      expect(find.textContaining(formatMoney(price, code)), findsOneWidget);
    });

    testWidgets('upcoming hero card fits a $code total at 360dp', (tester) async {
      final store = SubscriptionStore.instance;
      store.setCurrency(code);
      final s = sub('a', price, code);
      store.addSubscription(s);
      final charge = UpcomingCharge(subscription: s, date: s.nextBillingDate, status: ChargeStatus.upcoming);
      await pumpNarrow(
        tester,
        OneUIUpcomingHeroCard(
          horizonPhrase: 'next 30 days',
          charges: [charge, charge],
          annualSoon: const [],
          currency: code,
          toMain: store.toMain,
          cardSegments: const [(color: Colors.blue, total: 1)],
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  group('screens at 360dp with IDR as the main currency', () {
    late Subscription idr;

    setUp(() {
      final store = SubscriptionStore.instance;
      store.setCurrency('IDR');
      store.setMonthlyBudget(900000000);
      idr = sub('idr', 248000000, 'IDR');
      store.batchAdd([
        idr,
        sub('vnd', 999000000, 'VND'),
        sub('usd', 15.49, 'USD'),
        sub('yearly', 480000000, 'IDR').copyWith(billingCycle: BillingCycle.yearly),
      ]);
    });

    Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(1080, 2400); // 360 x 800 dp
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(routedTestApp(screen, theme: OneUITheme.darkTheme));
      await tester.pumpAndSettle();
    }

    testWidgets('Subscriptions tab', (tester) async {
      await pumpScreen(tester, const SubscriptionsScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Upcoming tab', (tester) async {
      await pumpScreen(tester, const UpcomingScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('Analytics tab', (tester) async {
      await pumpScreen(tester, const AnalyticsScreen());
      expect(tester.takeException(), isNull);
    });

    /// The key-value rows in [card] show every value and caption in full (the card's own
    /// title may still ellipsize).
    void expectAmountsInFull(WidgetTester tester, Type card) {
      final rows = find.descendant(of: find.byType(card), matching: find.byType(OneUIKeyValueRow));
      expect(rows, findsWidgets);
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(of: rows, matching: find.byType(RichText)),
      );
      for (final p in paragraphs) {
        expect(p.didExceedMaxLines, isFalse, reason: '${p.text.toPlainText()} is cut off');
      }
    }

    testWidgets('Analytics hero rows show large amounts in full', (tester) async {
      await pumpScreen(tester, const AnalyticsScreen());
      expectAmountsInFull(tester, OneUIAnalyticsHeroCard);
    });

    testWidgets('Upcoming hero rows show large amounts in full', (tester) async {
      await pumpScreen(tester, const UpcomingScreen());
      expectAmountsInFull(tester, OneUIUpcomingHeroCard);
    });

    testWidgets('Subscription detail', (tester) async {
      await pumpScreen(tester, SubscriptionDetailScreen(subscription: idr));
      expect(tester.takeException(), isNull);
    });
  });
}
