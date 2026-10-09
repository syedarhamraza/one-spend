import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_date_wheel.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_radio.dart';
import '../core/haptics/haptics.dart';
import '../theme/one_ui_scroll.dart';

/// Samsung One UI date picker subpage: month / day / year scroll wheels, a live summary,
/// quick picks, and the floating Cancel | Save pill. Returns the chosen date (no time part),
/// or null when cancelled.
class DatePickerScreen extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final String? subtitle;

  const DatePickerScreen({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select date',
    this.subtitle,
  });

  static Future<DateTime?> open(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String title = 'Select date',
    String? subtitle,
  }) {
    Haptics.tap();
    final DatePickerArgs args = (
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      subtitle: subtitle,
    );
    return context.push<DateTime>(AppRoutes.datePicker, extra: args);
  }

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  final GlobalKey<OneUIDateWheelState> _wheelKey = GlobalKey<OneUIDateWheelState>();
  static final DateFormat _summaryFormat = DateFormat('EEEE, MMMM d, y');
  static final DateFormat _pickFormat = DateFormat('EEE, MMM d');
  late DateTime _date;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _clamp(DateTime d) {
    final date = _dateOnly(d);
    final first = _dateOnly(widget.firstDate);
    final last = _dateOnly(widget.lastDate);
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }

  /// Relative quick picks that fall inside the allowed range.
  List<({String label, DateTime date})> get _quickPicks {
    final today = _dateOnly(DateTime.now());
    final candidates = [
      (label: 'Today', date: today),
      (label: 'Yesterday', date: DateTime(today.year, today.month, today.day - 1)),
      (label: 'A week ago', date: DateTime(today.year, today.month, today.day - 7)),
      (label: 'A month ago', date: DateTime(today.year, today.month - 1, today.day)),
    ];
    return [
      for (final pick in candidates)
        if (_clamp(pick.date) == pick.date) pick,
    ];
  }

  @override
  void initState() {
    super.initState();
    _date = _clamp(widget.initialDate);
  }

  void _save() {
    Haptics.confirm();
    Navigator.pop(context, _date);
  }

  @override
  Widget build(BuildContext context) {
    final quickPicks = _quickPicks;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const OneUIScrollPhysics(),
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
                        child: OneUIDateWheel(
                          key: _wheelKey,
                          date: _date,
                          firstDate: widget.firstDate,
                          lastDate: widget.lastDate,
                          onChanged: (date) => setState(() => _date = date),
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
                              child: const Icon(Icons.event_rounded, color: OneUITheme.accentBlue, size: 20),
                            ),
                            title: _summaryFormat.format(_date),
                            subtitle: widget.subtitle ?? 'Scroll the wheels or choose a quick pick',
                            subtitleColor: OneUITheme.textSecondary,
                          ),
                        ],
                      ),
                      if (quickPicks.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        OneUISection(
                          title: 'Quick picks',
                          child: OneUIGroupCard(
                            margin: EdgeInsets.zero,
                            items: [
                              for (final pick in quickPicks)
                                OneUIGroupItem(
                                  title: pick.label,
                                  subtitle: _pickFormat.format(pick.date),
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: OneUIRadio(isSelected: _date == pick.date),
                                  onTap: () {
                                    Haptics.select();
                                    setState(() => _date = pick.date);
                                    _wheelKey.currentState?.animateTo(pick.date);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
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
