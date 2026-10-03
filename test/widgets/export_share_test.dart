import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/reports/presentation/export_share_screen.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/subscription_detail_screen.dart';
import 'package:onespend/screens/subscriptions_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_menu.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    SubscriptionStore.instance.resetForTesting();
    // PDF sharing is a Pro feature; the locked state is covered in pro_gate_test.dart.
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(screen, theme: OneUITheme.darkTheme));
    await tester.pumpAndSettle();
  }

  testWidgets('offers PDF, CSV, text and backup', (tester) async {
    await pump(tester, const ExportShareScreen());
    for (final label in ['PDF report', 'Spreadsheet (CSV)', 'Text summary', 'Backup file']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('a category export says so and leaves out the backup', (tester) async {
    await pump(tester, const ExportShareScreen(category: SubscriptionCategory.music));
    expect(find.text('Only ${SubscriptionCategory.music.label} subscriptions are included.'), findsOneWidget);
    expect(find.text('Backup file'), findsNothing);
  });

  testWidgets('with nothing to export it says so instead of sharing an empty report', (tester) async {
    SubscriptionStore.instance.clearAllData();
    await pump(tester, const ExportShareScreen());
    await tester.tap(find.text('PDF report'));
    await tester.pump();
    expect(find.text('Add a subscription first'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('Share on a subscription opens the More-style menu: PDF or text', (tester) async {
    final sub = SubscriptionStore.instance.subscriptions.first;
    await pump(tester, SubscriptionDetailScreen(subscription: sub));
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(OneUIFloatingMenu.isOpen.value, isTrue);
    expect(find.text('Share as PDF'), findsOneWidget);
    expect(find.text('Share as text'), findsOneWidget);
    // Anchored above the Share button, like the More menu.
    expect(tester.getBottomLeft(find.text('Share as text')).dy, lessThan(tester.getTopLeft(find.text('Share')).dy));
  });

  testWidgets('Share in selection mode opens the same menu', (tester) async {
    await pump(tester, const SubscriptionsScreen());
    await tester.longPress(find.text('Netflix').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(OneUIFloatingMenu.isOpen.value, isTrue);
    expect(find.text('Share as PDF'), findsOneWidget);
    expect(find.text('Share as text'), findsOneWidget);
  });
}
