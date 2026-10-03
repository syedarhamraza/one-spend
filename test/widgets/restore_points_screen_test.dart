import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/backup/data/backup_service.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/features/backup/domain/restore_point.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/restore_points_screen.dart';
import 'package:onespend/screens/settings/restore_preview_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

/// Serves restore points from memory, so the screen needs no file system.
class _FakeBackupService extends BackupService {
  List<RestorePoint> points = [];

  _FakeBackupService() : super(controller: SubscriptionStore.instance, settings: sl<SettingsRepository>());

  @override
  Future<List<RestorePoint>> listRestorePoints() async => points;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBackupService service;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
    service = _FakeBackupService();
    sl.unregister<BackupService>();
    sl.registerSingleton<BackupService>(service);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const RestorePointsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('says when there are no restore points yet', (tester) async {
    await pump(tester);
    expect(find.text('No restore points yet'), findsOneWidget);
  });

  testWidgets('lists each point and opens it in the restore preview', (tester) async {
    final store = SubscriptionStore.instance;
    service.points = [
      RestorePoint(
        path: 'restore-2-clear.json',
        reason: RestorePointReason.beforeClearAll,
        snapshot: BackupSnapshot(
          createdAt: DateTime(2026, 10, 3, 21, 41),
          appVersion: '1.0.0-beta.1 (1)',
          subscriptions: store.subscriptions.take(3).toList(),
          paymentMethods: store.paymentMethods.take(1).toList(),
          settings: (
            monthlyBudget: 0,
            currency: 'USD',
            defaultReminderDays: 2,
            defaultReminderTimeMinutes: 540,
            notificationsEnabled: true,
            sortOption: SubscriptionSortOption.renewalAsc,
            groupByDate: false,
          ),
        ),
      ),
    ];
    await pump(tester);

    expect(find.text('Before clearing all'), findsOneWidget);
    expect(find.text('Oct 3, 2026 · 9:41 PM\n3 subscriptions · 1 card'), findsOneWidget);

    await tester.tap(find.text('Before clearing all'));
    await tester.pumpAndSettle();
    expect(find.byType(RestorePreviewScreen), findsOneWidget);
    expect(find.text('Restore point'), findsOneWidget);
  });
}
