import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/features/reports/presentation/export_share_screen.dart';
import 'package:onespend/screens/analytics_screen.dart';
import 'package:onespend/screens/category_editor_screen.dart';
import 'package:onespend/screens/category_picker_screen.dart';
import 'package:onespend/screens/one_ui_field_editor_screen.dart';
import 'package:onespend/screens/settings/appearance_settings_screen.dart';
import 'package:onespend/screens/subscription_card_customizer_screen.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_analytics_hero_card.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
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
    testWidgets('create a category and it gets selected', (tester) async {
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

    testWidgets('a duplicate name cannot be saved', (tester) async {
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
    testWidgets('the row opens its editor', (tester) async {
      await pump(tester, SubscriptionDetailScreen(subscription: monthly));
      await tester.scrollUntilVisible(find.text('Annual plan price'), 300);
      await tester.tap(find.text('Annual plan price'));
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is OneUIFieldEditorScreen), findsOneWidget);
    });

    testWidgets('the saving shows under the estimated annual cost', (tester) async {
      await pump(tester, SubscriptionDetailScreen(subscription: monthly));
      await tester.scrollUntilVisible(find.text('Switch to yearly'), 300);
      expect(find.textContaining('Save \$20'), findsOneWidget);
    });
  });

  group('Analytics', () {
    testWidgets('year-end row in the hero and yearly savings', (tester) async {
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

  group('Formerly Pro', () {
    testWidgets('the studios open straight from Appearance', (tester) async {
      await pump(tester, const AppearanceSettingsScreen());
      await tester.tap(find.text('Subscription cards'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionCardCustomizerScreen), findsOneWidget);
    });

    testWidgets('the PDF export row shows the share icon like the others', (tester) async {
      await pump(tester, const ExportShareScreen());
      final pdfRow = find.ancestor(of: find.text('PDF report'), matching: find.byType(OneUIGroupItemTile));
      expect(find.descendant(of: pdfRow, matching: find.byIcon(Icons.ios_share_rounded)), findsOneWidget);
    });
  });
}
