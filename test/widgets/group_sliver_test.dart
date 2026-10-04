import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_card.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_group_sliver.dart';

/// OneUIGroupSliver must look exactly like OneUISection + OneUIGroupCard (it replaced
/// them on the Subscriptions tab to build long lists lazily).
void main() {
  List<OneUIGroupItem> items(int n) => [
        for (var i = 0; i < n; i++)
          OneUIGroupItem(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: 'Item $i',
            subtitle: 'Subtitle $i',
          ),
      ];

  Future<Uint8List> capture(WidgetTester tester, Widget sliver) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      theme: OneUITheme.darkTheme,
      home: Scaffold(
        backgroundColor: OneUITheme.surfacePitch,
        body: RepaintBoundary(
          key: key,
          child: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(16), sliver: sliver)]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data!.buffer.asUint8List();
    }))!;
  }

  for (final count in [1, 2, 5]) {
    testWidgets('renders the same pixels as the card with $count rows', (tester) async {
      final card = await capture(
        tester,
        SliverToBoxAdapter(child: OneUISection(title: 'Due this week', child: OneUIGroupCard(items: items(count)))),
      );
      final sliver = await capture(
        tester,
        OneUIGroupSliver(title: 'Due this week', itemCount: count, itemBuilder: (_, i) => items(count)[i]),
      );
      expect(sliver.length, card.length);
      expect(sliver, card);
    });
  }

  testWidgets('builds only the rows on screen', (tester) async {
    var built = 0;
    await tester.pumpWidget(MaterialApp(
      home: CustomScrollView(slivers: [
        OneUIGroupSliver(
          title: 'All',
          itemCount: 500,
          itemBuilder: (_, i) {
            built++;
            return OneUIGroupItem(title: 'Item $i');
          },
        ),
      ]),
    ));
    expect(built, lessThan(40));
    expect(find.text('Item 0'), findsOneWidget);
  });
}
