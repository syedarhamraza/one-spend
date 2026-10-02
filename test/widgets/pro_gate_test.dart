import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/pro/presentation/pro_controller.dart';
import 'package:onespend/features/pro/presentation/pro_screen.dart';
import 'package:onespend/features/reports/presentation/export_share_screen.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/appearance_settings_screen.dart';
import 'package:onespend/screens/subscription_card_customizer_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
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

  group('without Pro', () {
    testWidgets('the studios show a Pro chip and open the Pro page', (tester) async {
      await pump(tester, const AppearanceSettingsScreen());
      expect(find.byType(OneUIProChip), findsNWidgets(2));

      await tester.tap(find.text('Subscription cards'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
      expect(find.byType(SubscriptionCardCustomizerScreen), findsNothing);
      expect(find.text('Restore purchase'), findsOneWidget);
      expect(find.text('Redeem a code'), findsOneWidget);
    });

    testWidgets('the PDF export is locked; CSV and text are not', (tester) async {
      await pump(tester, const ExportShareScreen());
      expect(find.byType(OneUIProChip), findsOneWidget);

      await tester.tap(find.text('PDF report'));
      await tester.pumpAndSettle();
      expect(find.byType(ProScreen), findsOneWidget);
    });
  });

  group('with Pro', () {
    setUp(() => ProController.instance.debugOverride = true);

    testWidgets('the studios open and show no Pro chip', (tester) async {
      await pump(tester, const AppearanceSettingsScreen());
      expect(find.byType(OneUIProChip), findsNothing);

      await tester.tap(find.text('Subscription cards'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionCardCustomizerScreen), findsOneWidget);
    });

    testWidgets('the Pro page thanks the user and offers no purchase', (tester) async {
      await pump(tester, const ProScreen());
      expect(find.text('You have Pro'), findsOneWidget);
      expect(find.textContaining('Get Pro'), findsNothing);
    });
  });
}
