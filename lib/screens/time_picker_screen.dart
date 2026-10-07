import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../utils/reminder_format.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_radio.dart';
import '../widgets/one_ui_time_wheel.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI time-of-day picker subpage: scroll wheels (hour : minute AM/PM),
/// a live summary, quick picks, and the floating Cancel | Save pill.
/// Returns minutes after midnight, or null when cancelled.
class TimePickerScreen extends StatefulWidget {
  final int initialMinutes;
  final String title;
  final String? subtitle;

  const TimePickerScreen({super.key, required this.initialMinutes, this.title = 'Reminder time', this.subtitle});

  static Future<int?> open(
    BuildContext context, {
    required int initialMinutes,
    String title = 'Reminder time',
    String? subtitle,
  }) {
    Haptics.tap();
    final TimePickerArgs args = (initialMinutes: initialMinutes, title: title, subtitle: subtitle);
    return context.push<int>(AppRoutes.timePicker, extra: args);
  }

  @override
  State<TimePickerScreen> createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  final GlobalKey<OneUITimeWheelState> _wheelKey = GlobalKey<OneUITimeWheelState>();
  late int _minutes;

  static const List<({String label, int minutes})> _quickPicks = [
    (label: 'Morning', minutes: 9 * 60),
    (label: 'Noon', minutes: 12 * 60),
    (label: 'Evening', minutes: 18 * 60),
    (label: 'Night', minutes: 21 * 60),
  ];

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes.clamp(0, 24 * 60 - 1);
  }

  void _save() {
    Haptics.confirm();
    Navigator.pop(context, _minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: widget.title,
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scroll wheels sit directly on the black surface, like the One UI alarm editor.
                      Center(
                        child: OneUITimeWheel(
                          key: _wheelKey,
                          minutes: _minutes,
                          onChanged: (minutes) => setState(() => _minutes = minutes),
                        ),
                      ),
                      const SizedBox(height: 20),
                      OneUIGroupCard(
                        margin: EdgeInsets.zero,
                        items: [
                          OneUIGroupItem(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: OneUITheme.accentBlue,
                                size: 20,
                              ),
                            ),
                            title: 'Alerts are delivered at ${formatReminderTime(_minutes)}',
                            subtitle: widget.subtitle ?? 'Scroll the wheels or choose a quick pick',
                            subtitleColor: OneUITheme.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OneUISection(
                        title: 'Quick picks',
                        child: OneUIGroupCard(
                          margin: EdgeInsets.zero,
                          items: [
                            for (final pick in _quickPicks)
                              OneUIGroupItem(
                                title: pick.label,
                                subtitle: formatReminderTime(pick.minutes),
                                subtitleColor: OneUITheme.textSecondary,
                                trailing: OneUIRadio(isSelected: _minutes == pick.minutes),
                                onTap: () {
                                  Haptics.select();
                                  setState(() => _minutes = pick.minutes);
                                  _wheelKey.currentState?.animateTo(pick.minutes);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progressive OLED Bottom Vignette Scrim
          const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),

          // Bottom Floating Stadium Cancel | Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    cancelLabel: 'Cancel',
                    saveLabel: 'Save',
                    onCancel: () => Navigator.pop(context),
                    onSave: _save,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
