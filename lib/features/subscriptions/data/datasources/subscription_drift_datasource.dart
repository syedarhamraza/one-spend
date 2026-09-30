import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../currency/domain/currency.dart';
import '../../domain/entities/subscription_enums.dart';
import '../models/subscription_model.dart';
import 'subscription_local_datasource.dart';

/// Drift SQLite implementation of SubscriptionLocalDataSource.
class SubscriptionDriftDataSource implements SubscriptionLocalDataSource {
  final AppDatabase db;

  const SubscriptionDriftDataSource(this.db);

  @override
  Future<List<SubscriptionModel>> loadSubscriptions() async {
    try {
      final rows = await db.select(db.subscriptionsTable).get();
      return rows.map((row) {
        return SubscriptionModel(
          id: row.id,
          name: row.name,
          description: row.description,
          price: row.price,
          currency: CurrencyCatalog.normalize(row.currency),
          billingCycle: BillingCycle.fromString(row.billingCycle),
          category: SubscriptionCategory.fromString(row.category),
          brandColorValue: row.brandColorValue,
          iconCodePoint: row.iconCodePoint,
          iconFontFamily: row.iconFontFamily,
          nextBillingDate: row.nextBillingDate,
          status: SubscriptionStatus.fromString(row.status),
          paymentMethod: row.paymentMethod,
          paymentMethodId: row.paymentMethodId,
          reminderDays: row.reminderDays,
          isPopular: row.isPopular,
          notes: row.notes,
          paymentHistory: row.paymentHistory,
          accountUrl: row.accountUrl,
          logoUrl: row.logoUrl,
          brandPresetId: row.brandPresetId,
          autoRenew: row.autoRenew,
          anchorDay: row.anchorDay,
          reminderTimeMinutes: row.reminderTimeMinutes,
        );
      }).toList();
    } catch (e) {
      throw StorageException('Failed to read subscriptions from SQLite', e);
    }
  }

  SubscriptionsTableCompanion _toCompanion(SubscriptionModel s) {
    return SubscriptionsTableCompanion.insert(
      id: s.id,
      name: s.name,
      description: s.description,
      price: s.price,
      currency: Value(s.currency),
      billingCycle: s.billingCycle.name,
      category: s.category.name,
      brandColorValue: s.brandColorValue,
      iconCodePoint: Value(s.iconCodePoint),
      iconFontFamily: Value(s.iconFontFamily),
      nextBillingDate: s.nextBillingDate,
      status: s.status.name,
      paymentMethod: s.paymentMethod,
      paymentMethodId: Value(s.paymentMethodId),
      reminderDays: Value(s.reminderDays),
      isPopular: Value(s.isPopular),
      notes: Value(s.notes),
      paymentHistory: Value(s.paymentHistory),
      accountUrl: Value(s.accountUrl),
      logoUrl: Value(s.logoUrl),
      brandPresetId: Value(s.brandPresetId),
      autoRenew: Value(s.autoRenew),
      anchorDay: Value(s.anchorDay),
      reminderTimeMinutes: Value(s.reminderTimeMinutes),
    );
  }

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async {
    try {
      await db.transaction(() async {
        await db.delete(db.subscriptionsTable).go();
        if (subscriptions.isNotEmpty) {
          await db.batch((batch) {
            batch.insertAll(db.subscriptionsTable, subscriptions.map(_toCompanion).toList());
          });
        }
      });
    } catch (e) {
      throw StorageException('Failed to save subscriptions to SQLite', e);
    }
  }

  @override
  Future<void> upsertSubscriptions(List<SubscriptionModel> subscriptions) async {
    if (subscriptions.isEmpty) return;
    try {
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.subscriptionsTable, subscriptions.map(_toCompanion).toList());
      });
    } catch (e) {
      throw StorageException('Failed to upsert subscriptions to SQLite', e);
    }
  }

  @override
  Future<void> deleteSubscriptions(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await (db.delete(db.subscriptionsTable)..where((tbl) => tbl.id.isIn(ids))).go();
    } catch (e) {
      throw StorageException('Failed to delete subscriptions from SQLite', e);
    }
  }
}
