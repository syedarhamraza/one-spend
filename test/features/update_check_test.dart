import 'dart:async';

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
import 'package:onespend/core/config/app_version.dart';
import 'package:onespend/core/config/changelog.dart';
import 'package:onespend/features/settings/domain/repositories/settings_repository.dart';
import 'package:onespend/screens/settings/changelog_screen.dart';
import 'package:onespend/screens/settings/software_update_screen.dart';
import 'package:onespend/screens/settings_screen.dart';
import 'package:onespend/widgets/one_ui_floating_modal.dart';
import 'package:onespend/widgets/one_ui_group_card.dart';
import 'package:onespend/widgets/one_ui_subpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

class _FakeNetwork implements NetworkStatus {
  bool wifi = true;
  bool connected = true;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<bool> onUnmeteredNetwork() async => connected && wifi;
}

class _FakeUpdateService implements UpdateService {
  UpdateCheckResult next = UpdateCheckResult.upToDate;
  UpdateInstallResult installResult = UpdateInstallResult.started;
  int checks = 0;
  int installs = 0;
  int downloads = 0;
  int installedDownloads = 0;

  /// When set, startDownload waits for it, like Play does until the download is done.
  Completer<UpdateInstallResult>? download;
  final states = StreamController<UpdateDownloadState>.broadcast();

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

  @override
  Future<UpdateInstallResult> startDownload() {
    downloads++;
    return download?.future ?? Future.value(installResult);
  }

  @override
  Stream<UpdateDownloadState> get downloadStates => states.stream;

  @override
  Future<bool> installDownloaded() async {
    installedDownloads++;
    return true;
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

    Map<String, Object?> info(
      int availability, {
      bool immediateAllowed = true,
      bool flexibleAllowed = true,
      int installStatus = 0,
    }) => {
      'updateAvailability': availability,
      'immediateAllowed': immediateAllowed,
      'flexibleAllowed': flexibleAllowed,
      'availableVersionCode': 7,
      'installStatus': installStatus,
      'packageName': 'com.syedarhamraza.onespend',
      'clientVersionStalenessDays': null,
      'updatePriority': 0,
    };

    test('maps what Play reports', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond((_) => info(2));
      expect(await service.check(), UpdateCheckResult.available);
      // Either flow is enough; startDownload falls back to the full-screen one.
      respond((_) => info(2, immediateAllowed: false));
      expect(await service.check(), UpdateCheckResult.available);
      respond((_) => info(2, flexibleAllowed: false));
      expect(await service.check(), UpdateCheckResult.available);
      respond((_) => info(2, immediateAllowed: false, flexibleAllowed: false));
      expect(await service.check(), UpdateCheckResult.upToDate);
      respond((_) => info(1));
      expect(await service.check(), UpdateCheckResult.upToDate);
      respond((_) => info(3));
      expect(await service.check(), UpdateCheckResult.inProgress);
    });

