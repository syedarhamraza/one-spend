import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../features/notifications/presentation/notification_developer_tools.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';

/// Settings › Developer options. Only reachable in debug builds.
class DeveloperOptionsScreen extends StatelessWidget {
  const DeveloperOptionsScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsDeveloperOptions);
  }

  void _restoreSamples(BuildContext context) {
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Load sample subscriptions?',
      message: 'Replaces your subscriptions with the demo catalog.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Load',
      confirmTextColor: OneUITheme.accentOrange,
      onConfirm: () {
        SubscriptionStore.instance.restoreDefaultCatalog();
        OneUIToast.show(context, 'Sample subscriptions loaded');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Developer options',
      builder: (context) => [
        OneUISection(
          title: 'Notifications',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: NotificationDeveloperTools.items(context, (icon, color) => OneUIIconBadge(icon, color)),
          ),
        ),
        OneUISection(
          title: 'Data',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.restore_rounded, OneUITheme.accentOrange),
                title: 'Load sample subscriptions',
                trailing: const SizedBox.shrink(),
                onTap: () => _restoreSamples(context),
              ),
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.tips_and_updates_rounded, OneUITheme.accentAmber),
                title: 'Restore dismissed tips',
                trailing: const SizedBox.shrink(),
                onTap: () {
                  store.restoreDismissedInsights();
                  OneUIToast.show(context, 'Dismissed tips restored');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
