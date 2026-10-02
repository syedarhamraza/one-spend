import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/feature_flags.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/backup/domain/backup_codec.dart';
import '../../features/backup/domain/backup_snapshot.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';
import 'restore_preview_screen.dart';
import '../../features/reports/presentation/export_share_screen.dart';

/// Settings › Backup & data.
///
/// One backup file, used both ways: "Save backup to device" writes it and "Restore from
/// backup" reads it. Replacing data or clearing it always saves a restore point first,
/// and an inline Undo row appears at the top until you leave the screen.
class BackupDataScreen extends StatelessWidget {
  const BackupDataScreen({super.key});

  static final DateFormat _savedFormat = DateFormat('MMM d, y');

  static Future<void> open(BuildContext context) async {
    HapticFeedback.lightImpact();
    await context.push(AppRoutes.settingsData);
    // The Undo row only makes sense right after the change; later edits would be lost.
    if (sl.isRegistered<BackupService>()) sl<BackupService>().undoableAction.value = null;
  }

  Future<void> _undoLast(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final undone = await sl<BackupService>().undoLast();
    if (context.mounted) OneUIToast.show(context, undone ? 'Change undone' : 'Nothing to undo');
  }

  Future<void> _saveBackup(BuildContext context) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    try {
      final contents = await sl<BackupService>().exportBackup(now: now);
      final uri = await FilePicker.saveFile(
        fileName: BackupService.fileName(now),
        bytes: Uint8List.fromList(utf8.encode(contents)),
        mimeType: 'application/json',
      );
      if (uri == null) return; // cancelled
      SubscriptionStore.instance.markBackupSaved(now);
      if (context.mounted) OneUIToast.show(context, 'Backup saved');
    } catch (_) {
      if (context.mounted) OneUIToast.show(context, 'Couldn\'t save the backup');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    HapticFeedback.lightImpact();
    final BackupSnapshot backup;
    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty) return; // cancelled
      backup = BackupCodec.decode(utf8.decode(await files.first.readAsBytes()));
    } on BackupFormatException catch (e) {
      if (context.mounted) OneUIToast.show(context, e.message);
      return;
    } catch (_) {
      if (context.mounted) OneUIToast.show(context, BackupFormatException.damaged.message);
      return;
    }
    if (!context.mounted) return;

    final outcome = await RestorePreviewScreen.open(context, backup);
    if (outcome == null || !context.mounted) return;
    if (outcome.mode == RestoreMode.replace) {
      OneUIToast.show(context, 'Backup restored');
    } else {
      final added = outcome.addedSubscriptions + outcome.addedPaymentMethods;
      OneUIToast.show(context, added == 0 ? 'Nothing new to add' : 'Added $added item${added == 1 ? '' : 's'}');
    }
  }

  void _clearAll(BuildContext context) {
    final count = SubscriptionStore.instance.subscriptions.length;
    if (count == 0) {
      OneUIToast.show(context, 'There are no subscriptions to clear');
      return;
    }
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Clear all subscriptions?',
      message:
          '$count subscription${count == 1 ? '' : 's'} and their payment history will be removed. '
          'A restore point is saved first, so you can undo.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Clear all',
      onConfirm: () async {
        HapticFeedback.mediumImpact();
        await sl<BackupService>().clearAll();
        if (!context.mounted) return;
        OneUIToast.show(context, 'All subscriptions cleared');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Backup & data',
      listenable: Listenable.merge([store, sl<BackupService>().undoableAction]),
      builder: (context) {
        final lastSaved = store.lastBackupAt;
        final undoable = sl<BackupService>().undoableAction.value;
        return [
          if (undoable != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  OneUIGroupItem(
                    title: 'Undo ${undoable.toLowerCase()}',
                    subtitle: 'Put back your data from before',
                    subtitleColor: OneUITheme.textSecondary,
                    trailing: const Icon(Icons.undo_rounded, color: OneUITheme.accentBlue, size: 22),
                    onTap: () => _undoLast(context),
                  ),
                ],
              ),
            ),
          OneUISection(
            title: 'Backup',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                OneUIGroupItem(
                  title: 'Save backup to device',
                  subtitle: lastSaved == null ? 'Never saved' : 'Last saved ${_savedFormat.format(lastSaved)}',
                  subtitleColor: OneUITheme.accentBlue,
                  trailing: const SizedBox.shrink(),
                  onTap: () => _saveBackup(context),
                ),
                OneUIGroupItem(
                  title: 'Restore from backup',
                  trailing: const SizedBox.shrink(),
                  onTap: () => _restoreBackup(context),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Saves subscriptions, cards and settings in one file. Keep it somewhere safe, like Downloads or '
              'your own cloud storage.',
              style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
            ),
          ),
          if (FeatureFlags.showPlannedFeatures)
            OneUISection(
              title: 'Google Drive',
              child: OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  OneUIGroupItem(
                    title: 'Automatic backups',
                    trailing: const OneUIProChip(),
                    onTap: () => ComingSoonScreen.open(context, PlannedFeature.driveBackup),
                  ),
                ],
              ),
            ),
          OneUISection(
            title: 'Export',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                OneUIGroupItem(
                  title: 'Export & share',
                  subtitle: 'PDF report, spreadsheet (CSV) or text summary',
                  subtitleColor: OneUITheme.textSecondary,
                  onTap: () => ExportShareScreen.open(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Clear all subscriptions',
                trailing: const Icon(Icons.delete_outline_rounded, color: OneUITheme.accentRed, size: 22),
                onTap: () => _clearAll(context),
              ),
            ],
          ),
        ];
      },
    );
  }
}
