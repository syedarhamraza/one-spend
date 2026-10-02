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
      expect(CardBrand.skrill.isWallet, isTrue); // generic wallet glyph, no logo
      expect(CardBrand.visa.isWallet, isFalse);
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

    testWidgets('deprecates live card preview and color tint, rendering strictly functional form fields', (tester) async {
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

      // Nickname in form field
      expect(find.text('Business Salary'), findsOneWidget);
      expect(find.textContaining('4242'), findsWidgets);
      expect(find.text('12/28'), findsWidgets);

      // Verify live mockup and contactless icon are deprecated and removed
      expect(find.byIcon(Icons.contactless_rounded), findsNothing);
      expect(find.text('Card appearance'), findsNothing);
      expect(find.text('Card color tint'), findsNothing);

      // Verify no "cardholder name" label is rendered anywhere
      expect(find.textContaining('cardholder', findRichText: true), findsNothing);
      expect(find.textContaining('CARDHOLDER', findRichText: true), findsNothing);

      // Verify functional form sections
      expect(find.text('Card details'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);

      // Verify OneUISwitch is used for default toggle
      expect(find.byType(OneUISwitch), findsOneWidget);
    });

    testWidgets('deprecates Card color tint subpage completely', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Card color tint must not exist
      expect(find.text('Card color tint'), findsNothing);
      expect(find.text('Card appearance'), findsNothing);
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

    testWidgets('nickname subpage positions floating pill directly above keyboard', (tester) async {
      setMobileDimensions(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentMethodEditorScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Card nickname'));
      await tester.pumpAndSettle();

      // Simulate keyboard open with 300px height
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      // Device height is 2400. With 300px keyboard, keyboard top is at 2100.
      // Pill height is 52. Bottom should be at 2400 - 300 - 12 = 2088.
      final pillCenter = tester.getCenter(find.text('Apply'));
      expect(pillCenter.dy, greaterThan(2000));
      expect(pillCenter.dy, lessThan(2100));

      tester.view.resetViewInsets();
    });
  });
}
