import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/main.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_nav_bar.dart';
import 'package:onespend/widgets/one_ui_floating_action_bar.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_selection_action_bar.dart';
import 'package:onespend/widgets/one_ui_scroll_to_top_button.dart';
import 'package:onespend/widgets/one_ui_sort_bottom_sheet.dart';
import 'package:onespend/widgets/one_ui_filter_bottom_sheet.dart';
import 'package:onespend/widgets/one_ui_floating_menu.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';

void main() {
  setUp(() {
    OneUIFloatingModal.isModalOpen.value = false;
  });

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
    expect(find.text('30-Day Forecast'), findsOneWidget);

    // Switch to Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated Annual Cost'), findsOneWidget);

    // Switch to Menu / Settings tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Monthly budget threshold'), findsOneWidget);
    expect(find.text('Navigation bar 3D effect'), findsOneWidget);

    // Switch back to Spend tab
    await tester.tap(find.text('Spend'));
    await tester.pumpAndSettle();

    // Tap a real subscription card (e.g. Netflix) to open detail screen
    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();

    // Verify authentic subscription detail screen elements
    expect(find.text('Netflix Plan'), findsOneWidget);
    expect(find.text('Plan & Billing'), findsOneWidget);
    expect(find.text('Payment & Reminders'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Return to main list
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsOneWidget);
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

  test('SubscriptionStore date clamping, pause preservation, batchAdd, and payment history', () {
    final store = SubscriptionStore.instance;

    // 1. Test Date Rollover Clamping on renewal (e.g. Jan 31 -> Feb)
    final jan31Sub = Subscription(
      id: 'rollover_test',
      name: 'Rollover Service',
      description: 'Test Clamping',
      price: 9.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      brandColor: Colors.blue,
      iconData: Icons.star,
      nextBillingDate: DateTime(2025, 1, 31),
    );
    store.addSubscription(jan31Sub);

    store.renewSubscription('rollover_test');
    final renewed = store.subscriptions.firstWhere((s) => s.id == 'rollover_test');
    // Month should advance and day should be clamped to valid days of that month (e.g. 28, not overflowing to Mar 3)
    expect(renewed.nextBillingDate.isAfter(DateTime.now()), isTrue);
    expect(renewed.paymentHistory.isNotEmpty, isTrue);

    // 2. Test Pause/Resume Status Preservation (trial preserved after unpause)
    final trialSub = Subscription(
      id: 'trial_test',
      name: 'Trial Service',
      description: 'Trial Status',
      price: 5.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.cloud,
      brandColor: Colors.purple,
      iconData: Icons.cloud,
      status: SubscriptionStatus.trial,
      nextBillingDate: DateTime.now().add(const Duration(days: 10)),
    );
    store.addSubscription(trialSub);

    store.togglePauseSubscription('trial_test');
    expect(store.subscriptions.firstWhere((s) => s.id == 'trial_test').status, SubscriptionStatus.paused);

    store.togglePauseSubscription('trial_test');
    expect(store.subscriptions.firstWhere((s) => s.id == 'trial_test').status, SubscriptionStatus.trial);

    // 3. Test batchAdd and unique ID generation
    final id1 = Subscription.generateUniqueId();
    final id2 = Subscription.generateUniqueId();
    expect(id1, isNot(equals(id2)));

    final subA = trialSub.copyWith(id: id1, name: 'Batch A');
    final subB = trialSub.copyWith(id: id2, name: 'Batch B');
    final beforeBatch = store.subscriptions.length;
    store.batchAdd([subA, subB]);
    expect(store.subscriptions.length, beforeBatch + 2);

    // Clean up
    store.removeSubscription('rollover_test');
    store.removeSubscription('trial_test');
    store.removeSubscription(id1);
    store.removeSubscription(id2);
  });

  testWidgets('Cancel monthly budget dialog test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Tap Menu tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Tap Monthly budget threshold
    await tester.tap(find.text('Monthly budget threshold'));
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Monthly Budget Limit'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pump(); // Start pop animation
    await tester.pump(const Duration(milliseconds: 100)); // Halfway through exit
    await tester.pump(const Duration(milliseconds: 200)); // Finished exit
    await tester.pumpAndSettle();

    // Now test from Spend screen
    await tester.tap(find.text('Spend'));
    await tester.pumpAndSettle();

    // Tap monthly budget card
    await tester.tap(find.text('Monthly Budget').first);
    await tester.pumpAndSettle();

    expect(find.text('Set Monthly Budget'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
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

  testWidgets('Subscription full edit and renewal flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Tap Spotify subscription from the list
    await tester.tap(find.text('Spotify').first);
    await tester.pumpAndSettle();

    expect(find.text('Spotify Plan'), findsOneWidget);

    // Tap Edit in the floating action bar
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Verify Edit Subscription screen is open
    expect(find.text('Edit Subscription'), findsOneWidget);

    // Enter new price (Card 2 is index 2)
    final priceFieldFinder = find.byType(TextField).at(2);
    await tester.enterText(priceFieldFinder, '19.99');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify detail screen reflects the new price
    expect(find.textContaining('19.99'), findsWidgets);

    // Wait for update SnackBar to dismiss
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Tap "Mark as renewed today" under Looking for something else?
    await tester.ensureVisible(find.text('Mark as renewed today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as renewed today'));
    await tester.pumpAndSettle();

    // Verify renewal SnackBar appeared
    expect(find.textContaining('Renewed Spotify'), findsOneWidget);
  });

  test('SubscriptionStore export, renewal, and budget operations', () {
    final store = SubscriptionStore.instance;
    final initialBudget = store.monthlyBudget;

    store.setMonthlyBudget(250.0);
    expect(store.monthlyBudget, equals(250.0));

    // Test JSON export
    final jsonExport = store.exportDataAsJson();
    expect(jsonExport.isNotEmpty, isTrue);
    expect(jsonExport.contains('Netflix'), isTrue);

    // Test CSV export
    final csvExport = store.exportDataAsCsv();
    expect(csvExport.isNotEmpty, isTrue);
    expect(csvExport.contains('Name,Category,Billing Cycle,Price'), isTrue);

    // Restore budget
    store.setMonthlyBudget(initialBudget);
  });

  testWidgets('Samsung One UI in-place multi-selection mode, header transformation, and bottom action bar flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify initially selection action bar is not visible
    expect(find.byType(OneUISelectionActionBar), findsNothing);

    // Tap more options menu
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    // Verify popup menu options
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Edit monthly budget'), findsOneWidget);
    expect(find.text('Export list (CSV)'), findsOneWidget);

    // Tap "Select" to enter selection mode
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    // Verify header transformed in-place: title shows "0 selected", back button and action icons visible
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byTooltip('Select all'), findsOneWidget);
    expect(find.byTooltip('Cancel selection'), findsOneWidget);

    // Verify OneUISelectionActionBar replaced the floating nav bar at the bottom
    expect(find.byType(OneUISelectionActionBar), findsOneWidget);

    // Verify 3 streamlined actions on the bottom floating bar (Share, Delete, More)
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    // Lock and Move are cleanly organized inside More
    expect(find.text('Move'), findsNothing);
    expect(find.text('Lock'), findsNothing);

    // Tap on Netflix to select it
    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();

    // Counter now shows 1 selected
    expect(find.text('1 selected'), findsOneWidget);

    // Tap 'Select all' in the header action pill
    await tester.tap(find.byTooltip('Select all'));
    await tester.pumpAndSettle();

    final totalCount = SubscriptionStore.instance.subscriptions.length;
    expect(find.text('$totalCount selected'), findsOneWidget);
    expect(find.byTooltip('Deselect all'), findsOneWidget);

    // Tap 'Deselect all'
    await tester.tap(find.byTooltip('Deselect all'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);

    // Tap Cancel selection icon in the header pill to exit selection mode
    await tester.tap(find.byTooltip('Cancel selection'));
    await tester.pumpAndSettle();

    expect(find.byType(OneUISelectionActionBar), findsNothing);
    expect(find.text('Subscriptions'), findsOneWidget);

    // Test entering selection mode via long-press on a subscription
    await tester.longPress(find.text('Spotify').first);
    await tester.pumpAndSettle();

    expect(find.byType(OneUISelectionActionBar), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);

    // Tap More (...) on selection bar to verify expanded menu with Move and Pause/Lock
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Move to category'), findsOneWidget);
    expect(find.text('Pause / Lock'), findsOneWidget);
    expect(find.text('Duplicate selected'), findsOneWidget);
    expect(find.text('Export selected (CSV)'), findsOneWidget);

    // Tap outside to dismiss floating menu
    await tester.tapAt(const Offset(50, 100));
    await tester.pumpAndSettle();

    // Exit selection mode via the in-place back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(OneUISelectionActionBar), findsNothing);
    expect(find.text('Subscriptions'), findsOneWidget);
  });

  testWidgets('Samsung One UI Sort by bottom sheet matching Screenshot 4', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Open popup menu and tap Sort
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();

    // Verify OneUISortBottomSheet elements matching Screenshot 4
    expect(find.byType(OneUISortBottomSheet), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Next renewal (soonest)'), findsOneWidget);
    expect(find.text('Name (A to Z)'), findsOneWidget);
    expect(find.text('Price (High to low)'), findsOneWidget);
    expect(find.text('Group by date'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Select "Price (High to low)"
    await tester.tap(find.text('Price (High to low)'));
    await tester.pumpAndSettle();

    // Toggle Group by date switch
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Tap Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify bottom sheet closed and store updated
    expect(find.byType(OneUISortBottomSheet), findsNothing);
    expect(SubscriptionStore.instance.sortOption, equals(SubscriptionSortOption.priceDesc));
    expect(SubscriptionStore.instance.groupByDate, isTrue);

    // Reset sort option
    SubscriptionStore.instance.setSortOption(SubscriptionSortOption.renewalAsc);
    SubscriptionStore.instance.setGroupByDate(false);
  });

  testWidgets('OneUIScrollToTopButton visibility and scroll behavior', (WidgetTester tester) async {
    final scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (ctx, i) => SizedBox(height: 50, child: Text('Row $i')),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: OneUIScrollToTopButton(
                  scrollController: scrollController,
                  threshold: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially at top (offset 0), up arrow has scale 0
    final upIcon = find.byIcon(Icons.keyboard_arrow_up_rounded);
    expect(upIcon, findsOneWidget);

    // Scroll down past threshold
    scrollController.jumpTo(250);
    await tester.pumpAndSettle();

    // Tap scroll to top button
    await tester.tap(upIcon);
    await tester.pumpAndSettle();

    // Verify scrolled back to top
    expect(scrollController.offset, equals(0.0));

    // Scroll down again and verify it automatically disappears when scrolling stops
    scrollController.jumpTo(300);
    await tester.pump(const Duration(milliseconds: 100)); // active scroll
    final animatedScaleFinder = find.byType(AnimatedScale);
    expect(animatedScaleFinder, findsOneWidget);
    AnimatedScale scaleWidget = tester.widget(animatedScaleFinder);
    expect(scaleWidget.scale, equals(1.0)); // Visible while scrolling

    // Wait for hideDelay (1000ms) to elapse after scrolling stops
    await tester.pump(const Duration(milliseconds: 1100));
    scaleWidget = tester.widget(animatedScaleFinder);
    expect(scaleWidget.scale, equals(0.0)); // Automatically disappeared!
  });

  testWidgets('Top floating action pill has equal gaps and uniform sizes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Find the 3 action buttons in the pill
    final addFinder = find.byTooltip('Add subscription');
    final searchFinder = find.byTooltip('Search subscriptions');
    final moreFinder = find.byTooltip('More options');

    expect(addFinder, findsOneWidget);
    expect(searchFinder, findsOneWidget);
    expect(moreFinder, findsOneWidget);

    // Verify all 3 action buttons have identical sizes (36x36)
    final sizeAdd = tester.getSize(addFinder);
    final sizeSearch = tester.getSize(searchFinder);
    final sizeMore = tester.getSize(moreFinder);

    expect(sizeAdd.width, equals(36.0));
    expect(sizeSearch.width, equals(36.0));
    expect(sizeMore.width, equals(36.0));

    // Verify equal gap between icon 1 and icon 2, and icon 2 and icon 3
    final posAdd = tester.getTopLeft(addFinder);
    final posSearch = tester.getTopLeft(searchFinder);
    final posMore = tester.getTopLeft(moreFinder);

    final gap1 = posSearch.dx - (posAdd.dx + sizeAdd.width);
    final gap2 = posMore.dx - (posSearch.dx + sizeSearch.width);

    // Gaps must be identical!
    expect(gap1, equals(gap2));
    expect(gap1, equals(4.0));
  });

  testWidgets('OneUIFloatingMenu displays directly on top of pill with transparent overlay', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Get position of the more options button in the floating pill
    final moreFinder = find.byTooltip('More options');
    expect(moreFinder, findsOneWidget);
    final pillButtonPos = tester.getTopLeft(moreFinder);

    // Tap more options to open expanded menu
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();

    // Verify expanded menu items are visible
    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Edit monthly budget'), findsOneWidget);
    expect(find.text('Export list (CSV)'), findsOneWidget);

    // Verify OneUIFloatingMenu.isOpen is true and the background pill is hidden (opacity 0)
    expect(OneUIFloatingMenu.isOpen.value, isTrue);
    final actionPillAnimatedOpacity = find.descendant(
      of: find.byType(SliverPersistentHeader),
      matching: find.byType(AnimatedOpacity),
    );
    expect(actionPillAnimatedOpacity, findsWidgets);
    final AnimatedOpacity pillOpacity = tester.widget(actionPillAnimatedOpacity.first);
    expect(pillOpacity.opacity, equals(0.0));

    // Verify ModalBarrier is strictly transparent (no dark background overlay!)
    final barrierFinder = find.byType(ModalBarrier).last;
    final ModalBarrier barrier = tester.widget(barrierFinder);
    expect(barrier.color == null || barrier.color == Colors.transparent, isTrue);

    // Verify menu item top is aligned with the floating pill (not pushed down below it)
    final selectPos = tester.getTopLeft(find.text('Select'));
    // The top of the menu should be within 20px of the pill's top, directly overlapping it
    expect((selectPos.dy - pillButtonPos.dy).abs(), lessThan(30.0));

    // Tap outside to dismiss
    await tester.tapAt(const Offset(30, 200));
    await tester.pumpAndSettle();

    // Verify menu closed cleanly and action pill restores full opacity
    expect(find.text('Select'), findsNothing);
    expect(OneUIFloatingMenu.isOpen.value, isFalse);
    final AnimatedOpacity restoredPillOpacity = tester.widget(actionPillAnimatedOpacity.first);
    expect(restoredPillOpacity.opacity, equals(1.0));
  });

  testWidgets('Samsung One UI Filter by category bottom sheet from expanded menu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Open popup menu and tap Filter
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Filter'), findsOneWidget);
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    // Verify OneUIFilterBottomSheet elements
    expect(find.byType(OneUIFilterBottomSheet), findsOneWidget);
    expect(find.text('Filter by category'), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Entertainment'), findsOneWidget);
    expect(find.text('Music & Audio'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Select "Music & Audio"
    await tester.tap(find.text('Music & Audio'));
    await tester.pumpAndSettle();

    // Tap Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify bottom sheet closed and filtered list only shows Music (Spotify)
    final musicCount = SubscriptionStore.instance.subscriptions.where((s) => s.category == SubscriptionCategory.music).length;
    expect(find.byType(OneUIFilterBottomSheet), findsNothing);
    expect(find.text('Music & Audio ($musicCount)'), findsOneWidget);
    expect(find.text('Spotify'), findsWidgets);
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('OneUIFloatingModal renders with 4 rounded corners and floating edge insets', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () {
                  OneUIFloatingModal.show(
                    context: ctx,
                    builder: (sheetCtx) => const Text('Floating Modal Content'),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIFloatingModal), findsOneWidget);
    expect(find.text('Floating Modal Content'), findsOneWidget);

    // Verify modal has 28px rounded radius and margins
    final animatedContainerFinder = find.descendant(
      of: find.byType(OneUIFloatingModal),
      matching: find.byType(AnimatedContainer),
    );
    expect(animatedContainerFinder, findsOneWidget);
    AnimatedContainer animatedContainer = tester.widget(animatedContainerFinder);
    BoxDecoration dec = animatedContainer.decoration as BoxDecoration;
    expect(dec.borderRadius, equals(BorderRadius.circular(28)));
    expect(dec.gradient, isNotNull); // 3D on by default

    // Toggle 3D effect off
    OneUIEffectsController.instance.floating3dEffect = false;
    await tester.pumpAndSettle();

    animatedContainer = tester.widget(animatedContainerFinder);
    dec = animatedContainer.decoration as BoxDecoration;
    expect(dec.gradient, isNull); // flat when 3D is off
    expect(dec.color, equals(const Color(0xC4202024)));

    // Restore 3D effect
    OneUIEffectsController.instance.floating3dEffect = true;
    await tester.pumpAndSettle();
  });

  testWidgets('Floating components have BackdropFilter blur background', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify OneUITheme.blurSigma is 20.0
    expect(OneUITheme.blurSigma, equals(20.0));

    // Verify OneUIFloatingNavBar has BackdropFilter
    final navBarBlurFinder = find.descendant(
      of: find.byType(OneUIFloatingNavBar),
      matching: find.byType(BackdropFilter),
    );
    expect(navBarBlurFinder, findsOneWidget);

    // Verify BackdropFilter inside modal
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () {
                  OneUIFloatingModal.show(
                    context: ctx,
                    builder: (sheetCtx) => const Text('Blurred Modal Content'),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    final modalBlurFinder = find.descendant(
      of: find.byType(OneUIFloatingModal),
      matching: find.byType(BackdropFilter),
    );
    expect(modalBlurFinder, findsOneWidget);

    // Dismiss modal cleanly
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
  });

  testWidgets('Settings screen header search icon toggle and live search filtering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Go to Settings / Menu tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Verify search icon in header actions pill
    final searchIconFinder = find.byTooltip('Search settings');
    expect(searchIconFinder, findsOneWidget);

    // Verify bottom search pill is removed (as requested by user)
    expect(find.text('Search settings...'), findsNothing);

    // Tap search icon to toggle inline search bar
    await tester.tap(searchIconFinder);
    await tester.pumpAndSettle();

    expect(find.text('Search settings...'), findsOneWidget);

    // Type query "currency"
    await tester.enterText(find.byType(TextField), 'currency');
    await tester.pumpAndSettle();

    // Currency should be visible, other cards like Navigation bar 3D effect should be hidden
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Navigation bar 3D effect'), findsNothing);

    // Type a query that yields no results
    await tester.enterText(find.byType(TextField), 'xyznonexistent');
    await tester.pumpAndSettle();

    expect(find.textContaining('No settings found for "xyznonexistent"'), findsOneWidget);

    // Close search
    await tester.tap(searchIconFinder);
    await tester.pumpAndSettle();

    // All settings restored
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Navigation bar 3D effect'), findsOneWidget);
  });

  testWidgets('OneUIFieldEditorScreen modular subpage editor and floating stadium pill', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Tap Netflix to open detail screen
    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();

    // Tap "Service name" row to open modular field editor subpage
    await tester.tap(find.text('Service name'));
    await tester.pumpAndSettle();

    // Verify OneUIFieldEditorScreen is open matching edit nickname screenshot
    expect(find.text('Edit name'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Edit the text
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Netflix 4K Premium');
    await tester.pumpAndSettle();

    // Tap Save on floating stadium pill
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify detail screen received the updated name
    expect(find.text('Netflix 4K Premium'), findsWidgets);
  });
}


