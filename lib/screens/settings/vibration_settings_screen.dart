import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
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
      listenable: Listenable.merge([store, Haptics.enabled, Haptics.intensity]),
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
          OneUISection(title: 'Intensity', child: _intensity(context, haptics)),
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

  /// One UI's vibration intensity slider: five steps, each change plays a sample.
  Widget _intensity(BuildContext context, bool haptics) {
    final level = Haptics.intensity.value;
    final adjustable = Haptics.canAdjust;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: haptics && adjustable ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !haptics || !adjustable,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Touch vibration',
                      style: TextStyle(fontSize: 16, color: OneUITheme.textPrimary, letterSpacing: -0.2),
                    ),
                  ),
                  Text(
                    level == null ? 'Phone default' : _levelName(level),
                    style: const TextStyle(fontSize: 13.5, color: OneUITheme.accentBlue),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.vibration_rounded, size: 16, color: OneUITheme.textSecondary),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: OneUITheme.accentBlue,
                        inactiveTrackColor: OneUITheme.surfacePill,
                        thumbColor: Colors.white,
                        overlayColor: OneUITheme.accentBlue.withValues(alpha: 0.12),
                        activeTickMarkColor: Colors.white.withValues(alpha: 0.5),
                        inactiveTickMarkColor: OneUITheme.textTertiary,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: (level ?? Haptics.defaultIntensity).toDouble(),
                        min: 1,
                        max: Haptics.maxIntensity.toDouble(),
                        divisions: Haptics.maxIntensity - 1,
                        semanticFormatterCallback: (v) => _levelName(v.round()),
                        onChanged: (v) {
                          if (v.round() != level) Haptics.setIntensity(v.round());
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.vibration_rounded, size: 24, color: OneUITheme.textSecondary),
                ],
              ),
              if (!adjustable)
                const Text(
                  "This phone's vibration strength can't be changed.",
                  style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                )
              else if (level != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Haptics.setIntensity(null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Use phone default',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: OneUITheme.accentBlue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _levelName(int level) => const ['Very light', 'Light', 'Medium', 'Strong', 'Very strong'][level - 1];
}
