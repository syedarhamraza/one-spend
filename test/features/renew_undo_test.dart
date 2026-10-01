import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/subscriptions/domain/services/billing_schedule.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    setupDependencies(database: db);
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
  });

  tearDown(OneUIToast.dismiss);

  group('SubscriptionController.undoRenew', () {
    test('restores the renewal date and payment history, and persists it', () async {
      final store = SubscriptionStore.instance;
      final before = store.subscriptions.first;

      store.renewSubscription(before.id);
      final renewed = store.getSubscription(before.id)!;
      expect(renewed.nextBillingDate.isAfter(before.nextBillingDate), isTrue);
      expect(renewed.paymentHistory.length, before.paymentHistory.length + 1);
      expect(store.canUndoRenew(before.id), isTrue);

      expect(store.undoRenew(before.id), isTrue);
      final undone = store.getSubscription(before.id)!;
      expect(undone.nextBillingDate, before.nextBillingDate);
      expect(undone.paymentHistory, before.paymentHistory);
      expect(store.canUndoRenew(before.id), isFalse);

      // Survives a reload from the database.
      await store.pendingWrites;
      final reloaded = SubscriptionController(
        subscriptionRepository: sl(),
        paymentMethodRepository: sl(),
        settingsRepository: sl(),
      );
      await reloaded.load();
      // The database stores times to the second.
      expect(
        reloaded.getSubscription(before.id)!.nextBillingDate.millisecondsSinceEpoch ~/ 1000,
        before.nextBillingDate.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('keeps edits made after renewing', () {
      final store = SubscriptionStore.instance;
      final sub = store.subscriptions.first;
      store.renewSubscription(sub.id);
      store.updateSubscription(store.getSubscription(sub.id)!.copyWith(name: 'Renamed'));

      store.undoRenew(sub.id);
      final undone = store.getSubscription(sub.id)!;
      expect(undone.name, 'Renamed');
      expect(undone.nextBillingDate, sub.nextBillingDate);
    });

    test('nothing to undo without a renew, or after discarding', () {
      final store = SubscriptionStore.instance;
      final id = store.subscriptions.first.id;
      expect(store.undoRenew(id), isFalse);
      store.renewSubscription(id);
      store.discardRenewUndo(id);
      expect(store.undoRenew(id), isFalse);
    });
  });

  group('same-day duplicate payments are refused', () {
    test('marking paid twice on the same day logs one payment and advances once', () {
      final store = SubscriptionStore.instance;
      final sub = store.subscriptions.first;

      expect(store.markSubscriptionPaid(sub.id), isTrue);
      final once = store.getSubscription(sub.id)!;
      expect(store.markSubscriptionPaid(sub.id), isFalse);
      expect(store.renewSubscription(sub.id), isFalse);

      final after = store.getSubscription(sub.id)!;
      expect(after.paymentHistory, hasLength(sub.paymentHistory.length + 1));
      expect(after.nextBillingDate, once.nextBillingDate);
      expect(store.canUndoRenew(sub.id), isFalse); // a refused renew leaves nothing to undo
    });

    test('a payment on a different date is still allowed', () {
      final store = SubscriptionStore.instance;
      final sub = store.subscriptions.first;
      final today = DateTime.now();
      expect(store.markSubscriptionPaid(sub.id, DateTime(today.year, today.month, today.day - 3)), isTrue);
      expect(store.markSubscriptionPaid(sub.id), isTrue);
      expect(store.getSubscription(sub.id)!.paymentHistory, hasLength(sub.paymentHistory.length + 2));
    });

    test('BillingSchedule.isAlreadyPaid compares by day', () {
      final sub = SubscriptionStore.instance.subscriptions.first;
      final now = DateTime(2026, 5, 10, 18);
      final paidEarlier = sub.copyWith(paymentHistory: [DateTime(2026, 5, 10, 8)], nextBillingDate: DateTime(2026, 6, 1));
      expect(BillingSchedule.isAlreadyPaid(paidEarlier, now: now), isTrue);
      expect(BillingSchedule.isAlreadyPaid(paidEarlier, now: DateTime(2026, 5, 11)), isFalse);
    });
  });

  testWidgets('Renew a second time the same day is refused with a message', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = SubscriptionStore.instance;
    final sub = store.subscriptions.first;
    await tester.pumpWidget(routedTestApp(SubscriptionDetailScreen(subscription: sub), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9)); // let the Undo window lapse
    await tester.pumpAndSettle();
    final renewedOnce = store.getSubscription(sub.id)!;

    await tester.tap(find.text('Renew'));
    await tester.pump();
    expect(find.text('Already marked paid today'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    expect(store.getSubscription(sub.id)!.nextBillingDate, renewedOnce.nextBillingDate);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Renew turns into Undo for a few seconds, and Undo reverts the date', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = SubscriptionStore.instance;
    final sub = store.subscriptions.first;

    await tester.pumpWidget(routedTestApp(SubscriptionDetailScreen(subscription: sub), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Renew'), findsNothing);
    expect(store.getSubscription(sub.id)!.nextBillingDate.isAfter(sub.nextBillingDate), isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.getSubscription(sub.id)!.nextBillingDate, sub.nextBillingDate);
    expect(find.text('Renew'), findsOneWidget);

    // Renew again and let the Undo window lapse.
    await tester.tap(find.text('Renew'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Renew'), findsOneWidget);
    expect(store.canUndoRenew(sub.id), isFalse);
  });
}
