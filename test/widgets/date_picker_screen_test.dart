import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/date_picker_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_date_wheel.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Opens the picker from a button and returns a getter for the popped result.
  Future<DateTime? Function()> openPicker(
    WidgetTester tester, {
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    DateTime? result;
    await tester.pumpWidget(
      routedTestApp(
        theme: OneUITheme.darkTheme,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await DatePickerScreen.open(
                  context,
                  initialDate: initial,
                  firstDate: first,
                  lastDate: last,
                  title: 'Payment date',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Finder wheel(int index) => find.byType(ListWheelScrollView).at(index);

  testWidgets('opens as a subpage and saves the initial date unchanged', (tester) async {
    final result = await openPicker(
      tester,
      initial: DateTime(2025, 3, 15),
      first: DateTime(2018),
      last: DateTime(2025, 12, 31),
    );

    expect(find.text('Payment date'), findsOneWidget);
    expect(find.byType(OneUIDateWheel), findsOneWidget);
    expect(find.text('Saturday, March 15, 2025'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2025, 3, 15));
  });

  testWidgets('scrolling the day wheel changes the saved date', (tester) async {
    final result = await openPicker(
      tester,
      initial: DateTime(2025, 3, 15),
      first: DateTime(2018),
      last: DateTime(2025, 12, 31),
    );

    await tester.drag(wheel(1), const Offset(0, -96));
    await tester.pumpAndSettle();
    expect(find.text('Sunday, March 16, 2025'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2025, 3, 16));
  });

  testWidgets('changing to a shorter month clamps the day', (tester) async {
    final result = await openPicker(
      tester,
      initial: DateTime(2025, 3, 31),
      first: DateTime(2018),
      last: DateTime(2025, 12, 31),
    );

    // Month wheel back one row: March -> February (28 days in 2025).
    await tester.drag(wheel(0), const Offset(0, 96));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2025, 2, 28));
  });

  testWidgets('scrolling past the last allowed date springs back to it', (tester) async {
    final result = await openPicker(
      tester,
      initial: DateTime(2025, 6, 10),
      first: DateTime(2018),
      last: DateTime(2025, 6, 12),
    );

    // Day wheel forward five rows: Jun 15 is after the last allowed date (Jun 12).
    await tester.drag(wheel(1), const Offset(0, -96 * 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2025, 6, 12));
  });

  testWidgets('quick picks only offer dates in range and select exactly', (tester) async {
    final today = dateOnly(DateTime.now());
    final result = await openPicker(tester, initial: DateTime(2020, 1, 1), first: DateTime(2018), last: today);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);

    await tester.tap(find.text('Yesterday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(today.year, today.month, today.day - 1));
  });

  testWidgets('cancel returns null', (tester) async {
    final result = await openPicker(
      tester,
      initial: DateTime(2025, 3, 15),
      first: DateTime(2018),
      last: DateTime(2025, 12, 31),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result(), isNull);
  });

  test('days in month handles leap years', () {
    expect(OneUIDateWheelState.daysInMonth(2024, 2), 29);
    expect(OneUIDateWheelState.daysInMonth(2025, 2), 28);
    expect(OneUIDateWheelState.daysInMonth(2025, 12), 31);
  });
}
