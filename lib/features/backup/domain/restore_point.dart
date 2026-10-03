import 'backup_snapshot.dart';

/// Why OneSpend saved a restore point.
enum RestorePointReason {
  beforeRestore('restore', 'Before restoring a backup'),
  beforeClearAll('clear', 'Before clearing all'),
  beforeRestorePoint('point', 'Before going back to a restore point');

  /// Short id stored in the restore point's file name.
  final String id;
  final String label;

  const RestorePointReason(this.id, this.label);

  /// Restore points saved before reasons existed count as [beforeRestore].
  static RestorePointReason fromId(String? id) =>
      values.firstWhere((r) => r.id == id, orElse: () => beforeRestore);
}

/// A full copy of the data that OneSpend saved automatically before replacing or clearing it.
class RestorePoint {
  /// Path of the restore point file in app storage.
  final String path;
  final RestorePointReason reason;
  final BackupSnapshot snapshot;

  const RestorePoint({required this.path, required this.reason, required this.snapshot});

  DateTime get createdAt => snapshot.createdAt;
}
