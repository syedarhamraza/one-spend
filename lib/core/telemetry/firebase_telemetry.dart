import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'events.dart';
import 'telemetry.dart';

/// Crash reports and breadcrumbs go to Firebase Crashlytics, events to Firebase Analytics.
///
/// Debug builds send nothing unless built with `--dart-define=TELEMETRY_IN_DEBUG=true`
/// (for checking the setup); they still print everything to the console.
class FirebaseTelemetry implements Telemetry {
  static const bool sendInDebug = bool.fromEnvironment('TELEMETRY_IN_DEBUG');

  /// Whether this build sends anything.
  static bool get collects => !kDebugMode || sendInDebug;

  final FirebaseCrashlytics _crashlytics;
  final FirebaseAnalytics _analytics;

  FirebaseTelemetry._(this._crashlytics, this._analytics);

  static Future<FirebaseTelemetry> create() async {
    final telemetry = FirebaseTelemetry._(FirebaseCrashlytics.instance, FirebaseAnalytics.instance);
    await telemetry._crashlytics.setCrashlyticsCollectionEnabled(collects);
    await telemetry._analytics.setAnalyticsCollectionEnabled(collects);
    // No ads, so no ad signals (the Advertising ID is also removed in the manifest).
    await telemetry._analytics.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
      analyticsStorageConsentGranted: true,
    );
    return telemetry;
  }

  @override
  void log(String message) {
    if (kDebugMode) debugPrint('OneSpend: $message');
    _crashlytics.log(message);
  }

  @override
  void recordError(Object error, StackTrace? stack, {required String reason, bool fatal = false}) {
    if (kDebugMode) debugPrint('OneSpend: $reason: $error');
    _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);
  }

  @override
  void event(TelemetryEvent event) {
    if (kDebugMode) debugPrint('OneSpend event: $event');
    _crashlytics.log('event: $event');
    _analytics.logEvent(name: event.name, parameters: event.params.isEmpty ? null : event.params);
  }

  @override
  void screen(String name) {
    _crashlytics.log('screen: $name');
    _analytics.logScreenView(screenName: name, screenClass: name);
  }

  @override
  void setContext(String key, Object value) => _crashlytics.setCustomKey(key, value);
}
