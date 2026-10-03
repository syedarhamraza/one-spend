import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../theme/one_ui_theme.dart';
import '../../../widgets/one_ui_floating_modal.dart';
import '../../../widgets/one_ui_group_card.dart';
import '../../../widgets/one_ui_toast.dart';
import '../../currency/domain/money_format.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../data/notification_service.dart';
import '../domain/planned_notification.dart';
import 'notification_permission.dart';
import 'notification_scheduler.dart';

/// Debug-only helpers for exercising notifications on a device.
/// Settings only builds these when `kDebugMode` is true, so they never ship in release.
class NotificationDeveloperTools {
  const NotificationDeveloperTools._();

  // Reserved ids (<= PlannedNotification.maxReservedId) so resyncs never cancel them.
  static const int _instantId = 1;
  static const int _scheduledId = 2;

  static final DateFormat _fireFormat = DateFormat('EEE, MMM d · h:mm a');

  static List<OneUIGroupItem> items(BuildContext context, Widget Function(IconData, Color) badge) {
    return [
      OneUIGroupItem(
        leading: badge(Icons.notification_add_rounded, OneUITheme.accentAmber),
        title: 'Send test notification now',
        subtitle: 'Shows immediately; tap it to test the deep link',
        onTap: () => _sendNow(context),
      ),
      OneUIGroupItem(
        leading: badge(Icons.timer_outlined, OneUITheme.accentBlue),
        title: 'Schedule test in 1 minute',
        subtitle: 'Uses the real scheduler; kill the app to test cold start',
        onTap: () => _scheduleInOneMinute(context),
      ),
      OneUIGroupItem(
        leading: badge(Icons.pending_actions_rounded, OneUITheme.accentTeal),
        title: 'Pending notifications',
        subtitle: 'Everything currently scheduled with Android',
        onTap: () => _showPending(context),
      ),
      OneUIGroupItem(
        leading: badge(Icons.sync_rounded, OneUITheme.accentPurple),
        title: 'Resync reminders now',
        subtitle: 'Re-plan all reminders from current data',
        onTap: () => _resync(context),
      ),
    ];
  }

  static PlannedNotification _testNotification(int id, DateTime fireAt) {
    final subs = SubscriptionController.instance.subscriptions;
    final sub = subs.isEmpty ? null : subs.first;
    return PlannedNotification(
      id: id,
      kind: NotificationKind.developer,
      fireAt: fireAt,
      title: sub == null ? 'One Spend test notification' : 'Test: ${sub.name} renews tomorrow',
      body: sub == null
          ? 'Notifications are working.'
          : '${formatMoney(sub.price, sub.currency)} will be charged. Tap to open it.',
      subjectId: sub?.id,
    );
  }

  static Future<bool> _ensureAllowed(BuildContext context) async {
    if (await sl<NotificationService>().areEnabled()) return true;
    final granted = await ensureNotificationPermission();
    if (!granted && context.mounted) {
      OneUIToast.show(context, 'Notifications are off or blocked for One Spend');
    }
    return granted;
  }

  static Future<void> _sendNow(BuildContext context) async {
    if (!await _ensureAllowed(context)) return;
    final notification = _testNotification(_instantId, DateTime.now());
    await sl<NotificationService>().showNow(notification, route: NotificationScheduler.routeFor(notification));
  }

  static Future<void> _scheduleInOneMinute(BuildContext context) async {
    if (!await _ensureAllowed(context)) return;
    final fireAt = DateTime.now().add(const Duration(minutes: 1));
    final notification = _testNotification(_scheduledId, fireAt);
    await sl<NotificationService>().schedule(notification, route: NotificationScheduler.routeFor(notification));
    if (context.mounted) {
      OneUIToast.show(context, 'Test scheduled for ${DateFormat('h:mm a').format(fireAt)} (may be ~1 min late)');
    }
  }

  static Future<void> _resync(BuildContext context) async {
    if (!sl.isRegistered<NotificationScheduler>()) {
      OneUIToast.show(context, 'Notification scheduler is not running');
      return;
    }
    final count = await sl<NotificationScheduler>().syncNow();
    if (context.mounted) OneUIToast.show(context, '$count reminders scheduled');
  }

  static Future<void> _showPending(BuildContext context) async {
    final pending = await sl<NotificationService>().pending();
    // The OS doesn't report fire times, so match them from the scheduler's last plan.
    final plan = sl.isRegistered<NotificationScheduler>() ? sl<NotificationScheduler>().lastPlan : const [];
    final fireTimes = {for (final n in plan) n.id: n.fireAt};
    if (!context.mounted) return;

    await OneUIFloatingModal.show<void>(
      context: context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending notifications (${pending.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OneUITheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            if (pending.isEmpty)
              const Text('Nothing is scheduled.', style: TextStyle(color: OneUITheme.textSecondary))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  separatorBuilder: (_, _) => const Divider(height: 16, color: Color(0x22FFFFFF)),
                  itemBuilder: (_, i) {
                    final p = pending[i];
                    final fireAt = fireTimes[p.id];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title ?? '(no title)',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fireAt == null ? 'time unknown' : _fireFormat.format(fireAt)} · ${p.route ?? ''}',
                          style: const TextStyle(fontSize: 12, color: OneUITheme.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
