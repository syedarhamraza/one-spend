import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/backup/domain/backup_merge.dart';
import '../../features/backup/domain/backup_snapshot.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_subpage.dart';

/// What a restore did, returned to the caller so it can show the toast (with Undo for replace).
typedef RestoreOutcome = ({RestoreMode mode, int addedSubscriptions, int addedPaymentMethods});

/// Preview of a backup file before restoring: what's in it, what you have, and how to apply it.
/// "Add missing items" is the default and never changes existing data.
class RestorePreviewScreen extends StatefulWidget {
  final BackupSnapshot backup;

  const RestorePreviewScreen({super.key, required this.backup});

  static Future<RestoreOutcome?> open(BuildContext context, BackupSnapshot backup) {
    HapticFeedback.lightImpact();
    return context.push<RestoreOutcome>(AppRoutes.settingsRestore, extra: backup);
  }

  @override
  State<RestorePreviewScreen> createState() => _RestorePreviewScreenState();
}

class _RestorePreviewScreenState extends State<RestorePreviewScreen> {
  static final DateFormat _date = DateFormat('MMM d, y · h:mm a');

  RestoreMode _mode = RestoreMode.addMissing;
  bool _busy = false;

  String _plural(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  String _items(int subs, int cards) =>
      cards == 0 ? _plural(subs, 'subscription') : '${_plural(subs, 'subscription')} · ${_plural(cards, 'card')}';

  Future<void> _restore(RestorePlan plan) async {
    if (_busy) return;
    if (_mode == RestoreMode.replace) {
      OneUIFloatingModal.showConfirmationDialog(
        context: context,
        title: 'Replace all data?',
        message:
            'Your ${_items(plan.currentSubscriptions, plan.currentPaymentMethods)} will be saved as a restore '
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
    HapticFeedback.mediumImpact();
    await sl<BackupService>().restore(widget.backup, _mode);
    if (!mounted) return;
    Navigator.pop<RestoreOutcome>(context, (
      mode: _mode,
      addedSubscriptions: _mode == RestoreMode.addMissing ? plan.newSubscriptions : plan.backupSubscriptions,
      addedPaymentMethods: _mode == RestoreMode.addMissing ? plan.newPaymentMethods : plan.backupPaymentMethods,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    final backup = widget.backup;
    final plan = BackupMerge.plan(
      currentSubscriptions: store.subscriptions,
      currentPaymentMethods: store.paymentMethods,
      backup: backup,
    );
    final nothingNew = plan.newSubscriptions == 0 && plan.newPaymentMethods == 0;

    return OneUISubpage(
      title: 'Restore backup',
      bottomPill: OneUIFloatingCancelSavePill(
        saveLabel: 'Restore',
        onCancel: () => Navigator.pop(context),
        onSave: () => _restore(plan),
      ),
      builder: (context) => [
        OneUISection(
          title: 'Backup',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.inventory_2_rounded, OneUITheme.accentTeal),
                title: _items(plan.backupSubscriptions, plan.backupPaymentMethods),
                subtitle: backup.isLegacy
                    ? 'Older export · subscriptions only'
                    : [
                        _date.format(backup.createdAt),
                        if (backup.appVersion.isNotEmpty) 'v${backup.appVersion}',
                      ].join(' · '),
                subtitleColor: OneUITheme.textSecondary,
                trailing: const SizedBox.shrink(),
              ),
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.smartphone_rounded, OneUITheme.accentBlue),
                title: 'On this phone',
                subtitle: _items(plan.currentSubscriptions, plan.currentPaymentMethods),
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
                    : 'Adds ${_items(plan.newSubscriptions, plan.newPaymentMethods)}. Nothing you have is changed.',
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _mode == RestoreMode.addMissing),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mode = RestoreMode.addMissing);
                },
              ),
              OneUIGroupItem(
                title: 'Replace everything',
                subtitle: backup.isLegacy
                    ? 'Replaces your subscriptions. Cards and settings are kept. You can undo.'
                    : 'Replaces subscriptions, cards and settings. Your current data is saved first, so you can undo.',
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _mode == RestoreMode.replace),
                onTap: () {
                  HapticFeedback.selectionClick();
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
