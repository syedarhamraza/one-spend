import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../utils/reminder_format.dart';
import 'time_picker_screen.dart';
import '../widgets/one_ui_radio.dart';
import '../core/haptics/haptics.dart';

/// Dedicated Samsung One UI Renewal Reminder Subpage.
/// Replaces the bottom modal sheet with a full One UI subpage for selecting
/// alert lead times (Same day, 1-7 days, custom days) and the time of day to notify.
class ReminderPickerScreen extends StatefulWidget {
  final int initialDays;

  /// Time of day in minutes after midnight.
  final int initialTimeMinutes;

  const ReminderPickerScreen({
    super.key,
    required this.initialDays,
    this.initialTimeMinutes = 9 * 60,
  });

  static Future<ReminderSetting?> open(
    BuildContext context, {
    required int initialDays,
    required int initialTimeMinutes,
  }) {
    Haptics.tap();
    final ReminderSetting initial = (days: initialDays, timeMinutes: initialTimeMinutes);
    return context.push<ReminderSetting>(AppRoutes.reminderPicker, extra: initial);
  }

  @override
  State<ReminderPickerScreen> createState() => _ReminderPickerScreenState();
}

class _ReminderPickerScreenState extends State<ReminderPickerScreen> {
  late int _selectedDays;
  late int _timeMinutes;
  bool _isCustom = false;
  final TextEditingController _customController = TextEditingController();

  static const List<Map<String, dynamic>> _presetOptions = [
    {'days': 0, 'title': 'Same day', 'subtitle': 'On the renewal day itself'},
    {'days': 1, 'title': '1 day before', 'subtitle': '24 hours prior to billing'},
    {'days': 2, 'title': '2 days before', 'subtitle': 'Recommended to review or cancel'},
    {'days': 3, 'title': '3 days before', 'subtitle': 'Early reminder for review'},
    {'days': 5, 'title': '5 days before', 'subtitle': 'Advance notice for weekly/monthly'},
    {'days': 7, 'title': '7 days before (1 week)', 'subtitle': 'Ideal for annual subscriptions'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    _timeMinutes = widget.initialTimeMinutes;
    final isKnownPreset = _presetOptions.any((opt) => opt['days'] == widget.initialDays);
    if (!isKnownPreset && widget.initialDays > 0) {
      _isCustom = true;
      _customController.text = widget.initialDays.toString();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _save() {
    Haptics.confirm();
    final days = _isCustom ? (int.tryParse(_customController.text.trim()) ?? _selectedDays).clamp(0, 60) : _selectedDays;
    final ReminderSetting result = (days: days, timeMinutes: _timeMinutes);
    Navigator.pop(context, result);
  }

  Future<void> _pickTime() async {
    Haptics.select();
    final picked = await TimePickerScreen.open(
      context,
      initialMinutes: _timeMinutes,
      title: 'Notification time',
      subtitle: 'When this subscription\'s reminder is delivered',
    );
    if (picked != null && mounted) {
      setState(() => _timeMinutes = picked);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Reminder notification',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status / Info Hero Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: OneUITheme.accentBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Advance Renewal Notice',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _selectedDays == 0
                                        ? 'Alert sent on the renewal day at ${formatReminderTime(_timeMinutes)}'
                                        : 'Alert sent $_selectedDays day${_selectedDays > 1 ? "s" : ""} prior at ${formatReminderTime(_timeMinutes)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time of day for this subscription's reminders
                      OneUISection(
                        title: 'Notification Time',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Remind me at',
                              subtitle: 'Time of day the alert is delivered',
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: Text(
                                formatReminderTime(_timeMinutes),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.accentBlue,
                                ),
                              ),
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Preset Options Group Card
                      OneUISection(
                        title: 'Select Alert Lead Time',
                        child: OneUIGroupCard(
                          items: _presetOptions.map((opt) {
                            final int days = opt['days'] as int;
                            final bool isSelected = !_isCustom && _selectedDays == days;

                            return OneUIGroupItem(
                              title: opt['title'] as String,
                              subtitle: opt['subtitle'] as String,
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: OneUIRadio(isSelected: isSelected),
                              onTap: () {
                                Haptics.select();
                                setState(() {
                                  _isCustom = false;
                                  _selectedDays = days;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Custom Days Section
                      OneUISection(
                        title: 'Custom Lead Time',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Custom number of days',
                              subtitle: _isCustom
                                  ? 'Enter days in advance (1-60)'
                                  : 'Specify custom days prior to renewal',
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: OneUIRadio(isSelected: _isCustom),
                              onTap: () {
                                Haptics.select();
                                setState(() {
                                  _isCustom = true;
                                  if (_customController.text.isEmpty) {
                                    _customController.text = _selectedDays.toString();
                                  }
                                });
                              },
                            ),
                            if (_isCustom)
                              OneUIGroupItem(
                                title: 'Days before renewal',
                                subtitle: 'Tap to edit number of days',
                                trailing: SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _customController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.accentBlue,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '2',
                                      suffixText: ' d',
                                      suffixStyle: TextStyle(
                                        color: OneUITheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val.trim());
                                      if (parsed != null) {
                                        setState(() => _selectedDays = parsed.clamp(0, 60));
                                      }
                                    },
                                  ),
                                ),
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
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          // Floating Cancel | Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: _save,
                    saveLabel: 'Save',
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
