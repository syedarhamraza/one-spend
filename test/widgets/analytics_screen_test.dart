import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/widgets/one_ui_analytics_hero_card.dart';
import 'package:onespend/widgets/one_ui_floating_menu.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_spending_chart.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  DateTime inDays(int days) => DateTime(now.year, now.month, now.day + days);

  Subscription sub(
    String id,
    String name, {
    double price = 10,
    BillingCycle cycle = BillingCycle.monthly,
    SubscriptionCategory category = SubscriptionCategory.entertainment,
    List<DateTime> history = const [],
  }) =>
      Subscription(
        id: id,
        name: name,
        description: '',
        price: price,
        billingCycle: cycle,
        category: category,
        nextBillingDate: inDays(10),
        paymentHistory: history,
      );

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    final store = SubscriptionStore.instance;
    store.resetForTesting();
    store.clearAllData();
    store.batchAdd([
      sub('movies', 'Movie Stream', price: 20),
      sub('tunes', 'Tune Box', price: 12, category: SubscriptionCategory.music, history: [inDays(-20)]),
      sub('drive', 'Drive Yearly', price: 120, cycle: BillingCycle.yearly, category: SubscriptionCategory.cloud),
    ]);
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pumpScreen(WidgetTester tester, {Size size = const Size(1080, 2400)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = size.width < 1000 ? 1.0 : 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const AnalyticsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('hero shows the yearly total and trajectory card renders', (tester) async {
    await pumpScreen(tester);
    // (20 + 12 + 120 / 12) * 12 = 504
    expect(find.descendant(of: find.byType(OneUIAnalyticsHeroCard), matching: find.text('\$504.00')), findsOneWidget);
    expect(find.byType(OneUISpendingTrendsCard), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Spending by category'), 300);
    expect(find.text('Spending by category'), findsOneWidget);
  });

  testWidgets('tapping a category filters the page and the pill clears it', (tester) async {
    await pumpScreen(tester);

    await tester.scrollUntilVisible(find.text('Music & Audio'), 300);
    await tester.ensureVisible(find.text('Music & Audio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music & Audio'));
    await tester.pumpAndSettle();

    // Lists narrow to the category.
    await tester.scrollUntilVisible(find.text('Subscriptions'), 300);
    expect(find.text('Tune Box'), findsWidgets);
    expect(find.text('Movie Stream'), findsNothing);

    // Back at the top, the filter pill clears it.
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    final pill = find.byIcon(Icons.close_rounded);
    expect(pill, findsOneWidget);
    expect(find.text('Music & Audio · \$12.00/mo'), findsOneWidget);
    await tester.tap(pill);
    await tester.pumpAndSettle();
    expect(pill, findsNothing);
    expect(find.text('Music & Audio · \$12.00/mo'), findsNothing);
  });

  testWidgets('tapping a top subscription opens its detail', (tester) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(find.text('Top subscriptions'), 300);
    await tester.scrollUntilVisible(find.text('Drive Yearly'), 200);
    await tester.ensureVisible(find.text('Drive Yearly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drive Yearly'));
    await tester.pumpAndSettle();
    expect(find.byType(SubscriptionDetailScreen), findsOneWidget);
  });

  testWidgets('more menu copies the report', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pumpScreen(tester);
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy report'));
    await tester.pumpAndSettle();

    expect(OneUIFloatingMenu.isOpen.value, isFalse);
    expect(copied, contains('Yearly cost: \$504.00'));
    expect(copied, contains('Month-over-month'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('empty state offers to add a subscription', (tester) async {
    SubscriptionStore.instance.clearAllData();
    await pumpScreen(tester);
    expect(find.text('No spending data yet'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget);
  });

  testWidgets('lays out without overflow at 360dp', (tester) async {
    await pumpScreen(tester, size: const Size(360, 800));
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
