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
          physics: OneUIScrollPhysics.bigHeader,
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

  testWidgets('a fling that would stop halfway carries on to closed without pausing', (tester) async {
    final position = await pumpPage(tester);
    // A short flick: on its own it would come to rest inside the header's range.
    await tester.fling(find.text('Row 2'), const Offset(0, -60), 400);
    final seen = <double>[];
    for (var i = 0; i < 120 && (seen.isEmpty || (seen.last - collapse).abs() > 0.5); i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(position.pixels);
    }
    expect(seen.last, closeTo(collapse, 0.5));
    // Every frame moves on towards the end: no stop-then-snap.
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThan(seen[i - 1]), reason: 'frame $i stalled at ${seen[i]}');
    }
  });

  testWidgets('a swipe back up from the list stops at the small top bar', (tester) async {
    final position = await pumpPage(tester);
    position.jumpTo(900);
    await tester.pump();
    await tester.fling(find.text('Row 16'), const Offset(0, 600), 3000);
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(collapse, 0.5));

    // From there, a pull from the top (a drag, not a fling) opens the big header.
    await slowDrag(tester, 300);
    expect(position.pixels, 0);
  });

  testWidgets('inside the header, a flick goes the way it was flicked', (tester) async {
    final position = await pumpPage(tester);
    position.jumpTo(140); // nearer to closed
    await tester.pump();
    await tester.fling(find.text('Row 2'), const Offset(0, 50), 600); // a short flick towards open
    await tester.pumpAndSettle();
    expect(position.pixels, 0);
  });

  testWidgets('the default physics has no snap (pages without a big header)', (tester) async {
    expect(const OneUIScrollPhysics().headerSnap, isNull);
    expect(OneUIScrollPhysics.bigHeader.headerSnap, collapse);
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

  testWidgets("big-header pages don't stretch at the top, only at the bottom", (tester) async {
    final shown = <bool, bool>{}; // leading edge? -> stretch allowed?
    await tester.pumpWidget(MaterialApp(
      scrollBehavior: const OneUIScrollBehavior(),
      home: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (n) {
          shown[n.leading] = n.accepted;
          return false;
        },
        child: OneUINoTopStretch(
          child: ListView(children: [for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text('Row $i'))]),
        ),
      ),
    ));
    await tester.drag(find.text('Row 1'), const Offset(0, 200)); // pull down at the top
    await tester.pumpAndSettle();
    expect(shown[true], isFalse);

    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.drag(find.text('Row 28'), const Offset(0, -200)); // push up at the bottom
    await tester.pumpAndSettle();
    expect(shown[false], isTrue);
  });
}
