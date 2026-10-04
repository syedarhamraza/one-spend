import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/config/app_info.dart';
import 'package:onespend/core/config/feature_flags.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/home_screen.dart';
import 'package:onespend/screens/settings/about_screen.dart';
import 'package:onespend/screens/settings/author_screen.dart';
import 'package:onespend/screens/settings/licenses_screen.dart';
import 'package:onespend/screens/settings/settings_catalog.dart';
import 'package:onespend/screens/settings_screen.dart';
import 'package:onespend/theme/one_ui_theme.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
import 'package:onespend/widgets/one_ui_switch.dart';
import 'package:onespend/widgets/one_ui_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    LicenseRegistry.addLicense(
      () => Stream.value(const LicenseEntryWithLineBreaks(['test_package'], 'Test licence text.')),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    OneUIFloatingModal.isModalOpen.value = false;
    HomeChrome.reset();
    SubscriptionStore.instance.resetForTesting();
    OneUIEffectsController.instance.floating3dEffect = false;
    FeatureFlags.showPlannedFeatures = true;
  });

  tearDown(OneUIToast.dismiss);

  Future<void> pumpSettings(WidgetTester tester, {bool developer = false}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(routedTestApp(SettingsScreen(showDeveloperOptions: developer)));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
    await tester.pumpAndSettle();
  }

  testWidgets('main page is titles only: no switches, subtitles or profile card', (tester) async {
    await pumpSettings(tester);
    for (final title in [
      'Budget & currency',
      'Notifications',
      'Payment methods',
      'Appearance',
      'Widgets',
      'Security & privacy',
      'Backup & data',
      'Help & feedback',
      'About One Spend',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.byType(OneUISwitch), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Your name'), findsNothing);
    final items = tester
        .widgetList<OneUIGroupCard>(find.byType(OneUIGroupCard))
        .expand((card) => card.items);
    expect(items.every((i) => i.subtitle == null && i.customSubtitle == null), isTrue);
    expect(find.text('Developer options'), findsNothing);
  });

  testWidgets('developer options appear only when enabled', (tester) async {
    await pumpSettings(tester, developer: true);
    await tester.scrollUntilVisible(find.text('Developer options'), 200);
    await tester.tap(find.text('Developer options'));
    await tester.pumpAndSettle();
    expect(find.text('Load sample subscriptions'), findsOneWidget);
  });

  testWidgets('every row opens its subpage', (tester) async {
    await pumpSettings(tester);
    const expectations = {
      'Budget & currency': 'Monthly budget',
      'Notifications': 'Default reminder',
      'Appearance': '3D floating elements',
      'Widgets': 'Coming soon',
      'Security & privacy': 'App lock',
      'Backup & data': 'Save backup to device',
      'Help & feedback': 'Send feedback',
      'About One Spend': 'Open source licences',
    };
    for (final e in expectations.entries) {
      await tester.scrollUntilVisible(find.text(e.key), 200);
      await tester.tap(find.text(e.key));
      await tester.pumpAndSettle();
      expect(find.text(e.value), findsWidgets, reason: e.key);
      await back(tester);
    }
  });

  testWidgets('main currency picker saves the chosen ISO code', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Budget & currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Euro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.currency, 'EUR');
    expect(find.text('EUR · Euro'), findsOneWidget);
  });

  testWidgets('Appearance has one 3D switch that drives floating3dEffect', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.byType(OneUISwitch), findsOneWidget);
    await tester.tap(find.text('3D floating elements'));
    await tester.pumpAndSettle();
    expect(OneUIEffectsController.instance.floating3dEffect, isTrue);
    expect(OneUIEffectsController.instance.floatingGradient, isNotNull, reason: 'the nav bar always has a fill');
    await tester.tap(find.byType(OneUISwitch));
    await tester.pumpAndSettle();
    expect(OneUIEffectsController.instance.floating3dEffect, isFalse);
  });

  testWidgets('Notifications master switch toggles and dims the reminders', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.notificationsEnabled, isTrue);
    await tester.tap(find.text('On'));
    await tester.pumpAndSettle();
    expect(SubscriptionStore.instance.notificationsEnabled, isFalse);
    expect(find.text('Off'), findsOneWidget);
  });

  testWidgets('search finds rows and options, and opens the subpage', (tester) async {
    await pumpSettings(tester);
    await tester.tap(find.byTooltip('Search settings'));
    await tester.pumpAndSettle();
    expect(HomeChrome.settingsSearchActive.value, isTrue);

    await tester.enterText(find.byType(TextField), 'csv');
    await tester.pumpAndSettle();
    expect(find.text('Export & share'), findsOneWidget);
    expect(find.text('Settings › Backup & data'), findsOneWidget);

    await tester.tap(find.text('Export & share'));
    await tester.pumpAndSettle();
    expect(find.text('Clear all subscriptions'), findsOneWidget);
  });

  testWidgets('release builds hide every placeholder', (tester) async {
    FeatureFlags.showPlannedFeatures = false;
    addTearDown(() => FeatureFlags.showPlannedFeatures = true);
    await pumpSettings(tester);

    expect(find.text('Widgets'), findsNothing);
    expect(find.byType(OneUISoonChip), findsNothing);
    expect(SettingsCatalog.search('app lock', developerOptions: false), isEmpty);
    expect(SettingsCatalog.search('privacy policy', developerOptions: false), isNotEmpty);
    expect(SettingsCatalog.search('drive', developerOptions: false), isEmpty);
    expect(SettingsCatalog.search('restore', developerOptions: false), isNotEmpty);

    // Subpages drop their placeholder rows too.
    await tester.tap(find.text('Security & privacy'));
    await tester.pumpAndSettle();
    expect(find.text('App lock'), findsNothing);
    expect(find.text('Privacy policy'), findsOneWidget);
    await back(tester);
    await tester.tap(find.text('Budget & currency'));
    await tester.pumpAndSettle();
    expect(find.text('Multiple currencies'), findsNothing);
    await back(tester);
    await tester.tap(find.text('Backup & data'));
    await tester.pumpAndSettle();
    expect(find.text('Automatic backups'), findsNothing);
    expect(find.text('Save backup to device'), findsOneWidget);
    await back(tester);
    await tester.scrollUntilVisible(find.text('Help & feedback'), 200);
    await tester.tap(find.text('Help & feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Rate One Spend'), findsNothing);
  });

  testWidgets('debug builds show the Drive backup as Soon', (tester) async {
    await pumpSettings(tester);
    await tester.scrollUntilVisible(find.text('Backup & data'), 200);
    await tester.tap(find.text('Backup & data'));
    await tester.pumpAndSettle();
    final driveRow = find.ancestor(of: find.text('Automatic backups'), matching: find.byType(OneUIGroupItemTile));
    expect(find.descendant(of: driveRow, matching: find.byType(OneUISoonChip)), findsOneWidget);
    expect(find.text('Never saved'), findsOneWidget);
  });

  test('catalog search is case-insensitive and lists rows before options', () {
    final results = SettingsCatalog.search('NOTIF', developerOptions: false);
    expect(results.first.title, 'Notifications');
    expect(results.first.path, isNull);
    expect(SettingsCatalog.search('   ', developerOptions: false), isEmpty);
    expect(SettingsCatalog.search('sample', developerOptions: false), isEmpty);
    expect(SettingsCatalog.search('sample', developerOptions: true), isNotEmpty);
  });

  testWidgets('About shows the app and opens licences and the developer page', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(routedTestApp(const AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text(AppInfo.name), findsOneWidget);
    expect(find.text(AppInfo.tagline), findsOneWidget);
    expect(find.text('About'), findsWidgets); // page title (not "About One Spend")
    expect(find.text('Source code'), findsNothing);

    await tester.tap(find.text('Open source licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensesScreen), findsOneWidget);
    expect(find.text('test_package'), findsOneWidget);
    await tester.tap(find.text('test_package'));
    await tester.pumpAndSettle();
    expect(find.text('Test licence text.'), findsOneWidget);
    await back(tester);
    await back(tester);

    await tester.tap(find.text('Developer'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthorScreen), findsOneWidget);
  });

  testWidgets('developer page shows filled details and hides empty ones', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(routedTestApp(const AuthorScreen()));
    await tester.pumpAndSettle();
    expect(find.text(AuthorInfo.name), findsOneWidget);
    expect(find.text('Email'), AuthorInfo.email.isEmpty ? findsNothing : findsOneWidget);
    expect(find.text('LinkedIn'), AuthorInfo.linkedInUrl.isEmpty ? findsNothing : findsOneWidget);
    expect(find.text('Website'), AuthorInfo.websiteUrl.isEmpty ? findsNothing : findsOneWidget);
    expect(find.text('One Spend source code'), findsNothing); // closed source
  });
}
