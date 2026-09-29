import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/screens/time_picker_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_radio.dart';
import 'package:onespend/widgets/one_ui_time_wheel.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Opens the picker from a button and returns a getter for the popped result.
  Future<int? Function()> openPicker(WidgetTester tester, int initialMinutes) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    int? result;
    await tester.pumpWidget(
      routedTestApp(
        theme: OneUITheme.darkTheme,
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await TimePickerScreen.open(context, initialMinutes: initialMinutes, title: 'Reminder time');
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

  testWidgets('opens as a subpage showing the initial time and saves it unchanged', (tester) async {
    final result = await openPicker(tester, 20 * 60 + 30);

    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.byType(OneUITimeWheel), findsOneWidget);
    expect(find.text('Alerts are delivered at 8:30 PM'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), 20 * 60 + 30);
  });

  testWidgets('scrolling the minute wheel changes the saved time', (tester) async {
    final result = await openPicker(tester, 20 * 60 + 30);

    // Drag the minute wheel (second wheel) up by one row: 30 -> 31.
    await tester.drag(find.byType(ListWheelScrollView).at(1), const Offset(0, -96));
    await tester.pumpAndSettle();
    expect(find.text('Alerts are delivered at 8:31 PM'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), 20 * 60 + 31);
  });

  testWidgets('switching the period wheel to AM keeps the hour and minute', (tester) async {
    final result = await openPicker(tester, 20 * 60 + 30);

    await tester.drag(find.byType(ListWheelScrollView).at(2), const Offset(0, 96));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), 8 * 60 + 30);
  });

  testWidgets('quick picks set the exact time and mark their radio', (tester) async {
    final result = await openPicker(tester, 20 * 60 + 30);

    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();

    expect(find.text('Alerts are delivered at 9:00 AM'), findsOneWidget);
    final morningRadio = tester.widget<OneUIRadio>(
      find.descendant(of: find.ancestor(of: find.text('Morning'), matching: find.byType(Row)).first, matching: find.byType(OneUIRadio)),
    );
    expect(morningRadio.isSelected, isTrue);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result(), 9 * 60);
  });

  testWidgets('cancel returns null', (tester) async {
    final result = await openPicker(tester, 9 * 60);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result(), isNull);
  });

  test('12-hour conversion handles midnight and noon', () {
    expect(OneUITimeWheelState.toMinutes(hour12: 12, minute: 0, isPm: false), 0);
    expect(OneUITimeWheelState.toMinutes(hour12: 12, minute: 0, isPm: true), 12 * 60);
    expect(OneUITimeWheelState.toMinutes(hour12: 11, minute: 59, isPm: true), 23 * 60 + 59);
    expect(OneUITimeWheelState.toMinutes(hour12: 1, minute: 5, isPm: false), 65);
  });
}
