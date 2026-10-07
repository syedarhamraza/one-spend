import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../domain/planned_notification.dart';
import 'notification_service.dart';
import '../../../core/telemetry/telemetry.dart';

/// [NotificationService] backed by flutter_local_notifications (Android).
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();

  static const _icon = 'ic_stat_name';

  /// One Android channel per kind so users can mute categories in system settings.
  static const Map<NotificationKind, AndroidNotificationChannel> _channels = {
    NotificationKind.renewal: AndroidNotificationChannel(
      'renewals',
      'Renewal reminders',
      description: 'Upcoming subscription charges',
      importance: Importance.high,
    ),
    NotificationKind.card: AndroidNotificationChannel(
      'cards',
      'Card expiry',
      description: 'Saved payment methods that are about to expire',
    ),
    NotificationKind.budget: AndroidNotificationChannel(
      'budget',
      'Budget alerts',
      description: 'Upcoming charges that push you over your monthly budget',
    ),
    NotificationKind.developer: AndroidNotificationChannel(
      'developer',
      'Developer tests',
      description: 'Test notifications sent from the debug-only developer tools',
      importance: Importance.high,
    ),
  };

  /// Kinds that follow Settings › Vibration. Developer tests always use their own channel.
  static const _userKinds = [NotificationKind.renewal, NotificationKind.card, NotificationKind.budget];

  /// The no-vibration twin of [channel]. Android fixes a channel's vibration when it's
  /// created (and a deleted id comes back with its old settings), so "Vibrate for
  /// notifications" off moves the reminders to these channels instead.
  static AndroidNotificationChannel _quiet(AndroidNotificationChannel channel) => AndroidNotificationChannel(
        '${channel.id}_quiet',
        channel.name,
        description: channel.description,
        importance: channel.importance,
        enableVibration: false,
      );

  bool _vibrate = true;

  AndroidNotificationChannel _channelFor(NotificationKind kind) {
    final channel = _channels[kind]!;
    return _vibrate || !_userKinds.contains(kind) ? channel : _quiet(channel);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> setVibration(bool enabled) async {
    _vibrate = enabled;
    final android = _android;
    if (android == null) return;
    for (final kind in _userKinds) {
      final channel = _channels[kind]!;
      final (active, unused) = enabled ? (channel, _quiet(channel)) : (_quiet(channel), channel);
      await android.createNotificationChannel(active);
      // Only one set shows in the system's notification settings.
      await android.deleteNotificationChannel(channelId: unused.id);
    }
  }

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      AppLog.info('Could not resolve local timezone, reminders use UTC: ${e.runtimeType}');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings(_icon)),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.isNotEmpty) _taps.add(route);
      },
    );

    final android = _android;
    if (android != null) {
      // The reminder channels are created by setVibration, once the setting is known.
      await android.createNotificationChannel(_channels[NotificationKind.developer]!);
      // Clean up the unused "Free trials" channel created by earlier pre-release builds.
      await android.deleteNotificationChannel(channelId: 'trials');
    }
  }

  NotificationDetails _details(NotificationKind kind) {
    final channel = _channelFor(kind);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        enableVibration: channel.enableVibration,
        icon: _icon,
        importance: channel.importance,
        priority: channel.importance == Importance.high ? Priority.high : Priority.defaultPriority,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async => await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> areEnabled() async => await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<void> schedule(PlannedNotification notification, {required String route}) {
    return _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(notification.fireAt, tz.local),
      notificationDetails: _details(notification.kind),
      // Inexact is fine for reminders and needs no exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: route,
    );
  }

  @override
  Future<void> showNow(PlannedNotification notification, {required String route}) {
    return _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: _details(notification.kind),
      payload: route,
    );
  }

  @override
  Future<void> cancel(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }

  @override
  Future<List<PendingNotification>> pending() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [for (final r in requests) (id: r.id, title: r.title, body: r.body, route: r.payload)];
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchRoute() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final route = details.notificationResponse?.payload;
    return route == null || route.isEmpty ? null : route;
  }
}
