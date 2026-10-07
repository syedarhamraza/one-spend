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
/// * **Settings › Vibration › Intensity.** Left alone ([intensity] is null) Android picks
///   each effect for the phone's motor. Once set, phones that can vary their vibration
///   ([canAdjust]) play clicks at that strength through the `onespend/haptics` channel
///   (`HapticsChannel.kt`); phones with a basic motor can't, and keep the system haptics,
///   where [HapticKind.select] may be silent.
///
/// Widgets with a long-press should set `enableFeedback: false` on their `InkWell`
/// (or use a `GestureDetector`) and call [longPress], so Flutter's built-in long-press
/// buzz doesn't play on top.
class Haptics {
  const Haptics._();

  static const Duration _minGap = Duration(milliseconds: 80);

  /// Whether Settings › Vibration › Haptic feedback is on.
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  /// The strongest [intensity].
  static const int maxIntensity = 5;

  /// Settings › Vibration › Intensity, 1 to [maxIntensity]; null is the phone's own haptics.
  static final ValueNotifier<int?> intensity = ValueNotifier(null);

  /// The level the slider shows while [intensity] is the phone's own.
  static const int defaultIntensity = 3;

  /// Whether this phone can play vibrations at a chosen strength.
  static bool canAdjust = false;

  static const MethodChannel _channel = MethodChannel('onespend/haptics');

  /// The vibration strength (0–1) for each [intensity] level.
  static const List<double> _strengths = [0.3, 0.5, 0.68, 0.85, 1.0];

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

  /// Reads the saved settings and what the phone's motor can do. Awaited in
  /// `configureDependencies()`.
  static Future<void> load(SettingsRepository settings) async {
    enabled.value = await settings.getHapticsEnabled();
    intensity.value = await settings.getHapticIntensity();
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      canAdjust = info?['canAdjust'] == true;
    } on MissingPluginException {
      canAdjust = false; // tests and other platforms
    } on PlatformException {
      canAdjust = false;
    }
  }

  /// Sets [intensity] (null goes back to the phone's own) and plays a sample of it.
  static Future<void> setIntensity(int? level) async {
    intensity.value = level?.clamp(1, maxIntensity);
    _lastPlayed = null; // a sample always plays
    confirm();
    if (sl.isRegistered<SettingsRepository>()) await sl<SettingsRepository>().setHapticIntensity(intensity.value);
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
    final level = intensity.value;
    if (level != null && canAdjust) {
      unawaited(
        _channel
            .invokeMethod<void>('play', {'kind': kind.name, 'strength': _strengths[level - 1]})
            .catchError((Object _) {}),
      );
      return;
    }
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
    intensity.value = null;
    canAdjust = false;
    _pending = null;
    _lastPlayed = null;
    debugSink = null;
  }
}
