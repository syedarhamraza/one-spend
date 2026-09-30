import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';

/// Settings › Backup & data: export, placeholders for import and cloud sync, and clearing data.
class BackupDataScreen extends StatelessWidget {
  const BackupDataScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsData);
  }

  Future<void> _export(BuildContext context, {required bool csv}) async {
    final store = SubscriptionStore.instance;
    if (store.subscriptions.isEmpty) {
      OneUIToast.show(context, 'No subscriptions to export');
      return;
    }
    HapticFeedback.lightImpact();
    final content = csv ? store.exportDataAsCsv() : store.exportDataAsJson();
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, csv ? 'onespend-subscriptions.csv' : 'onespend-backup.json'));
      await file.writeAsString(content);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: csv ? 'text/csv' : 'application/json')],
          subject: csv ? 'OneSpend subscriptions' : 'OneSpend backup',
        ),
      );
    } catch (_) {
      if (context.mounted) OneUIToast.show(context, 'Couldn\'t open the share sheet');
    }
  }

  void _clearAll(BuildContext context) {
    final store = SubscriptionStore.instance;
    final count = store.subscriptions.length;
    if (count == 0) {
      OneUIToast.show(context, 'There are no subscriptions to clear');
      return;
    }
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Clear all subscriptions?',
      message: '$count subscription${count == 1 ? '' : 's'} and their payment history will be deleted. '
          'This can\'t be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Clear all',
      onConfirm: () {
        HapticFeedback.mediumImpact();
        store.clearAllData();
        OneUIToast.show(context, 'All subscriptions cleared');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Backup & data',
      builder: (context) => [
        OneUISection(
          title: 'Export',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Export backup',
                subtitle: 'JSON file with everything, for restoring later',
                trailing: const SizedBox.shrink(),
                onTap: () => _export(context, csv: false),
              ),
              OneUIGroupItem(
                title: 'Export as spreadsheet',
                subtitle: 'CSV file for Excel or Google Sheets',
                trailing: const SizedBox.shrink(),
                onTap: () => _export(context, csv: true),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'Restore',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: PlannedFeature.import.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.import),
              ),
              OneUIGroupItem(
                title: PlannedFeature.cloudBackup.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.cloudBackup),
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
      ],
    );
  }
}
