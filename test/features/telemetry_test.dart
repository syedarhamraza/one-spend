import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/core/telemetry/events.dart';
import 'package:onespend/core/telemetry/telemetry.dart';
import 'package:onespend/features/backup/data/backup_service.dart';
import 'package:onespend/features/backup/domain/backup_snapshot.dart';
import 'package:onespend/features/backup/domain/restore_point.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/utils/external_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTelemetry implements Telemetry {
  final logs = <String>[];
  final errors = <({String reason, bool fatal})>[];
  final events = <TelemetryEvent>[];
  final context = <String, Object>{};

  @override
  void log(String message) => logs.add(message);

  @override
  void recordError(Object error, StackTrace? stack, {required String reason, bool fatal = false}) =>
      errors.add((reason: reason, fatal: fatal));

  @override
  void event(TelemetryEvent event) => events.add(event);

  @override
  void screen(String name) => logs.add('screen $name');

  @override
  void setContext(String key, Object value) => context[key] = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingTelemetry telemetry;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    telemetry = _RecordingTelemetry();
    sl.unregister<Telemetry>();
    sl.registerSingleton<Telemetry>(telemetry);
  });

  test('tests and builds without Firebase get the console-only telemetry', () {
    sl.unregister<Telemetry>();
    setupDependencies();
    expect(sl<Telemetry>(), isA<NoopTelemetry>());
  });

  test('AppLog forwards to the registered telemetry', () {
    AppLog.info('hello');
    AppLog.error(StateError('x'), StackTrace.current, reason: 'Failed to save data');
    AppLog.fatal(StateError('y'), null, reason: 'Uncaught async error');
    AppLog.event(TelemetryEvent.backupSaved);
    AppLog.context(TelemetryContext.currency, 'EUR');

    expect(telemetry.logs, ['hello']);
    expect(telemetry.errors, [(reason: 'Failed to save data', fatal: false), (reason: 'Uncaught async error', fatal: true)]);
    expect(telemetry.events.single.name, 'backup_saved');
    expect(telemetry.context, {'currency': 'EUR'});
  });

  group('events never carry user content', () {
    test('custom categories are reported only as "custom"', () {
      final store = SubscriptionStore.instance;
      final custom = store.addCustomCategory(name: 'My secret side project', iconCodePoint: 0xe000, colorValue: 0);
      final event = TelemetryEvent.subscriptionAdded(
        category: custom,
        billingCycle: BillingCycle.monthly,
        fromPreset: false,
      );
      expect(event.params, {'category': 'custom', 'billing_cycle': 'monthly', 'from_preset': false});
      expect(event.params.values.join(), isNot(contains('secret')));

      final builtIn = TelemetryEvent.subscriptionAdded(
        category: SubscriptionCategory.music,
        billingCycle: BillingCycle.yearly,
        fromPreset: true,
      );
      expect(builtIn.params['category'], 'music');
    });

    test('names fit Firebase rules and values are only strings, ints and bools', () {
      final all = [
        TelemetryEvent.onboardingCompleted,
        TelemetryEvent.subscriptionAdded(
          category: SubscriptionCategory.cloud,
          billingCycle: BillingCycle.monthly,
          fromPreset: true,
        ),
        TelemetryEvent.subscriptionsDeleted(3),
        TelemetryEvent.renewTapped,
        TelemetryEvent.renewUndone,
        TelemetryEvent.backupSaved,
        TelemetryEvent.backupRestored(mode: 'replace', fromRestorePoint: true),
        TelemetryEvent.clearAll,
        TelemetryEvent.undoLast,
        TelemetryEvent.exportShared(format: 'pdf', scope: 'all'),
        TelemetryEvent.studioOpened('cards'),
        TelemetryEvent.customCategoryCreated,
        TelemetryEvent.notificationOpened('subscription'),
        TelemetryEvent.updateCheck('upToDate'),
        TelemetryEvent.updateStarted,
      ];
      for (final e in all) {
        expect(e.name, matches(RegExp(r'^[a-z][a-z0-9_]{0,39}$')), reason: e.name);
        for (final v in e.params.values) {
          expect(v is String || v is int || v is bool, isTrue, reason: '${e.name}: $v');
        }
      }
    });

    test('list sizes are bucketed, never exact', () {
      expect(TelemetryContext.bucket(0), '0');
      expect(TelemetryContext.bucket(4), '1-5');
      expect(TelemetryContext.bucket(12), '6-20');
      expect(TelemetryContext.bucket(80), '21+');
    });
  });

  test('restores report their mode and whether they came from a restore point', () async {
    final tempDir = await Directory.systemTemp.createTemp('onespend_telemetry_test');
    addTearDown(() => tempDir.delete(recursive: true));
    final service = BackupService(
      controller: SubscriptionStore.instance,
      settings: sl<SettingsRepository>(),
      baseDirectory: () async => tempDir,
      appVersion: () async => '1.0.0-alpha.1 (1)',
    );
    final backup = await service.createSnapshot();

    await service.restore(backup, RestoreMode.addMissing);
    await service.restore(backup, RestoreMode.replace, reason: RestorePointReason.beforeRestorePoint);

    expect(telemetry.events.map((e) => e.params), [
      {'mode': 'add_missing', 'from_restore_point': false},
      {'mode': 'replace', 'from_restore_point': true},
    ]);
  });

  test('feedback emails carry a subject and a body', () {
    expect(
      mailtoUrl('a@b.c', subject: 'One Spend feedback', body: 'Hi\n---\nOne Spend 1.0.0'),
      'mailto:a@b.c?subject=One%20Spend%20feedback&body=Hi%0A---%0AOne%20Spend%201.0.0',
    );
    expect(mailtoUrl('a@b.c'), 'mailto:a@b.c');
  });
}
