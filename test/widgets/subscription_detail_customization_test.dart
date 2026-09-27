import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings_screen.dart';
import 'package:onespend/screens/subscription_detail_customizer_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';

void main() {
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

      ctrl.detailShowItemIcons = false;
      ctrl.detailIconShape = DetailIconShape.circle;
      ctrl.detailHighlightSelectable = false;

      expect(ctrl.detailShowItemIcons, isFalse);
      expect(ctrl.detailIconShape, equals(DetailIconShape.circle));
      expect(ctrl.detailHighlightSelectable, isFalse);

      ctrl.resetDetailStyle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailHighlightSelectable, isTrue);
    });

    test('resetCardStyle also resets detail styling', () {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailShowItemIcons = false;
      ctrl.detailIconShape = DetailIconShape.circle;
      ctrl.detailHighlightSelectable = false;

      ctrl.resetCardStyle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
      expect(ctrl.detailHighlightSelectable, isTrue);
    });
  });

  group('SubscriptionDetailScreen Customization', () {
    final testSub = Subscription(
      id: 'test_netflix',
      name: 'Netflix',
      description: 'Movies & TV shows',
      price: 15.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime(2026, 9, 30),
      brandPresetId: 'netflix',
      brandColorValue: const Color(0xFFE50914).toARGB32(),
    );

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

    testWidgets('detailHighlightSelectable highlights selectable items in blue or restores fallback', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;
      ctrl.detailHighlightSelectable = true;

      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionDetailScreen(subscription: testSub),
        ),
      );
      await tester.pumpAndSettle();

      // With highlightSelectable = true, Next renewal date and Billing cycle are accentBlue
      final groupTiles = tester.widgetList<OneUIGroupItemTile>(find.byType(OneUIGroupItemTile));
      final renewalTile = groupTiles.firstWhere((t) => t.item.title == 'Next renewal date');
      final billingTile = groupTiles.firstWhere((t) => t.item.title == 'Billing cycle');
      final categoryTile = groupTiles.firstWhere((t) => t.item.title == 'Category');
      final serviceTile = groupTiles.firstWhere((t) => t.item.title == 'Service name');

      expect(renewalTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(billingTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      expect(categoryTile.item.subtitleColor, equals(OneUITheme.accentBlue));
      // Non-selectable item remains textPrimary
      expect(serviceTile.item.subtitleColor, equals(OneUITheme.textPrimary));

      // With highlightSelectable = false, selectable subtitles fall back to standard text colors
      ctrl.detailHighlightSelectable = false;
      await tester.pumpAndSettle();

      final updatedTiles = tester.widgetList<OneUIGroupItemTile>(find.byType(OneUIGroupItemTile));
      final updatedRenewalTile = updatedTiles.firstWhere((t) => t.item.title == 'Next renewal date');
      final updatedBillingTile = updatedTiles.firstWhere((t) => t.item.title == 'Billing cycle');
      final updatedCategoryTile = updatedTiles.firstWhere((t) => t.item.title == 'Category');

      expect(updatedRenewalTile.item.subtitleColor, equals(OneUITheme.textSecondary));
      expect(updatedBillingTile.item.subtitleColor, equals(OneUITheme.textSecondary));
      expect(updatedCategoryTile.item.subtitleColor, equals(OneUITheme.textPrimary));
    });
  });

  group('SubscriptionDetailCustomizerScreen & Settings Integration', () {
    testWidgets('Settings screen contains Detail screen styling and navigates to customizer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down in CustomScrollView to reveal Appearance section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
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
    });

    testWidgets('SubscriptionDetailCustomizerScreen toggles live preview and controller state', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(ctrl.detailShowItemIcons, isTrue);

      // Scroll down to see Setting items section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

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

      // Scroll further and tap Reset to defaults
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      final resetFinder = find.text('Reset to defaults');
      expect(resetFinder, findsOneWidget);
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(ctrl.detailShowItemIcons, isTrue);
      expect(ctrl.detailHighlightSelectable, isTrue);
      expect(ctrl.detailIconShape, equals(DetailIconShape.squircle));
    });

    testWidgets('Icon shape subpage allows switching to Circle and back', (WidgetTester tester) async {
      final ctrl = OneUIEffectsController.instance;

      await tester.pumpWidget(
        const MaterialApp(
          home: SubscriptionDetailCustomizerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Icon shape"
      final iconShapeFinder = find.text('Icon shape');
      await tester.scrollUntilVisible(iconShapeFinder, 150);
      await tester.tap(iconShapeFinder);
      await tester.pumpAndSettle();

      // Select Circle
      final circleFinder = find.text('Circle');
      await tester.scrollUntilVisible(circleFinder, 150);
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
