import '../../payment_methods/domain/entities/payment_method.dart';
import '../../subscriptions/domain/entities/custom_category.dart';
import '../../subscriptions/domain/entities/subscription.dart';
import 'backup_snapshot.dart';

/// What restoring a backup would do, for the preview screen.
typedef RestorePlan = ({
  int backupSubscriptions,
  int backupPaymentMethods,
  int newSubscriptions,
  int newPaymentMethods,
  int currentSubscriptions,
  int currentPaymentMethods,
  int backupCustomCategories,
  int newCustomCategories,
  int currentCustomCategories,
});

/// Pure logic for "Add missing items".
class BackupMerge {
  const BackupMerge._();

  static RestorePlan plan({
    required List<Subscription> currentSubscriptions,
    required List<PaymentMethod> currentPaymentMethods,
    required BackupSnapshot backup,
    List<CustomCategory> currentCustomCategories = const [],
  }) {
    final missing = missingItems(
      currentSubscriptions: currentSubscriptions,
      currentPaymentMethods: currentPaymentMethods,
      currentCustomCategories: currentCustomCategories,
      backup: backup,
    );
    return (
      backupSubscriptions: backup.subscriptions.length,
      backupPaymentMethods: backup.paymentMethods.length,
      newSubscriptions: missing.subscriptions.length,
      newPaymentMethods: missing.paymentMethods.length,
      currentSubscriptions: currentSubscriptions.length,
      currentPaymentMethods: currentPaymentMethods.length,
      backupCustomCategories: backup.customCategories?.length ?? 0,
      newCustomCategories: missing.customCategories.length,
      currentCustomCategories: currentCustomCategories.length,
    );
  }

  /// Items in [backup] whose id isn't already present. Existing items are never touched.
  /// Custom categories come along when missing, so added subscriptions keep their category.
  static ({List<Subscription> subscriptions, List<PaymentMethod> paymentMethods, List<CustomCategory> customCategories})
      missingItems({
    required List<Subscription> currentSubscriptions,
    required List<PaymentMethod> currentPaymentMethods,
    required BackupSnapshot backup,
    List<CustomCategory> currentCustomCategories = const [],
  }) {
    final subIds = {for (final s in currentSubscriptions) s.id};
    final methodIds = {for (final m in currentPaymentMethods) m.id};
    final categoryIds = {for (final c in currentCustomCategories) c.id};
    return (
      subscriptions: [for (final s in backup.subscriptions) if (!subIds.contains(s.id)) s],
      paymentMethods: [for (final m in backup.paymentMethods) if (!methodIds.contains(m.id)) m],
      customCategories: [
        for (final c in backup.customCategories ?? const <CustomCategory>[])
          if (!categoryIds.contains(c.id)) c,
      ],
    );
  }
}
