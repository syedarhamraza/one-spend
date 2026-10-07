import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_switch.dart';

/// Settings › Vibration: touch feedback in the app, and whether reminders vibrate.
/// Both are on by default, which means "follow the phone's own settings".
class VibrationSettingsScreen extends StatelessWidget {
  const VibrationSettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return context.push(AppRoutes.settingsVibration);
  }

  static Future<void> _setHaptics(bool value) async {
    final saving = Haptics.setEnabled(value); // takes effect at once; saving follows
    // Turning it on gives a sample of what it feels like.
    if (value) Haptics.select();
    await saving;
  }

  static void _setNotificationVibration(SubscriptionStore store, bool value) {
    Haptics.select();
    store.setNotificationVibration(value);
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Vibration',
      listenable: Listenable.merge([store, Haptics.enabled]),
      builder: (context) {
        final haptics = Haptics.enabled.value;
        final notifications = store.notificationVibration;
        return [
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Haptic feedback',
                subtitle: 'Vibrate when you tap buttons, switches and lists',
                trailing: OneUISwitch(value: haptics, onChanged: _setHaptics),
                onTap: () => _setHaptics(!haptics),
              ),
              OneUIGroupItem(
                title: 'Vibrate for notifications',
                subtitle: 'Renewal reminders, card expiry and budget alerts',
                trailing: OneUISwitch(
                  value: notifications,
                  onChanged: (v) => _setNotificationVibration(store, v),
                ),
                onTap: () => _setNotificationVibration(store, !notifications),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              "When these are on, One Spend follows your phone's sound mode and touch feedback "
              'setting. Phones without a haptic motor use a short, simple vibration instead.',
              style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
            ),
          ),
        ];
      },
    );
  }
}
