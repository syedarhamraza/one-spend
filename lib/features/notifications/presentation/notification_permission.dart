import '../../../core/di/injection.dart';
import '../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../data/notification_service.dart';

/// Asks the OS for notification permission when reminders are switched on in the app
/// but not yet allowed by the system. Returns whether notifications can be shown.
///
/// Android shows the system dialog at most twice before treating it as a permanent denial,
/// so calling this at natural moments (enabling reminders, adding a subscription) is safe.
Future<bool> ensureNotificationPermission() async {
  if (!SubscriptionController.instance.notificationsEnabled) return false;
  final service = sl<NotificationService>();
  if (await service.areEnabled()) return true;
  return service.requestPermission();
}
