import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_version.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/backup/domain/backup_merge.dart';
import '../../features/backup/domain/backup_snapshot.dart';
import '../../features/backup/domain/restore_point.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../core/haptics/haptics.dart';

/// What a restore did, returned to the caller so it can show the toast (with Undo for replace).
typedef RestoreOutcome = ({RestoreMode mode, int addedSubscriptions, int addedPaymentMethods, int addedCategories});

/// The toast to show after a restore.
String restoreOutcomeMessage(RestoreOutcome outcome) {
  if (outcome.mode == RestoreMode.replace) return 'Restored';
  final added = outcome.addedSubscriptions + outcome.addedPaymentMethods + outcome.addedCategories;
  return added == 0 ? 'Nothing new to add' : 'Added $added item${added == 1 ? '' : 's'}';
}

/// Preview of a backup file before restoring: what's in it, what you have, and how to apply it.
/// "Add missing items" is the default and never changes existing data.
///
/// Also used for going back to a [RestorePoint] (see `RestorePointsScreen`).
class RestorePreviewScreen extends StatefulWidget {
  final BackupSnapshot backup;

  /// Set when previewing one of OneSpend's automatic restore points instead of a file.
  final RestorePoint? restorePoint;

  const RestorePreviewScreen({super.key, required this.backup, this.restorePoint});

  /// Previews a backup file.
  static Future<RestoreOutcome?> open(BuildContext context, BackupSnapshot backup) {
    Haptics.tap();
    return context.push<RestoreOutcome>(AppRoutes.settingsRestore, extra: backup);
  }

  /// Previews a restore point.
  static Future<RestoreOutcome?> openPoint(BuildContext context, RestorePoint point) {
    Haptics.tap();
    return context.push<RestoreOutcome>(AppRoutes.settingsRestore, extra: point);
  }

  @override
  State<RestorePreviewScreen> createState() => _RestorePreviewScreenState();
}

class _RestorePreviewScreenState extends State<RestorePreviewScreen> {
  static final DateFormat _date = DateFormat('MMM d, y · h:mm a');

  RestoreMode _mode = RestoreMode.addMissing;
  bool _busy = false;

  String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  String _items(int subs, int cards, [int categories = 0]) => [
        _plural(subs, 'subscription'),
        if (cards > 0) _plural(cards, 'card'),
        if (categories > 0) categories == 1 ? '1 category' : '$categories categories',
      ].join(' · ');

  Future<void> _restore(RestorePlan plan) async {
    if (_busy) return;
    if (_mode == RestoreMode.replace) {
      OneUIFloatingModal.showConfirmationDialog(
        context: context,
        title: 'Replace all data?',
        message:
            'Your ${_items(plan.currentSubscriptions, plan.currentPaymentMethods, plan.currentCustomCategories)} will be saved as a restore '
            'point first, so you can undo this.',
        cancelLabel: 'Cancel',
        confirmLabel: 'Replace',
        confirmTextColor: OneUITheme.accentOrange,
        onConfirm: () => _apply(plan),
      );
    } else {
      await _apply(plan);
    }
  }

  Future<void> _apply(RestorePlan plan) async {
    setState(() => _busy = true);
    Haptics.confirm();
    await sl<BackupService>().restore(
      widget.backup,
      _mode,
      reason: widget.restorePoint == null ? RestorePointReason.beforeRestore : RestorePointReason.beforeRestorePoint,
    );
    if (!mounted) return;
    Navigator.pop<RestoreOutcome>(context, (
      mode: _mode,
      addedSubscriptions: _mode == RestoreMode.addMissing ? plan.newSubscriptions : plan.backupSubscriptions,
      addedPaymentMethods: _mode == RestoreMode.addMissing ? plan.newPaymentMethods : plan.backupPaymentMethods,
      addedCategories: _mode == RestoreMode.addMissing ? plan.newCustomCategories : plan.backupCustomCategories,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    final backup = widget.backup;
    final plan = BackupMerge.plan(
      currentSubscriptions: store.subscriptions,
      currentPaymentMethods: store.paymentMethods,
      currentCustomCategories: store.customCategories,
      backup: backup,
    );
    final nothingNew = plan.newSubscriptions == 0 && plan.newPaymentMethods == 0 && plan.newCustomCategories == 0;
    final point = widget.restorePoint;

    return OneUISubpage(
      title: point == null ? 'Restore backup' : 'Restore point',
      bottomPill: OneUIFloatingCancelSavePill(
        saveLabel: 'Restore',
        onCancel: () => Navigator.pop(context),
        onSave: () => _restore(plan),
      ),
      builder: (context) => [
        OneUISection(
          title: point == null ? 'Backup' : point.reason.label,
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                leading: point == null
                    ? const OneUIIconBadge(Icons.inventory_2_rounded, OneUITheme.accentTeal)
                    : const OneUIIconBadge(Icons.history_rounded, OneUITheme.accentPurple),
                title: _items(plan.backupSubscriptions, plan.backupPaymentMethods, plan.backupCustomCategories),
                subtitle: backup.isLegacy
                    ? 'Older export · subscriptions only'
                    : [
                        _date.format(backup.createdAt),
                        if (point == null && backup.appVersion.isNotEmpty)
                          'One Spend ${AppVersion.describe(backup.appVersion)}',
                      ].join(' · '),
                subtitleColor: OneUITheme.textSecondary,
                trailing: const SizedBox.shrink(),
              ),
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.smartphone_rounded, OneUITheme.accentBlue),
                title: 'On this phone',
                subtitle: _items(plan.currentSubscriptions, plan.currentPaymentMethods, plan.currentCustomCategories),
                subtitleColor: OneUITheme.textSecondary,
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'How to restore',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Add missing items',
                subtitle: nothingNew
                    ? 'Everything in this backup is already here'
                    : 'Adds ${_items(plan.newSubscriptions, plan.newPaymentMethods, plan.newCustomCategories)}. '
                        'Nothing you have is changed.',
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _mode == RestoreMode.addMissing),
                onTap: () {
                  Haptics.select();
                  setState(() => _mode = RestoreMode.addMissing);
                },
              ),
              OneUIGroupItem(
                title: 'Replace everything',
                subtitle: backup.isLegacy
                    ? 'Replaces your subscriptions. Cards and settings are kept. You can undo.'
                    : 'Replaces subscriptions, cards, categories and settings. Your current data is saved first, '
                        'so you can undo.',
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _mode == RestoreMode.replace),
                onTap: () {
                  Haptics.select();
                  setState(() => _mode = RestoreMode.replace);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
