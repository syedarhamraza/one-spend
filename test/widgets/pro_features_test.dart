import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/pro/presentation/pro_controller.dart';
import 'package:onespend/features/pro/presentation/pro_screen.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/category_editor_screen.dart';
import 'package:onespend/screens/category_picker_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_analytics_hero_card.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  final now = DateTime.now();
  final monthly = Subscription(
    id: 'stream',
    name: 'Stream Plus',
    description: '',
    price: 10,
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    nextBillingDate: DateTime(now.year, now.month, now.day + 10),
    annualPlanPrice: 100,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    final store = SubscriptionStore.instance;
    store.resetForTesting();
    store.clearAllData();
    store.addSubscription(monthly);
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(screen, theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
  }

  group('Custom categories', () {
    testWidgets('free: "New category" opens the Pro page', (tester) async {
      await pump(tester, const CategoryPickerScreen(initialCategory: SubscriptionCategory.music));
      await tester.scrollUntilVisible(find.text('New category'), 300);
      expect(find.descendant(of: find.byType(Scrollable).first, matching: find.byType(OneUIProChip)), findsOneWidget);
      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
      expect(find.byType(CategoryEditorScreen), findsNothing);
    });

    testWidgets('Pro: create a category and it gets selected', (tester) async {
      ProController.instance.debugOverride = true;
      await pump(tester, const CategoryPickerScreen(initialCategory: SubscriptionCategory.music));
      await tester.scrollUntilVisible(find.text('New category'), 300);
      await tester.tap(find.text('New category'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryEditorScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Kids');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryPickerScreen), findsOneWidget);
      final custom = SubscriptionStore.instance.customCategories.single;
      expect(custom.name, 'Kids');
      // The hero at the top shows the selection.
      expect(find.text('Kids'), findsWidgets);
    });

    testWidgets('Pro: a duplicate name cannot be saved', (tester) async {
      ProController.instance.debugOverride = true;
      await pump(tester, const CategoryEditorScreen());
      await tester.enterText(find.byType(TextField), 'gaming');
      await tester.pumpAndSettle();
      expect(find.text('A category with this name already exists'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(SubscriptionStore.instance.customCategories, isEmpty);
    });
  });

  group('Annual plan price', () {
    testWidgets('free: the row is locked and no saving is shown', (tester) async {
      await pump(tester, SubscriptionDetailScreen(subscription: monthly));
      await tester.scrollUntilVisible(find.text('Annual plan price'), 300);
      await tester.tap(find.text('Annual plan price'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
    });

    testWidgets('Pro: the saving shows under the estimated annual cost', (tester) async {
      ProController.instance.debugOverride = true;
      await pump(tester, SubscriptionDetailScreen(subscription: monthly));
      await tester.scrollUntilVisible(find.text('Switch to yearly'), 300);
      expect(find.textContaining('Save \$20'), findsOneWidget);
    });
  });

  group('Analytics', () {
    testWidgets('free: year-end projection is a locked row; no yearly savings section', (tester) async {
      await pump(tester, const AnalyticsScreen());
      await tester.scrollUntilVisible(find.text('Year-end projection'), 300);
      expect(find.text('Year-end projection'), findsOneWidget);
      expect(find.text('Switch to yearly'), findsNothing);
    });

    testWidgets('Pro: year-end row in the hero and yearly savings', (tester) async {
      ProController.instance.debugOverride = true;
      await pump(tester, const AnalyticsScreen());
      // Tracking started today, so the row names the months left rather than the whole year.
      final label = switch (now.month) {
        1 => 'On track for ${now.year}',
        12 => 'Dec ${now.year}',
        _ => '${DateFormat('MMM').format(now)} – Dec ${now.year}',
      };
      await tester.scrollUntilVisible(find.text(label), 300);
      expect(find.text(label), findsOneWidget);
      expect(find.textContaining('spent so far'), findsOneWidget);
      expect(find.byType(OneUIAnalyticsHeroCard, skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Save \$20 a year'), 300);
      expect(find.text('Save \$20 a year'), findsOneWidget);
    });
  });
}
