import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../theme/one_ui_theme.dart';
import '../../settings/domain/repositories/settings_repository.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../domain/backup_codec.dart';
import '../domain/backup_merge.dart';
import '../domain/backup_snapshot.dart';

/// Creates and restores backups, and keeps restore points so no restore or wipe is final.
///
/// A **restore point** is a full backup file written to app storage right before
/// "Replace everything" or "Clear all subscriptions"; [undoLast] puts it back.
class BackupService {
  final SubscriptionController controller;
  final SettingsRepository settings;

  /// Where restore points live; defaults to the app documents directory.
  final Future<Directory> Function() _baseDirectory;
  final Future<String> Function() _appVersion;

  /// The last action this session that [undoLast] can revert ("Restore" or
  /// "Clear all"), or null. Screens offer an inline Undo while it is set.
  final ValueNotifier<String?> undoableAction = ValueNotifier(null);

  static const int maxRestorePoints = 3;

  BackupService({
    required this.controller,
    required this.settings,
    Future<Directory> Function()? baseDirectory,
    Future<String> Function()? appVersion,
  })  : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory,
        _appVersion = appVersion ?? _packageVersion;

  static Future<String> _packageVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } catch (_) {
      return '';
    }
  }

  /// The current data as a backup.
  Future<BackupSnapshot> createSnapshot({DateTime? now}) async {
    return BackupSnapshot(
      createdAt: now ?? DateTime.now(),
      appVersion: await _appVersion(),
      subscriptions: List.of(controller.subscriptions),
      paymentMethods: List.of(controller.paymentMethods),
      settings: (
        monthlyBudget: controller.monthlyBudget,
        currency: controller.currency,
        defaultReminderDays: controller.defaultReminderDays,
        defaultReminderTimeMinutes: controller.defaultReminderTimeMinutes,
        notificationsEnabled: controller.notificationsEnabled,
        sortOption: controller.sortOption,
        groupByDate: controller.groupByDate,
      ),
      appearance: await settings.getAppearanceSettings(),
      rateOverrides: controller.rates.overrides,
    );
  }

  /// The current data as backup file contents.
  Future<String> exportBackup({DateTime? now}) async => BackupCodec.encode(await createSnapshot(now: now));

  /// Suggested file name, e.g. `OneSpend-backup-2026-09-30.json`.
  static String fileName(DateTime now) =>
      'OneSpend-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';

  /// Applies [backup]. [RestoreMode.replace] saves a restore point first.
  ///
  /// A legacy (subscriptions-only) backup never replaces cards or settings.
  Future<void> restore(BackupSnapshot backup, RestoreMode mode) async {
    switch (mode) {
      case RestoreMode.addMissing:
        final missing = BackupMerge.missingItems(
          currentSubscriptions: controller.subscriptions,
          currentPaymentMethods: controller.paymentMethods,
          backup: backup,
        );
        controller.addItems(subscriptions: missing.subscriptions, paymentMethods: missing.paymentMethods);
      case RestoreMode.replace:
        await saveRestorePoint();
        await _apply(backup);
        undoableAction.value = 'Restore';
    }
    await controller.pendingWrites;
  }

  /// Saves a restore point, then clears every subscription.
  Future<void> clearAll() async {
    await saveRestorePoint();
    controller.clearAllData();
    await controller.pendingWrites;
    undoableAction.value = 'Clear all';
  }

  Future<void> _apply(BackupSnapshot backup) async {
    controller.replaceAllData(
      subscriptions: backup.subscriptions,
      paymentMethods: backup.isLegacy ? List.of(controller.paymentMethods) : backup.paymentMethods,
      settings: backup.settings,
      // Older backups have no pinned rates (null); the current ones are kept then.
      rateOverrides: backup.isLegacy ? null : backup.rateOverrides,
    );
    if (backup.appearance.isNotEmpty) {
      await settings.setAppearanceSettings(backup.appearance);
      await OneUIEffectsController.instance.init();
    }
  }

  Future<Directory> _restorePointDir() async {
    final dir = Directory(p.join((await _baseDirectory()).path, 'restore_points'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Restore points, newest first.
  Future<List<File>> restorePoints() async {
    final dir = await _restorePointDir();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return files;
  }

  /// Writes the current data as a restore point and keeps only the newest [maxRestorePoints].
  Future<File> saveRestorePoint() async {
    final now = DateTime.now();
    final dir = await _restorePointDir();
    // Zero-padded microseconds sort chronologically by name.
    final file = File(p.join(dir.path, 'restore-${now.microsecondsSinceEpoch.toString().padLeft(20, '0')}.json'));
    await file.writeAsString(BackupCodec.encode(await createSnapshot(now: now)));
    final points = await restorePoints();
    for (final old in points.skip(maxRestorePoints)) {
      await old.delete();
    }
    return file;
  }

  /// Puts back the newest restore point (and removes it). Returns false if there is none.
  Future<bool> undoLast() async {
    undoableAction.value = null;
    final points = await restorePoints();
    if (points.isEmpty) return false;
    final latest = points.first;
    await _apply(BackupCodec.decode(await latest.readAsString()));
    await latest.delete();
    await controller.pendingWrites;
    return true;
  }
}
