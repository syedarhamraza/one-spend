import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/backup/data/backup_service.dart';
import 'package:onespend/features/backup/domain/backup_merge.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/restore_preview_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_radio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// Applies restores without touching the file system (restore points need real I/O).
class _FakeBackupService extends BackupService {
  final List<RestoreMode> calls = [];

  _FakeBackupService() : super(controller: SubscriptionStore.instance, settings: sl<SettingsRepository>());

  @override
  Future<void> restore(BackupSnapshot backup, RestoreMode mode) async {
    calls.add(mode);
    if (mode == RestoreMode.addMissing) {
      final missing = BackupMerge.missingItems(
        currentSubscriptions: controller.subscriptions,
        currentPaymentMethods: controller.paymentMethods,
        backup: backup,
      );
      controller.addItems(subscriptions: missing.subscriptions, paymentMethods: missing.paymentMethods);
      return;
    }
    controller.replaceAllData(
      subscriptions: backup.subscriptions,
      paymentMethods: backup.paymentMethods,
      settings: backup.settings,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBackupService service;

  Subscription sub(String id) => Subscription(
        id: id,
        name: 'Sub $id',
        description: '',
        price: 10,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.music,
        nextBillingDate: DateTime(2026, 10, 5),
      );

  final backup = BackupSnapshot(
    createdAt: DateTime(2026, 9, 1, 9, 30),
    appVersion: '1.0.0 (1)',
    subscriptions: [sub('mine1'), sub('new1')],
    paymentMethods: const [],
  );

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance
      ..resetForTesting()
      ..clearAllData()
      ..batchAdd([sub('mine1'), sub('mine2')]);
    service = _FakeBackupService();
    sl.unregister<BackupService>();
    sl.registerSingleton<BackupService>(service);
  });

  /// Opens the preview from a host page; returns a getter for the popped outcome.
  Future<RestoreOutcome? Function()> openPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    RestoreOutcome? outcome;
    await tester.pumpWidget(routedTestApp(Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () async => outcome = await RestorePreviewScreen.open(context, backup),
          child: const Text('open'),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => outcome;
  }

  testWidgets('shows both sides and defaults to adding missing items', (tester) async {
    await openPreview(tester);
    expect(find.text('Restore backup'), findsOneWidget);
    expect(find.text('2 subscriptions'), findsOneWidget); // the backup
    expect(find.textContaining('2 subscriptions ·'), findsOneWidget); // this phone, with its cards
    expect(find.textContaining('Adds 1 subscription. Nothing you have is changed.'), findsOneWidget);
    final radios = tester.widgetList<OneUIRadio>(find.byType(OneUIRadio)).toList();
    expect(radios.map((r) => r.isSelected), [true, false]);
  });

  testWidgets('restoring with add missing keeps existing data', (tester) async {
    final outcome = await openPreview(tester);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(service.calls, [RestoreMode.addMissing]);
    expect(outcome()?.addedSubscriptions, 1);
    expect(SubscriptionStore.instance.subscriptions.map((s) => s.id), ['mine1', 'mine2', 'new1']);
  });

  testWidgets('replace asks for confirmation first', (tester) async {
    final outcome = await openPreview(tester);
    await tester.tap(find.text('Replace everything'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Replace all data?'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(service.calls, [RestoreMode.replace]);
    expect(outcome()?.mode, RestoreMode.replace);
    expect(SubscriptionStore.instance.subscriptions.map((s) => s.id), ['mine1', 'new1']);
  });

  testWidgets('cancel leaves everything as it was', (tester) async {
    final outcome = await openPreview(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.calls, isEmpty);
    expect(outcome(), isNull);
    expect(SubscriptionStore.instance.subscriptions.map((s) => s.id), ['mine1', 'mine2']);
  });
}
