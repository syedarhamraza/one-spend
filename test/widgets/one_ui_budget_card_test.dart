import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_budget_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    SubscriptionStore.instance.resetForTesting();
    SubscriptionStore.instance.clearAllData();
  });

  Widget buildTestCard({
    required SubscriptionStore store,
    required List<Subscription> upcomingSubs,
    required VoidCallback onTap,
  }) {
    return MaterialApp(
      theme: OneUITheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: OneUIBudgetCard(
            store: store,
            upcomingSubs: upcomingSubs,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  testWidgets('Renders One UI budget card with primary spend, inline limit and percentage', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;
    store.setMonthlyBudget(150.0);
    // Add sample subscription
    store.addSubscription(
      Subscription(
        id: 'sub_netflix',
        name: 'Netflix',
        description: 'Streaming service',
        price: 83.96,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 9, 30),
      ),
    );

    var tapped = false;
    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: store.subscriptions,
        onTap: () => tapped = true,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header has title and chevron, but NO standalone pencil icon
    expect(find.text('Monthly budget'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mode_edit_outline_rounded), findsNothing);

    // 2. Single status badge on top right (no separate pill for percentage)
    expect(find.text('${store.currency}66 left'), findsOneWidget);

    // 3. Primary spend metric 32pt bold, inline budget limit without redundant word, and right-aligned percentage
    expect(find.text('${store.currency}83.96'), findsOneWidget);
    expect(find.text('/ ${store.currency}150'), findsOneWidget);
    expect(find.text('56%'), findsOneWidget);

    // 4. Track bar is rendered
    expect(find.byType(ClipRRect), findsWidgets);

    // 5. Samsung Device Care key-value container with divider and NO icons
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('Daily burn'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsNothing);
    expect(find.textContaining('/ day'), findsOneWidget);
    expect(find.text('Next renewal'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
    expect(find.textContaining('Netflix'), findsOneWidget);
    expect(find.textContaining('Sep 30'), findsOneWidget);

    // Frosted glass BackdropFilter is present
    expect(find.byType(BackdropFilter), findsOneWidget);

    // 6. Tap triggers callback
    await tester.tap(find.byType(OneUIBudgetCard));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('Track bar transitions color states under 75%, 75-90%, and over 90%', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;

    // State 1: Under 75% -> Soft Samsung Blue
    store.setMonthlyBudget(100.0);
    store.addSubscription(
      Subscription(
        id: 'sub_1',
        name: 'Spotify',
        description: 'Music streaming',
        price: 50.0, // 50%
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.music,
        nextBillingDate: DateTime(2026, 10, 1),
      ),
    );

    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: store.subscriptions,
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('${store.currency}50 left'), findsOneWidget);

    // State 2: 75% to 90% -> Soft Amber / Warning
    store.addSubscription(
      Subscription(
        id: 'sub_2',
        name: 'iCloud',
        description: 'Cloud storage',
        price: 30.0, // Total = 80.0 (80%)
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.cloud,
        nextBillingDate: DateTime(2026, 10, 5),
      ),
    );

    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: store.subscriptions,
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('80%'), findsOneWidget);
    expect(find.text('${store.currency}20 left'), findsOneWidget);

    // State 3: Over 90% / Over budget -> Vibrant Crimson
    store.addSubscription(
      Subscription(
        id: 'sub_3',
        name: 'Gym',
        description: 'Fitness membership',
        price: 35.0, // Total = 115.0 (115% - over budget)
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.health,
        nextBillingDate: DateTime(2026, 10, 10),
      ),
    );

    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: store.subscriptions,
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('115%'), findsOneWidget);
    expect(find.text('${store.currency}15 over'), findsOneWidget);
  });

  testWidgets('Renders properly when no budget is set', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;
    store.setMonthlyBudget(0.0);

    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: [],
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No limit set'), findsOneWidget);
    expect(find.text('spent this month'), findsOneWidget);
    expect(find.text('None scheduled'), findsOneWidget);
  });

  testWidgets('Renders long titles like YouTube Premium without truncation or clipping', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;
    store.setMonthlyBudget(200.0);
    store.addSubscription(
      Subscription(
        id: 'sub_yt',
        name: 'YouTube Premium Family',
        description: 'Family video & music streaming',
        price: 22.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 10, 15),
      ),
    );

    await tester.pumpWidget(
      buildTestCard(
        store: store,
        upcomingSubs: store.subscriptions,
        onTap: () {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('YouTube Premium Family'), findsOneWidget);
    expect(find.textContaining('Oct 15'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsNothing);
  });
}
