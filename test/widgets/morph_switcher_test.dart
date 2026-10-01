import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/widgets/one_ui_morph_switcher.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  Widget box(String key, double width, {Key? innerKey}) =>
      SizedBox(key: ValueKey(key), width: width, height: 40, child: Text(key, key: innerKey));

  double opacityOf(WidgetTester tester, String text) {
    final opacity = tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first);
    return opacity.opacity;
  }

  testWidgets('fade-through: old content is gone before the new one is mostly in', (tester) async {
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('old', 200))));
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('new', 100))));
    await tester.pump(OneUIMorphSwitcher.exitDuration);

    expect(opacityOf(tester, 'old'), 0);
    expect(opacityOf(tester, 'new'), lessThan(0.3));

    await tester.pumpAndSettle();
    expect(find.text('old'), findsNothing);
    expect(opacityOf(tester, 'new'), 1);
  });

  testWidgets('a shrinking morph starts shrinking right away', (tester) async {
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('wide', 300))));
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('narrow', 100))));
    await tester.pump(const Duration(milliseconds: 60));

    final width = tester.getSize(find.byType(OneUIMorphSwitcher)).width;
    expect(width, lessThan(300));
    expect(width, greaterThan(100));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(OneUIMorphSwitcher)).width, 100);
  });

  testWidgets('switching back mid-morph revives the outgoing child (no duplicate GlobalKey)', (tester) async {
    final anchor = GlobalKey();
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('a', 200, innerKey: anchor))));
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('b', 100))));
    await tester.pump(const Duration(milliseconds: 40)); // 'a' still fading out
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: box('a', 200, innerKey: anchor))));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsNothing);
    expect(anchor.currentContext, isNotNull);
  });

  testWidgets('outgoing content keeps its size while it fades (no relayout errors)', (tester) async {
    Widget filling(String key) => SizedBox(
          key: ValueKey(key),
          width: key == 'row' ? 240 : 80,
          height: 40,
          child: Row(children: [Expanded(child: Text(key))]),
        );
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: filling('row'))));
    await tester.pumpWidget(host(OneUIMorphSwitcher(child: filling('small'))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('row')).width, 240);
    await tester.pumpAndSettle();
  });
}
