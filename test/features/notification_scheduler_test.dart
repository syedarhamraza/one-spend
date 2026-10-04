import 'dart:io';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/router/app_router.dart';
import 'package:onespend/features/notifications/data/notification_service.dart';
import 'package:onespend/features/notifications/domain/planned_notification.dart';
import 'package:onespend/features/notifications/presentation/notification_scheduler.dart';
import 'package:onespend/features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import 'package:onespend/features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import 'package:onespend/features/settings/data/datasources/settings_drift_datasource.dart';
import 'package:onespend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:onespend/features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import 'package:onespend/features/subscriptions/data/fixtures/popular_catalog.dart';
import 'package:onespend/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription.dart';
import 'package:onespend/features/subscriptions/domain/entities/subscription_enums.dart';
import 'package:onespend/features/subscriptions/presentation/controllers/subscription_controller.dart';

/// Records what the scheduler asks the platform to do.
class FakeNotificationService extends NoopNotificationService {
  final Map<int, ({PlannedNotification notification, String route})> scheduled = {};
  final List<int> cancelled = [];
  int scheduleCalls = 0;

  @override
  Future<void> schedule(PlannedNotification notification, {required String route}) async {
    scheduleCalls++;
    scheduled[notification.id] = (notification: notification, route: route);
  }

  @override
  Future<void> cancel(Iterable<int> ids) async {
    for (final id in ids) {
      cancelled.add(id);
      scheduled.remove(id);
    }
  }

  @override
  Future<List<PendingNotification>> pending() async => [
        for (final e in scheduled.entries)
          (id: e.key, title: e.value.notification.title, body: e.value.notification.body, route: e.value.route),
      ];
}

