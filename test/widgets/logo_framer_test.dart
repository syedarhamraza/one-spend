import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/features/subscriptions/domain/entities/logo_transform.dart';
import 'package:onespend/widgets/one_ui_brand_icon.dart';
import 'package:onespend/widgets/one_ui_logo_framer.dart';

void main() {
  Future<ValueNotifier<LogoTransform>> pumpFramer(WidgetTester tester, [LogoTransform start = LogoTransform.identity]) async {
    final value = ValueNotifier(start);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder<LogoTransform>(
            valueListenable: value,
            builder: (context, t, _) => OneUILogoFramer(
              url: 'https://example.com/logo.png',
              name: 'Test',
              background: Colors.white,
              value: t,
              onChanged: (n) => value.value = n,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return value;
  }

  testWidgets('dragging moves the image by a fraction of the icon size', (tester) async {
    final value = await pumpFramer(tester);
    await tester.drag(find.byType(OneUIBrandIcon), const Offset(50, -20));
    await tester.pumpAndSettle();
    expect(value.value.dx, greaterThan(0.1));
    expect(value.value.dy, lessThan(0));
    expect(value.value.scale, 1.0);
  });

  testWidgets('double-tap and Reset return to the original framing', (tester) async {
    final value = await pumpFramer(tester, const LogoTransform(scale: 2, dx: 0.2, dy: 0.1));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(value.value.isIdentity, isTrue);

    value.value = const LogoTransform(scale: 1.5);
    await tester.pump();
    await tester.tap(find.byType(OneUIBrandIcon));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(OneUIBrandIcon));
    await tester.pumpAndSettle();
    expect(value.value.isIdentity, isTrue);
  });

  testWidgets('the slider zooms within limits', (tester) async {
    final value = await pumpFramer(tester);
    await tester.drag(find.byType(Slider), const Offset(1000, 0));
    await tester.pumpAndSettle();
    expect(value.value.scale, LogoTransform.maxScale);
  });

  testWidgets('the brand icon applies the framing to a custom logo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: OneUIBrandIcon(
          name: 'X',
          logoUrl: 'https://example.com/logo.png',
          logoTransform: LogoTransform(scale: 2, dx: 0.1),
          size: 100,
        ),
      ),
    ));
    final scale = tester.widget<Transform>(
      find.descendant(of: find.byType(OneUIBrandIcon), matching: find.byType(Transform)).last,
    );
    expect(scale.transform.getMaxScaleOnAxis(), closeTo(2, 0.001));
  });
}
