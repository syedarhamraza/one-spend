import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/widgets/one_ui_fab.dart';
import 'package:onespend/widgets/one_ui_floating_nav_bar.dart';

void main() {
  testWidgets('OneSpend app smoke test and One UI navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify One UI viewing area header
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('OneSpend'), findsOneWidget);

    // Verify floating bottom navigation bar exists with its 4 tabs
    expect(find.byType(OneUIFloatingNavBar), findsOneWidget);
    expect(find.text('Spend'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);

    // Switch to Upcoming tab
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.text('Renewals calendar'), findsOneWidget);

    // Switch to Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated Annual Cost'), findsOneWidget);

    // Switch to Menu / Settings tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Open Routine Demo (Screenshot 3)'), findsOneWidget);

    // Open the 1:1 Routine Demo Screen
    await tester.tap(find.text('Open Routine Demo (Screenshot 3)'));
    await tester.pumpAndSettle();

    // Verify initial detail screen elements
    expect(find.text('Color filter'), findsWidgets);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Toggle to exact Screenshot 3 routine labels
    await tester.tap(find.text('Subscription Mode'));
    await tester.pumpAndSettle();

    expect(find.text('If'), findsOneWidget);
    expect(find.text('Then'), findsOneWidget);
    expect(find.text('When routine ends'), findsOneWidget);
    expect(find.text('App opened'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('Add Custom and Popular Subscription flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Find the green circular FAB matching Screenshot 4
    expect(find.byType(OneUIFAB), findsOneWidget);
    await tester.tap(find.byType(OneUIFAB));
    await tester.pumpAndSettle();

    // Verify Add Subscription Screen
    expect(find.text('Add Subscription'), findsOneWidget);
    expect(find.text('Top & Popular Subscriptions'), findsOneWidget);
    expect(find.text('Service Name'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);

    // Tap a popular subscription from carousel (e.g. Spotify)
    await tester.tap(find.text('Spotify'));
    await tester.pumpAndSettle();

    // Verify form was auto-populated
    expect(find.text('Spotify'), findsWidgets);

    // Save the subscription
    await tester.tap(find.text('Save Subscription'));
    await tester.pumpAndSettle();

    // Verify back on home screen with subscription added
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Spotify'), findsWidgets);
  });

  test('SubscriptionStore calculations and modifications', () {
    final store = SubscriptionStore.instance;
    final initialCount = store.subscriptions.length;
    expect(initialCount, greaterThan(0));

    final testSub = Subscription(
      id: 'test_sub_unit',
      name: 'Test Service',
      description: 'Test Plan',
      price: 10.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      brandColor: Colors.blue,
      iconData: Icons.star,
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
    );

    store.addSubscription(testSub);
    expect(store.subscriptions.length, initialCount + 1);
    expect(store.totalMonthlySpend, greaterThan(0));

    store.removeSubscription('test_sub_unit');
    expect(store.subscriptions.length, initialCount);
  });
}
