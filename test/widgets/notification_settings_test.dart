import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/notifications/domain/planned_notification.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/notification_settings_screen.dart';
import 'package:onespend/widgets/one_ui_switch.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    SubscriptionStore.instance.resetForTesting();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const NotificationSettingsScreen()));
    await tester.pumpAndSettle();
  }

  OneUISwitch switchFor(WidgetTester tester, String title) => tester.widget<OneUISwitch>(
        find.descendant(
          of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
          matching: find.byType(OneUISwitch),
        ),
      );

  testWidgets('one switch per notification type, all on to start', (tester) async {
    await pump(tester);
    expect(find.text('Notify me about'), findsOneWidget);
    for (final title in ['Renewal reminders', 'Card expiry', 'Budget alerts']) {
      expect(switchFor(tester, title).value, isTrue, reason: title);
    }
  });

  testWidgets('tapping a row turns that type off', (tester) async {
    final store = SubscriptionStore.instance;
    await pump(tester);
    await tester.ensureVisible(find.text('Budget alerts'));
    await tester.tap(find.text('Budget alerts'));
    await tester.pumpAndSettle();
    expect(store.isNotificationKindEnabled(NotificationKind.budget), isFalse);
    expect(store.isNotificationKindEnabled(NotificationKind.renewal), isTrue);
    expect(switchFor(tester, 'Budget alerts').value, isFalse);
  });

  testWidgets('with notifications off, the types are disabled', (tester) async {
    SubscriptionStore.instance.setNotificationsEnabled(false);
    await pump(tester);
    await tester.ensureVisible(find.text('Card expiry'));
    await tester.tap(find.text('Card expiry'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.isNotificationKindEnabled(NotificationKind.card), isTrue);
  });
}
