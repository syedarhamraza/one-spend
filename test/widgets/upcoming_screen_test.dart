import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/home_screen.dart';
import 'package:onespend/screens/upcoming_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_ambient_glow.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_selection_header_pills.dart';
import 'package:onespend/widgets/one_ui_month_calendar.dart';
import 'package:onespend/widgets/one_ui_floating_action_bar.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:onespend/widgets/one_ui_upcoming_hero_card.dart';
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
    HomeChrome.reset();
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

  /// A subscription name inside a charge row (the hero card also shows names).
  Finder row(String name) => find.descendant(of: find.byType(OneUIGroupCard), matching: find.text(name));

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

  Color heroGlow(WidgetTester tester) => tester
      .widget<OneUIAmbientGlow>(
          find.descendant(of: find.byType(OneUIUpcomingHeroCard), matching: find.byType(OneUIAmbientGlow)))
      .color;

  testWidgets('hero glow takes the brand colour of the biggest charge', (tester) async {
    await pumpUpcoming(tester);
    // Music Plus ($11) is the biggest single charge in the next 30 days.
    final music = SubscriptionStore.instance.getSubscription('music')!;
    expect(heroGlow(tester), OneUITheme.glowTint(Color(music.brandColorValue)));
  });

  testWidgets('hero glow turns crimson when something is overdue', (tester) async {
    SubscriptionStore.instance.batchAdd([sub('late', 'Late Service', next: inDays(-3))]);
    await pumpUpcoming(tester);
    expect(heroGlow(tester), OneUIUpcomingHeroCard.colorCrimson);
  });

  testWidgets('timeline lists every charge, so a weekly subscription repeats', (tester) async {
    await pumpUpcoming(tester);

    // 30-day horizon: the weekly gym bills on day 2, 9, 16, 23 and 30.
    expect(row('Weekly Gym'), findsNWidgets(5));
    expect(row('Music Plus'), findsOneWidget);
    expect(row('Cloud Yearly'), findsNothing);
    expect(find.textContaining('due in the next 30 days'), findsOneWidget);

    // Hero card: horizon title, total, charge count and the biggest charge.
    expect(find.byType(OneUIUpcomingHeroCard), findsOneWidget);
    expect(find.text('Due in the next 30 days'), findsOneWidget);
    expect(find.text('\$36.00'), findsOneWidget); // 5 x \$5 gym + \$11 music
    expect(find.text('6 charges'), findsOneWidget);
    expect(find.text('Biggest charge'), findsOneWidget);
  });

  testWidgets('horizon pills change the range and the header total', (tester) async {
    await pumpUpcoming(tester);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(find.textContaining('\$16.00 due in the next 7 days'), findsOneWidget);
    expect(row('Weekly Gym'), findsOneWidget);

    await tester.tap(find.text('3 months'));
    await tester.pumpAndSettle();
    expect(row('Cloud Yearly'), findsWidgets);
    expect(find.text('Yearly renewal'), findsOneWidget);
  });

  testWidgets('tapping a card in "By payment method" filters the timeline', (tester) async {
    await pumpUpcoming(tester);
    final visaName = SubscriptionStore.instance.getPaymentMethod('pay_samsung_visa')!.displayName;

    await tester.tap(find.text(visaName).first);
    await tester.pumpAndSettle();

    expect(row('Weekly Gym'), findsNothing);
    expect(row('Music Plus'), findsOneWidget);
    expect(find.text('By payment method'), findsNothing);

    // Clearing the filter pill restores everything.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(row('Weekly Gym'), findsNWidgets(5));
  });

  testWidgets('check button asks for confirmation before marking paid', (tester) async {
    await pumpUpcoming(tester);
    final store = SubscriptionStore.instance;
    final before = store.getSubscription('music')!;

    // Cancel leaves the subscription untouched.
    await tester.tap(find.bySemanticsLabel('Mark Music Plus as paid'));
    await tester.pumpAndSettle();
    expect(find.text('Mark Music Plus as paid?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(store.getSubscription('music'), before);

    // Confirming logs the payment and advances the date, with no Undo offered.
    await tester.tap(find.bySemanticsLabel('Mark Music Plus as paid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark paid').last);
    await tester.pumpAndSettle();
    final after = store.getSubscription('music')!;
    expect(after.nextBillingDate.isAfter(before.nextBillingDate), isTrue);
    expect(after.paymentHistory, hasLength(1));
    expect(find.text('Undo'), findsNothing);
    await settleToasts(tester);
  });

  testWidgets('long-press enters selection mode with the floating action bar', (tester) async {
    await pumpUpcoming(tester);

    await tester.longPress(row('Music Plus'));
    await tester.pumpAndSettle();

    expect(HomeChrome.upcomingSelectionActive.value, isTrue);
    expect(find.bySemanticsLabel('Music Plus selected'), findsOneWidget);
    expect(find.byType(OneUIFloatingActionBar), findsOneWidget);
    expect(find.text('Skip this cycle'), findsNothing); // no action sheet any more
    expect(find.bySemanticsLabel('Mark Music Plus as paid'), findsNothing);

    // Tapping another row adds it (every occurrence); tapping again removes it.
    await tester.tap(row('Weekly Gym').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Weekly Gym selected'), findsNWidgets(5));
    await tester.tap(row('Weekly Gym').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Weekly Gym selected'), findsNothing);

    // Select all, then Cancel exits selection.
    await tester.tap(find.byType(OneUISelectionCountPill));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Weekly Gym selected'), findsNWidgets(5));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(HomeChrome.upcomingSelectionActive.value, isFalse);
    expect(find.bySemanticsLabel('Mark Music Plus as paid'), findsOneWidget);
  });

  testWidgets('batch mark paid confirms and advances every selected subscription', (tester) async {
    await pumpUpcoming(tester);
    final store = SubscriptionStore.instance;
    final gymBefore = store.getSubscription('gym')!;
    final musicBefore = store.getSubscription('music')!;

    await tester.longPress(row('Music Plus'));
    await tester.pumpAndSettle();
    await tester.tap(row('Weekly Gym').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark paid'));
    await tester.pumpAndSettle();
    expect(find.text('Mark 2 subscriptions as paid?'), findsOneWidget);
    await tester.tap(find.text('Mark paid').last);
    await tester.pumpAndSettle();

    expect(store.getSubscription('gym')!.nextBillingDate.isAfter(gymBefore.nextBillingDate), isTrue);
    expect(store.getSubscription('music')!.nextBillingDate.isAfter(musicBefore.nextBillingDate), isTrue);
    expect(store.getSubscription('music')!.paymentHistory, hasLength(1));
    expect(HomeChrome.upcomingSelectionActive.value, isFalse);
    await settleToasts(tester);
  });

  testWidgets('batch skip moves subscriptions on without logging payments', (tester) async {
    await pumpUpcoming(tester);
    final store = SubscriptionStore.instance;
    final before = store.getSubscription('music')!;

    await tester.longPress(row('Music Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip').last);
    await tester.pumpAndSettle();

    final skipped = store.getSubscription('music')!;
    expect(skipped.nextBillingDate.isAfter(before.nextBillingDate), isTrue);
    expect(skipped.paymentHistory, isEmpty);
    await settleToasts(tester);
  });

  testWidgets('system back leaves selection mode', (tester) async {
    await pumpUpcoming(tester);
    await tester.longPress(row('Music Plus'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(HomeChrome.upcomingSelectionActive.value, isFalse);
    expect(find.byType(UpcomingScreen), findsOneWidget);
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
    expect(row('Music Plus'), findsOneWidget);

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
    await tester.ensureVisible(find.text(visaName).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(visaName).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(row('Music Plus').first);
    await tester.pumpAndSettle();
    await tester.longPress(row('Music Plus').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Calendar view'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('charges on deleted cards fold into a single "No card" row', (tester) async {
    SubscriptionStore.instance.batchAdd([
      sub('old1', 'Old Card Sub A', next: inDays(3), paymentMethodId: 'deleted_card_1'),
      sub('old2', 'Old Card Sub B', next: inDays(4), paymentMethodId: 'deleted_card_2'),
    ]);
    await pumpUpcoming(tester);

    expect(find.text('Removed card'), findsNothing);
    // Weekly Gym (no card) + the two subs on deleted cards share one row.
    expect(find.text('No card'), findsOneWidget);

    await tester.tap(find.text('No card'));
    await tester.pumpAndSettle();
    expect(row('Old Card Sub A'), findsOneWidget);
    expect(row('Old Card Sub B'), findsOneWidget);
    expect(row('Music Plus'), findsNothing);
  });

  testWidgets('shows the empty state with no subscriptions', (tester) async {
    SubscriptionStore.instance.clearAllData();
    await pumpUpcoming(tester);
    expect(find.text('No upcoming renewals'), findsOneWidget);
    expect(find.text('Add subscription'), findsOneWidget);
  });
}
