import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_nav_bar.dart';
import 'package:onespend/widgets/one_ui_glass_surface.dart';

void main() {
  tearDown(() => OneUIEffectsController.instance.floating3dEffect = false);

  Widget host(Widget child) => MaterialApp(
        theme: OneUITheme.darkTheme,
        home: Scaffold(body: Center(child: child)),
      );

  Finder rimPainters() => find.byWidgetPredicate((w) => w is CustomPaint && w.foregroundPainter is OneUIRimPainter);

  group('OneUIGlassSurface', () {
    testWidgets('flat: no rim light, no gradient, no outline', (tester) async {
      OneUIEffectsController.instance.floating3dEffect = false;
      await tester.pumpWidget(host(const OneUIGlassSurface(height: 44, child: Text('x'))));
      await tester.pumpAndSettle();

      expect(rimPainters(), findsNothing);
      final body = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final deco = body.decoration! as BoxDecoration;
      expect(deco.gradient, isNull);
      expect(deco.border, isNull);
      expect(deco.color, isNotNull);
    });

    testWidgets('flat modal casts no shadow', (tester) async {
      OneUIEffectsController.instance.floating3dEffect = false;
      await tester.pumpWidget(host(const OneUIGlassSurface(elevation: OneUIGlassElevation.modal, child: Text('x'))));
      await tester.pumpAndSettle();

      final shadowBox = tester.widget<DecoratedBox>(
        find.ancestor(of: find.byType(ClipRRect), matching: find.byType(DecoratedBox)).first,
      );
      expect((shadowBox.decoration as BoxDecoration).boxShadow, isEmpty);
    });

    testWidgets('3D: gradient body with a top-lit rim light', (tester) async {
      OneUIEffectsController.instance.floating3dEffect = true;
      await tester.pumpWidget(host(const OneUIGlassSurface(height: 44, child: Text('x'))));
      await tester.pumpAndSettle();

      expect(rimPainters(), findsOneWidget);
      final deco = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration! as BoxDecoration;
      expect(deco.gradient, isNotNull);
    });

    testWidgets('progress 0 renders only the child: no blur, clip or shadow', (tester) async {
      OneUIEffectsController.instance.floating3dEffect = true;
      await tester.pumpWidget(host(const OneUIGlassSurface(progress: 0, child: Text('x'))));
      await tester.pumpAndSettle();

      expect(find.text('x'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(rimPainters(), findsNothing);
    });
  });

  group('OneUIFloatingNavBar', () {
    const items = [
      OneUINavItem(activeIcon: Icons.home, inactiveIcon: Icons.home_outlined, label: 'One'),
      OneUINavItem(activeIcon: Icons.event, inactiveIcon: Icons.event_outlined, label: 'Two'),
      OneUINavItem(activeIcon: Icons.pie_chart, inactiveIcon: Icons.pie_chart_outline, label: 'Three'),
      OneUINavItem(activeIcon: Icons.menu, inactiveIcon: Icons.menu, label: 'Menu'),
    ];

    Widget bar(int index) => host(OneUIFloatingNavBar(currentIndex: index, onTap: (_) {}, items: items));

    testWidgets('active capsule is wider than its slot and centred on the selected tab', (tester) async {
      await tester.pumpWidget(bar(1));
      await tester.pumpAndSettle();

      final pill = tester.getRect(find.byType(AnimatedPositioned));
      final slot = tester.getRect(find.text('Two'));
      expect(pill.width, OneUIFloatingNavBar.itemWidth + OneUIFloatingNavBar.pillOverhang * 2);
      expect(pill.center.dx, moreOrLessEquals(slot.center.dx, epsilon: 0.5));
    });

    testWidgets('capsule slides to the newly selected tab', (tester) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();
      final start = tester.getRect(find.byType(AnimatedPositioned)).center.dx;

      await tester.pumpWidget(bar(3));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getRect(find.byType(AnimatedPositioned)).center.dx;
      await tester.pumpAndSettle();
      final end = tester.getRect(find.byType(AnimatedPositioned)).center.dx;

      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
      expect(end, moreOrLessEquals(tester.getRect(find.text('Menu')).center.dx, epsilon: 0.5));
    });

    testWidgets('end capsules are inset by the same gap as top and bottom', (tester) async {
      for (final i in [0, 3]) {
        await tester.pumpWidget(bar(i));
        await tester.pumpAndSettle();
        final pill = tester.getRect(find.byType(AnimatedPositioned));
        final barRect = tester.getRect(find.byType(OneUIGlassSurface));
        final vertical = pill.top - barRect.top;
        expect(barRect.bottom - pill.bottom, moreOrLessEquals(vertical, epsilon: 0.01));
        final endGap = i == 0 ? pill.left - barRect.left : barRect.right - pill.right;
        expect(endGap, moreOrLessEquals(vertical, epsilon: 0.01));
      }
    });

    testWidgets('tab icon and label are vertically centred in the capsule', (tester) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();
      final pill = tester.getRect(find.byType(AnimatedPositioned));
      final top = tester.getRect(find.byIcon(Icons.home)).top;
      final bottom = tester.getRect(find.text('One')).bottom;
      expect((top + bottom) / 2, moreOrLessEquals(pill.center.dy, epsilon: 1.0));
    });
  });
}
