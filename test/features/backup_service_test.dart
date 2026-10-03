import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/backup/data/backup_service.dart';
import 'package:onespend/features/backup/domain/backup_codec.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/features/backup/domain/restore_point.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tempDir;
  late SubscriptionController controller;
  late BackupService service;

  Subscription sub(String id) => Subscription(
        id: id,
        name: 'Sub $id',
        description: '',
        price: 10,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.music,
        nextBillingDate: DateTime(2026, 10, 5),
      );

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    setupDependencies(database: db);
    tempDir = await Directory.systemTemp.createTemp('onespend_backup_test');
    controller = SubscriptionStore.instance
      ..resetForTesting()
      ..clearAllData()
      ..batchAdd([sub('mine1'), sub('mine2')]);
    await controller.pendingWrites;
    service = BackupService(
      controller: controller,
      settings: sl<SettingsRepository>(),
      baseDirectory: () async => tempDir,
      appVersion: () async => '9.9.9 (9)',
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  SubscriptionController reloadedController() => SubscriptionController(
        subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
        paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
        settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
      );

  BackupSnapshot backupWith(List<Subscription> subs, {String currency = 'EUR'}) => BackupSnapshot(
        createdAt: DateTime(2026, 9, 1),
        appVersion: '1.0.0 (1)',
        subscriptions: subs,
        paymentMethods: const [],
        settings: (
          monthlyBudget: 42,
          currency: currency,
          defaultReminderDays: 1,
          defaultReminderTimeMinutes: 7 * 60,
          notificationsEnabled: true,
          sortOption: SubscriptionSortOption.nameAsc,
          groupByDate: false,
        ),
      );

  test('a snapshot round-trips through the backup file', () async {
    final text = await service.exportBackup(now: DateTime(2026, 9, 30));
    final decoded = BackupCodec.decode(text);
    expect(decoded.appVersion, '9.9.9 (9)');
    expect(decoded.subscriptions.map((s) => s.id), ['mine1', 'mine2']);
    expect(decoded.paymentMethods.length, controller.paymentMethods.length);
    expect(decoded.settings?.currency, controller.currency);
  });

  test('add missing keeps everything and adds only new items', () async {
    await service.restore(backupWith([sub('mine1'), sub('new1')]), RestoreMode.addMissing);
    expect(controller.subscriptions.map((s) => s.id), ['mine1', 'mine2', 'new1']);
    expect(controller.currency, 'USD', reason: 'settings are not touched');
    expect(await service.restorePoints(), isEmpty);
  });

  test('replace saves a restore point, persists, and undo brings the data back', () async {
    final cardsBefore = controller.paymentMethods.length;
    await service.restore(backupWith([sub('fromBackup')]), RestoreMode.replace);

    expect(controller.subscriptions.map((s) => s.id), ['fromBackup']);
    expect(controller.paymentMethods, isEmpty);
    expect(controller.currency, 'EUR');
    expect(controller.monthlyBudget, 42);
    expect(await service.restorePoints(), hasLength(1));

    final reloaded = reloadedController();
    await reloaded.load();
    expect(reloaded.subscriptions.map((s) => s.id), ['fromBackup']);
    expect(reloaded.currency, 'EUR');

    expect(await service.undoLast(), isTrue);
    expect(controller.subscriptions.map((s) => s.id), ['mine1', 'mine2']);
    expect(controller.paymentMethods.length, cardsBefore);
    expect(controller.currency, 'USD');
    expect(await service.restorePoints(), isEmpty);
    expect(await service.undoLast(), isFalse);
  });

  test('replacing with an old subscriptions-only export keeps cards and settings', () async {
    final cardsBefore = controller.paymentMethods.length;
    final legacy = BackupSnapshot(
      createdAt: DateTime(2026, 1, 1),
      appVersion: '',
      subscriptions: [sub('old')],
      paymentMethods: const [],
    );
    await service.restore(legacy, RestoreMode.replace);
    expect(controller.subscriptions.map((s) => s.id), ['old']);
    expect(controller.paymentMethods.length, cardsBefore);
    expect(controller.currency, 'USD');
  });

  test('clear all can be undone', () async {
    expect(service.undoableAction.value, isNull);
    await service.clearAll();
    expect(controller.subscriptions, isEmpty);
    expect(service.undoableAction.value, 'Clear all');
    expect(await service.undoLast(), isTrue);
    expect(controller.subscriptions.map((s) => s.id), ['mine1', 'mine2']);
    expect(service.undoableAction.value, isNull);
  });

  test('only the newest restore points are kept', () async {
    for (var i = 0; i < BackupService.maxRestorePoints + 2; i++) {
      await service.saveRestorePoint();
    }
    expect(await service.restorePoints(), hasLength(BackupService.maxRestorePoints));
  });

  test('restore points are listed newest first with why they were saved', () async {
    await service.restore(backupWith([sub('fromBackup')]), RestoreMode.replace);
    await service.clearAll();

    final points = await service.listRestorePoints();
    expect(points.map((p) => p.reason), [RestorePointReason.beforeClearAll, RestorePointReason.beforeRestore]);
    // Each holds the data from just before: first the restored backup, then the original.
    expect(points[0].snapshot.subscriptions.map((s) => s.id), ['fromBackup']);
    expect(points[1].snapshot.subscriptions.map((s) => s.id), ['mine1', 'mine2']);
  });

  test('going back to a restore point is itself undoable', () async {
    await service.clearAll();
    final point = (await service.listRestorePoints()).single;

    await service.restore(point.snapshot, RestoreMode.replace, reason: RestorePointReason.beforeRestorePoint);
    expect(controller.subscriptions.map((s) => s.id), ['mine1', 'mine2']);

    final points = await service.listRestorePoints();
    expect(points.first.reason, RestorePointReason.beforeRestorePoint);
    expect(points.first.snapshot.subscriptions, isEmpty);
    expect(await service.undoLast(), isTrue);
    expect(controller.subscriptions, isEmpty);
  });

  test('unreadable restore points are skipped and old file names still list', () async {
    final dir = Directory('${tempDir.path}/restore_points')..createSync(recursive: true);
    File('${dir.path}/restore-00000000000000000001.json').writeAsStringSync(await service.exportBackup());
    File('${dir.path}/restore-00000000000000000002-clear.json').writeAsStringSync('not json');

    final points = await service.listRestorePoints();
    expect(points.single.reason, RestorePointReason.beforeRestore);
    expect(points.single.snapshot.subscriptions, hasLength(2));
  });

  test('suggested file name uses the date', () {
    expect(BackupService.fileName(DateTime(2026, 3, 7)), 'One-Spend-backup-2026-03-07.json');
  });
}
