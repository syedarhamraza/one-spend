import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/one_ui_theme.dart';

/// What to draw on one calendar day.
class CalendarDayMarker {
  /// One dot per item (e.g. brand colours); up to three are drawn, then "+N".
  final List<Color> dotColors;

  /// Amount used for the heat tint, relative to the heaviest day of the month.
  final double amount;

  /// True when every item on the day is already settled; dots are drawn dimmed.
  final bool settled;

  const CalendarDayMarker({required this.dotColors, this.amount = 0, this.settled = false});
}

/// Samsung One UI (Calendar app) style month grid: swipeable months, weekday initials,
/// a ring on today, a filled selected day, brand-colour dots and a heat tint per day.
class OneUIMonthCalendar extends StatefulWidget {
  /// First and last month that can be shown (any day inside the month).
  final DateTime firstMonth;
  final DateTime lastMonth;
  final DateTime initialMonth;
  final DateTime today;
  final DateTime? selectedDay;

  /// Markers keyed by calendar day (no time part).
  final Map<DateTime, CalendarDayMarker> markers;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime>? onMonthChanged;

  const OneUIMonthCalendar({
    super.key,
    required this.firstMonth,
    required this.lastMonth,
    required this.initialMonth,
    required this.today,
    required this.markers,
    required this.onDaySelected,
    this.selectedDay,
    this.onMonthChanged,
  });

  @override
  State<OneUIMonthCalendar> createState() => _OneUIMonthCalendarState();
}

class _OneUIMonthCalendarState extends State<OneUIMonthCalendar> {
  static const double _cellHeight = 54;
  static final DateFormat _monthTitle = DateFormat('MMMM y');

  late final PageController _pageController;
  late int _page;

  DateTime get _first => DateTime(widget.firstMonth.year, widget.firstMonth.month);
  int get _pageCount =>
      (widget.lastMonth.year - _first.year) * 12 + widget.lastMonth.month - _first.month + 1;

  DateTime _monthAt(int page) => DateTime(_first.year, _first.month + page);

  int _pageOf(DateTime month) => ((month.year - _first.year) * 12 + month.month - _first.month).clamp(0, _pageCount - 1);

  @override
  void initState() {
    super.initState();
    _page = _pageOf(widget.initialMonth);
    _pageController = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final weekdayInitials = [
      for (var i = 0; i < 7; i++) DateFormat.E().format(DateTime(2023, 1, 1 + (firstWeekday + i) % 7))[0],
    ];
    final month = _monthAt(_page);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _monthTitle.format(month),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ),
              _chevron(Icons.chevron_left_rounded, 'Previous month', _page > 0 ? () => _goTo(_page - 1) : null),
              _chevron(
                Icons.chevron_right_rounded,
                'Next month',
                _page < _pageCount - 1 ? () => _goTo(_page + 1) : null,
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (final initial in weekdayInitials)
              Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: _cellHeight * 6,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (page) {
              HapticFeedback.selectionClick();
              setState(() => _page = page);
              widget.onMonthChanged?.call(_monthAt(page));
            },
            itemBuilder: (context, page) => _MonthGrid(
              month: _monthAt(page),
              firstWeekday: firstWeekday,
              cellHeight: _cellHeight,
              today: widget.today,
              selectedDay: widget.selectedDay,
              markers: widget.markers,
              onDaySelected: widget.onDaySelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chevron(IconData icon, String tooltip, VoidCallback? onTap) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      color: OneUITheme.textPrimary,
      disabledColor: OneUITheme.textTertiary,
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final int firstWeekday;
  final double cellHeight;
  final DateTime today;
  final DateTime? selectedDay;
  final Map<DateTime, CalendarDayMarker> markers;
  final ValueChanged<DateTime> onDaySelected;

  const _MonthGrid({
    required this.month,
    required this.firstWeekday,
    required this.cellHeight,
    required this.today,
    required this.selectedDay,
    required this.markers,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: Mon=1..Sun=7; convert to 0=Sun..6=Sat, then offset by locale start.
    final leading = (DateTime(month.year, month.month, 1).weekday % 7 - firstWeekday + 7) % 7;
    final maxAmount = [
      for (var d = 1; d <= daysInMonth; d++) markers[DateTime(month.year, month.month, d)]?.amount ?? 0,
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var week = 0; week < 6; week++)
          SizedBox(
            height: cellHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: () {
                      final dayNumber = week * 7 + col - leading + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
                      final day = DateTime(month.year, month.month, dayNumber);
                      return _DayCell(
                        day: day,
                        isToday: day == DateTime(today.year, today.month, today.day),
                        isSelected: day == selectedDay,
                        marker: markers[day],
                        maxAmount: maxAmount,
                        onTap: () => onDaySelected(day),
                      );
                    }(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final CalendarDayMarker? marker;
  final double maxAmount;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.marker,
    required this.maxAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final marker = this.marker;
    final heat = marker == null || maxAmount <= 0 || marker.settled ? 0.0 : (marker.amount / maxAmount) * 0.25;
    final dots = marker?.dotColors ?? const <Color>[];
    final dotOpacity = marker?.settled ?? false ? 0.45 : 1.0;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${DateFormat.yMMMMd().format(day)}${dots.isEmpty ? '' : ', ${dots.length} charges'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? OneUITheme.accentBlue
                    : (heat > 0 ? OneUITheme.accentBlue.withValues(alpha: heat) : Colors.transparent),
                border: isToday && !isSelected ? Border.all(color: OneUITheme.accentBlue, width: 1.6) : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday && !isSelected ? OneUITheme.accentBlue : OneUITheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final color in dots.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: dotOpacity)),
                    ),
                  if (dots.length > 3)
                    Text(
                      '+${dots.length - 3}',
                      style: const TextStyle(fontSize: 7.5, height: 1, color: OneUITheme.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