    test('a background download shows up in the check', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond((_) => info(3, installStatus: 2));
      expect(await service.check(), UpdateCheckResult.downloading);
      respond((_) => info(2, installStatus: 11));
      expect(await service.check(), UpdateCheckResult.downloaded);
    });

    test('a background download is used when Play allows it, the full-screen one otherwise', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      final calls = <String>[];
      respond((call) {
        calls.add(call.method);
        return call.method == 'checkForUpdate' ? info(2, flexibleAllowed: calls.length > 2) : null;
      });
      await service.check(); // flexible not allowed
      expect(await service.startDownload(), UpdateInstallResult.started);
      await service.check(); // flexible allowed
      expect(await service.startDownload(), UpdateInstallResult.started);
      expect(calls, ['checkForUpdate', 'performImmediateUpdate', 'checkForUpdate', 'startFlexibleUpdate']);
    });

    test('a build not installed from Play is told apart from a failure', () async {
      final service = PlayUpdateService(isAndroid: true, installer: () async => PlayUpdateService.playStoreInstaller);
      respond(
        (_) => throw PlatformException(
          code: 'TASK_FAILURE',
          message: '-10: Install Error(-10): The app is not owned by any user on this device.',
        ),
      );
      expect(await service.check(), UpdateCheckResult.notFromPlay);

      respond(
        (_) => throw PlatformException(code: 'TASK_FAILURE', message: '-100: Install Error(-100): Internal error.'),
      );
      expect(await service.check(), UpdateCheckResult.failed);
    });

    test('a copy Play did not install is not from Play, without asking Play', () async {
      var asked = false;
      respond((_) {
        asked = true;
        return info(1);
      });
      expect(
        await PlayUpdateService(isAndroid: true, installer: () async => null).check(),
        UpdateCheckResult.notFromPlay,
      );
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

    test('a background download from an earlier session is picked up', () async {
      service.next = UpdateCheckResult.downloaded;
      expect(await controller.check(), UpdateStatus.readyToInstall);
      expect(controller.updateAvailable, isTrue);
      expect(await controller.installAndRestart(), isTrue);
      expect(service.installedDownloads, 1);
    });

    test('downloading in the background, then ready to install', () async {
      service.next = UpdateCheckResult.available;
      await controller.check();
      service.download = Completer();
      final download = controller.download();
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, UpdateStatus.downloading);
      expect(controller.updateAvailable, isTrue);
      expect(await controller.check(), UpdateStatus.downloading); // no second check meanwhile
      expect(service.checks, 1);

      service.download!.complete(UpdateInstallResult.started);
      expect(await download, UpdateDownloadResult.started);
      expect(controller.status, UpdateStatus.readyToInstall);
    });

    test('a declined download goes back to available', () async {
      service.next = UpdateCheckResult.available;
      await controller.check();
      service.installResult = UpdateInstallResult.declined;
      expect(await controller.download(), UpdateDownloadResult.declined);
      expect(controller.status, UpdateStatus.available);
    });

    test('a download Play gives up on goes back to available', () async {
      service.next = UpdateCheckResult.available;
      await controller.check();
      service.download = Completer();
      unawaited(controller.download());
      await Future<void>.delayed(Duration.zero);
      service.states.add(UpdateDownloadState.failed);
      await Future<void>.delayed(Duration.zero);
      expect(controller.status, UpdateStatus.available);
    });

    test('offline: Play is not asked, and nothing downloads', () async {
      final network = _FakeNetwork()..connected = false;
      final offline = UpdateController(service: service, network: network);
      expect(await offline.check(), UpdateStatus.offline);
      expect(service.checks, 0);

      network.connected = true;
      service.next = UpdateCheckResult.available;
      expect(await offline.check(), UpdateStatus.available);
      network.connected = false;
      expect(await offline.download(), UpdateDownloadResult.offline);
      expect(service.downloads, 0);
      expect(offline.status, UpdateStatus.available);
    });

    test('reopening the page forgets a settled check but keeps a found update', () async {
      for (final result in [UpdateCheckResult.upToDate, UpdateCheckResult.failed, UpdateCheckResult.notFromPlay]) {
        service.next = result;
        await controller.check();
        controller.resetSettledResult();
        expect(controller.status, UpdateStatus.notChecked, reason: result.name);
      }

      service.next = UpdateCheckResult.available;
      await controller.check();
      controller.resetSettledResult();
      expect(controller.status, UpdateStatus.available);

      service.next = UpdateCheckResult.downloaded;
      final fresh = UpdateController(service: service);
      await fresh.check();
      fresh.resetSettledResult();
      expect(fresh.status, UpdateStatus.readyToInstall);
    });

    test('a tapped check shows the dots for a minimum time; the launch check does not wait', () async {
      final slow = UpdateController(service: service, minCheckDuration: const Duration(milliseconds: 300));
      final watch = Stopwatch()..start();
      await slow.check();
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(290));

      watch.reset();
      await slow.check(quick: true);
      expect(watch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('Auto check', () {
    late _FakeUpdateService service;
    late _FakeNetwork network;

    setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

    setUp(() {
      service = _FakeUpdateService();
      network = _FakeNetwork();
      setupDependencies(database: AppDatabase.forTesting(NativeDatabase.memory()));
    });

    UpdateController controllerFor() =>
        UpdateController(service: service, settings: sl<SettingsRepository>(), network: network);

    test('is off by default', () async {
      final controller = controllerFor();
      await controller.loadPreferences();
      expect(controller.autoCheckMode, AutoUpdateCheck.never);
      expect(await controller.autoCheck(), isFalse);
      expect(service.checks, 0);
      expect(controller.status, UpdateStatus.notChecked);
    });

    test('any network checks on mobile data, but stays quiet offline', () async {
      final controller = controllerFor();
      await controller.setAutoCheck(AutoUpdateCheck.always);
      network.wifi = false;
      expect(await controller.autoCheck(), isTrue);
      expect(service.checks, 1);

      final offline = controllerFor();
      await offline.setAutoCheck(AutoUpdateCheck.always);
      network.connected = false;
      expect(await offline.autoCheck(), isFalse);
      expect(offline.status, UpdateStatus.notChecked); // no "failed", no dot
      expect(service.checks, 1);
    });

    test('Never skips the launch check; Wi-Fi only waits for Wi-Fi', () async {
      final controller = controllerFor();
      await controller.setAutoCheck(AutoUpdateCheck.never);
      expect(await controller.autoCheck(), isFalse);

      await controller.setAutoCheck(AutoUpdateCheck.wifiOnly);
      network.wifi = false;
      expect(await controller.autoCheck(), isFalse);
      network.wifi = true;
      expect(await controller.autoCheck(), isTrue);
      expect(service.checks, 1);
    });

    test('the choice is saved', () async {
      await controllerFor().setAutoCheck(AutoUpdateCheck.wifiOnly);
      final reloaded = controllerFor();
      await reloaded.loadPreferences();
      expect(reloaded.autoCheckMode, AutoUpdateCheck.wifiOnly);
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
      sl.registerSingleton<UpdateController>(UpdateController(service: service, settings: sl<SettingsRepository>()));
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

    testWidgets('Software update: with auto-check off, the page opens ready to check', (tester) async {
      await UpdateController.instance.autoCheck(); // what the app does at launch
      await pump(tester, const SoftwareUpdateScreen());
      expect(service.checks, 0);
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('One Spend is up to date.'), findsNothing);

      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('One Spend is up to date.'), findsOneWidget);
      expect(find.text('Check for updates'), findsNothing); // the button fades out
    });

    testWidgets('Software update: leaving and coming back offers Check for updates again', (tester) async {
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('One Spend is up to date.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await pump(tester, const SoftwareUpdateScreen());
      expect(find.text('Check for updates'), findsOneWidget);
      expect(find.text('One Spend is up to date.'), findsNothing);
    });

    testWidgets('Software update: download in the background, then install and restart', (tester) async {
      service.next = UpdateCheckResult.available;
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('A new version is available.'), findsOneWidget);
      expect(service.downloads, 0); // waits for a second tap

      service.download = Completer();
      await tester.tap(find.text('Download and install'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Downloading the update'), findsOneWidget);

      service.download!.complete(UpdateInstallResult.started);
      await tester.pumpAndSettle();
      expect(find.text('The update is ready to install.'), findsOneWidget);

      await tester.tap(find.text('Install and restart'));
      await tester.pumpAndSettle();
      expect(service.installedDownloads, 1);
      expect(service.installs, 0); // never Play's full-screen updater
    });

    testWidgets('Software update: a declined download says so and offers it again', (tester) async {
      service.next = UpdateCheckResult.available;
      service.installResult = UpdateInstallResult.declined;
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Download and install'));
      await tester.pump();
      expect(find.textContaining('Update cancelled'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Download and install'), findsOneWidget);
    });

    testWidgets('Software update: offline says so, and Try again checks once connected', (tester) async {
      final network = _FakeNetwork()..connected = false;
      sl.unregister<UpdateController>();
      sl.registerSingleton<UpdateController>(UpdateController(service: service, network: network));
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No internet connection'), findsOneWidget);
      expect(service.checks, 0);

      network.connected = true;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(service.checks, 1);
      expect(find.text('One Spend is up to date.'), findsOneWidget);
    });

    testWidgets('Software update: a copy not from Play says so', (tester) async {
      service.next = UpdateCheckResult.notFromPlay;
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.textContaining("wasn't installed from Play"), findsOneWidget);
    });

    testWidgets('Software update: a failed check offers Try again', (tester) async {
      service.next = UpdateCheckResult.failed;
      await pump(tester, const SoftwareUpdateScreen());
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't reach Google Play."), findsOneWidget);

      service.next = UpdateCheckResult.upToDate;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(service.checks, 2);
    });

    Future<void> openMenuItem(WidgetTester tester, String label) async {
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets('Software update menu: Software information', (tester) async {
      await pump(tester, const SoftwareUpdateScreen());
      await openMenuItem(tester, 'Software information');
      expect(find.textContaining('Version: '), findsOneWidget);
      expect(find.textContaining('Installed from: '), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Software information'), findsNothing);
    });

    testWidgets('Software update menu: Auto download saves the choice', (tester) async {
      await pump(tester, const SoftwareUpdateScreen());
      await openMenuItem(tester, 'Auto download');
      await tester.tap(find.text(AutoUpdateCheck.wifiOnly.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byType(SoftwareUpdateScreen), findsOneWidget); // back on the page
      expect(UpdateController.instance.autoCheckMode, AutoUpdateCheck.wifiOnly);
    });

    testWidgets('Software update menu: Changelog shows the installed version and folds the rest', (tester) async {
      await pump(tester, const SoftwareUpdateScreen());
      await openMenuItem(tester, 'Changelog');
      expect(find.byType(ChangelogScreen), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
      expect(find.text(Changelog.entries.first.changes.first), findsOneWidget);

      final older = Changelog.entries[1];
      final olderTitle = find.text(AppVersion.describe(older.version));
      await tester.scrollUntilVisible(olderTitle, 200);
      expect(find.text(older.changes.first), findsNothing);
      await tester.tap(olderTitle);
      await tester.pumpAndSettle();
      expect(find.text(older.changes.first), findsOneWidget);
    });

    testWidgets('Settings: only the Software update row gets a dot, when an update is available', (tester) async {
      await pump(tester, const SettingsScreen());
      await tester.scrollUntilVisible(find.text('About One Spend'), 200);
      expect(find.descendant(of: rowWith('Software update'), matching: find.byType(OneUIDot)), findsNothing);

      service.next = UpdateCheckResult.available;
      await UpdateController.instance.check();
      await tester.pumpAndSettle();
      expect(find.descendant(of: rowWith('Software update'), matching: find.byType(OneUIDot)), findsOneWidget);
      expect(find.descendant(of: rowWith('About One Spend'), matching: find.byType(OneUIDot)), findsNothing);
    });
  });
}
