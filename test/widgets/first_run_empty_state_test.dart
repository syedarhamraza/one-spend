import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/subscriptions/presentation/widgets/first_run_empty_state.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/add_subscription_screen.dart';
import 'package:onespend/screens/settings/backup_data_screen.dart';
import 'package:onespend/screens/subscriptions_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
    SubscriptionStore.instance.clearAllData();
  });

  Future<void> pumpEmpty(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const SubscriptionsScreen(), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
  }

  testWidgets('a new user sees the first-run screen, not an empty list', (tester) async {
    await pumpEmpty(tester);
    expect(find.byType(FirstRunEmptyState), findsOneWidget);
    expect(find.text('Every subscription,\none place'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget);
    expect(find.bySemanticsLabel('Add Netflix'), findsOneWidget);
    expect(find.textContaining('active •'), findsNothing); // no "0 active • $0 / month"
    expect(tester.takeException(), isNull);
  });

  testWidgets('a popular chip starts a new subscription from that service', (tester) async {
    await pumpEmpty(tester);
    await tester.tap(find.bySemanticsLabel('Add Spotify'));
    await tester.pumpAndSettle();
    expect(find.byType(AddSubscriptionScreen), findsOneWidget);
    expect(find.text('Spotify'), findsWidgets);
  });

  testWidgets('the restore link opens Backup & data', (tester) async {
    await pumpEmpty(tester);
    await tester.tap(find.textContaining('Restore from backup', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.byType(BackupDataScreen), findsOneWidget);
  });

  testWidgets('with animations off the hero is fully shown immediately', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpEmpty(tester);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
