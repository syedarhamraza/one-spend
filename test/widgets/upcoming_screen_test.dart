import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/upcoming_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_month_calendar.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime inDays(int days) => DateTime(today.year, today.month, today.day + days);

  Subscription sub(
    String id,
    String name, {
    required DateTime next,
    BillingCycle cycle = BillingCycle.monthly,
    double price = 10,
    String? paymentMethodId,
  }) =>
      Subscription(
        id: id,
        name: name,
        description: '',
        price: price,
        billingCycle: cycle,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: next,
        paymentMethodId: paymentMethodId,
        paymentMethod: paymentMethodId == null ? '' : 'Card',
      );

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    OneUIEffectsController.instance.upcomingViewMode = UpcomingViewMode.timeline;
    final store = SubscriptionStore.instance;
    store.resetForTesting(); // default cards
    store.clearAllData();
    store.batchAdd([
      sub('gym', 'Weekly Gym', next: inDays(2), cycle: BillingCycle.weekly, price: 5),
      sub('music', 'Music Plus', next: inDays(5), price: 11, paymentMethodId: 'pay_samsung_visa'),
      sub('cloud', 'Cloud Yearly', next: inDays(40), cycle: BillingCycle.yearly, price: 99, paymentMethodId: 'pay_mastercard_4242'),
    ]);
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pumpUpcoming(WidgetTester tester) async {
    // Very tall surface so every lazily-built timeline section is laid out.
    tester.view.physicalSize = const Size(1200, 12000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const UpcomingScreen(), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
  }

  /// Lets any Undo toast time out so no timers are left pending.
  Future<void> settleToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('timeline lists every charge, so a weekly subscription repeats', (tester) async {
    await pumpUpcoming(tester);

    // 30-day horizon: the weekly gym bills on day 2, 9, 16, 23 and 30.
    expect(find.text('Weekly Gym'), findsNWidgets(5));
    expect(find.text('Music Plus'), findsOneWidget);
    expect(find.text('Cloud Yearly'), findsNothing);
    expect(find.textContaining('due in the next 30 days'), findsOneWidget);
    expect(find.text('Total due'), findsOneWidget);
  });

  testWidgets('horizon pills change the range and the header total', (tester) async {
    await pumpUpcoming(tester);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.textContaining('\$16.00 due in the next 7 days'), findsOneWidget);
    expect(find.text('Weekly Gym'), findsOneWidget);

    await tester.tap(find.text('3 months'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud Yearly'), findsWidgets);
    // The insight strip scrolls horizontally, so this card may be just off-screen.
    expect(find.text('Yearly renewal soon', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tapping a card in "By payment method" filters the timeline', (tester) async {
    await pumpUpcoming(tester);
    final visaName = SubscriptionStore.instance.getPaymentMethod('pay_samsung_visa')!.displayName;

    await tester.tap(find.text(visaName).first);
    await tester.pumpAndSettle();

    expect(find.text('Weekly Gym'), findsNothing);
    expect(find.text('Music Plus'), findsOneWidget);
    expect(find.text('By payment method'), findsNothing);

    // Clearing the filter pill restores everything.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Gym'), findsNWidgets(5));
  });

  testWidgets('mark paid can be undone', (tester) async {
    await pumpUpcoming(tester);
    final store = SubscriptionStore.instance;
    final before = store.getSubscription('music')!;

    await tester.tap(find.bySemanticsLabel('Mark Music Plus as paid'));
    await tester.pump();
    expect(store.getSubscription('music')!.nextBillingDate.isAfter(before.nextBillingDate), isTrue);
    expect(store.getSubscription('music')!.paymentHistory, hasLength(1));

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.getSubscription('music'), before);
    await settleToasts(tester);
  });

  testWidgets('long-press offers "Skip this cycle", which is undoable', (tester) async {
    await pumpUpcoming(tester);
    final store = SubscriptionStore.instance;
    final before = store.getSubscription('music')!;

    await tester.longPress(find.text('Music Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip this cycle'));
    await tester.pumpAndSettle();

    final skipped = store.getSubscription('music')!;
    expect(skipped.nextBillingDate.isAfter(before.nextBillingDate), isTrue);
    expect(skipped.paymentHistory, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.getSubscription('music'), before);
    await settleToasts(tester);
  });

  testWidgets('only the next occurrence can be marked paid', (tester) async {
    await pumpUpcoming(tester);
    expect(find.bySemanticsLabel('Mark Weekly Gym as paid'), findsOneWidget);
  });

  testWidgets('calendar view shows the month grid and lists a tapped day\'s charges', (tester) async {
    await pumpUpcoming(tester);

    await tester.tap(find.byTooltip('Calendar view'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIMonthCalendar), findsOneWidget);
    expect(OneUIEffectsController.instance.upcomingViewMode, UpcomingViewMode.calendar);

    final musicDay = inDays(5);
    if (musicDay.month != today.month) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.bySemanticsLabel(RegExp('^${RegExp.escape(DateFormat.yMMMMd().format(musicDay))}')));
    await tester.pumpAndSettle();
    expect(find.text('Music Plus'), findsOneWidget);

    await tester.tap(find.byTooltip('Timeline view'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUIMonthCalendar), findsNothing);
  });

  testWidgets('lays out without overflow on a 360dp phone in both views', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(const UpcomingScreen(), theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();

    final visaName = SubscriptionStore.instance.getPaymentMethod('pay_samsung_visa')!.displayName;
    await tester.tap(find.text(visaName).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Calendar view'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state with no subscriptions', (tester) async {
    SubscriptionStore.instance.clearAllData();
    await pumpUpcoming(tester);
    expect(find.text('No upcoming renewals'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget);
  });
}
