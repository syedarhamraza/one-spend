import '../../currency/domain/exchange_rates.dart';
import '../../payment_methods/domain/entities/payment_method.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import '../../subscriptions/domain/entities/subscription_enums.dart';

/// App-wide preferences stored in a backup.
typedef BackupSettings = ({
  double monthlyBudget,
  String currency,
  int defaultReminderDays,
  int defaultReminderTimeMinutes,
  bool notificationsEnabled,
  SubscriptionSortOption sortOption,
  bool groupByDate,
});

/// Everything a OneSpend backup holds.
///
/// Profile fields, recent searches and dismissed tips are left out on purpose.
class BackupSnapshot {
  final DateTime createdAt;

  /// e.g. "1.0.0 (1)"; empty when unknown (such as legacy exports).
  final String appVersion;
  final List<Subscription> subscriptions;
  final List<PaymentMethod> paymentMethods;

  /// Null for legacy exports, which held subscriptions only.
  final BackupSettings? settings;

  /// Raw appearance key/values (without the `appearance.` prefix).
  final Map<String, String> appearance;

  /// Exchange rates the user pinned, by currency code; null for backups made before
  /// multi-currency support.
  final Map<String, RateOverride>? rateOverrides;

  /// User-made categories (backup format v2); null for older backups, which had none.
  final List<CustomCategory>? customCategories;

  const BackupSnapshot({
    required this.createdAt,
    required this.appVersion,
    required this.subscriptions,
    required this.paymentMethods,
    this.settings,
    this.appearance = const {},
    this.rateOverrides,
    this.customCategories,
  });

  /// True for files produced by the old subscriptions-only "Export backup".
  bool get isLegacy => settings == null;
}

/// How a backup is applied.
enum RestoreMode {
  /// Add subscriptions and cards that aren't already present; change nothing else.
  addMissing,

  /// Replace all data and settings with the backup (after saving a restore point).
  replace,
}
