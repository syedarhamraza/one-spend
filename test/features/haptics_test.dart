import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/core/haptics/haptics.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/vibration_settings_screen.dart';
import 'package:onespend/widgets/one_ui_switch.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<HapticKind> played;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    SubscriptionStore.instance.resetForTesting();
    Haptics.resetForTesting();
    played = [];
    Haptics.debugSink = played.add;
  });

  tearDown(Haptics.resetForTesting);

  group('Haptics', () {
    test('one touch plays once, at the strongest strength asked for', () async {
      // A shared widget, the screen and an open() helper all asking at once.
      Haptics.tap();
      Haptics.select();
      Haptics.confirm();
      Haptics.tap();
      await Future<void>.delayed(Duration.zero);
      expect(played, [HapticKind.confirm]);
    });

    test('a second touch straight after the first is dropped', () async {
      Haptics.tap();
      await Future<void>.delayed(Duration.zero);
      Haptics.tap();
      await Future<void>.delayed(Duration.zero);
      expect(played, [HapticKind.tap]);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      Haptics.warn();
      await Future<void>.delayed(Duration.zero);
      expect(played, [HapticKind.tap, HapticKind.warn]);
    });

    test('off means silent, and the choice is saved', () async {
      await Haptics.setEnabled(false);
      Haptics.tap();
      Haptics.longPress();
      await Future<void>.delayed(Duration.zero);
      expect(played, isEmpty);

      Haptics.enabled.value = true;
      await Haptics.load(sl<SettingsRepository>());
      expect(Haptics.enabled.value, isFalse);
    });
  });

  group('Settings › Vibration', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(routedTestApp(const VibrationSettingsScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('both switches start on and turn off', (tester) async {
      await pump(tester);
      final switches = find.byType(OneUISwitch);
      expect(switches, findsNWidgets(2));
      expect(tester.widgetList<OneUISwitch>(switches).map((s) => s.value), [true, true]);

      await tester.tap(find.text('Haptic feedback'));
      await tester.pumpAndSettle();
      expect(Haptics.enabled.value, isFalse);

      await tester.tap(find.text('Vibrate for notifications'));
      await tester.pumpAndSettle();
      expect(SubscriptionStore.instance.notificationVibration, isFalse);
      expect(tester.widgetList<OneUISwitch>(switches).map((s) => s.value), [false, false]);

      // Switching haptics back on plays a sample.
      played.clear();
      // Past the gap that drops a second touch (real time; pumps don't move it).
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.tap(find.text('Haptic feedback'));
      await tester.pumpAndSettle();
      expect(Haptics.enabled.value, isTrue);
      expect(played, [HapticKind.select]);
    });
  });
}
