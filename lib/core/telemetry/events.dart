import '../../features/subscriptions/domain/entities/subscription_enums.dart';

/// Every analytics event One Spend sends. Parameters are only fixed names, counts and
/// flags; nothing the user typed or any amount of money ever goes here.
class TelemetryEvent {
  /// Firebase event name: lowercase with underscores, at most 40 characters.
  final String name;

  /// Values are `String` (from code, never user input), `int` or `bool` only.
  final Map<String, Object> params;

  const TelemetryEvent._(this.name, [this.params = const {}]);

  static const onboardingCompleted = TelemetryEvent._('onboarding_completed');

  /// Custom categories are named by the user, so they're reported only as `custom`.
  factory TelemetryEvent.subscriptionAdded({
    required SubscriptionCategory category,
    required BillingCycle billingCycle,
    required bool fromPreset,
  }) =>
      TelemetryEvent._('subscription_added', {
        'category': category.isCustom ? 'custom' : category.name,
        'billing_cycle': billingCycle.name,
        'from_preset': fromPreset,
      });

  factory TelemetryEvent.subscriptionsDeleted(int count) =>
      TelemetryEvent._('subscriptions_deleted', {'count': count});

  static const renewTapped = TelemetryEvent._('renew_tapped');
  static const renewUndone = TelemetryEvent._('renew_undone');

  static const backupSaved = TelemetryEvent._('backup_saved');

  /// [mode] is `add_missing` or `replace`; [fromRestorePoint] when it came from a restore point.
  factory TelemetryEvent.backupRestored({required String mode, required bool fromRestorePoint}) =>
      TelemetryEvent._('backup_restored', {'mode': mode, 'from_restore_point': fromRestorePoint});

  static const clearAll = TelemetryEvent._('clear_all');
  static const undoLast = TelemetryEvent._('undo_last');

  /// [format] is `pdf`, `csv`, `text`, `backup` or `calendar`; [scope] is `all`, `category`,
  /// `selection`, `single` or `upcoming`.
  factory TelemetryEvent.exportShared({required String format, required String scope}) =>
      TelemetryEvent._('export_shared', {'format': format, 'scope': scope});

  /// [which] is `cards` or `details`.
  factory TelemetryEvent.studioOpened(String which) => TelemetryEvent._('studio_opened', {'which': which});

  static const customCategoryCreated = TelemetryEvent._('custom_category_created');

  /// [target] is what the notification opened: `subscription`, `card` or `tab`.
  factory TelemetryEvent.notificationOpened(String target) =>
      TelemetryEvent._('notification_opened', {'target': target});

  /// [result] is the update check's outcome, e.g. `up_to_date` or `available`.
  factory TelemetryEvent.updateCheck(String result) => TelemetryEvent._('update_check', {'result': result});

  static const updateStarted = TelemetryEvent._('update_started');

  @override
  String toString() => params.isEmpty ? name : '$name $params';
}

/// Keys attached to every crash report, describing the setup (never the data).
class TelemetryContext {
  const TelemetryContext._();

  static const version = 'version';
  static const build = 'build';
  static const channel = 'channel';
  static const currency = 'currency';
  static const subscriptions = 'subscriptions_bucket';
  static const notifications = 'notifications_enabled';
  static const effects3d = '3d_effects';

  /// Rough size of the user's list, so reports can be grouped without exact counts.
  static String bucket(int count) => switch (count) {
        0 => '0',
        <= 5 => '1-5',
        <= 20 => '6-20',
        _ => '21+',
      };
}
