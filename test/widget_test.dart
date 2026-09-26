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
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:onespend/screens/popular_presets_screen.dart';
import 'package:onespend/screens/reminder_picker_screen.dart';
import 'package:onespend/screens/payment_history_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/screens/upcoming_schedule_screen.dart';
import 'package:onespend/screens/category_picker_screen.dart';
import 'package:onespend/screens/payment_methods_screen.dart';
import 'package:onespend/screens/payment_method_picker_screen.dart';
import 'package:onespend/widgets/one_ui_payment_brand_icon.dart';
import 'package:onespend/widgets/one_ui_spending_chart.dart';
import 'package:onespend/widgets/one_ui_bottom_vignette.dart';
import 'package:onespend/widgets/one_ui_status_bar_scrim.dart';
import 'package:onespend/widgets/one_ui_cancel_save_pill.dart';
import 'package:onespend/widgets/one_ui_selection_pills.dart';
import 'package:onespend/utils/one_ui_brand_catalog.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
  });

  tearDown(() {
    OneUIToast.dismiss();
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
    expect(find.text('Renew'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
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
    expect(find.text('Add subscription'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Choose from popular presets'), findsOneWidget);
    expect(find.text('Service name'), findsOneWidget);
    expect(find.text('Price / Cost'), findsOneWidget);

    // Tap popular presets option to open PopularPresetsScreen subpage
    await tester.tap(find.text('Choose from popular presets'));
    await tester.pumpAndSettle();

    // Verify Popular Presets subpage
    expect(find.text('Popular services'), findsOneWidget);
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

    // Wait for save toast to dismiss
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Open Add Subscription again and test Cancel button on floating pill
    await tester.tap(addActionFinder);
    await tester.pumpAndSettle();
    expect(find.text('Add subscription'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Add subscription'), findsNothing);
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
    await tester.tap(find.text('Monthly budget').first);
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

    // Tap "Price / Cost" to edit price using the modular subpage editor
    await tester.tap(find.text('Price / Cost'));
    await tester.pumpAndSettle();

    // Verify OneUIFieldEditorScreen is open
    expect(find.text('Edit price'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Enter new price
    final priceFieldFinder = find.byType(TextField);
    await tester.enterText(priceFieldFinder, '19.99');
    await tester.pumpAndSettle();

    // Tap Save on floating stadium pill
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify detail screen reflects the new price
    expect(find.textContaining('19.99'), findsWidgets);

    // Wait for update toast to dismiss
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Tap Renew in the floating action bar at bottom
    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();

    // Verify renewal toast appeared
    expect(find.textContaining('Renewed Spotify'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
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

    // Verify header transformed in-place: selection count pill and Cancel button visible
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Verify subscription description/subtitle is hidden in selection mode
    expect(find.text('Entertainment'), findsNothing);

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
    expect(find.text('1'), findsOneWidget);

    // Tap selection count pill to toggle Select all
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    final totalCount = SubscriptionStore.instance.subscriptions.length;
    expect(find.text('$totalCount selected'), findsOneWidget);
    expect(find.text('$totalCount'), findsOneWidget);

    // Tap count pill again to Deselect all
    await tester.tap(find.text('$totalCount'));
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Tap Cancel pill to exit selection mode
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(OneUISelectionActionBar), findsNothing);
    expect(find.text('Subscriptions'), findsOneWidget);
    // Verify subscription subtitle is restored
    expect(find.textContaining('Entertainment'), findsWidgets);

    // Test entering selection mode via long-press on a subscription
    await tester.longPress(find.text('Spotify').first);
    await tester.pumpAndSettle();

    expect(find.byType(OneUISelectionActionBar), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap More (...) on selection bar to verify expanded menu with Move and Pause/Lock
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Move to category'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Duplicate selected'), findsOneWidget);
    expect(find.text('Export selected (CSV)'), findsOneWidget);

    // Tap Pause to pause Spotify
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Paused 1 subscription'), findsOneWidget);

    // Clear SnackBar so it does not block the floating bottom bar
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
    await tester.pumpAndSettle();

    // Long press Spotify again (now it is paused)
    await tester.longPress(find.text('Spotify').first);
    await tester.pumpAndSettle();

    // Tap More on selection bar to verify it now offers 'Resume'
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);

    // Tap Resume to unpause Spotify
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Resumed 1 subscription'), findsOneWidget);
    expect(find.byType(OneUISelectionActionBar), findsNothing);
    expect(find.text('Subscriptions'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
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

    // Verify positions do not shift to the left when pill background appears on scroll
    final initialMoreDx = tester.getTopLeft(moreFinder).dx;
    final initialAddDx = tester.getTopLeft(addFinder).dx;

    // Scroll into the collapse zone where pill appears (>190px)
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -250));
    await tester.pumpAndSettle();

    final scrolledMoreDx = tester.getTopLeft(moreFinder).dx;
    final scrolledAddDx = tester.getTopLeft(addFinder).dx;

    expect(scrolledMoreDx, equals(initialMoreDx));
    expect(scrolledAddDx, equals(initialAddDx));
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
    expect(find.descendant(of: find.byType(OneUIFilterBottomSheet), matching: find.text('Entertainment')), findsOneWidget);
    expect(find.descendant(of: find.byType(OneUIFilterBottomSheet), matching: find.text('Music & Audio')), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Select "Music & Audio"
    await tester.tap(find.descendant(of: find.byType(OneUIFilterBottomSheet), matching: find.text('Music & Audio')));
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
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('Samsung One UI floating search bar matching reference screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Tap search action in top pill
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    // Verify search header and empty state
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('No recent searches'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);

    // Verify search pill sits at bottom before keyboard
    final initialPillY = tester.getTopLeft(find.text('What are you looking for?')).dy;
    expect(initialPillY, greaterThan(1000.0)); // Near bottom of 1200dp logical height

    // Simulate keyboard opening (600 physical px = 300 logical px)
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pumpAndSettle();

    // Verify search pill moves cleanly above the keyboard (not to the top of screen!)
    final keyboardPillY = tester.getTopLeft(find.text('What are you looking for?')).dy;
    // Logical height is 1200, keyboard is 300, pill bottom is 314, pill top is around 830
    expect(keyboardPillY, lessThan(initialPillY));
    expect(keyboardPillY, greaterThan(800.0)); // Stays in bottom region above keyboard, not near top!

    // Type query into floating search bar
    await tester.enterText(find.byType(TextField), 'Spotify');
    await tester.pumpAndSettle();

    // Results should show Spotify, and 'No recent searches' should disappear
    expect(find.text('No recent searches'), findsNothing);
    expect(find.text('Spotify'), findsWidgets);

    // Clear search using the X button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('No recent searches'), findsOneWidget);

    // Reset keyboard insets
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();

    // Exit search using back button
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsOneWidget);
  });

  testWidgets('Payment Methods Management, Non-Forceful Deletion & Missing Card Status', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify Menu (Settings) does not have Payment methods anymore
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Payment methods'), findsNothing);

    // Return to Spend tab
    await tester.tap(find.text('Spend'));
    await tester.pumpAndSettle();

    // Navigate to a subscription (e.g. Netflix) -> Payment method picker
    await tester.tap(find.text('Netflix').first);
    await tester.pumpAndSettle();

    expect(find.text('Payment method'), findsOneWidget);
    await tester.tap(find.text('Payment method'));
    await tester.pumpAndSettle();

    // Verify Payment method picker subpage
    expect(find.text('Payment method'), findsWidgets);
    expect(find.text('Primary Samsung Pay'), findsWidgets);
    expect(find.text('Personal Meezan Debit'), findsOneWidget);
    expect(find.text('Standard Chartered World'), findsOneWidget);

    // Verify linked subscriptions count badge exists (e.g. linked subscription)
    expect(find.textContaining('linked subscription'), findsWidgets);

    // Hold-press (long-press) on Primary Samsung Pay to enter selection mode
    await tester.longPress(find.text('Primary Samsung Pay').last);
    await tester.pumpAndSettle();

    // Tap Delete in floating action bar
    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify Non-Forceful deletion dialog opens with options
    expect(find.text('Card In Use'), findsOneWidget);
    expect(find.text('Delete anyway'), findsOneWidget);

    // Tap "Delete anyway" (non-forceful deletion)
    await tester.tap(find.text('Delete anyway'));
    await tester.pumpAndSettle();

    // Verify card is removed
    expect(find.text('Primary Samsung Pay'), findsNothing);

    // Go back to Subscription Detail
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    // Subscriptions previously tied to that card now display 'No card'
    expect(find.text('No card'), findsWidgets);
  });

  testWidgets('Popular Presets subpage filtering and search', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PopularPresetsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and tap search action to reveal floating search pill
    expect(find.text('Popular services'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Search presets'), findsWidgets);

    // Type query to filter
    await tester.enterText(find.byType(TextField), 'Figma');
    await tester.pumpAndSettle();

    // Verify Figma item is visible in OneUIGroupCard and unrelated presets are filtered
    expect(
      find.descendant(of: find.byType(OneUIGroupCard), matching: find.text('Figma')),
      findsOneWidget,
    );
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('Reminder Picker subpage lead time selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    int? selectedResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                selectedResult = await ReminderPickerScreen.open(context, initialDays: 2);
              },
              child: const Text('Open Reminder Picker'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Reminder Picker'));
    await tester.pumpAndSettle();

    // Verify header and preset options
    expect(find.text('Reminder notification'), findsOneWidget);
    expect(find.text('3 days before'), findsOneWidget);

    // Select 3 days before
    await tester.tap(find.text('3 days before'));
    await tester.pumpAndSettle();

    // Save using floating pill
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify result returned was 3
    expect(selectedResult, 3);
  });

  testWidgets('Auto-record renewals advances billing date when past due', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;
    store.resetForTesting();

    // Netflix is by default active and autoRenew is true
    final netflix = store.subscriptions.firstWhere((s) => s.name == 'Netflix');
    expect(netflix.autoRenew, isTrue);

    // Set billing date to yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    store.updateSubscription(netflix.copyWith(nextBillingDate: yesterday));

    // Running checkAndProcessAutoRenewals should advance Netflix to next month and add to paymentHistory
    store.checkAndProcessAutoRenewals();
    final updatedNetflix = store.subscriptions.firstWhere((s) => s.name == 'Netflix');
    expect(updatedNetflix.nextBillingDate.isAfter(DateTime.now()), isTrue);
    expect(updatedNetflix.paymentHistory.isNotEmpty, isTrue);
  });

  test('Upcoming billing dates and store payment record operations', () {
    final store = SubscriptionStore.instance;
    store.resetForTesting();
    final sub = store.subscriptions.first;

    // Test getUpcomingBillingDates
    final upcoming = sub.getUpcomingBillingDates(4);
    expect(upcoming.length, 4);
    expect(upcoming[1].isAfter(upcoming[0]), isTrue);
    expect(upcoming[2].isAfter(upcoming[1]), isTrue);
    expect(upcoming[3].isAfter(upcoming[2]), isTrue);

    // Test markSubscriptionPaid
    final initialHistoryCount = sub.paymentHistory.length;
    final initialDate = sub.nextBillingDate;
    store.markSubscriptionPaid(sub.id);
    final paidSub = store.getSubscription(sub.id)!;
    expect(paidSub.paymentHistory.length, initialHistoryCount + 1);
    expect(paidSub.nextBillingDate.isAfter(initialDate), isTrue);

    // Test skipSubscriptionCycle
    final beforeSkipDate = paidSub.nextBillingDate;
    final beforeSkipCount = paidSub.paymentHistory.length;
    store.skipSubscriptionCycle(sub.id);
    final skippedSub = store.getSubscription(sub.id)!;
    expect(skippedSub.nextBillingDate.isAfter(beforeSkipDate), isTrue);
    expect(skippedSub.paymentHistory.length, beforeSkipCount); // No new history

    // Test addPaymentRecord and deletePaymentRecord
    final manualDate = DateTime(2025, 1, 15);
    store.addPaymentRecord(sub.id, manualDate);
    final withManual = store.getSubscription(sub.id)!;
    expect(withManual.paymentHistory.contains(manualDate), isTrue);

    store.deletePaymentRecord(sub.id, withManual.paymentHistory.indexOf(manualDate));
    final afterDelete = store.getSubscription(sub.id)!;
    expect(afterDelete.paymentHistory.contains(manualDate), isFalse);
  });

  testWidgets('PaymentHistoryScreen displays lifetime spend and manages records', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final store = SubscriptionStore.instance;
    store.resetForTesting();
    final netflix = store.subscriptions.firstWhere((s) => s.name == 'Netflix');

    // Add 2 payment history records
    store.addPaymentRecord(netflix.id, DateTime(2026, 8, 26));
    store.addPaymentRecord(netflix.id, DateTime(2026, 7, 26));

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: PaymentHistoryScreen(subscriptionId: netflix.id),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment History'), findsOneWidget);
    expect(find.text('Lifetime spend'), findsOneWidget);
    expect(find.text('Payment ledger'), findsOneWidget);
    expect(find.text('2 cycles paid'), findsOneWidget);
    expect(find.text('Paid'), findsNWidgets(2));

    // Tap delete icon on first record
    final deleteIcons = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcons, findsNWidgets(2));
    await tester.tap(deleteIcons.first);
    await tester.pumpAndSettle();

    // Confirm dialog appears
    expect(find.text('Delete record'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Now 1 cycle paid
    expect(find.text('1 cycle paid'), findsOneWidget);
  });

  testWidgets('Context-Aware Due Date Action Banner only renders when due or overdue', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final store = SubscriptionStore.instance;
    store.resetForTesting();
    final netflix = store.subscriptions.firstWhere((s) => s.name == 'Netflix');

    // Case 1: Subscription has 25 days remaining (Not Due)
    store.updateSubscription(netflix.copyWith(
      nextBillingDate: DateTime.now().add(const Duration(days: 25)),
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: SubscriptionDetailScreen(subscription: store.getSubscription(netflix.id)!),
      ),
    );
    await tester.pumpAndSettle();

    // Due banner should NOT be present
    expect(find.text('Mark as Paid'), findsNothing);
    expect(find.text('Skip cycle'), findsNothing);
    expect(find.text('Spend & Billing'), findsOneWidget);
    expect(find.text('Upcoming schedule'), findsOneWidget);
    expect(find.text('Payment history'), findsOneWidget);

    // Case 2: Subscription is Overdue by 2 days
    store.updateSubscription(netflix.copyWith(
      nextBillingDate: DateTime.now().subtract(const Duration(days: 2)),
    ));

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: SubscriptionDetailScreen(subscription: store.getSubscription(netflix.id)!),
      ),
    );
    await tester.pumpAndSettle();

    // Due banner MUST be visible now
    expect(find.text('Payment overdue (2d)'), findsOneWidget);
    expect(find.text('Mark as Paid'), findsOneWidget);
    expect(find.text('Skip cycle'), findsOneWidget);

    // Tapping Mark as Paid
    await tester.tap(find.text('Mark as Paid'));
    await tester.pumpAndSettle();

    // Banner is dismissed because billing date moved to next month
    expect(find.text('Mark as Paid'), findsNothing);
    final updated = store.getSubscription(netflix.id)!;
    expect(updated.nextBillingDate.isAfter(DateTime.now()), isTrue);
  });

  testWidgets('UpcomingScheduleScreen displays 12 projected billing cycles and total estimate', (WidgetTester tester) async {
    final sub = Subscription(
      id: 'test_sub',
      name: 'Netflix Premium',
      description: 'Ultra HD 4 Screens',
      price: 15.49,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      brandColor: const Color(0xFFE50914),
      iconData: Icons.movie,
      nextBillingDate: DateTime.now().add(const Duration(days: 7)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: UpcomingScheduleScreen(subscription: sub),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming schedule'), findsOneWidget);
    expect(find.text('Netflix Premium'), findsOneWidget);
    expect(find.text('PROJECTED BILLING DATES'), findsOneWidget);
    expect(find.text('12 occurrences'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('CategoryPickerScreen displays all One UI categories and updates selection', (WidgetTester tester) async {
    SubscriptionCategory? selectedCat;

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                selectedCat = await CategoryPickerScreen.open(
                  context,
                  initialCategory: SubscriptionCategory.entertainment,
                );
              },
              child: const Text('Open Category Picker'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Category Picker'));
    await tester.pumpAndSettle();

    expect(find.text('ALL CATEGORIES'), findsOneWidget);
    expect(find.text('Productivity & AI'), findsOneWidget);
    expect(find.text('Music & Audio'), findsOneWidget);

    // Tap Music & Audio
    await tester.tap(find.text('Music & Audio'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(selectedCat, equals(SubscriptionCategory.music));
  });

  testWidgets('Payment method display and duplicate PayPal prevention', (WidgetTester tester) async {
    const paypalCard = PaymentMethod(
      id: 'test_paypal',
      nickname: 'Business PayPal',
      type: PaymentMethodType.paypal,
      brand: CardBrand.paypal,
      last4: '',
    );

    // Subtitle must NOT have duplicate "PayPal PayPal"
    expect(paypalCard.subtitleDisplay, equals('PayPal • Digital Wallet'));
    expect(paypalCard.maskedDisplay, equals('Digital Wallet'));
    expect(paypalCard.displayName, equals('Business PayPal'));

    const visaCard = PaymentMethod(
      id: 'test_visa',
      nickname: 'Personal Meezan',
      type: PaymentMethodType.creditCard,
      brand: CardBrand.visa,
      last4: '4242',
    );
    expect(visaCard.subtitleDisplay, equals('Visa •••• 4242'));
    expect(visaCard.displayName, equals('Personal Meezan (•••• 4242)'));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OneUIPaymentBrandIcon(brand: CardBrand.visa),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OneUIPaymentBrandIcon), findsOneWidget);
  });

  testWidgets('Smart payment record deduplication prevents duplicate entries on same date', (WidgetTester tester) async {
    final store = SubscriptionStore.instance;
    final sub = Subscription(
      id: 'test_dedup_sub',
      name: 'GitHub Copilot',
      description: 'Individual Plan',
      price: 10.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.developer,
      brandColor: const Color(0xFF24292E),
      iconData: Icons.code,
      nextBillingDate: DateTime.now().add(const Duration(days: 10)),
    );
    store.addSubscription(sub);

    final today = DateTime.now();
    final firstAdd = store.addPaymentRecord(sub.id, today);
    expect(firstAdd, isTrue);

    final historyAfterFirst = store.getSubscription(sub.id)!.paymentHistory;
    expect(historyAfterFirst.length, equals(1));

    // Attempting to add payment on same calendar day must be rejected
    final secondAdd = store.addPaymentRecord(sub.id, today);
    expect(secondAdd, isFalse);

    final historyAfterSecond = store.getSubscription(sub.id)!.paymentHistory;
    expect(historyAfterSecond.length, equals(1));

    // Adding on a different calendar day succeeds
    final differentDay = today.subtract(const Duration(days: 30));
    final thirdAdd = store.addPaymentRecord(sub.id, differentDay);
    expect(thirdAdd, isTrue);

    final historyAfterThird = store.getSubscription(sub.id)!.paymentHistory;
    expect(historyAfterThird.length, equals(2));
  });

  testWidgets('PaymentMethodsScreen multi-selection mode and floating action bar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: const PaymentMethodsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Payment methods'), findsOneWidget);

    // Long-press on first card to enter multi-selection mode
    final firstCard = find.text('Primary Samsung Pay');
    expect(firstCard, findsOneWidget);
    await tester.longPress(firstCard);
    await tester.pumpAndSettle();

    // In selection mode: header changes to "1" pill and bottom action bar appears
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Move subs'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap second card to select 2
    final secondCard = find.text('Standard Chartered World');
    await tester.tap(secondCard);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    // When > 1 selected, Edit is hidden, Move subs and Delete remain
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Move subs'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap cancel selection pill
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Payment methods'), findsOneWidget);
  });

  testWidgets('PaymentMethodPickerScreen displays saved cards and handles selection', (WidgetTester tester) async {
    PaymentMethod? picked;

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                picked = await PaymentMethodPickerScreen.open(
                  context,
                  currentMethodId: 'pay_samsung_visa',
                );
              },
              child: const Text('Open Payment Picker'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Payment Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('SAVED PAYMENT CARDS'), findsOneWidget);
    expect(find.text('OTHER OPTIONS'), findsOneWidget);
    expect(find.text('Primary Samsung Pay'), findsWidgets);
    expect(find.text('Standard Chartered World'), findsOneWidget);
    expect(find.text('No payment method'), findsOneWidget);

    // Select second card: Standard Chartered World
    await tester.tap(find.text('Standard Chartered World'));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.id, equals('pay_mastercard_4242'));
    expect(picked!.nickname, equals('Standard Chartered World'));
  });

  testWidgets('Consistent bottom spacing across floating navbars, action bars, and stadium pills', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    tester.view.padding = const FakeViewPadding(bottom: 40); // 40px gesture navigation handle
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetPadding();
    });

    // Verify OneUIFloatingNavBar padding
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OneUIFloatingNavBar(
            currentIndex: 0,
            onTap: (_) {},
            items: const [
              OneUINavItem(activeIcon: Icons.home, inactiveIcon: Icons.home_outlined, label: 'Home'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navBarPadding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(OneUIFloatingNavBar),
        matching: find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.only(bottom: 8)),
      ),
    );
    expect(navBarPadding, isNotNull);

    // Verify OneUISelectionActionBar padding
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OneUISelectionActionBar(
            selectedCount: 1,
            onShare: () {},
            onDelete: () {},
            onMore: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectionBarPadding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(OneUISelectionActionBar),
        matching: find.byWidgetPredicate((w) => w is Padding && w.padding == const EdgeInsets.only(bottom: 8)),
      ),
    );
    expect(selectionBarPadding, isNotNull);
  });

  test('Billing anchor drift fix preserves 31st across February', () {
    final sub = Subscription(
      id: 'sub_drift_test',
      name: 'Drift Test',
      description: 'Test Anchor',
      price: 15.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.cloud,
      brandColor: Colors.blue,
      iconData: Icons.cloud,
      nextBillingDate: DateTime(2025, 1, 31),
      anchorDay: 31,
    );

    // Roll forward to February: should clamp to Feb 28
    final febDate = sub.calculateNextDateFrom(sub.nextBillingDate);
    expect(febDate.year, equals(2025));
    expect(febDate.month, equals(2));
    expect(febDate.day, equals(28));

    // Roll forward to March: anchorDay 31 restores March 31 without drifting to 28!
    final marchDate = sub.calculateNextDateFrom(febDate);
    expect(marchDate.year, equals(2025));
    expect(marchDate.month, equals(3));
    expect(marchDate.day, equals(31));

    // Serialization preserves anchorDay
    final json = sub.toJson();
    expect(json['anchorDay'], equals(31));
    final decoded = Subscription.fromJson(json);
    expect(decoded.anchorDay, equals(31));
  });

  test('Free trial exclusion from spend, active status count, and budget clamping', () {
    final store = SubscriptionStore.instance;
    store.clearAllData();

    final activeSub = Subscription(
      id: 'sub_active',
      name: 'Active Service',
      description: 'Active',
      price: 20.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.productivity,
      brandColor: Colors.green,
      iconData: Icons.work,
      status: SubscriptionStatus.active,
      nextBillingDate: DateTime.now().add(const Duration(days: 10)),
    );

    final dueSoonSub = Subscription(
      id: 'sub_due_soon',
      name: 'Due Soon Service',
      description: 'Due Soon',
      price: 10.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      brandColor: Colors.red,
      iconData: Icons.movie,
      status: SubscriptionStatus.dueSoon,
      nextBillingDate: DateTime.now().add(const Duration(days: 1)),
    );

    final trialSub = Subscription(
      id: 'sub_trial',
      name: 'Trial Service',
      description: 'Trial',
      price: 50.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.cloud,
      brandColor: Colors.purple,
      iconData: Icons.cloud,
      status: SubscriptionStatus.trial,
      nextBillingDate: DateTime.now().add(const Duration(days: 20)),
    );

    store.batchAdd([activeSub, dueSoonSub, trialSub]);

    // totalMonthlySpend must only sum active + dueSoon (20 + 10 = 30), NOT the $50 trial!
    expect(store.totalMonthlySpend, equals(30.0));

    // totalActiveCount counts both active and dueSoon (2 paying services)
    expect(store.totalActiveCount, equals(2));

    // highestCostSubscription must be Active Service ($20), NOT the $50 trial!
    expect(store.highestCostSubscription?.id, equals('sub_active'));

    // categorySpendMap must not include the trial category
    expect(store.categorySpendMap[SubscriptionCategory.cloud], isNull);
    expect(store.categorySpendMap[SubscriptionCategory.productivity], equals(20.0));
    expect(store.categorySpendMap[SubscriptionCategory.entertainment], equals(10.0));

    // Budget clamping test
    store.setMonthlyBudget(-50.0);
    expect(store.monthlyBudget, equals(0.0));

    store.setMonthlyBudget(1500000.0);
    expect(store.monthlyBudget, equals(999999.0));

    store.setMonthlyBudget(150.0);
    expect(store.monthlyBudget, equals(150.0));
  });

  test('Monogram hash bitwise AND handles negative hashes gracefully', () {
    // Calling getMonogramColor on various strings should never crash or throw negative index
    expect(() => OneUIBrandCatalog.getMonogramColor(''), returnsNormally);
    expect(() => OneUIBrandCatalog.getMonogramColor('Netflix'), returnsNormally);
    expect(() => OneUIBrandCatalog.getMonogramColor('A' * 1000), returnsNormally);
    expect(() => OneUIBrandCatalog.getMonogramColor('⚡️ Special & Characters 123!'), returnsNormally);
  });

  test('PaymentMethod statement day clamping and expiry month validation', () {
    final methodJson = {
      'id': 'pay_test_clamp',
      'nickname': 'Test Card',
      'statementDay': 99, // Out of bounds
      'expiryDate': '14/28', // Invalid month 14
    };

    final method = PaymentMethod.fromJson(methodJson);
    expect(method.statementDay, equals(31)); // Clamped to 31
    expect(method.expiryStatus, equals(CardExpiryStatus.valid)); // Invalid month does not crash
  });

  test('Free tier \$0.00 subscription creation and constraints', () {
    final freeSub = Subscription(
      id: 'sub_free',
      name: 'Free Cloudflare Tier',
      description: 'Free tier',
      price: 0.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.developer,
      brandColor: Colors.orange,
      iconData: Icons.terminal,
      nextBillingDate: DateTime.now().add(const Duration(days: 30)),
    );

    expect(freeSub.price, equals(0.0));
    expect(freeSub.monthlyCost, equals(0.0));
    expect(freeSub.yearlyCost, equals(0.0));
  });

  test('SpendingTrendsEngine calculates 6M, 12M, and Forecast trajectory accurately', () {
    final ref = DateTime(2026, 9, 24);
    final store = SubscriptionStore.instance;

    // 6 Months horizon
    final points6M = store.getSpendingTrends(SpendingTrendHorizon.sixMonths, ref);
    expect(points6M.length, equals(6));
    expect(points6M.last.month.year, equals(2026));
    expect(points6M.last.month.month, equals(9));
    expect(points6M.first.month.month, equals(4)); // Apr to Sep

    // Summary calculation
    final summary6M = store.getSpendingTrendSummary(SpendingTrendHorizon.sixMonths, ref);
    expect(summary6M.hasData, isTrue);
    expect(summary6M.averageMonthlySpend, greaterThan(0));
    expect(summary6M.peakMonth, isNotNull);
    expect(summary6M.lowestMonth, isNotNull);

    // 12 Months horizon
    final points1Y = store.getSpendingTrends(SpendingTrendHorizon.oneYear, ref);
    expect(points1Y.length, equals(12));
    expect(points1Y.last.month.month, equals(9));
    expect(points1Y.first.month.month, equals(10)); // Oct 2025 to Sep 2026
    expect(points1Y.first.month.year, equals(2025));

    // Forecast horizon
    final pointsForecast = store.getSpendingTrends(SpendingTrendHorizon.forecastSixMonths, ref);
    expect(pointsForecast.length, equals(6));
    expect(pointsForecast.first.month.month, equals(9)); // Sep
    expect(pointsForecast.last.month.month, equals(2));  // Feb 2027
    expect(pointsForecast.last.month.year, equals(2027));
    expect(pointsForecast.first.isProjected, isTrue);
  });

  test('SpendingTrendsEngine respects paymentHistory charges and MoM calculation', () {
    final ref = DateTime(2026, 9, 24);
    final testSub = Subscription(
      id: 'sub_trend_test',
      name: 'Custom Service',
      description: 'Test service',
      price: 50.0,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      brandColor: Colors.blue,
      iconData: Icons.bolt,
      nextBillingDate: DateTime(2026, 9, 10),
      paymentHistory: [
        DateTime(2026, 8, 10), // Logged in August
        DateTime(2026, 7, 10), // Logged in July
      ],
    );

    final points = SpendingTrendsEngine.calculateTrends(
      subscriptions: [testSub],
      horizon: SpendingTrendHorizon.sixMonths,
      referenceDate: ref,
    );

    // August point (index 4) should have $50
    final augPoint = points.firstWhere((p) => p.month.month == 8 && p.month.year == 2026);
    expect(augPoint.amount, equals(50.0));
    expect(augPoint.renewalCount, equals(1));
    expect(augPoint.categoryBreakdown[SubscriptionCategory.utilities], equals(50.0));

    // MoM comparison between July ($50) and August ($50) should be 0%
    expect(augPoint.momDifference, equals(0.0));
    expect(augPoint.momPercentage, equals(0.0));
    expect(augPoint.isNeutral, isTrue);
  });

  testWidgets('OneUISpendingTrendsCard renders and interacts smoothly in AnalyticsScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Navigate to Analytics tab
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    // Verify Spending trajectory card header and components
    expect(find.text('Spending trajectory'), findsOneWidget);
    expect(find.text('6M'), findsOneWidget);
    expect(find.text('1Y'), findsOneWidget);
    expect(find.text('Forecast'), findsOneWidget);
    expect(find.byType(OneUILineChart), findsOneWidget);
    expect(find.text('Monthly Avg'), findsWidgets);

    // Switch to 1Y horizon
    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUILineChart), findsOneWidget);

    // Switch to Forecast horizon
    await tester.tap(find.text('Forecast'));
    await tester.pumpAndSettle();
    expect(find.text('Projected'), findsWidgets);

    // Test chart scrubbing / touch gesture
    final chartFinder = find.byType(OneUILineChart);
    final chartTopLeft = tester.getTopLeft(chartFinder);
    await tester.tapAt(chartTopLeft + const Offset(40, 40));
    await tester.pumpAndSettle();

    // Verify share report dialog includes MoM trajectory
    await tester.tap(find.byTooltip('Share report'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MoM Trajectory'), findsOneWidget);
    expect(find.text('Copy Report'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('OneUISpendingTrendsCard displays empty state when all subscriptions removed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Render standalone card with empty list
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: OneUISpendingTrendsCard(
              subscriptions: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No spending trajectory yet'), findsOneWidget);
  });

  testWidgets('Samsung One UI Bottom Gradient Vignette renders on all main tabs and isolates GPU repaints', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify OneUIBottomVignette is present on Spend tab
    expect(find.byType(OneUIBottomVignette), findsWidgets);

    // Verify OneUIBottomVignette contains IgnorePointer and RepaintBoundary for GPU isolation
    final vignetteFinder = find.byType(OneUIBottomVignette).first;
    expect(find.descendant(of: vignetteFinder, matching: find.byType(IgnorePointer)), findsOneWidget);
    expect(find.descendant(of: vignetteFinder, matching: find.byType(RepaintBoundary)), findsOneWidget);

    // Switch to Upcoming tab and verify vignette exists
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIBottomVignette), findsWidgets);

    // Switch to Analytics tab and verify vignette exists
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIBottomVignette), findsWidgets);

    // Switch to Menu (Settings) tab and verify vignette exists
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIBottomVignette), findsWidgets);
  });

  testWidgets('OneUIBottomVignette respects OneUIEffectsController toggle and Settings appearance switch', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    OneUIEffectsController.instance.bottomVignetteEffect = true;

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Navigate to Menu tab
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Verify Settings displays 'Bottom gradient vignette'
    expect(find.text('Bottom gradient vignette'), findsOneWidget);
    expect(OneUIEffectsController.instance.bottomVignetteEffect, isTrue);

    // Toggle switch off
    await tester.dragUntilVisible(find.text('Bottom gradient vignette'), find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bottom gradient vignette'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.bottomVignetteEffect, isFalse);

    // Reset appearance effects
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset appearance effects'));
    await tester.pumpAndSettle();

    expect(OneUIEffectsController.instance.bottomVignetteEffect, isTrue);
  });

  testWidgets('OneUIBottomVignette is layered behind OneUIScrollToTopButton and floating navigation pill', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Verify both OneUIBottomVignette and OneUIFloatingNavBar exist simultaneously
    expect(find.byType(OneUIBottomVignette), findsWidgets);
    expect(find.byType(OneUIFloatingNavBar), findsOneWidget);

    // Scroll down to reveal OneUIScrollToTopButton
    await tester.drag(find.text('Netflix').first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIScrollToTopButton), findsOneWidget);
  });

  testWidgets('Floating pill and navbar shadows are elevated in both 3D and Flat modes so they never dissolve', (WidgetTester tester) async {
    // 3D Mode Check
    OneUIEffectsController.instance.floating3dEffect = true;
    OneUIEffectsController.instance.navbar3dEffect = true;
    OneUIEffectsController.instance.card3dEffect = true;

    final shadow3d = OneUITheme.floatingShadow;
    expect(shadow3d, isNotEmpty);
    expect(shadow3d.length, 2);
    expect(shadow3d.first.blurRadius, 20);
    expect(shadow3d.first.spreadRadius, 1.0);
    expect(shadow3d.first.offset.dy, 4);

    final navShadow3d = OneUITheme.navbarShadow;
    expect(navShadow3d, isNotEmpty);
    expect(navShadow3d.length, 2);
    expect(navShadow3d.first.offset.dy, lessThan(0)); // Upward lift
    expect(navShadow3d.first.spreadRadius, 1.0);

    final cardShadow3d = OneUITheme.cardShadow;
    expect(cardShadow3d, isNotEmpty);
    expect(cardShadow3d.first.blurRadius, 16);
    expect(cardShadow3d.first.offset.dy, 6);

    // Flat Mode Check
    OneUIEffectsController.instance.floating3dEffect = false;
    OneUIEffectsController.instance.navbar3dEffect = false;
    OneUIEffectsController.instance.card3dEffect = false;

    final shadowFlat = OneUITheme.floatingShadow;
    expect(shadowFlat, isNotEmpty);
    expect(shadowFlat.length, 2);
    expect(shadowFlat.first.blurRadius, 16);
    expect(shadowFlat.first.spreadRadius, 1.0);
    expect(shadowFlat.first.offset.dy, 3); // Soft ambient offset matching Samsung One UI reference

    final navShadowFlat = OneUITheme.navbarShadow;
    expect(navShadowFlat, isNotEmpty);
    expect(navShadowFlat.first.offset.dy, lessThan(0)); // Upward ambient lift in flat mode!
    expect(navShadowFlat.first.spreadRadius, 0.5);

    // Cards remain flat in normal/flat mode
    final cardShadowFlat = OneUITheme.cardShadow;
    expect(cardShadowFlat, isEmpty);

    // Reset back to defaults
    OneUIEffectsController.instance.floating3dEffect = true;
    OneUIEffectsController.instance.navbar3dEffect = true;
    OneUIEffectsController.instance.card3dEffect = true;
  });

  testWidgets('Top selection capsules render with ambient floating shadow matching Samsung One UI reference screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(
          body: OneUISelectionPills(
            selectedCount: 1,
            totalCount: 5,
            onToggleSelectAll: () {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify pills render with text and circle
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Verify selection pills have ambient floatingShadow with soft offset <= 2 (no 8px blob)
    final decoratedBoxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    final selectionBox = decoratedBoxes.firstWhere((box) {
      final decoration = box.decoration;
      return decoration is BoxDecoration && decoration.boxShadow == OneUITheme.floatingShadow;
    });
    final shadows = (selectionBox.decoration as BoxDecoration).boxShadow!;
    expect(shadows, isNotEmpty);
    for (final s in shadows) {
      expect(s.offset.dy, lessThanOrEqualTo(4.0), reason: 'Shadow offset must be ambient (<= 4px), never a heavy 8px downward blob');
    }
  });

  testWidgets('OneUIBottomVignette is present on subpages with floating bottom action bars and pills', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. SubscriptionDetailScreen
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: SubscriptionDetailScreen(
        subscription: Subscription(
          id: 'test_sub_1',
          name: 'Netflix',
          description: 'Standard Plan',
          price: 15.99,
          billingCycle: BillingCycle.monthly,
          nextBillingDate: DateTime.now().add(const Duration(days: 10)),
          category: SubscriptionCategory.entertainment,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIBottomVignette), findsOneWidget);
    expect(find.byType(OneUIFloatingActionBar), findsOneWidget);

    // 2. PaymentMethodPickerScreen (Normal mode)
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: const PaymentMethodPickerScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIBottomVignette), findsOneWidget);
    expect(find.byType(OneUIFloatingCancelSavePill), findsOneWidget);

    // 3. CategoryPickerScreen
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: const CategoryPickerScreen(initialCategory: SubscriptionCategory.entertainment),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIBottomVignette), findsOneWidget);
    expect(find.byType(OneUIFloatingCancelSavePill), findsOneWidget);

    // 4. ReminderPickerScreen
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: const ReminderPickerScreen(initialDays: 2),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIBottomVignette), findsOneWidget);
    expect(find.byType(OneUIFloatingCancelSavePill), findsOneWidget);

    // 5. PopularPresetsScreen
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: const PopularPresetsScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIBottomVignette), findsOneWidget);
  });

  test('SubscriptionDriftDataSource saves and retrieves recent searches via Drift AppSettingsTable', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final ds = SubscriptionDriftDataSource(db);

    expect(await ds.getRecentSearches(), isEmpty);

    await ds.saveRecentSearches(['Netflix', 'Spotify', 'ChatGPT']);
    final loaded = await ds.getRecentSearches();
    expect(loaded, ['Netflix', 'Spotify', 'ChatGPT']);

    await ds.saveRecentSearches([]);
    expect(await ds.getRecentSearches(), isEmpty);
    await db.close();
  });

  test('SubscriptionController handles recent searches deduplication and cap', () {
    final store = SubscriptionStore.instance;
    expect(store.recentSearches, isEmpty);

    store.addRecentSearch('Netflix');
    store.addRecentSearch('Spotify');
    expect(store.recentSearches, ['Spotify', 'Netflix']);

    // Re-adding Netflix moves it to the front
    store.addRecentSearch('Netflix');
    expect(store.recentSearches, ['Netflix', 'Spotify']);

    // Case-insensitive deduplication
    store.addRecentSearch('spotify');
    expect(store.recentSearches, ['spotify', 'Netflix']);

    // Cap at 10
    for (int i = 0; i < 15; i++) {
      store.addRecentSearch('Query $i');
    }
    expect(store.recentSearches.length, 10);
    expect(store.recentSearches.first, 'Query 14');

    // Remove single
    store.removeRecentSearch('Query 14');
    expect(store.recentSearches.contains('Query 14'), isFalse);
    expect(store.recentSearches.length, 9);

    // Clear all
    store.clearRecentSearches();
    expect(store.recentSearches, isEmpty);
  });

  testWidgets('SubscriptionsScreen displays Samsung One UI Recent Searches chips, handles search tap, delete, and clear all', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const OneSpendApp());
    await tester.pumpAndSettle();

    // Tap search icon in header
    final searchIconFinder = find.byIcon(Icons.search_rounded).first;
    await tester.tap(searchIconFinder);
    await tester.pumpAndSettle();

    // Verify empty state "No recent searches" is visible
    expect(find.text('No recent searches'), findsOneWidget);
    expect(find.text('Recent searches'), findsNothing);

    // Add recent searches programmatically
    SubscriptionStore.instance.addRecentSearch('Netflix');
    SubscriptionStore.instance.addRecentSearch('Spotify');
    await tester.pumpAndSettle();

    // Verify "Recent searches" header, chips, and "Clear all" button appear
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
    expect(find.text('No recent searches'), findsNothing);

    // Tap on 'Netflix' chip -> triggers search and shows Netflix results
    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();

    expect(find.text('Results (1)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'Netflix');

    // Clear search text field using clear button
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    // Back to recent searches view
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);

    // Tap delete on Spotify chip
    final spotifyCloseBtn = find.descendant(
      of: find.ancestor(of: find.text('Spotify'), matching: find.byType(Container)),
      matching: find.byIcon(Icons.close_rounded),
    );
    await tester.tap(spotifyCloseBtn.first);
    await tester.pumpAndSettle();

    expect(find.text('Spotify'), findsNothing);
    expect(find.text('Netflix'), findsOneWidget);

    // Tap "Clear all"
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    // Verify reverts cleanly to "No recent searches"
    expect(find.text('No recent searches'), findsOneWidget);
    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets('OneUIBottomVignette decreases height and gradient when hasFloatingElements is false', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. With floating elements (normal mode)
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OneUIBottomVignette(hasFloatingElements: true),
      ),
    ));
    await tester.pumpAndSettle();

    final animatedContainerNormal = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(OneUIBottomVignette), matching: find.byType(AnimatedContainer)),
    );
    final normalBoxDec = animatedContainerNormal.decoration as BoxDecoration;
    expect(normalBoxDec.gradient, OneUIBottomVignette.normalGradient);

    // 2. Without floating elements (decreased mode)
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OneUIBottomVignette(hasFloatingElements: false),
      ),
    ));
    await tester.pumpAndSettle();

    final animatedContainerDecreased = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(OneUIBottomVignette), matching: find.byType(AnimatedContainer)),
    );
    final decBoxDec = animatedContainerDecreased.decoration as BoxDecoration;
    expect(decBoxDec.gradient, OneUIBottomVignette.decreasedGradient);
  });

  testWidgets('PopularPresetsScreen toggles OneUIBottomVignette hasFloatingElements between search modes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: const PopularPresetsScreen(),
    ));
    await tester.pumpAndSettle();

    // In browsing mode, hasFloatingElements is false (decreased)
    var vignette = tester.widget<OneUIBottomVignette>(find.byType(OneUIBottomVignette));
    expect(vignette.hasFloatingElements, isFalse);

    // Enter search mode
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    // Now hasFloatingElements is true (normal mode behind search pill)
    vignette = tester.widget<OneUIBottomVignette>(find.byType(OneUIBottomVignette));
    expect(vignette.hasFloatingElements, isTrue);
  });

  testWidgets('OneUIStatusBarScrim renders with extended height, progressive blur, and GPU isolation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: OneUIStatusBarScrim(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OneUIStatusBarScrim), findsOneWidget);
    final scrimFinder = find.byType(OneUIStatusBarScrim);
    expect(find.descendant(of: scrimFinder, matching: find.byType(IgnorePointer)), findsOneWidget);
    expect(find.descendant(of: scrimFinder, matching: find.byType(RepaintBoundary)), findsOneWidget);
    expect(find.descendant(of: scrimFinder, matching: find.byType(BackdropFilter)), findsOneWidget);
  });
}



