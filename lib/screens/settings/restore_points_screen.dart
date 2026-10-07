import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/backup/domain/restore_point.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import 'restore_preview_screen.dart';
import '../../core/haptics/haptics.dart';

/// Settings › Backup & data › Restore points: the copies OneSpend saved automatically
/// before replacing or clearing data. Tapping one previews it like a backup file.
class RestorePointsScreen extends StatefulWidget {
  const RestorePointsScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return context.push(AppRoutes.settingsRestorePoints);
  }

  @override
  State<RestorePointsScreen> createState() => _RestorePointsScreenState();
}

class _RestorePointsScreenState extends State<RestorePointsScreen> {
  static final DateFormat _date = DateFormat('MMM d, y · h:mm a');

  late Future<List<RestorePoint>> _points = sl<BackupService>().listRestorePoints();

  String _contents(RestorePoint point) {
    final s = point.snapshot;
    final subs = s.subscriptions.length;
    final cards = s.paymentMethods.length;
    return [
      '$subs subscription${subs == 1 ? '' : 's'}',
      if (cards > 0) '$cards card${cards == 1 ? '' : 's'}',
    ].join(' · ');
  }

  Future<void> _open(RestorePoint point) async {
    final outcome = await RestorePreviewScreen.openPoint(context, point);
    if (!mounted) return;
    if (outcome != null) OneUIToast.show(context, restoreOutcomeMessage(outcome));
    // Replacing saves a new restore point (and may retire the oldest).
    setState(() => _points = sl<BackupService>().listRestorePoints());
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Restore points',
      builder: (context) => [
        FutureBuilder<List<RestorePoint>>(
          future: _points,
          builder: (context, snapshot) {
            final points = snapshot.data;
            if (points == null) return const SizedBox(height: 120);
            if (points.isEmpty) {
              return OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  OneUIGroupItem(
                    leading: const OneUIIconBadge(Icons.history_rounded, OneUITheme.accentPurple),
                    title: 'No restore points yet',
                    subtitle: 'One is saved automatically the next time data is replaced or cleared',
                    subtitleColor: OneUITheme.textSecondary,
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              );
            }
            return OneUISection(
              title: 'Newest first',
              child: OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  for (final point in points)
                    OneUIGroupItem(
                      leading: const OneUIIconBadge(Icons.history_rounded, OneUITheme.accentPurple),
                      title: point.reason.label,
                      subtitle: '${_date.format(point.createdAt)}\n${_contents(point)}',
                      subtitleColor: OneUITheme.textSecondary,
                      onTap: () => _open(point),
                    ),
                ],
              ),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'One Spend saves a copy of your data automatically before it replaces or clears it. The newest '
            '${BackupService.maxRestorePoints} are kept on this phone only, so also save a backup file now and then.',
            style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
