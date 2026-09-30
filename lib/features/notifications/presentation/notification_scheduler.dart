import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/router/app_router.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../data/notification_service.dart';
import '../domain/notification_planner.dart';
import '../domain/planned_notification.dart';

/// Keeps the OS's scheduled notifications equal to [NotificationPlanner]'s output.
///
/// Re-plans (debounced) whenever [SubscriptionController] changes and whenever the app
/// resumes, cancelling what it scheduled before. Developer test notifications use reserved
/// ids and are never cancelled here.
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
    _debounceTimer = Timer(debounce, syncNow);
  }

  /// Re-plans immediately; returns how many notifications are now scheduled.
  Future<int> syncNow() {
    // Serialize syncs so a slow one never interleaves with the next.
    return _syncQueue = _syncQueue.then((_) => _sync()).catchError((Object e) {
      debugPrint('OneSpend: Failed to sync notifications: $e');
      return 0;
    });
  }

  Future<int> _sync() async {
    // First run in this process: forget whatever a previous process scheduled.
    final previous = _scheduledIds ??
        {
          for (final p in await service.pending())
            if (p.id > PlannedNotification.maxReservedId) p.id,
        };
    await service.cancel(previous);

    if (!controller.notificationsEnabled) {
      _scheduledIds = {};
      _lastPlan = const [];
      return 0;
    }

    final plan = NotificationPlanner.plan(
      subscriptions: controller.subscriptions,
      paymentMethods: controller.paymentMethods,
      monthlyBudget: controller.monthlyBudget,
      currency: controller.currency,
      toMain: controller.toMain,
      defaultReminderTimeMinutes: controller.defaultReminderTimeMinutes,
      now: clock(),
    );
    for (final notification in plan) {
      await service.schedule(notification, route: routeFor(notification));
    }
    _scheduledIds = {for (final n in plan) n.id};
    _lastPlan = plan;
    return plan.length;
  }
}