SubscriptionController _controllerFor(AppDatabase db) => SubscriptionController(
      subscriptionRepository: SubscriptionRepositoryImpl(SubscriptionDriftDataSource(db)),
      paymentMethodRepository: PaymentMethodRepositoryImpl(PaymentMethodDriftDataSource(db)),
      settingsRepository: SettingsRepositoryImpl(SettingsDriftDataSource(db)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SubscriptionController controller;
  late FakeNotificationService service;
  late NotificationScheduler scheduler;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = _controllerFor(db);
    await controller.load();
    service = FakeNotificationService();
    scheduler = NotificationScheduler(
      controller: controller,
      service: service,
      clock: () => DateTime.now(),
      debounce: Duration.zero,
    );
  });

  tearDown(() async {
    scheduler.dispose();
    await controller.pendingWrites;
    await db.close();
  });

  Subscription dueSoon() => popularCatalog[0].copyWith(
        nextBillingDate: DateTime.now().add(const Duration(days: 10)),
        reminderDays: 2,
      );

  test('schedules the plan with deep-link routes', () async {
    controller.addSubscription(dueSoon());
    final count = await scheduler.syncNow();

    expect(count, greaterThan(0));
    final first = service.scheduled.values.first;
    expect(first.notification.kind, NotificationKind.renewal);
    expect(first.route, AppRoutes.subscriptionDetail(popularCatalog[0].id));
  });

  test('a data change triggers a resync that replaces the old plan', () async {
    scheduler.start();
    controller.addSubscription(dueSoon());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await scheduler.syncNow();
    final before = service.scheduled.keys.toSet();
    expect(before, isNotEmpty);

    controller.removeSubscription(popularCatalog[0].id);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await scheduler.syncNow();

    expect(service.scheduled, isEmpty);
    expect(service.cancelled, containsAll(before));
  });

  test('turning notifications off cancels everything; on reschedules', () async {
    controller.addSubscription(dueSoon());
    await scheduler.syncNow();
    expect(service.scheduled, isNotEmpty);

    controller.setNotificationsEnabled(false);
    expect(await scheduler.syncNow(), 0);
    expect(service.scheduled, isEmpty);

    controller.setNotificationsEnabled(true);
    expect(await scheduler.syncNow(), greaterThan(0));
  });

  test('changing the default time reschedules at the new time', () async {
    controller.addSubscription(dueSoon());
    controller.setDefaultReminderTimeMinutes(20 * 60);
    await scheduler.syncNow();

    final times = service.scheduled.values.map((s) => s.notification.fireAt);
    expect(times.every((t) => t.hour == 20 && t.minute == 0), isTrue);
  });

  group('a data change only touches what changed', () {
    Future<void> settle() async {
      await Future<void>.delayed(const Duration(milliseconds: 20)); // debounce (zero) + queued sync
      await scheduler.lastSyncDone;
    }

    setUp(() async {
      scheduler.start();
      controller.addSubscription(dueSoon());
      controller.addSubscription(popularCatalog[1].copyWith(
        nextBillingDate: DateTime.now().add(const Duration(days: 12)),
        reminderDays: 1,
      ));
      await settle();
      expect(service.scheduled, isNotEmpty);
      service.cancelled.clear();
      service.scheduleCalls = 0;
    });

    test('changes that affect no reminder schedule and cancel nothing', () async {
      controller.addRecentSearch('netflix');
      controller.setSortOption(SubscriptionSortOption.nameAsc);
      controller.dismissInsight('some-insight');
      await settle();

      expect(service.scheduleCalls, 0);
      expect(service.cancelled, isEmpty);
    });

    test("editing one subscription reschedules only that subscription's reminders", () async {
      final untouched = {
        for (final e in service.scheduled.entries)
          if (e.value.notification.subjectId == popularCatalog[1].id) e.key,
      };
      final sub = controller.getSubscription(popularCatalog[0].id)!;
      controller.updateSubscription(sub.copyWith(reminderDays: 3));
      await settle();

      expect(service.scheduleCalls, greaterThan(0));
      final rescheduledSubjects = service.scheduled.values
          .where((s) => s.notification.subjectId == popularCatalog[0].id)
          .map((s) => s.notification.fireAt);
      expect(rescheduledSubjects, isNotEmpty);
      expect(service.cancelled.toSet().intersection(untouched), isEmpty);
      expect(service.scheduled.keys, containsAll(untouched));
      // The fake mirrors the OS: what's scheduled now equals a full fresh plan.
      expect(service.scheduled.keys.toSet(), scheduler.lastPlan.map((n) => n.id).toSet());
    });

    test('removing a subscription cancels its reminders', () async {
      final ids = {
        for (final e in service.scheduled.entries)
          if (e.value.notification.subjectId == popularCatalog[0].id) e.key,
      };
      controller.removeSubscription(popularCatalog[0].id);
      await settle();

      expect(service.cancelled, containsAll(ids));
      expect(service.scheduleCalls, 0);
    });

    test('a resume still reschedules everything', () async {
      scheduler.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await scheduler.lastSyncDone;
      expect(service.scheduleCalls, scheduler.lastPlan.length);
    });
  });

  test('never cancels developer test notifications', () async {
    final devTest = PlannedNotification(
      id: 2,
      kind: NotificationKind.developer,
      fireAt: DateTime.now().add(const Duration(minutes: 1)),
      title: 'dev',
      body: 'dev',
    );
    await service.schedule(devTest, route: AppRoutes.subscriptions);
    controller.addSubscription(dueSoon());

    await scheduler.syncNow();
    await scheduler.syncNow();

    expect(service.cancelled, isNot(contains(2)));
    expect(service.scheduled.containsKey(2), isTrue);
  });

  group('Settings persistence', () {
    test('notification toggle and default time survive relaunch', () async {
      controller.setNotificationsEnabled(false);
      controller.setDefaultReminderTimeMinutes(7 * 60 + 15);
      await controller.pendingWrites;

      final relaunched = _controllerFor(db);
      await relaunched.load();
      expect(relaunched.notificationsEnabled, isFalse);
      expect(relaunched.defaultReminderTimeMinutes, 7 * 60 + 15);
    });

    test('fresh install defaults to on at 9:00 AM', () {
      expect(controller.notificationsEnabled, isTrue);
      expect(controller.defaultReminderTimeMinutes, 9 * 60);
    });
  });

  group('Schema v2 migration', () {
    test('upgrades a v1 database and keeps existing rows', () async {
      final dir = Directory.systemTemp.createTempSync('onespend_migration');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/v1.sqlite');

      // Build a v1 database: current schema minus the new column, user_version 1.
      final v1 = AppDatabase.forTesting(NativeDatabase(file));
      await SubscriptionDriftDataSource(v1).saveSubscriptions([]);
      await _controllerFor(v1).subscriptionRepository.upsert([popularCatalog[0]]);
      await v1.customStatement('ALTER TABLE subscriptions DROP COLUMN reminder_time_minutes');
      await v1.customStatement('PRAGMA user_version = 1');
      await v1.close();

      final upgraded = AppDatabase.forTesting(NativeDatabase(file));
      final ds = SubscriptionDriftDataSource(upgraded);
      final subs = await ds.loadSubscriptions();
      expect(subs.single.id, popularCatalog[0].id);
      expect(subs.single.reminderTimeMinutes, isNull);

      // The new column round-trips.
      final withTime = _controllerFor(upgraded);
      await withTime.subscriptionRepository.upsert([subs.single.copyWith(reminderTimeMinutes: 20 * 60 + 30)]);
      expect((await ds.loadSubscriptions()).single.reminderTimeMinutes, 20 * 60 + 30);
      await upgraded.close();
    });
  });
}
