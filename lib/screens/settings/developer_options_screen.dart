import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../core/telemetry/firebase_telemetry.dart';
import '../../core/telemetry/telemetry.dart';
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

  /// Whether the test buttons below actually reach Firebase in this build.
  static String _telemetryStatus() {
    if (!sl.isRegistered<Telemetry>() || sl<Telemetry>() is! FirebaseTelemetry) {
      return "Firebase isn't set up, so this only prints to the console";
    }
    return FirebaseTelemetry.collects
        ? 'Sent to Crashlytics'
        : 'Debug build: kept on the phone. Build with --dart-define=TELEMETRY_IN_DEBUG=true to send';
  }

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
          title: 'Crash reports',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.bug_report_rounded, OneUITheme.accentRed),
                title: 'Send test error',
                subtitle: _telemetryStatus(),
                subtitleColor: OneUITheme.textSecondary,
                trailing: const SizedBox.shrink(),
                onTap: () {
                  AppLog.info('Test breadcrumb from Developer options');
                  AppLog.error(StateError('Test error from Developer options'), StackTrace.current,
                      reason: 'Developer options test error');
                  OneUIToast.show(context, 'Test error recorded');
                },
              ),
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.dangerous_rounded, OneUITheme.accentRed),
                title: 'Throw uncaught error',
                subtitle: 'Reported as a crash; the app keeps running',
                subtitleColor: OneUITheme.textSecondary,
                trailing: const SizedBox.shrink(),
                onTap: () => Future<void>.error(StateError('Test uncaught error from Developer options')),
              ),
            ],
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
