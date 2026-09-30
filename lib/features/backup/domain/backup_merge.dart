import '../../payment_methods/domain/entities/payment_method.dart';
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
});

/// Pure logic for "Add missing items".
class BackupMerge {
  const BackupMerge._();

  static RestorePlan plan({
    required List<Subscription> currentSubscriptions,
    required List<PaymentMethod> currentPaymentMethods,
    required BackupSnapshot backup,
  }) {
    final missing = missingItems(
      currentSubscriptions: currentSubscriptions,
      currentPaymentMethods: currentPaymentMethods,
      backup: backup,
    );
    return (
      backupSubscriptions: backup.subscriptions.length,
      backupPaymentMethods: backup.paymentMethods.length,
      newSubscriptions: missing.subscriptions.length,
      newPaymentMethods: missing.paymentMethods.length,
      currentSubscriptions: currentSubscriptions.length,
      currentPaymentMethods: currentPaymentMethods.length,
    );
  }

  /// Items in [backup] whose id isn't already present. Existing items are never touched.
  static ({List<Subscription> subscriptions, List<PaymentMethod> paymentMethods}) missingItems({
    required List<Subscription> currentSubscriptions,
    required List<PaymentMethod> currentPaymentMethods,
    required BackupSnapshot backup,
  }) {
    final subIds = {for (final s in currentSubscriptions) s.id};
    final methodIds = {for (final m in currentPaymentMethods) m.id};
    return (
      subscriptions: [for (final s in backup.subscriptions) if (!subIds.contains(s.id)) s],
      paymentMethods: [for (final m in backup.paymentMethods) if (!methodIds.contains(m.id)) m],
    );
  }
}
