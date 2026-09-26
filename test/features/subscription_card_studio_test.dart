import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_card_customizer_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_subscription_card.dart';
import 'package:onespend/widgets/one_ui_upcoming_carousel.dart';
import 'package:onespend/widgets/one_ui_bottom_vignette.dart';
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
      expect(ctrl.priceMode, equals(SubscriptionPriceMode.billedAmount));
      expect(ctrl.renewalBadgeMode, equals(SubscriptionRenewalBadgeMode.countdown));
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.showPaymentMethodChip, isTrue);
      expect(ctrl.showCategoryChip, isTrue);
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.upcomingSectionStyle, equals(UpcomingSectionStyle.groupedList));
    });

    test('Data display settings toggle and persist in OneUIEffectsController', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.priceMode = SubscriptionPriceMode.monthlyEquivalent;
      ctrl.showDailyEquivalent = true;
      ctrl.showCycleProgress = false;
      ctrl.showPaymentMethodChip = false;
      ctrl.showCategoryChip = false;

      expect(ctrl.priceMode, equals(SubscriptionPriceMode.monthlyEquivalent));
      expect(ctrl.showDailyEquivalent, isTrue);
      expect(ctrl.showCycleProgress, isFalse);
      expect(ctrl.showPaymentMethodChip, isFalse);
      expect(ctrl.showCategoryChip, isFalse);
    });

    test('resetCardStyle restores data display settings to default', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.priceMode = SubscriptionPriceMode.monthlyEquivalent;
      ctrl.showDailyEquivalent = true;
      ctrl.showCycleProgress = false;
      ctrl.showPaymentMethodChip = false;
      ctrl.showCategoryChip = false;

      ctrl.resetCardStyle();

      expect(ctrl.priceMode, equals(SubscriptionPriceMode.billedAmount));
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.showPaymentMethodChip, isTrue);
      expect(ctrl.showCategoryChip, isTrue);
    });
  });

  group('SubscriptionCardCustomizerScreen UI & Live Studio', () {
    testWidgets('Renders preview card, sample brands, and toggles price modes', (WidgetTester tester) async {
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
      expect(find.text('Card details & indicators'), findsWidgets);

      // Verify sample brand switcher chips
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Spotify Premium'), findsWidgets);
      expect(find.text('YouTube Premium'), findsWidgets);
      expect(find.text('Apple iCloud+ 2TB'), findsWidgets);

      // Tap Spotify chip to switch preview sample
      await tester.tap(find.text('Spotify Premium'));
      await tester.pumpAndSettle();
      expect(find.text('Spotify Premium'), findsWidgets);

      // Verify Price & cost presentation options
      expect(find.text('Price & cost presentation'), findsOneWidget);
      expect(find.text('Billed amount prominent'), findsOneWidget);
      expect(find.text('Monthly normalized prominent'), findsOneWidget);
      expect(find.text('Raw amount only'), findsOneWidget);

      // Tap Monthly normalized prominent
      await tester.tap(find.text('Monthly normalized prominent'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.priceMode, equals(SubscriptionPriceMode.monthlyEquivalent));

      // Tap Raw amount only
      await tester.tap(find.text('Raw amount only'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.priceMode, equals(SubscriptionPriceMode.rawAmount));
    });

    testWidgets('Toggles indicator switches and daily equivalent cost interactively', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionCardCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Indicators & Badges section
      await tester.scrollUntilVisible(find.text('Indicators & badges'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.text('Indicators & badges'), findsOneWidget);
      expect(find.text('Billing cycle progress bar'), findsOneWidget);
      expect(find.text('Payment method chip'), findsOneWidget);
      expect(find.text('Category chip'), findsOneWidget);

      // Toggle Billing cycle progress bar
      await tester.tap(find.text('Billing cycle progress bar'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showCycleProgress, isFalse);

      // Toggle Payment method chip
      await tester.tap(find.text('Payment method chip'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showPaymentMethodChip, isFalse);

      // Toggle Category chip
      await tester.tap(find.text('Category chip'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.showCategoryChip, isFalse);

      // Scroll to Reset Button
      await tester.scrollUntilVisible(find.text('Reset card data display to defaults'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Reset card data display to defaults'));
      await tester.pumpAndSettle();

      // Verify restored defaults
      expect(OneUIEffectsController.instance.showCycleProgress, isTrue);
      expect(OneUIEffectsController.instance.showPaymentMethodChip, isTrue);
      expect(OneUIEffectsController.instance.showCategoryChip, isTrue);
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
              overrideShowDailyEquivalent: true,
              overrideShowCycleProgress: true,
              overrideShowCategoryChip: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disney+'), findsOneWidget);
      expect(find.textContaining('13.99'), findsWidgets);
      expect(find.textContaining('/ day'), findsOneWidget);
    });

    testWidgets('OneUISubscriptionCard renders inline payment method icon and nickname', (WidgetTester tester) async {
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
              cardBrandIcon: Icons.credit_card_rounded,
              overrideShowPaymentMethodChip: true,
              overrideShowCategoryChip: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spotify Premium'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_rounded), findsOneWidget);
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
