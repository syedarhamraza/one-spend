import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/widgets/one_ui_toast.dart';

void main() {
  tearDown(() {
    OneUIToast.debugSdkInt = null;
    OneUIToast.dismiss();
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    return ctx;
  }

  testWidgets('shows a text-only capsule that times out', (tester) async {
    final ctx = await pumpHost(tester);
    OneUIToast.show(ctx, 'Backup saved');
    await tester.pump();
    expect(find.text('Backup saved'), findsOneWidget);
    expect(find.byType(Image), findsNothing); // no app icon

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Backup saved'), findsNothing);
  });

  testWidgets('a new toast replaces the one on screen', (tester) async {
    final ctx = await pumpHost(tester);
    OneUIToast.show(ctx, 'First');
    await tester.pump();
    OneUIToast.show(ctx, 'Second');
    await tester.pump();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('copied() is skipped on Android 13+, where the system confirms copies', (tester) async {
    final ctx = await pumpHost(tester);

    OneUIToast.debugSdkInt = 33;
    OneUIToast.copied(ctx, 'CSV copied');
    await tester.pump();
    expect(find.text('CSV copied'), findsNothing);

    OneUIToast.debugSdkInt = 31;
    OneUIToast.copied(ctx, 'CSV copied');
    await tester.pump();
    expect(find.text('CSV copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
