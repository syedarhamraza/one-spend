import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_fab.dart';
import 'package:onespend/widgets/one_ui_floating_nav_bar.dart';
import 'package:onespend/widgets/one_ui_floating_action_bar.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';

void main() {
  testWidgets('OneSpend app smoke test and One UI navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify One UI viewing area header
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.textContaining('active'), findsOneWidget);

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
    await tester.ensureVisible(find.text('Open Routine Demo (Screenshot 3)'));
    await tester.pumpAndSettle();
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

    // Find the + icon in the top header actions pill matching screenshot
    final addActionFinder = find.byTooltip('Add subscription');
    expect(addActionFinder, findsOneWidget);
    await tester.tap(addActionFinder);
    await tester.pumpAndSettle();

    // Verify Add Subscription Screen with Cancel | Save floating pill
    expect(find.text('Add Subscription'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Top & Popular Subscriptions'), findsOneWidget);
    expect(find.text('Service Name'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);

    // Tap a popular subscription from carousel (e.g. Spotify)
    await tester.tap(find.text('Spotify'));
    await tester.pumpAndSettle();

    // Verify form was auto-populated
    expect(find.text('Spotify'), findsWidgets);

    // Save the subscription using the floating pill
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify back on home screen with subscription added
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Spotify'), findsWidgets);

    // Wait for previous save SnackBar to dismiss
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Open Add Subscription again and test Cancel button on floating pill
    await tester.tap(addActionFinder);
    await tester.pumpAndSettle();
    expect(find.text('Add Subscription'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add Subscription'), findsNothing);
    expect(find.text('Subscriptions'), findsOneWidget);
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

  testWidgets('Samsung One UI 9 collapsible header 3-stage scroll test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Stage 1: Unscrolled -> Big centered title is visible
    expect(find.text('Subscriptions'), findsOneWidget);

    // Stage 2: Scroll slightly down by 50px
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -50));
    await tester.pump();

    // Stage 3: Scroll deeply down by 300px
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -300));
    await tester.pump();

    // Scroll back up to the top
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsWidgets);
  });

  testWidgets('Settings page Navigation bar 3D effect toggle', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Start with 3D effect enabled
    OneUIEffectsController.instance.navbar3dEffect = true;

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Navigate to Menu / Settings tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Verify Navigation bar 3D effect item is present in Settings
    expect(find.text('Navigation bar 3D effect'), findsOneWidget);
    expect(find.text('3D floating pill elevation & top rim highlight'), findsOneWidget);

    // Tap the setting to toggle it OFF
    await tester.tap(find.text('Navigation bar 3D effect'));
    await tester.pumpAndSettle();

    // Verify it updated to false and subtitle changed to classic flat
    expect(OneUIEffectsController.instance.navbar3dEffect, isFalse);
    expect(find.text('Classic flat appearance'), findsWidgets);

    // Tap the setting to toggle it back ON
    await tester.tap(find.text('Navigation bar 3D effect'));
    await tester.pumpAndSettle();

    // Verify it updated back to true
    expect(OneUIEffectsController.instance.navbar3dEffect, isTrue);
    expect(find.text('3D floating pill elevation & top rim highlight'), findsOneWidget);

    // Verify Floating buttons & pills 3D effect item is present
    expect(find.text('Floating buttons & pills 3D effect'), findsOneWidget);
    expect(find.text('3D elevation & rim highlight on search, back & action pills'), findsOneWidget);

    // Toggle Floating buttons & pills OFF
    await tester.tap(find.text('Floating buttons & pills 3D effect'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.floating3dEffect, isFalse);

    // Toggle Floating buttons & pills back ON
    await tester.tap(find.text('Floating buttons & pills 3D effect'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.floating3dEffect, isTrue);
    expect(find.text('3D elevation & rim highlight on search, back & action pills'), findsOneWidget);

    // Verify Cards 3D depth effect item is present and starts OFF
    expect(find.text('Cards 3D depth effect'), findsOneWidget);
    expect(OneUIEffectsController.instance.card3dEffect, isFalse);
    expect(OneUITheme.cardBorder, isNull);
    expect(OneUITheme.cardShadow, isEmpty);

    // Scroll into view and toggle Cards 3D depth effect ON
    await tester.ensureVisible(find.text('Cards 3D depth effect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards 3D depth effect'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.card3dEffect, isTrue);
    expect(find.text('3D elevation, rim highlight & soft shadows on all cards'), findsOneWidget);
    expect(OneUITheme.cardBorder, isNotNull);
    expect(OneUITheme.cardShadow, isNotEmpty);

    // Toggle Cards 3D depth effect back OFF
    await tester.tap(find.text('Cards 3D depth effect'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.card3dEffect, isFalse);
    expect(OneUITheme.cardBorder, isNull);
    expect(OneUITheme.cardShadow, isEmpty);
  });

  testWidgets('Cards 3D depth effect updates all cards across screens simultaneously', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Ensure started in flat mode
    OneUIEffectsController.instance.card3dEffect = false;

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify multiple OneUIGroupCard exist on home page
    expect(find.byType(OneUIGroupCard), findsWidgets);

    // Go to Settings tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Multiple OneUIGroupCards on Settings page
    final groupCardsFinder = find.byType(OneUIGroupCard);
    expect(groupCardsFinder, findsWidgets);

    // Find Containers inside OneUIGroupCards and confirm they have no border/shadow initially
    final initialContainers = tester.widgetList<Container>(
      find.descendant(of: groupCardsFinder, matching: find.byType(Container)),
    );
    final cardContainersBefore = initialContainers.where((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.borderRadius == OneUITheme.cardBorderRadius;
      }
      return false;
    }).toList();

    expect(cardContainersBefore.isNotEmpty, isTrue);
    for (var c in cardContainersBefore) {
      final dec = c.decoration as BoxDecoration;
      expect(dec.border, isNull);
      expect(dec.boxShadow ?? const [], isEmpty);
    }

    // Scroll down and toggle Cards 3D effect ON
    await tester.ensureVisible(find.text('Cards 3D depth effect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards 3D depth effect'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.card3dEffect, isTrue);

    // Verify ALL OneUIGroupCards on Settings screen now have border and boxShadow
    final updatedContainers = tester.widgetList<Container>(
      find.descendant(of: groupCardsFinder, matching: find.byType(Container)),
    );
    final cardContainersAfter = updatedContainers.where((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.borderRadius == OneUITheme.cardBorderRadius;
      }
      return false;
    }).toList();

    expect(cardContainersAfter.isNotEmpty, isTrue);
    for (var c in cardContainersAfter) {
      final dec = c.decoration as BoxDecoration;
      expect(dec.border, isNotNull, reason: 'Every card must have 3D rim border');
      expect((dec.boxShadow ?? const []).isNotEmpty, isTrue, reason: 'Every card must have 3D elevation shadow');
    }

    // Switch to Spend tab and verify cards there have 3D depth
    await tester.tap(find.text('Spend'));
    await tester.pumpAndSettle();

    final spendGroupCards = find.byType(OneUIGroupCard);
    final spendContainers = tester.widgetList<Container>(
      find.descendant(of: spendGroupCards, matching: find.byType(Container)),
    );
    final spendCards = spendContainers.where((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.borderRadius == OneUITheme.cardBorderRadius;
      }
      return false;
    }).toList();

    expect(spendCards.isNotEmpty, isTrue);
    for (var c in spendCards) {
      final dec = c.decoration as BoxDecoration;
      expect(dec.border, isNotNull, reason: 'Spend cards must have 3D rim border');
      expect((dec.boxShadow ?? const []).isNotEmpty, isTrue, reason: 'Spend cards must have 3D elevation shadow');
    }

    // Switch to Upcoming tab and verify cards there also have 3D depth
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();

    final upcomingGroupCards = find.byType(OneUIGroupCard);
    final upcomingContainers = tester.widgetList<Container>(
      find.descendant(of: upcomingGroupCards, matching: find.byType(Container)),
    );
    final upcomingCards = upcomingContainers.where((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.borderRadius == OneUITheme.cardBorderRadius;
      }
      return false;
    }).toList();

    expect(upcomingCards.isNotEmpty, isTrue);
    for (var c in upcomingCards) {
      final dec = c.decoration as BoxDecoration;
      expect(dec.border, isNotNull, reason: 'Upcoming cards must have 3D rim border');
      expect((dec.boxShadow ?? const []).isNotEmpty, isTrue, reason: 'Upcoming cards must have 3D elevation shadow');
    }
  });

  testWidgets('OneUIFloatingActionBar dynamically sizes to fit item count', (WidgetTester tester) async {
    int tappedIndex = -1;

    // Test with 3 items (matching SubscriptionDetailScreen)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: OneUIFloatingActionBar(
              items: [
                OneUIFloatingActionBarItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => tappedIndex = 0,
                ),
                OneUIFloatingActionBarItem(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () => tappedIndex = 1,
                ),
                OneUIFloatingActionBarItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: OneUITheme.accentRed,
                  onTap: () => tappedIndex = 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 items rendered
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Get size of AnimatedContainer in floating action bar
    final animatedContainerFinder = find.descendant(
      of: find.byType(OneUIFloatingActionBar),
      matching: find.byType(AnimatedContainer),
    );
    final size3Items = tester.getSize(animatedContainerFinder);
    // Width should hug 3 items (around 224px, strictly less than old fixed 320px)
    expect(size3Items.width, lessThan(250.0));
    expect(size3Items.width, greaterThan(200.0));

    // Tap second item
    await tester.tap(find.text('Share'));
    expect(tappedIndex, equals(1));

    // Test with 2 items and verify it dynamically shrinks
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: OneUIFloatingActionBar(
              items: [
                OneUIFloatingActionBarItem(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () {},
                ),
                OneUIFloatingActionBarItem(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final size2Items = tester.getSize(animatedContainerFinder);
    // Dynamic width for 2 items should be noticeably smaller than 3 items
    expect(size2Items.width, lessThan(size3Items.width));
    expect(size2Items.width, lessThan(180.0));
    expect(size2Items.width, greaterThan(140.0));
  });
}

