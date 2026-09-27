import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings_screen.dart';
import 'package:onespend/screens/subscription_detail_customizer_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:flutter/services.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_payment_brand_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    OneUIEffectsController.instance.resetDetailStyle();
  });

  group('OneUIEffectsController Detail Screen Settings', () {
    test('Defaults and reset functionality', () {
      final ctrl = OneUIEffectsController.instance;
      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailHighlightSelectable, isTrue);
      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.cardBrand));
      expect(ctrl.detailShowInlineCardBrand, isTrue);

      ctrl.detailShowItemIcons = false;
      ctrl.detailIconShape = DetailIconShape.circle;
      ctrl.detailHighlightSelectable = false;
      ctrl.detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
      ctrl.detailShowInlineCardBrand = false;

      expect(ctrl.detailShowItemIcons, isFalse);
      expect(ctrl.detailIconShape, equals(DetailIconShape.circle));
      expect(ctrl.detailHighlightSelectable, isFalse);
      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.iconBadge));
      expect(ctrl.detailShowInlineCardBrand, isFalse);

      ctrl.resetDetailStyle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailHighlightSelectable, isTrue);
      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.cardBrand));
      expect(ctrl.detailShowInlineCardBrand, isTrue);
    });

    test('resetCardStyle also resets detail styling', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = false;
      ctrl.detailIconShape = DetailIconShape.circle;
      ctrl.detailHighlightSelectable = false;
      ctrl.detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
      ctrl.detailShowInlineCardBrand = false;

      ctrl.resetCardStyle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailHighlightSelectable, isTrue);
      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.cardBrand));
      expect(ctrl.detailShowInlineCardBrand, isTrue);
    });
  });

  group('SubscriptionDetailScreen Customization', () {
    final testSub = Subscription(
      id: 'test_netflix',
      name: 'Netflix',
      description: 'Movies & TV shows',
      notes: 'Family 4K plan',
      price: 15.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime(2026, 9, 30),
      paymentMethodId: 'card_visa',
      brandPresetId: 'netflix',
      brandColorValue: const Color(0xFFE50914).toARGB32(),
    );

    setUp(() {
      final card = const PaymentMethod(
        id: 'card_visa',
        nickname: 'Personal Chase',
        last4: '4242',
        brand: CardBrand.visa,
        expiryDate: '12/28',
      );
      SubscriptionStore.instance.addPaymentMethod(card);
    });

    testWidgets('Toggling detailShowItemIcons hides and shows icons after hero card', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = true;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // Setting row icons should exist
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);

      // Now toggle icons off
      ctrl.detailShowItemIcons = false;
      await tester.pumpAndSettle();

      // Setting row icons should no longer be present
      expect(find.byIcon(Icons.badge_outlined), findsNothing);
      expect(find.byIcon(Icons.repeat_rounded), findsNothing);

      // Verify that OneUIGroupItem has null leading when hidden
      final groupTiles = tester.widgetList<OneUIGroupItemTile>(find.byType(OneUIGroupItemTile));
      expect(groupTiles.any((tile) => tile.item.title == 'Service name' && tile.item.leading == null), isTrue);
      expect(groupTiles.any((tile) => tile.item.title == 'Billing cycle' && tile.item.leading == null), isTrue);
    });

    testWidgets('detailIconShape applies squircle and circle shapes to item icons', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = true;
      ctrl.detailIconShape = DetailIconShape.squircle;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // Find icon container for Service name (Icons.badge_outlined)
      final badgeIconFinder = find.byIcon(Icons.badge_outlined);
      expect(badgeIconFinder, findsOneWidget);

      final squircleContainer = tester.widget<Container>(
        find.ancestor(of: badgeIconFinder, matching: find.byType(Container)).first,
      );
      final squircleDecoration = squircleContainer.decoration as BoxDecoration;
      expect(squircleDecoration.shape, equals(BoxShape.rectangle));
      expect(squircleDecoration.borderRadius, equals(BorderRadius.circular(12)));

      // Switch to circle shape
      ctrl.detailIconShape = DetailIconShape.circle;
      await tester.pumpAndSettle();

      final circleContainer = tester.widget<Container>(
        find.ancestor(of: badgeIconFinder, matching: find.byType(Container)).first,
      );
      final circleDecoration = circleContainer.decoration as BoxDecoration;
      expect(circleDecoration.shape, equals(BoxShape.circle));
      expect(circleDecoration.borderRadius, isNull);
    });

    testWidgets('Payment card logo is NOT deformed into circle when detailIconShape is circle in cardBrand mode', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = true;
      ctrl.detailIconShape = DetailIconShape.circle;
      ctrl.detailPaymentIconStyle = DetailPaymentIconStyle.cardBrand;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // In cardBrand mode, OneUIPaymentBrandIcon is used with width 36, height 26 (undeformed 3:2 ratio)
      final brandIcons = tester.widgetList<OneUIPaymentBrandIcon>(find.byType(OneUIPaymentBrandIcon));
      expect(brandIcons.any((icon) => icon.width == 36 && icon.height == 26), isTrue);
    });

    testWidgets('Switching to iconBadge uses Icons.payment_rounded and respects detailIconShape', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = true;
      ctrl.detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
      ctrl.detailIconShape = DetailIconShape.circle;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // Now Icons.payment_rounded is used for leading
      final paymentIconFinder = find.byIcon(Icons.payment_rounded);
      expect(paymentIconFinder, findsOneWidget);

      final iconContainer = tester.widget<Container>(
        find.ancestor(of: paymentIconFinder, matching: find.byType(Container)).first,
      );
      final decoration = iconContainer.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
    });

    testWidgets('Inline card brand appears beside subtitle when in iconBadge mode with detailShowInlineCardBrand = true', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
      ctrl.detailShowInlineCardBrand = true;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // Should find an inline OneUIPaymentBrandIcon with width 22, height 14.5
      final brandIcons = tester.widgetList<OneUIPaymentBrandIcon>(find.byType(OneUIPaymentBrandIcon));
      expect(brandIcons.any((icon) => icon.width == 22 && icon.height == 14.5), isTrue);

      // Disable inline card brand
      ctrl.detailShowInlineCardBrand = false;
      await tester.pumpAndSettle();

      final updatedBrandIcons = tester.widgetList<OneUIPaymentBrandIcon>(find.byType(OneUIPaymentBrandIcon));
      expect(updatedBrandIcons.any((icon) => icon.width == 22 && icon.height == 14.5), isFalse);
    });

    testWidgets('detailHighlightSelectable highlights selectable items in blue or restores fallback', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailHighlightSelectable = true;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // With highlightSelectable = true, Next renewal date, Billing cycle, Category, Service name, Price, and Notes are accentBlue
      final groupTiles = tester.widgetList<OneUIGroupItemTile>(find.byType(OneUIGroupItemTile));
      final renewalTile = groupTiles.firstWhere((t) => t.item.title == 'Next renewal date');
      final billingTile = groupTiles.firstWhere((t) => t.item.title == 'Billing cycle');
      final categoryTile = groupTiles.firstWhere((t) => t.item.title == 'Category');
      final serviceTile = groupTiles.firstWhere((t) => t.item.title == 'Service name');
      final priceTile = groupTiles.firstWhere((t) => t.item.title == 'Price / Cost');
      final notesTile = groupTiles.firstWhere((t) => t.item.title == 'Plan notes');

      expect(renewalTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(billingTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(categoryTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(serviceTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(priceTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(notesTile.item.subtitleColor, equals(OneUITheme.accentBlue));

      // With highlightSelectable = false, subtitles fall back to standard text colors
      ctrl.detailHighlightSelectable = false;
      await tester.pumpAndSettle();

      final updatedTiles = tester.widgetList<OneUIGroupItemTile>(find.byType(OneUIGroupItemTile));
      final updatedRenewalTile = updatedTiles.firstWhere((t) => t.item.title == 'Next renewal date');
      final updatedBillingTile = updatedTiles.firstWhere((t) => t.item.title == 'Billing cycle');
      final updatedCategoryTile = updatedTiles.firstWhere((t) => t.item.title == 'Category');
      final updatedServiceTile = updatedTiles.firstWhere((t) => t.item.title == 'Service name');
      final updatedPriceTile = updatedTiles.firstWhere((t) => t.item.title == 'Price / Cost');
      final updatedNotesTile = updatedTiles.firstWhere((t) => t.item.title == 'Plan notes');

      expect(updatedRenewalTile.item.subtitleColor, equals(OneUITheme.textSecondary));
      expect(updatedBillingTile.item.subtitleColor, equals(OneUITheme.textSecondary));
      expect(updatedCategoryTile.item.subtitleColor, equals(OneUITheme.textPrimary));
      expect(updatedServiceTile.item.subtitleColor, equals(OneUITheme.textPrimary));
      expect(updatedPriceTile.item.subtitleColor, equals(OneUITheme.accentGreen));
      expect(updatedNotesTile.item.subtitleColor, equals(OneUITheme.textSecondary));
    });
  });

  group('SubscriptionDetailCustomizerScreen & Settings Integration', () {
    testWidgets('Settings screen contains Detail screen styling and navigates to customizer', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final detailItemFinder = find.text('Detail screen styling');
      expect(detailItemFinder, findsOneWidget);

      await tester.tap(detailItemFinder);
      await tester.pumpAndSettle();

      // Should have navigated to SubscriptionDetailCustomizerScreen
      expect(find.byType(SubscriptionDetailCustomizerScreen), findsOneWidget);
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Show setting icons'), findsOneWidget);
      expect(find.text('Blue selectable descriptions'), findsOneWidget);
      expect(find.text('Payment method icon'), findsOneWidget);
    });

    testWidgets('Live preview displays strictly 3 rows: Service name, Price / Cost, Payment method', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Row 1, 2, 3 should exist in Live Preview
      expect(find.text('Netflix Premium'), findsOneWidget);
      expect(find.text('\$15.99 / Monthly'), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);

      // Other rows should NOT be in the Live Preview
      expect(find.text('Sep 30, 2026'), findsNothing);
      expect(find.text('Entertainment'), findsNothing);
      expect(find.text('4K Ultra HD • Family Plan'), findsNothing);
    });

    testWidgets('SubscriptionDetailCustomizerScreen toggles live preview and controller state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctrl = OneUIEffectsController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(ctrl.detailShowItemIcons, isTrue);

      // Tap "Show setting icons"
      final showIconsFinder = find.text('Show setting icons');
      expect(showIconsFinder, findsOneWidget);
      await tester.tap(showIconsFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailShowItemIcons, isFalse);

      // Tap "Blue selectable descriptions" to toggle
      expect(ctrl.detailHighlightSelectable, isTrue);
      final blueDescFinder = find.text('Blue selectable descriptions');
      expect(blueDescFinder, findsOneWidget);
      await tester.tap(blueDescFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailHighlightSelectable, isFalse);

      // Tap Reset to defaults
      final resetFinder = find.text('Reset to defaults');
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailHighlightSelectable, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.cardBrand));
      expect(ctrl.detailShowInlineCardBrand, isTrue);
    });

    testWidgets('Payment method icon subpage allows switching to Setting icon badge and toggling inline logo', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctrl = OneUIEffectsController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Payment method icon"
      final paymentIconFinder = find.text('Payment method icon');
      expect(paymentIconFinder, findsOneWidget);
      await tester.tap(paymentIconFinder);
      await tester.pumpAndSettle();

      // Select Setting icon badge
      final badgeOptionFinder = find.text('Setting icon badge');
      expect(badgeOptionFinder, findsOneWidget);
      await tester.tap(badgeOptionFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailPaymentIconStyle, equals(DetailPaymentIconStyle.iconBadge));

      // Inline card brand option appears
      final inlineToggleFinder = find.text('Card logo beside description');
      expect(inlineToggleFinder, findsOneWidget);

      await tester.tap(inlineToggleFinder);
      await tester.pumpAndSettle();
      expect(ctrl.detailShowInlineCardBrand, isFalse);

      // Pop back using the back button in header
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Customizer screen now shows 'Setting icon badge' and the inline toggle
      expect(find.text('Setting icon badge'), findsOneWidget);
      expect(find.text('Card logo beside description'), findsOneWidget);
    });

    testWidgets('Icon shape subpage allows switching to Circle and back with 3-row preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ctrl = OneUIEffectsController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Icon shape"
      final iconShapeFinder = find.text('Icon shape');
      expect(iconShapeFinder, findsOneWidget);
      await tester.tap(iconShapeFinder);
      await tester.pumpAndSettle();

      // Preview in subpage also has 3 rows
      expect(find.text('Netflix Premium'), findsOneWidget);
      expect(find.text('\$15.99 / Monthly'), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);

      // Select Circle
      final circleFinder = find.text('Circle');
      expect(circleFinder, findsOneWidget);
      await tester.tap(circleFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailIconShape, equals(DetailIconShape.circle));

      // Pop back using the back button in header
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Circle'), findsOneWidget);
    });
  });
}
