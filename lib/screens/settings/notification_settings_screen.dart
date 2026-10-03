import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/presentation/notification_permission.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/reminder_format.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';
import '../reminder_picker_screen.dart';

/// Settings › Notifications: master switch, default reminder, and the Android permission state.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsNotifications);
  }

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  /// Whether Android currently allows OneSpend to post notifications (null until checked).
  bool? _systemAllowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshSystemState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may have changed the permission in system settings while away.
    if (state == AppLifecycleState.resumed) _refreshSystemState();
  }

  Future<void> _refreshSystemState() async {
    if (!sl.isRegistered<NotificationService>()) return;
    final allowed = await sl<NotificationService>().areEnabled();
    if (mounted) setState(() => _systemAllowed = allowed);
  }

  Future<void> _setEnabled(SubscriptionStore store, bool enabled) async {
    HapticFeedback.selectionClick();
    store.setNotificationsEnabled(enabled);
    if (enabled) {
      await ensureNotificationPermission();
      await _refreshSystemState();
    }
  }

  Future<void> _pickReminder(SubscriptionStore store) async {
    final picked = await ReminderPickerScreen.open(
      context,
      initialDays: store.defaultReminderDays,
      initialTimeMinutes: store.defaultReminderTimeMinutes,
    );
    if (picked == null) return;
    store.setDefaultReminderDays(picked.days);
    store.setDefaultReminderTimeMinutes(picked.timeMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Notifications',
      listenable: store,
      builder: (context) {
        final enabled = store.notificationsEnabled;
        return [
          _masterSwitch(store, enabled),
          if (enabled && _systemAllowed == false)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: OneUIGroupCard(
                margin: EdgeInsets.zero,
                items: [
                  OneUIGroupItem(
                    leading: const OneUIIconBadge(Icons.notifications_off_rounded, OneUITheme.accentRed),
                    title: 'Blocked by Android',
                    subtitle: 'Tap to allow notifications for One Spend',
                    subtitleColor: OneUITheme.accentRed,
                    onTap: () async {
                      await ensureNotificationPermission();
                      await _refreshSystemState();
                    },
                  ),
                ],
              ),
            ),
          IgnorePointer(
            ignoring: !enabled,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1 : 0.4,
              child: OneUISection(
                title: 'Reminders',
                child: OneUIGroupCard(
                  margin: EdgeInsets.zero,
                  items: [
                    OneUIGroupItem(
                      title: 'Default reminder',
                      subtitle: describeReminder(store.defaultReminderDays, store.defaultReminderTimeMinutes),
                      subtitleColor: OneUITheme.accentBlue,
                      onTap: () => _pickReminder(store),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Used for new subscriptions, card expiry and budget alerts. Each subscription can override it.',
              style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
            ),
          ),
        ];
      },
    );
  }

  /// One UI style "On / Off" master switch bar.
  Widget _masterSwitch(SubscriptionStore store, bool enabled) {
    return Semantics(
      toggled: enabled,
      label: 'Notifications',
      child: Material(
        color: enabled ? OneUITheme.accentBlue.withValues(alpha: 0.18) : OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        child: InkWell(
          borderRadius: OneUITheme.cardBorderRadius,
          onTap: () => _setEnabled(store, !enabled),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    enabled ? 'On' : 'Off',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                  ),
                ),
                OneUISwitch(value: enabled, onChanged: (v) => _setEnabled(store, v)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
