import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_card_customizer_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_subscription_card.dart';
import 'package:onespend/widgets/one_ui_upcoming_carousel.dart';
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
      expect(ctrl.brandAccent, equals(SubscriptionBrandAccent.leftStrip));
      expect(ctrl.priceMode, equals(SubscriptionPriceMode.billedAmount));
      expect(ctrl.renewalBadgeMode, equals(SubscriptionRenewalBadgeMode.countdown));
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.showPaymentMethodChip, isTrue);
      expect(ctrl.showCategoryChip, isTrue);
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.upcomingSectionStyle, equals(UpcomingSectionStyle.carousel));
    });

    test('Background resolution matches selected palette preset', () {
      final ctrl = OneUIEffectsController.instance;

      // Pure Black
      ctrl.cardBackground = SubscriptionCardBackground.pureBlack;
      expect(ctrl.resolveCardBackground(), equals(const Color(0xFF090A0D)));

      // Midnight Navy
      ctrl.cardBackground = SubscriptionCardBackground.midnightNavy;
      expect(ctrl.resolveCardBackground(), equals(const Color(0xFF151B27)));

      // Deep Amethyst
      ctrl.cardBackground = SubscriptionCardBackground.deepAmethyst;
      expect(ctrl.resolveCardBackground(), equals(const Color(0xFF1E172E)));

      // Custom Color
      ctrl.customCardBackgroundColor = const Color(0xFF1B2E24);
      ctrl.cardBackground = SubscriptionCardBackground.custom;
      expect(ctrl.resolveCardBackground(), equals(const Color(0xFF1B2E24)));

      // Brand Tinted
      ctrl.cardBackground = SubscriptionCardBackground.brandTinted;
      final brandColor = const Color(0xFFE50914);
      final tinted = ctrl.resolveCardBackground(brandColor: brandColor);
      expect(tinted, isNot(equals(const Color(0xFF1C1C1E))));
    });

    test('resetCardStyle restores all settings to default', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.cardBackground = SubscriptionCardBackground.midnightNavy;
      ctrl.cardLayout = SubscriptionCardLayout.bentoElevated;
      ctrl.brandAccent = SubscriptionBrandAccent.ambientGlow;
      ctrl.priceMode = SubscriptionPriceMode.monthlyEquivalent;
      ctrl.showDailyEquivalent = true;
      ctrl.showCycleProgress = false;
      ctrl.upcomingSectionStyle = UpcomingSectionStyle.spotlight;

      ctrl.resetCardStyle();

      expect(ctrl.cardBackground, equals(SubscriptionCardBackground.oneUiDark));
      expect(ctrl.cardLayout, equals(SubscriptionCardLayout.oneUiFluent));
      expect(ctrl.brandAccent, equals(SubscriptionBrandAccent.leftStrip));
      expect(ctrl.priceMode, equals(SubscriptionPriceMode.billedAmount));
      expect(ctrl.showDailyEquivalent, isFalse);
      expect(ctrl.showCycleProgress, isTrue);
      expect(ctrl.upcomingSectionStyle, equals(UpcomingSectionStyle.carousel));
    });
  });

  group('SubscriptionCardCustomizerScreen UI & Live Studio', () {
    testWidgets('Renders preview card, sample brands, and custom palette options', (WidgetTester tester) async {
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
      expect(find.text('Card style'), findsWidgets);

      // Verify sample brand switcher chips
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Spotify Premium'), findsWidgets);
      expect(find.text('YouTube Premium'), findsWidgets);
      expect(find.text('Apple iCloud+ 2TB'), findsWidgets);

      // Tap Spotify chip to switch preview sample
      await tester.tap(find.text('Spotify Premium'));
      await tester.pumpAndSettle();
      expect(find.text('Spotify Premium'), findsWidgets);

      // Verify background options exist
      expect(find.text('One UI Dark'), findsOneWidget);
      expect(find.text('Pure Black (OLED)'), findsOneWidget);

      // Tap Midnight Navy
      await tester.scrollUntilVisible(find.text('Midnight Navy'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Midnight Navy'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.cardBackground, equals(SubscriptionCardBackground.midnightNavy));

      // Open Custom Color sheet
      await tester.scrollUntilVisible(find.text('Custom color'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Custom color'));
      await tester.pumpAndSettle();
      expect(find.text('Select custom background color'), findsOneWidget);

      // Select first custom color circle and verify it updates
      await tester.tap(find.descendant(of: find.byType(Wrap), matching: find.byType(GestureDetector)).first);
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.cardBackground, equals(SubscriptionCardBackground.custom));
    });

    testWidgets('Switches layout archetypes and brand accents interactively', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionCardCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Layout Architecture section
      await tester.scrollUntilVisible(find.text('Card layout architecture'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.text('Card layout architecture'), findsOneWidget);
      expect(find.textContaining('Bento Elevated'), findsOneWidget);
      expect(find.textContaining('Compact Minimalist'), findsOneWidget);

      // Tap Bento Elevated
      await tester.tap(find.textContaining('Bento Elevated'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.cardLayout, equals(SubscriptionCardLayout.bentoElevated));

      // Tap Compact Minimalist
      await tester.tap(find.textContaining('Compact Minimalist'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.cardLayout, equals(SubscriptionCardLayout.compact));

      // Scroll to Upcoming Renewals section
      await tester.scrollUntilVisible(find.text('Upcoming renewals layout'), 300, scrollable: find.byType(Scrollable).first);
      await tester.scrollUntilVisible(find.textContaining('Urgent renewal spotlight'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.text('Upcoming renewals layout'), findsOneWidget);
      expect(find.textContaining('Horizontal swipeable carousel'), findsOneWidget);
      expect(find.textContaining('Urgent renewal spotlight'), findsOneWidget);

      // Select Spotlight Hero Card
      await tester.tap(find.textContaining('Urgent renewal spotlight'));
      await tester.pumpAndSettle();
      expect(OneUIEffectsController.instance.upcomingSectionStyle, equals(UpcomingSectionStyle.spotlight));
    });
  });

  group('OneUISubscriptionCard & OneUIUpcomingRenewalsSection Widgets', () {
    testWidgets('OneUISubscriptionCard renders Bento, Compact, and Fluent layouts smoothly', (WidgetTester tester) async {
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

      // Test Bento Elevated
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overrideLayout: SubscriptionCardLayout.bentoElevated,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Disney+'), findsOneWidget);
      expect(find.textContaining('13.99'), findsOneWidget);

      // Test Compact
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overrideLayout: SubscriptionCardLayout.compact,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Disney+'), findsOneWidget);

      // Test One UI Fluent
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUISubscriptionCard(
              subscription: sampleSub,
              overrideLayout: SubscriptionCardLayout.oneUiFluent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Disney+'), findsOneWidget);
    });

    testWidgets('OneUIUpcomingRenewalsSection supports Carousel and Spotlight styles', (WidgetTester tester) async {
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
          price: 49.00,
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.health,
          nextBillingDate: DateTime.now().add(const Duration(days: 6)),
          brandColor: const Color(0xFF00C853),
        ),
      ];

      // Test Carousel mode
      OneUIEffectsController.instance.upcomingSectionStyle = UpcomingSectionStyle.carousel;
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIUpcomingRenewalsSection(
              upcomingSubscriptions: sampleSubs,
              onTapSubscription: (_) => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming renewals'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);

      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      // Test Spotlight mode
      OneUIEffectsController.instance.upcomingSectionStyle = UpcomingSectionStyle.spotlight;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneUIUpcomingRenewalsSection(
              upcomingSubscriptions: sampleSubs,
              onTapSubscription: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Next upcoming renewal'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    });
  });
}
