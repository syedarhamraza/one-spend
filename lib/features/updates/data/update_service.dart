import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/telemetry/telemetry.dart';

/// What Google Play says about updates for this install.
enum UpdateCheckResult {
  /// This is the newest version on the user's Play track.
  upToDate,

  /// A newer version can be installed now.
  available,

  /// An update started earlier didn't finish (e.g. the app was closed); resume it.
  inProgress,

  /// Not installed from Google Play (a `flutter run` or sideloaded build), or Play is missing.
  notFromPlay,

  /// Play couldn't be reached.
  failed,
}

/// How an install attempt ended.
enum UpdateInstallResult { started, declined, failed }

/// When One Spend checks Google Play for updates on its own, at launch
/// (Software update › Auto download).
enum AutoUpdateCheck {
  never('Never'),
  wifiOnly('Using Wi-Fi only'),
  always('Using Wi-Fi or mobile data');

  final String label;

  const AutoUpdateCheck(this.label);
}

/// Whether the phone is on an unmetered network, for [AutoUpdateCheck.wifiOnly].
abstract class NetworkStatus {
  Future<bool> onUnmeteredNetwork();
}

/// Used in tests: always on Wi-Fi.
class AnyNetworkStatus implements NetworkStatus {
  const AnyNetworkStatus();

  @override
  Future<bool> onUnmeteredNetwork() async => true;
}

/// Wi-Fi or ethernet counts as unmetered. If the plugin fails, assume mobile data.
class ConnectivityNetworkStatus implements NetworkStatus {
  @override
  Future<bool> onUnmeteredNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }
}

/// Platform boundary for Google Play in-app updates.
abstract class UpdateService {
  Future<UpdateCheckResult> check();

  /// Opens Play's full-screen updater. Only valid right after [check] returned
  /// [UpdateCheckResult.available] or [UpdateCheckResult.inProgress].
  Future<UpdateInstallResult> installNow();
}

/// Used in tests and on platforms without Google Play.
class NoopUpdateService implements UpdateService {
  @override
  Future<UpdateCheckResult> check() async => UpdateCheckResult.notFromPlay;

  @override
  Future<UpdateInstallResult> installNow() async => UpdateInstallResult.failed;
}

/// Google Play In-App Updates (immediate flow). Needs a foreground activity, so call it
/// after the first frame, not during startup.
class PlayUpdateService implements UpdateService {
  /// Package name of the Play Store, the installer of every copy Play can update
  /// (Production, testing tracks and internal app sharing alike).
  static const playStoreInstaller = 'com.android.vending';

  // Play Core install error codes meaning "no Play to update from".
  static const _notFromPlayCodes = ['-10', '-9', '-3']; // app not owned, Play Store missing, API unavailable

  final bool _isAndroid;
  final Future<String?> Function() _installer;

  PlayUpdateService({@visibleForTesting bool? isAndroid, @visibleForTesting Future<String?> Function()? installer})
      : _isAndroid = isAndroid ?? Platform.isAndroid,
        _installer = installer ?? _installerStore;

  static Future<String?> _installerStore() async {
    try {
      return (await PackageInfo.fromPlatform()).installerStore;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UpdateCheckResult> check() async {
    if (!_isAndroid) return UpdateCheckResult.notFromPlay;
    // Play answers "no update" for copies it didn't install (e.g. `flutter run`), so ask first.
    if (await _installer() != playStoreInstaller) return UpdateCheckResult.notFromPlay;
    try {
      final info = await play.InAppUpdate.checkForUpdate();
      switch (info.updateAvailability) {
        case play.UpdateAvailability.updateAvailable:
          return info.immediateUpdateAllowed ? UpdateCheckResult.available : UpdateCheckResult.upToDate;
        case play.UpdateAvailability.developerTriggeredUpdateInProgress:
          return UpdateCheckResult.inProgress;
        case play.UpdateAvailability.updateNotAvailable:
          return UpdateCheckResult.upToDate;
        case play.UpdateAvailability.unknown:
          return UpdateCheckResult.failed;
      }
    } on MissingPluginException {
      return UpdateCheckResult.notFromPlay;
    } on PlatformException catch (e) {
      final message = e.message ?? '';
      if (_notFromPlayCodes.any((code) => message.contains('($code)') || message.startsWith('$code:'))) {
        return UpdateCheckResult.notFromPlay;
      }
      AppLog.info('Update check failed: ${e.code} ${e.message}');
      return UpdateCheckResult.failed;
    } catch (e) {
      AppLog.info('Update check failed: ${e.runtimeType}');
      return UpdateCheckResult.failed;
    }
  }

  @override
  Future<UpdateInstallResult> installNow() async {
    try {
      return switch (await play.InAppUpdate.performImmediateUpdate()) {
        play.AppUpdateResult.success => UpdateInstallResult.started,
        play.AppUpdateResult.userDeniedUpdate => UpdateInstallResult.declined,
        play.AppUpdateResult.inAppUpdateFailed => UpdateInstallResult.failed,
      };
    } catch (e, stack) {
      AppLog.error(e, stack, reason: 'Update install failed');
      return UpdateInstallResult.failed;
    }
  }
}
