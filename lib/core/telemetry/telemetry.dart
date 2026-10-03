import 'package:flutter/foundation.dart';

import '../di/injection.dart';
import 'events.dart';

/// Where crash reports, breadcrumbs and analytics events go.
///
/// Never pass user content: no subscription names, prices, notes, URLs or card digits.
/// Events come only from [TelemetryEvent]; messages are fixed text plus ids/keys.
abstract class Telemetry {
  /// A breadcrumb: shown with the next crash or error report.
  void log(String message);

  /// A non-fatal error (or a fatal one, for uncaught errors), grouped by [reason].
  void recordError(Object error, StackTrace? stack, {required String reason, bool fatal = false});

  /// An analytics event.
  void event(TelemetryEvent event);

  /// The screen now showing, as a route pattern such as `/subscriptions/:id`.
  void screen(String name);

  /// Context attached to every crash report (see [TelemetryContext]).
  void setContext(String key, Object value);
}

/// Prints to the console only. Used in tests and when Firebase isn't configured.
class NoopTelemetry implements Telemetry {
  @override
  void log(String message) => debugPrint('OneSpend: $message');

  @override
  void recordError(Object error, StackTrace? stack, {required String reason, bool fatal = false}) =>
      debugPrint('OneSpend: $reason: $error');

  @override
  void event(TelemetryEvent event) {}

  @override
  void screen(String name) {}

  @override
  void setContext(String key, Object value) {}
}

/// The one place app code reports through.
class AppLog {
  const AppLog._();

  static Telemetry get _t => sl.isRegistered<Telemetry>() ? sl<Telemetry>() : _fallback;
  static final Telemetry _fallback = NoopTelemetry();

  /// Something worth knowing when reading a crash report later (expected conditions too).
  static void info(String message) => _t.log(message);

  /// Something failed that shouldn't have. [reason] groups reports, so keep it fixed text.
  static void error(Object error, StackTrace? stack, {required String reason}) =>
      _t.recordError(error, stack, reason: reason);

  /// An error nothing else caught (see `main.dart`); shows as a crash in Crashlytics.
  static void fatal(Object error, StackTrace? stack, {required String reason}) =>
      _t.recordError(error, stack, reason: reason, fatal: true);

  static void event(TelemetryEvent event) => _t.event(event);

  static void screen(String name) => _t.screen(name);

  static void context(String key, Object value) => _t.setContext(key, value);
}
