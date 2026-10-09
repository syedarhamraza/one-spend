import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/theme/one_ui_scroll.dart';
import 'package:onespend/widgets/one_ui_collapsible_header.dart';

void main() {
  Future<ScrollPosition> pumpPage(WidgetTester tester, {int rows = 40}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      scrollBehavior: const OneUIScrollBehavior(),
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: const OneUICollapsibleHeaderDelegate(title: 'Spend', subtitle: 'Monthly'),
            ),
            SliverList.builder(
              itemCount: rows,
              itemBuilder: (context, i) => SizedBox(height: 60, child: Text('Row $i')),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return tester.state<ScrollableState>(find.byType(Scrollable)).position;
  }

  /// Drags by [dy] like a finger that stops before lifting (no fling).
  Future<void> slowDrag(WidgetTester tester, double dy) async {
    final gesture = await tester.startGesture(tester.getCenter(find.text('Row 2')));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(0, dy / 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 300)); // hold still
    await gesture.up();
    await tester.pumpAndSettle();
  }

  const collapse = 270.0 - 92.0;

  testWidgets('the app scrolls with One UI physics', (tester) async {
    final position = await pumpPage(tester);
    // Flutter may wrap it (e.g. in AlwaysScrollableScrollPhysics); look down the chain.
    var physics = position.physics as ScrollPhysics?;
    var found = false;
    while (physics != null) {
      if (physics is OneUIScrollPhysics) found = true;
      physics = physics.parent;
    }
    expect(found, isTrue);
  });

  testWidgets('a header let go less than halfway closed opens again', (tester) async {
    final position = await pumpPage(tester);
    await slowDrag(tester, -60);
    expect(position.pixels, 0);
  });

  testWidgets('a header let go more than halfway closed finishes closing', (tester) async {
    final position = await pumpPage(tester);
    await slowDrag(tester, -140);
    expect(position.pixels, closeTo(collapse, 0.5));
  });

  testWidgets('scrolled past the header, nothing snaps', (tester) async {
    final position = await pumpPage(tester);
    await slowDrag(tester, -400);
    expect(position.pixels, closeTo(400, 1));
  });

  testWidgets('the big title shrinks and rises as the page scrolls', (tester) async {
    await pumpPage(tester);
    final before = tester.getRect(find.text('Spend').first);
    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(40);
    await tester.pump();
    final after = tester.getRect(find.text('Spend').first);
    expect(after.height, lessThan(before.height));
    expect(after.top, lessThan(before.top));
  });
}
