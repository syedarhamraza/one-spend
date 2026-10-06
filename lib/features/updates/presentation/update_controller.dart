import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../../settings/domain/repositories/settings_repository.dart';
import '../data/update_service.dart';
import '../../../core/telemetry/events.dart';
import '../../../core/telemetry/telemetry.dart';

/// State of "Check for updates", shown on Settings › Software update.
enum UpdateStatus { notChecked, checking, upToDate, available, notFromPlay, failed }

/// Checks Google Play for a newer OneSpend and installs it with Play's full-screen updater.
///
/// The app also calls [autoCheck] once per launch, after the first frame. That result only
/// shows as a dot on the Software update row and on its page, never as a pop-up.
class UpdateController extends ChangeNotifier {
  final UpdateService service;
  final SettingsRepository? settings;
  final NetworkStatus _network;

  UpdateController({required this.service, this.settings, NetworkStatus? network})
      : _network = network ?? const AnyNetworkStatus();

  static UpdateController get instance {
    if (!sl.isRegistered<UpdateController>()) setupDependencies();
    return sl<UpdateController>();
  }

  UpdateStatus _status = UpdateStatus.notChecked;
  AutoUpdateCheck _autoCheck = AutoUpdateCheck.always;
  DateTime? _lastChecked;
  bool _installing = false;

  UpdateStatus get status => _status;
  DateTime? get lastChecked => _lastChecked;
  bool get updateAvailable => _status == UpdateStatus.available;
  bool get installing => _installing;

  /// When the launch check runs (Software update › Auto download).
  AutoUpdateCheck get autoCheckMode => _autoCheck;

  /// Reads the saved [autoCheckMode]. Awaited in `configureDependencies()`.
  Future<void> loadPreferences() async {
    final saved = await settings?.getAutoUpdateCheck();
    _autoCheck = AutoUpdateCheck.values.asNameMap()[saved] ?? AutoUpdateCheck.always;
    notifyListeners();
  }

  Future<void> setAutoCheck(AutoUpdateCheck mode) async {
    if (mode == _autoCheck) return;
    _autoCheck = mode;
    notifyListeners();
    await settings?.setAutoUpdateCheck(mode.name);
  }

  /// The once-per-launch check, honouring [autoCheckMode]. Returns whether it asked Play.
  Future<bool> autoCheck() async {
    switch (_autoCheck) {
      case AutoUpdateCheck.never:
        return false;
      case AutoUpdateCheck.wifiOnly:
        if (!await _network.onUnmeteredNetwork()) return false;
      case AutoUpdateCheck.always:
        break;
    }
    await check();
    return true;
  }

  /// Asks Play for updates. Returns the new status.
  Future<UpdateStatus> check() async {
    if (_status == UpdateStatus.checking) return _status;
    _set(UpdateStatus.checking);
    final result = await service.check();
    _lastChecked = DateTime.now();
    AppLog.event(TelemetryEvent.updateCheck(result.name));
    switch (result) {
      case UpdateCheckResult.upToDate:
        _set(UpdateStatus.upToDate);
      case UpdateCheckResult.available:
        _set(UpdateStatus.available);
      case UpdateCheckResult.inProgress:
        // Play's guidance: an immediate update that was interrupted should be resumed.
        _set(UpdateStatus.available);
        await install();
      case UpdateCheckResult.notFromPlay:
        _set(UpdateStatus.notFromPlay);
      case UpdateCheckResult.failed:
        _set(UpdateStatus.failed);
    }
    return _status;
  }

  /// Opens Play's updater for the available update. Play restarts the app when it's done.
  Future<UpdateInstallResult> install() async {
    if (_installing) return UpdateInstallResult.started;
    if (_status != UpdateStatus.available) {
      if (await check() != UpdateStatus.available) return UpdateInstallResult.failed;
    }
    _installing = true;
    notifyListeners();
    try {
      final result = await service.installNow();
      if (result == UpdateInstallResult.started) AppLog.event(TelemetryEvent.updateStarted);
      return result;
    } finally {
      _installing = false;
      notifyListeners();
    }
  }

  void _set(UpdateStatus status) {
    _status = status;
    notifyListeners();
  }
}
