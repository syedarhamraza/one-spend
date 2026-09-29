import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/one_ui_theme.dart';
import 'one_ui_wheel_column.dart';

/// Samsung One UI style scroll-wheel time picker (hour : minute  AM/PM), modelled on the
/// One UI Clock alarm editor: flat wheels on the black surface, the selected value large
/// and white, neighbours dimmed, a haptic tick per step.
///
/// Works in minutes after midnight (0–1439). Use a `GlobalKey<OneUITimeWheelState>` to
/// call [OneUITimeWheelState.animateTo] from outside (e.g. quick picks).
class OneUITimeWheel extends StatefulWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const OneUITimeWheel({super.key, required this.minutes, required this.onChanged});

  @override
  State<OneUITimeWheel> createState() => OneUITimeWheelState();
}

class OneUITimeWheelState extends State<OneUITimeWheel> {
  static const Duration _animation = Duration(milliseconds: 380);

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;
  late final FixedExtentScrollController _periodController;

  late int _hour12; // 1–12
  late int _minute; // 0–59
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    _setFromMinutes(widget.minutes);
    // Looping wheels start far from index 0 so they can scroll both ways freely.
    _hourController = FixedExtentScrollController(initialItem: 12 * 100 + (_hour12 - 1));
    _minuteController = FixedExtentScrollController(initialItem: 60 * 100 + _minute);
    _periodController = FixedExtentScrollController(initialItem: _isPm ? 1 : 0);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _setFromMinutes(int minutes) {
    final hour24 = (minutes ~/ 60) % 24;
    _minute = minutes % 60;
    _isPm = hour24 >= 12;
    _hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  }

  /// Minutes after midnight for a 12-hour clock value.
  static int toMinutes({required int hour12, required int minute, required bool isPm}) =>
      ((hour12 % 12) + (isPm ? 12 : 0)) * 60 + minute;

  int get _currentMinutes => toMinutes(hour12: _hour12, minute: _minute, isPm: _isPm);

  /// True while [animateTo] drives the wheels, so passing items don't fire haptic ticks.
  bool _animating = false;

  void _emit() {
    if (!_animating) HapticFeedback.selectionClick();
    widget.onChanged(_currentMinutes);
  }

  /// Nearest looping index to [current] that shows [value] on a wheel of [length] items.
  static int _nearestIndex(int current, int value, int length) {
    final delta = ((value - current) % length + length) % length;
    return delta > length ~/ 2 ? current + delta - length : current + delta;
  }

  /// Smoothly scrolls every wheel to [minutes].
  Future<void> animateTo(int minutes) async {
    _setFromMinutes(minutes);
    _animating = true;
    try {
      await Future.wait([
        _hourController.animateToItem(
          _nearestIndex(_hourController.selectedItem, _hour12 - 1, 12),
          duration: _animation,
          curve: Curves.easeOutCubic,
        ),
        _minuteController.animateToItem(
          _nearestIndex(_minuteController.selectedItem, _minute, 60),
          duration: _animation,
          curve: Curves.easeOutCubic,
        ),
        _periodController.animateToItem(_isPm ? 1 : 0, duration: _animation, curve: Curves.easeOutCubic),
      ]);
    } finally {
      _animating = false;
    }
    // Wheels report intermediate items while animating; settle on the exact target.
    _setFromMinutes(minutes);
    widget.onChanged(minutes);
  }

  @override
  Widget build(BuildContext context) {
    const digits = TextStyle(
      fontSize: 72,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: -1.5,
      color: OneUITheme.textPrimary,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    const period = TextStyle(fontSize: 44, fontWeight: FontWeight.w700, height: 1, color: OneUITheme.textPrimary);

    // Scales down on narrow phones instead of overflowing.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OneUIWheelColumn(
            controller: _hourController,
            count: 12,
            looping: true,
            width: 96,
            label: (i) => '${i + 1}',
            semanticsLabel: (i) => '${i + 1} hours',
            onSelected: (i) {
              _hour12 = i + 1;
              _emit();
            },
            style: digits,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(':', style: digits),
          ),
          OneUIWheelColumn(
            controller: _minuteController,
            count: 60,
            looping: true,
            width: 120,
            label: (i) => i.toString().padLeft(2, '0'),
            semanticsLabel: (i) => '$i minutes',
            onSelected: (i) {
              _minute = i;
              _emit();
            },
            style: digits,
          ),
          const SizedBox(width: 20),
          OneUIWheelColumn(
            controller: _periodController,
            count: 2,
            looping: false,
            width: 96,
            label: (i) => i == 0 ? 'AM' : 'PM',
            semanticsLabel: (i) => i == 0 ? 'AM' : 'PM',
            onSelected: (i) {
              _isPm = i == 1;
              _emit();
            },
            style: period,
          ),
        ],
      ),
    );
  }
}
