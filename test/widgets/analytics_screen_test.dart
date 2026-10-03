import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/features/subscriptions/domain/services/insight_cards.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_ambient_glow.dart';
import 'package:onespend/widgets/one_ui_analytics_hero_card.dart';
import 'package:onespend/widgets/one_ui_category_breakdown_card.dart';
import 'package:onespend/widgets/one_ui_floating_menu.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_insight_card.dart';
import 'package:onespend/widgets/one_ui_spending_chart.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
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

  testWidgets('hero shows the yearly total and trend card renders', (tester) async {
    await pumpScreen(tester);
    // (20 + 12 + 120 / 12) * 12 = 504
    expect(find.descendant(of: find.byType(OneUIAnalyticsHeroCard), matching: find.text('\$504')), findsOneWidget);
    expect(find.byType(OneUISpendingTrendsCard), findsOneWidget);
    await tester.scrollUntilVisible(find.text('By category'), 300);
    expect(find.text('By category'), findsOneWidget);
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
    // The pill comes before the insight card, whose ✕ uses the same icon.
    final pill = find.byIcon(Icons.close_rounded).first;
    expect(find.text('Music & Audio · \$12/mo'), findsOneWidget);
    await tester.tap(pill);
    await tester.pumpAndSettle();
    expect(find.text('Music & Audio · \$12/mo'), findsNothing);
  });

  List<InsightCardData> expectedCards() {
    final store = SubscriptionStore.instance;
    return InsightCards.build(
      store.subscriptions,
      now: DateTime.now(),
      currency: store.currency,
      monthlyBudget: store.monthlyBudget,
      trackingSince: store.trackingSince,
    );
  }

  testWidgets('insight card shows the top tip; dismiss moves on to the next', (tester) async {
    final cards = expectedCards();
    expect(cards.length, greaterThan(1));
    await pumpScreen(tester);

    expect(find.byType(OneUIInsightCard), findsOneWidget);
    expect(find.text(cards[0].title), findsOneWidget);
    expect(find.text('1 of ${cards.length}'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Dismiss tip'));
    await tester.pumpAndSettle();
    expect(find.text(cards[0].title), findsNothing);
    expect(find.text(cards[1].title), findsOneWidget);
    expect(SubscriptionStore.instance.dismissedInsights, contains(cards[0].key));
    // No inline Undo: the ⋮ menu's "Show dismissed tips" brings tips back.
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('swiping the insight card dismisses it', (tester) async {
    final cards = expectedCards();
    await pumpScreen(tester);
    await tester.fling(find.byType(OneUIInsightCard), const Offset(-500, 0), 2000);
    await tester.pumpAndSettle();
    expect(find.text(cards[0].title), findsNothing);
    expect(find.text(cards[1].title), findsOneWidget);
  });

  testWidgets('dismissing every tip hides the card; the menu restores them', (tester) async {
    final store = SubscriptionStore.instance;
    for (final c in expectedCards()) {
      store.dismissInsight(c.key);
    }
    await pumpScreen(tester);
    expect(find.byType(OneUIInsightCard), findsNothing);

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show dismissed tips'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIInsightCard), findsOneWidget);
    expect(store.dismissedInsights, isEmpty);
  });

  testWidgets('selecting categories keeps the category card still on screen', (tester) async {
    await pumpScreen(tester);
    Finder legend(String label) =>
        find.descendant(of: find.byType(OneUICategoryBreakdownCard), matching: find.text(label));

    await tester.scrollUntilVisible(legend('Music & Audio'), 300);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
    await tester.pumpAndSettle();

    for (final label in ['Music & Audio', 'Cloud & Backup', 'Cloud & Backup', 'Entertainment']) {
      final before = tester.getTopLeft(legend(label)).dy;
      await tester.tap(legend(label));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(legend(label)).dy, closeTo(before, 1), reason: 'tapping $label');
    }
  });

  testWidgets('hero glow follows the largest (or selected) category', (tester) async {
    await pumpScreen(tester);
    Color glow() => tester
        .widget<OneUIAmbientGlow>(
            find.descendant(of: find.byType(OneUIAnalyticsHeroCard), matching: find.byType(OneUIAmbientGlow)))
        .color;
    expect(glow(), OneUITheme.glowTint(SubscriptionCategory.entertainment.color));

    final music = find.descendant(of: find.byType(OneUICategoryBreakdownCard), matching: find.text('Music & Audio'));
    await tester.scrollUntilVisible(music, 300);
    await tester.ensureVisible(music);
    await tester.pumpAndSettle();
    await tester.tap(music);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 3000), 3000);
    await tester.pumpAndSettle();
    expect(glow(), OneUITheme.glowTint(SubscriptionCategory.music.color));
  });

  testWidgets('tapping a top subscription opens its detail', (tester) async {
    await pumpScreen(tester);
    // "Drive Yearly" also appears in the spending trends card; tap the Top subscriptions row.
    final topRow = find.descendant(of: find.byType(OneUIGroupItemTile), matching: find.text('Drive Yearly'));
    await tester.scrollUntilVisible(find.text('Top subscriptions'), 300);
    await tester.scrollUntilVisible(topRow, 200);
    await tester.ensureVisible(topRow);
    await tester.pumpAndSettle();
    await tester.tap(topRow);
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
    expect(copied, contains('Yearly cost: \$504'));
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
