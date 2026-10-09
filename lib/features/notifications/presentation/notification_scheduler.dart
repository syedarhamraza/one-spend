import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/router/app_router.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../data/notification_service.dart';
import '../domain/notification_planner.dart';
import '../domain/planned_notification.dart';
import '../../../core/telemetry/telemetry.dart';

/// Keeps the OS's scheduled notifications equal to [NotificationPlanner]'s output.
///
/// Re-plans (debounced) whenever [SubscriptionController] changes and whenever the app
/// resumes. A data change only cancels and schedules the notifications that differ from
/// the last plan (most changes, like a search or a sort, touch none); a resume or an
/// explicit [syncNow] cancels everything this scheduler owns and schedules the plan
/// afresh, which also repairs anything the OS dropped. Developer test notifications use
/// reserved ids and are never cancelled here.
class NotificationScheduler with WidgetsBindingObserver {
  final SubscriptionController controller;
  final NotificationService service;
  final DateTime Function() clock;
  final Duration debounce;

  NotificationScheduler({
    required this.controller,
    required this.service,
    DateTime Function()? clock,
    this.debounce = const Duration(milliseconds: 500),
  }) : clock = clock ?? DateTime.now;

  Timer? _debounceTimer;
  Future<int> _syncQueue = Future.value(0);
  Set<int>? _scheduledIds;
  List<PlannedNotification> _lastPlan = const [];

  /// The vibration setting the scheduled notifications were made with.
  bool? _vibration;

  /// Completes when the syncs queued so far have finished.
  @visibleForTesting
  Future<void> get lastSyncDone => _syncQueue;

  /// What the most recent sync scheduled (empty when notifications are off).
  List<PlannedNotification> get lastPlan => _lastPlan;

  /// go_router location opened when [notification] is tapped.
  static String routeFor(PlannedNotification notification) {
    final subjectId = notification.subjectId;
    return switch (notification.kind) {
      NotificationKind.renewal => AppRoutes.subscriptionDetail(subjectId!),
      NotificationKind.card => AppRoutes.paymentMethods,
      NotificationKind.budget => AppRoutes.analytics,
      NotificationKind.developer =>
        subjectId == null ? AppRoutes.subscriptions : AppRoutes.subscriptionDetail(subjectId),
    };
  }

  void start() {
    controller.addListener(_scheduleSync);
    WidgetsBinding.instance.addObserver(this);
    syncNow();
  }

  void dispose() {
    _debounceTimer?.cancel();
    controller.removeListener(_scheduleSync);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Moves the rolling window forward and drops reminders whose time has passed.
    if (state == AppLifecycleState.resumed) syncNow();
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _enqueue(full: false));
  }

  /// Re-plans immediately and reschedules everything; returns how many notifications
  /// are now scheduled.
  Future<int> syncNow() => _enqueue(full: true);

  Future<int> _enqueue({required bool full}) {
    // Serialize syncs so a slow one never interleaves with the next.
    return _syncQueue = _syncQueue.then((_) => full ? _sync() : _syncChanges()).catchError((Object e, StackTrace stack) {
      AppLog.error(e, stack, reason: 'Failed to sync notifications');
      return 0;
    });
  }

  /// Applies only the difference between the last plan and the current one.
  Future<int> _syncChanges() async {
    final previousIds = _scheduledIds;
    // Nothing scheduled by this process yet: start from a clean slate. A new vibration
    // setting moves everything to other channels, so it reschedules everything too.
    if (previousIds == null || _vibration != controller.notificationVibration) return _sync();

    final plan = controller.notificationsEnabled ? _plan() : const <PlannedNotification>[];
    final before = {for (final n in _lastPlan) n.id: n};
    final ids = {for (final n in plan) n.id};

    final removed = previousIds.difference(ids);
    if (removed.isNotEmpty) await service.cancel(removed);
    for (final notification in plan) {
      // Scheduling an id again replaces it, so changed ones need no cancel first.
      if (before[notification.id] != notification) {
        await service.schedule(notification, route: routeFor(notification));
      }
    }
    _scheduledIds = ids;
    _lastPlan = plan;
    return plan.length;
  }

  /// The plan, without the kinds switched off in Settings › Notifications.
  List<PlannedNotification> _plan() => [
        for (final n in NotificationPlanner.plan(
          subscriptions: controller.subscriptions,
          paymentMethods: controller.paymentMethods,
          monthlyBudget: controller.monthlyBudget,
          currency: controller.currency,
          toMain: controller.toMain,
          defaultReminderTimeMinutes: controller.defaultReminderTimeMinutes,
          now: clock(),
        ))
          if (controller.isNotificationKindEnabled(n.kind)) n,
      ];

  Future<int> _sync() async {
    // First run in this process: forget whatever a previous process scheduled.
    final previous = _scheduledIds ??
        {
          for (final p in await service.pending())
            if (p.id > PlannedNotification.maxReservedId) p.id,
        };
    await service.cancel(previous);
    _vibration = controller.notificationVibration;
    await service.setVibration(_vibration!);

    if (!controller.notificationsEnabled) {
      _scheduledIds = {};
      _lastPlan = const [];
      return 0;
    }

    final plan = _plan();
    for (final notification in plan) {
      await service.schedule(notification, route: routeFor(notification));
    }
    _scheduledIds = {for (final n in plan) n.id};
    _lastPlan = plan;
    return plan.length;
  }
}
