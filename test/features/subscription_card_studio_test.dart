import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_card_customizer_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_subscription_card.dart';
import 'package:onespend/widgets/one_ui_upcoming_carousel.dart';
import 'package:onespend/widgets/one_ui_bottom_vignette.dart';
import 'package:onespend/widgets/one_ui_payment_brand_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OneUIEffectsController.instance.init();
    OneUIEffectsController.instance.resetCardStyle();
  });

  group('OneUIEffectsController Subscription Card Customizations', () {
    test('Default values follow Samsung One UI specifications', () {
      final ctrl = OneUIEffectsController.instance;
      expect(ctrl.cardBackground, equals(SubscriptionCardBackground.oneUiDark));
      expect(ctrl.cardLayout, equals(SubscriptionCardLayout.oneUiFluent));
      expect(ctrl.brandAccent, equals(SubscriptionBrandAccent.neutral));
      expect(ctrl.priceMode, equals(SubscriptionPriceMode.rawAmount));
      expect(ctrl.renewalBadgeMode, equals(SubscriptionRenewalBadgeMode.countdown));
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.showPaymentMethodChip, isFalse);
      expect(ctrl.showCategoryChip, isTrue);
      expect(ctrl.showBillingCycle, isFalse);
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.upcomingSectionStyle, equals(UpcomingSectionStyle.groupedList));
    });

    test('Data display settings toggle and persist in OneUIEffectsController', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.priceMode = SubscriptionPriceMode.monthlyEquivalent;
      ctrl.showDailyEquivalent = true;
      ctrl.showCycleProgress = false;
      ctrl.showPaymentMethodChip = true;
      ctrl.showCategoryChip = false;
      ctrl.showBillingCycle = true;

      expect(ctrl.priceMode, equals(SubscriptionPriceMode.monthlyEquivalent));
      expect(ctrl.showDailyEquivalent, isTrue);
      expect(ctrl.showCycleProgress, isFalse);
      expect(ctrl.showPaymentMethodChip, isTrue);
      expect(ctrl.showCategoryChip, isFalse);
      expect(ctrl.showBillingCycle, isTrue);
    });

    test('resetCardStyle restores data display settings to default', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.priceMode = SubscriptionPriceMode.monthlyEquivalent;
      ctrl.showDailyEquivalent = true;
      ctrl.showCycleProgress = false;
      ctrl.showPaymentMethodChip = true;
      ctrl.showCategoryChip = false;
      ctrl.showBillingCycle = true;

      ctrl.resetCardStyle();

      expect(ctrl.priceMode, equals(SubscriptionPriceMode.rawAmount));
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.showPaymentMethodChip, isFalse);
      expect(ctrl.showCategoryChip, isTrue);
      expect(ctrl.showBillingCycle, isFalse);
    });
  });

  group('SubscriptionCardCustomizerScreen UI & Settings', () {
    testWidgets('Toggles price modes with One UI option subpage and live preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionCardCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Subscription cards'), findsWidgets);

      // Verify Price display row with current default subtitle (Amount only)
      expect(find.text('Price display'), findsOneWidget);
      expect(find.text('Amount only'), findsOneWidget);

      // Tap Price display to navigate to option subpage
      await tester.tap(find.text('Price display'));
      await tester.pumpAndSettle();

      // Subpage is open with live preview card and options
      expect(find.byType(SubscriptionCardOptionScreen<SubscriptionPriceMode>), findsOneWidget);
      expect(find.byType(OneUISubscriptionCard), findsOneWidget);
      expect(find.text('Monthly normalized'), findsOneWidget);
      expect(find.text('Actual billed amount'), findsOneWidget);

      // Tap Monthly normalized
      await tester.tap(find.text('Monthly normalized'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.priceMode, equals(SubscriptionPriceMode.monthlyEquivalent));

      // Tap Actual billed amount on the same subpage
      await tester.tap(find.text('Actual billed amount'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.priceMode, equals(SubscriptionPriceMode.billedAmount));

      // Back navigation returns to main customizer
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Actual billed amount'), findsOneWidget); // subtitle updated on main screen
    });

    testWidgets('Toggles card detail switches and reset action interactively', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionCardCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Card details section and clean headings (no descriptions)
      expect(find.text('Card details'), findsOneWidget);
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Billing cycle'), findsOneWidget);
      // Payment method is initially false by default, so Corner payment badge is hidden
      expect(find.text('Corner payment badge'), findsNothing);

      // Toggle Payment method (from default false to true)
      await tester.tap(find.text('Payment method'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showPaymentMethodChip, isTrue);
      // Now Corner payment badge is visible
      expect(find.text('Corner payment badge'), findsOneWidget);

      // Toggle Category (from default true to false)
      await tester.tap(find.text('Category'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showCategoryChip, isFalse);

      // Toggle Billing cycle (from default false to true)
      await tester.tap(find.text('Billing cycle'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showBillingCycle, isTrue);

      // Toggle Corner payment badge
      await tester.tap(find.text('Corner payment badge'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.paymentBadgeStyle, equals(PaymentBadgeStyle.inlineSubtitle));

      // Drag up to reveal Reset Button
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset to defaults'));
      await tester.pumpAndSettle();

      // Verify restored defaults
      expect(OneUIEffectsController.instance.showPaymentMethodChip, isFalse);
      expect(OneUIEffectsController.instance.showCategoryChip, isTrue);
      expect(OneUIEffectsController.instance.showBillingCycle, isFalse);
      expect(OneUIEffectsController.instance.paymentBadgeStyle, equals(PaymentBadgeStyle.cornerBadge));
      expect(find.text('Corner payment badge'), findsNothing);
    });

    testWidgets('Corner badge and Card expiring badge are visible on OneUISubscriptionCard', (WidgetTester tester) async {
      final sampleSub = Subscription(
        id: 'sub_expiring_test',
        name: 'Netflix',
        description: 'Movies & TV',
        price: 15.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 3)),
        brandColorValue: 0xFFE50914,
      );

      // Test 1: Corner badge style with expiring card
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              paymentMethodNickname: 'Chase Visa',
              cardBrand: CardBrand.visa,
              isCardExpiring: true,
              overrideShowPaymentMethodChip: true,
              overridePaymentBadgeStyle: PaymentBadgeStyle.cornerBadge,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.byType(OneUIPaymentBrandIcon), findsOneWidget);
      expect(find.text('Card expiring'), findsOneWidget);

      // Test 2: Inline subtitle style with expiring card
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              paymentMethodNickname: 'Chase Visa',
              cardBrand: CardBrand.visa,
              isCardExpiring: true,
              overrideShowPaymentMethodChip: true,
              overridePaymentBadgeStyle: PaymentBadgeStyle.inlineSubtitle,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.byType(OneUIPaymentBrandIcon), findsOneWidget);
      expect(find.text('Card expiring'), findsOneWidget);
    });
  });

  group('OneUISubscriptionCard & OneUIUpcomingRenewalsSection Widgets', () {
    testWidgets('OneUISubscriptionCard renders data fields and formats price correctly', (WidgetTester tester) async {
      final sampleSub = Subscription(
        id: 'sub_test',
        name: 'Disney+',
        description: 'Movies & series',
        price: 13.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        brandColor: const Color(0xFF113CCF),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overridePriceMode: SubscriptionPriceMode.monthlyEquivalent,
              overrideShowCategoryChip: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disney+'), findsOneWidget);
      expect(find.textContaining('13.99/mo'), findsOneWidget);
    });

    testWidgets('OneUISubscriptionCard renders daily equivalent cost when enabled', (WidgetTester tester) async {
      final sampleSub = Subscription(
        id: 'sub_daily_test',
        name: 'Spotify',
        description: 'Music',
        price: 10.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        brandColor: const Color(0xFF1DB954),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overridePriceMode: SubscriptionPriceMode.rawAmount,
              overrideShowDailyEquivalent: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$10.99'), findsOneWidget);
      expect(find.text('\$0.36/day'), findsOneWidget);
    });

    testWidgets('OneUISubscriptionCard hides billing cycle from desc by default and shows when enabled', (WidgetTester tester) async {
      final sampleSub = Subscription(
        id: 'sub_cycle_test',
        name: 'Netflix',
        description: 'Movies',
        price: 15.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        brandColor: const Color(0xFFE50914),
      );

      // Default (showCategoryChip: true, showBillingCycle: false)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overrideShowCategoryChip: true,
              overrideShowBillingCycle: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only category "Entertainment" should be in the description, NOT "Monthly"
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.textContaining('Monthly'), findsNothing);

      // When overrideShowBillingCycle is true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overrideShowCategoryChip: true,
              overrideShowBillingCycle: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Now "Entertainment • Monthly" is present
      expect(find.text('Entertainment • Monthly'), findsOneWidget);
    });

    testWidgets('OneUISubscriptionCard renders official CardBrand logo (Visa, Mastercard)', (WidgetTester tester) async {
      final sampleSub = Subscription(
        id: 'sub_pay_test',
        name: 'Spotify Premium',
        description: 'Music',
        price: 10.99,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime.now().add(const Duration(days: 5)),
        brandColor: const Color(0xFF1DB954),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              paymentMethodNickname: 'Chase Visa',
              cardBrand: CardBrand.visa,
              overrideShowPaymentMethodChip: true,
              overrideShowCategoryChip: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.byType(OneUIPaymentBrandIcon), findsOneWidget);
      expect(find.textContaining('Chase Visa'), findsOneWidget);
    });

    testWidgets('SubscriptionCardCustomizerScreen positions bottom vignette at bottom of stack', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionCardCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final vignetteFinder = find.byType(OneUIBottomVignette);
      expect(vignetteFinder, findsOneWidget);

      final positionedFinder = find.ancestor(
        of: vignetteFinder,
        matching: find.byType(Positioned),
      );
      expect(positionedFinder, findsOneWidget);

      final Positioned positioned = tester.widget(positionedFinder);
      expect(positioned.bottom, equals(0.0));
      expect(positioned.left, equals(0.0));
      expect(positioned.right, equals(0.0));
    });

    testWidgets('OneUIUpcomingRenewalsSection renders upcoming list cleanly', (WidgetTester tester) async {
      final sampleSubs = [
        Subscription(
          id: 'sub_1',
          name: 'Netflix',
          description: 'Streaming',
          price: 19.99,
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.entertainment,
          nextBillingDate: DateTime.now().add(const Duration(days: 2)),
          brandColor: const Color(0xFFE50914),
        ),
        Subscription(
          id: 'sub_2',
          name: 'Gym',
          description: 'Fitness club',
          price: 49.99,
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.health,
          nextBillingDate: DateTime.now().add(const Duration(days: 6)),
          brandColor: const Color(0xFF00C853),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIUpcomingRenewalsSection(
              upcomingSubscriptions: sampleSubs,
              onTapSubscription: (sub) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming renewals'), findsOneWidget);
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Gym'), findsWidgets);
    });
  });
}
