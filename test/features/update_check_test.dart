import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/database/app_database.dart';
import 'package:onespend/core/di/injection.dart';
import 'package:onespend/features/updates/data/update_service.dart';
import 'package:onespend/features/updates/presentation/update_controller.dart';
import 'package:onespend/models/subscription.dart';
import 'package:onespend/screens/settings/about_screen.dart';
import 'package:onespend/screens/settings_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

class _FakeUpdateService implements UpdateService {
  UpdateCheckResult next = UpdateCheckResult.upToDate;
  UpdateInstallResult installResult = UpdateInstallResult.started;
  int checks = 0;
  int installs = 0;

  @override
  Future<UpdateCheckResult> check() async {
    checks++;
    return next;
  }

  @override
  Future<UpdateInstallResult> installNow() async {
    installs++;
    return installResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayUpdateService', () {
    const channel = MethodChannel('de.ffuf.in_app_update/methods');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    void respond(Object? Function(MethodCall call) handler) =>
        messenger.setMockMethodCallHandler(channel, (call) async => handler(call));

    Map<String, Object?> info(int availability, {bool immediateAllowed = true}) => {
          'updateAvailability': availability,
          'immediateAllowed': immediateAllowed,
          'flexibleAllowed': true,
          'availableVersionCode': 7,
          'installStatus': 0,
          'packageName': 'com.syedarhamraza.onespend',
          'clientVersionStalenessDays': null,
          'updatePriority': 0,
        };

    test('maps what Play reports', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond((_) => info(2));
      expect(await service.check(), UpdateCheckResult.available);
      respond((_) => info(2, immediateAllowed: false));
      expect(await service.check(), UpdateCheckResult.upToDate);
      respond((_) => info(1));
      expect(await service.check(), UpdateCheckResult.upToDate);
      respond((_) => info(3));
      expect(await service.check(), UpdateCheckResult.inProgress);
    });

    test('a build not installed from Play is told apart from a failure', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond((_) => throw PlatformException(
            code: 'TASK_FAILURE',
            message: '-10: Install Error(-10): The app is not owned by any user on this device.',
          ));
      expect(await service.check(), UpdateCheckResult.notFromPlay);

      respond((_) => throw PlatformException(code: 'TASK_FAILURE', message: '-100: Install Error(-100): Internal error.'));
      expect(await service.check(), UpdateCheckResult.failed);
    });

    test('a copy Play did not install is not from Play, without asking Play', () async {
      var asked = false;
      respond((_) {
        asked = true;
        return info(1);
      });
      expect(await PlayUpdateService(isAndroid: true, installer: () async => null).check(), UpdateCheckResult.notFromPlay);
      expect(
        await PlayUpdateService(isAndroid: true, installer: () async => 'com.sec.android.app.samsungapps').check(),
        UpdateCheckResult.notFromPlay,
      );
      expect(asked, isFalse);
    });

    test('off Android there is nothing to check', () async {
      expect(await PlayUpdateService(isAndroid: false).check(), UpdateCheckResult.notFromPlay);
    });

    test('install results', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond((_) => null);
      expect(await service.installNow(), UpdateInstallResult.started);
      respond((_) => throw PlatformException(code: 'USER_DENIED_UPDATE'));
      expect(await service.installNow(), UpdateInstallResult.declined);
    });
  });

  group('UpdateController', () {
    late _FakeUpdateService service;
    late UpdateController controller;

    setUp(() {
      service = _FakeUpdateService();
      controller = UpdateController(service: service);
    });

    test('check reports each outcome', () async {
      expect(controller.status, UpdateStatus.notChecked);
      expect(await controller.check(), UpdateStatus.upToDate);
      expect(controller.lastChecked, isNotNull);
      service.next = UpdateCheckResult.available;
      expect(await controller.check(), UpdateStatus.available);
      expect(controller.updateAvailable, isTrue);
      service.next = UpdateCheckResult.notFromPlay;
      expect(await controller.check(), UpdateStatus.notFromPlay);
    });

    test('an interrupted update is resumed', () async {
      service.next = UpdateCheckResult.inProgress;
      await controller.check();
      expect(service.installs, 1);
    });

    test('install checks first when nothing is known to be available', () async {
      expect(await controller.install(), UpdateInstallResult.failed);
      expect(service.checks, 1);
      expect(service.installs, 0);

      service.next = UpdateCheckResult.available;
      expect(await controller.install(), UpdateInstallResult.started);
      expect(service.installs, 1);
    });
  });

  group('UI', () {
    late _FakeUpdateService service;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
      OneUIFloatingModal.isModalOpen.value = false;
      SubscriptionStore.instance.resetForTesting();
      service = _FakeUpdateService();
      sl.unregister<UpdateController>();
      sl.registerSingleton<UpdateController>(UpdateController(service: service));
    });

    Future<void> pump(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(routedTestApp(screen));
      await tester.pumpAndSettle();
    }

    Finder rowWith(String title) => find.ancestor(of: find.text(title), matching: find.byType(OneUIGroupItemTile));

    testWidgets('About: checking, then installing an available update', (tester) async {
      await pump(tester, const AboutScreen());
      expect(find.text('Check for updates'), findsOneWidget);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('One Spend is up to date'), findsOneWidget);
      expect(service.installs, 0);

      service.next = UpdateCheckResult.available;
      await UpdateController.instance.check();
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      expect(find.descendant(of: rowWith('Update available'), matching: find.byType(OneUIDot)), findsOneWidget);

      await tester.tap(find.text('Update available'));
      await tester.pumpAndSettle();
      expect(service.installs, 1);
    });

    testWidgets('About: a copy not from Play says so', (tester) async {
      service.next = UpdateCheckResult.notFromPlay;
      await pump(tester, const AboutScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.textContaining("wasn't installed from Play"), findsOneWidget);
    });

    testWidgets('Settings: the About row gets a dot only when an update is available', (tester) async {
      await pump(tester, const SettingsScreen());
      await tester.scrollUntilVisible(find.text('About One Spend'), 200);
      expect(find.descendant(of: rowWith('About One Spend'), matching: find.byType(OneUIDot)), findsNothing);

      service.next = UpdateCheckResult.available;
      await UpdateController.instance.check();
      await tester.pumpAndSettle();
      expect(find.descendant(of: rowWith('About One Spend'), matching: find.byType(OneUIDot)), findsOneWidget);
    });
  });
}
