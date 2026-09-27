import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/payment_method_editor_screen.dart';
import 'package:onespend/widgets/one_ui_switch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardBrand Enum & Entity Tests', () {
    test('contains exactly 12 supported card brands including Skrill', () {
      expect(CardBrand.values.length, equals(12));
      expect(CardBrand.values, contains(CardBrand.skrill));
      expect(CardBrand.skrill.label, equals('Skrill'));
      expect(CardBrand.skrill.assetPath, equals('assets/logos/payments/skrill.svg'));
      expect(CardBrand.skrill.defaultColorValue, equals(0xFF811963));
    });

    test('has removed obsolete payment brands', () {
      final brandNames = CardBrand.values.map((b) => b.name).toList();
      expect(brandNames.contains('amex'), isFalse);
      expect(brandNames.contains('discover'), isFalse);
      expect(brandNames.contains('diners'), isFalse);
      expect(brandNames.contains('klarna'), isFalse);
      expect(brandNames.contains('amazonPay'), isFalse);
      expect(brandNames.contains('bank'), isFalse);
      expect(brandNames.contains('other'), isFalse);
    });

    test('CardBrand.fromString safely falls back to visa for removed brands', () {
      expect(CardBrand.fromString('amex'), equals(CardBrand.visa));
      expect(CardBrand.fromString('discover'), equals(CardBrand.visa));
      expect(CardBrand.fromString('skrill'), equals(CardBrand.skrill));
      expect(CardBrand.fromString('unknown_value'), equals(CardBrand.visa));
    });

    test('subtitleDisplay correctly formats Skrill as digital wallet', () {
      const skrillMethod = PaymentMethod(
        id: 'skrill_1',
        nickname: 'My Skrill',
        brand: CardBrand.skrill,
        type: PaymentMethodType.digitalWallet,
      );
      expect(skrillMethod.subtitleDisplay, equals('Skrill • Digital Wallet'));
    });
  });

  group('PaymentMethodEditorScreen Widget Tests', () {
    void setMobileDimensions(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('renders flat realistic card mockup without cardholder name label', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(
            initialMethod: PaymentMethod(
              id: 'test_card',
              nickname: 'Business Salary',
              brand: CardBrand.visa,
              last4: '4242',
              expiryDate: '12/28',
              isDefault: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Flat realistic mockup assertions (nickname in card & list item)
      expect(find.text('Business Salary'), findsNWidgets(2));
      expect(find.textContaining('4242'), findsWidgets);
      expect(find.text('12/28'), findsWidgets);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.byIcon(Icons.contactless_rounded), findsOneWidget);

      // Verify no "cardholder name" label is rendered anywhere
      expect(find.textContaining('cardholder', findRichText: true), findsNothing);
      expect(find.textContaining('CARDHOLDER', findRichText: true), findsNothing);

      // Verify One UI sections
      expect(find.text('Card appearance'), findsOneWidget);
      expect(find.text('Card details'), findsOneWidget);
      expect(find.text('Billing & preferences'), findsOneWidget);

      // Verify OneUISwitch is used for default toggle
      expect(find.byType(OneUISwitch), findsOneWidget);
    });

    testWidgets('navigates to Card color tint subpage and displays hex swatches', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Card color tint
      await tester.tap(find.text('Card color tint'));
      await tester.pumpAndSettle();

      // Should be in subpage with 'Select color' section and hex codes
      expect(find.text('Select color'), findsOneWidget);
      expect(find.text('#1E2638'), findsOneWidget);
      expect(find.text('#1428A0'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Tapping apply pops back to editor screen
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Card appearance'), findsOneWidget);
    });

    testWidgets('navigates to Card network subpage and displays 12 brands including Skrill', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Card network
      await tester.tap(find.text('Card network / Provider'));
      await tester.pumpAndSettle();

      // Verify subpage
      expect(find.text('Supported networks & wallets'), findsOneWidget);
      expect(find.text('Skrill'), findsOneWidget);
      expect(find.text('Samsung Pay'), findsOneWidget);
      expect(find.text('Alipay'), findsOneWidget);
      expect(find.text('WeChat Pay'), findsOneWidget);

      // Select Skrill
      await tester.tap(find.text('Skrill'));
      await tester.pumpAndSettle();

      // Tap apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify Skrill is now selected on main screen
      expect(find.text('Skrill'), findsWidgets);
    });

    testWidgets('navigates to Nickname subpage with suggestion chips and updates live', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Card nickname'));
      await tester.pumpAndSettle();

      expect(find.text('Nickname / Alias'), findsOneWidget);
      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);

      // Tap 'Salary' chip
      await tester.tap(find.text('Salary'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Salary'), findsWidgets);
    });

    testWidgets('navigates to Payment method type subpage and selects type', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payment method type'));
      await tester.pumpAndSettle();

      expect(find.text('Select type'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Debit Card'), findsOneWidget);
      expect(find.text('Digital Wallet'), findsOneWidget);

      await tester.tap(find.text('Debit Card'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Debit Card'), findsWidgets);
    });
  });
}
