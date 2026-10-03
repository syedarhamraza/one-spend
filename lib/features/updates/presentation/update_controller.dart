import 'package:flutter/foundation.dart';

import '../../../core/di/injection.dart';
import '../data/update_service.dart';

/// State of "Check for updates", shared by Settings and About.
enum UpdateStatus { notChecked, checking, upToDate, available, notFromPlay, failed }

/// Checks Google Play for a newer OneSpend and installs it with Play's full-screen updater.
///
/// The app also calls [check] once per launch, after the first frame. That result only
/// shows as a dot on the About row and the "Check for updates" row, never as a pop-up.
class UpdateController extends ChangeNotifier {
  final UpdateService service;

  UpdateController({required this.service});

  static UpdateController get instance {
    if (!sl.isRegistered<UpdateController>()) setupDependencies();
    return sl<UpdateController>();
  }

  UpdateStatus _status = UpdateStatus.notChecked;
  DateTime? _lastChecked;
  bool _installing = false;

  UpdateStatus get status => _status;
  DateTime? get lastChecked => _lastChecked;
  bool get updateAvailable => _status == UpdateStatus.available;
  bool get installing => _installing;

  /// Asks Play for updates. Returns the new status.
  Future<UpdateStatus> check() async {
    if (_status == UpdateStatus.checking) return _status;
    _set(UpdateStatus.checking);
    final result = await service.check();
    _lastChecked = DateTime.now();
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
      return await service.installNow();
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
