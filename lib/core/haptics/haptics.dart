import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/settings/domain/repositories/settings_repository.dart';
import '../di/injection.dart';

/// What a haptic is for, weakest first. One touch plays only the strongest it asked for.
enum HapticKind {
  /// Picking a value: switches, pills, chips, selecting an item, wheel and calendar steps.
  select,

  /// Pressing something: rows, buttons, menu items, opening a page.
  tap,

  /// Finishing something: Save, Add, Mark as paid.
  confirm,

  /// Holding an item to pick it up (selection mode, reordering).
  longPress,

  /// Something destructive or wrong: Delete, Clear, an error.
  warn,
}

/// The only way One Spend vibrates on touch. Use it instead of [HapticFeedback].
///
/// * **One buzz per touch.** A tap often passes through a shared widget, the screen's
///   handler and a page's `open()` helper, and each used to vibrate. Requests made in
///   the same moment are merged and only the strongest plays; another within
///   [_minGap] of the last one is dropped.
/// * **Settings › Vibration › Haptic feedback** turns it off. When on, Android still
///   follows the phone's own touch feedback setting.
/// * Android maps each kind to the effect that suits the phone's motor; on phones with
///   only a basic vibration motor, [HapticKind.select] may be silent.
///
/// Widgets with a long-press should set `enableFeedback: false` on their `InkWell`
/// (or use a `GestureDetector`) and call [longPress], so Flutter's built-in long-press
/// buzz doesn't play on top.
class Haptics {
  const Haptics._();

  static const Duration _minGap = Duration(milliseconds: 80);

  /// Whether Settings › Vibration › Haptic feedback is on.
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static HapticKind? _pending;
  static DateTime? _lastPlayed;

  /// Replaces playing on the device; tests use it to count what plays.
  @visibleForTesting
  static void Function(HapticKind kind)? debugSink;

  static void select() => _request(HapticKind.select);
  static void tap() => _request(HapticKind.tap);
  static void confirm() => _request(HapticKind.confirm);
  static void longPress() => _request(HapticKind.longPress);
  static void warn() => _request(HapticKind.warn);

  /// Reads the saved setting. Awaited in `configureDependencies()`.
  static Future<void> load(SettingsRepository settings) async {
    enabled.value = await settings.getHapticsEnabled();
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (sl.isRegistered<SettingsRepository>()) await sl<SettingsRepository>().setHapticsEnabled(value);
  }

  static void _request(HapticKind kind) {
    if (!enabled.value) return;
    final pending = _pending;
    if (pending == null) scheduleMicrotask(_play);
    if (pending == null || kind.index > pending.index) _pending = kind;
  }

  static void _play() {
    final kind = _pending;
    _pending = null;
    if (kind == null || !enabled.value) return;
    final now = DateTime.now();
    final last = _lastPlayed;
    if (last != null && now.difference(last) < _minGap) return;
    _lastPlayed = now;

    final sink = debugSink;
    if (sink != null) return sink(kind);
    unawaited(switch (kind) {
      HapticKind.select => HapticFeedback.selectionClick(),
      HapticKind.tap => HapticFeedback.lightImpact(),
      HapticKind.confirm => HapticFeedback.mediumImpact(),
      HapticKind.longPress => HapticFeedback.vibrate(),
      HapticKind.warn => HapticFeedback.heavyImpact(),
    });
  }

  @visibleForTesting
  static void resetForTesting() {
    enabled.value = true;
    _pending = null;
    _lastPlayed = null;
    debugSink = null;
  }
}
