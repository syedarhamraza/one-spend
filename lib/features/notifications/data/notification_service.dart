import 'dart:async';
import '../domain/planned_notification.dart';

/// A notification currently scheduled with the OS.
typedef PendingNotification = ({int id, String? title, String? body, String? route});

/// Platform notification boundary. Payloads are go_router locations opened on tap.
abstract class NotificationService {
  Future<void> init();

  /// Asks for the OS permission (Android 13+); returns whether notifications are allowed.
  Future<bool> requestPermission();

  /// Whether the OS currently allows this app to post notifications.
  Future<bool> areEnabled();

  /// Whether notifications scheduled from now on vibrate (Settings › Vibration).
  Future<void> setVibration(bool enabled);

  Future<void> schedule(PlannedNotification notification, {required String route});

  /// Shows [notification] immediately, ignoring its fire time.
  Future<void> showNow(PlannedNotification notification, {required String route});

  Future<void> cancel(Iterable<int> ids);

  Future<List<PendingNotification>> pending();

  /// Routes from notifications tapped while the app is running.
  Stream<String> get taps;

  /// Route of the notification that cold-started the app, if any.
  Future<String?> launchRoute();
}

/// Does nothing; used in tests and whenever the platform plugin is unavailable.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  // Reports "allowed" so the UI never shows a blocked state when there is no platform.
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areEnabled() async => true;

  @override
  Future<void> setVibration(bool enabled) async {}

  @override
  Future<void> schedule(PlannedNotification notification, {required String route}) async {}

  @override
  Future<void> showNow(PlannedNotification notification, {required String route}) async {}

  @override
  Future<void> cancel(Iterable<int> ids) async {}

  @override
  Future<List<PendingNotification>> pending() async => const [];

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> launchRoute() async => null;
}
