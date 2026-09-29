import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/payment_method.dart';
import '../models/payment_method_model.dart';
import 'payment_method_local_datasource.dart';

/// Drift SQLite implementation of PaymentMethodLocalDataSource.
class PaymentMethodDriftDataSource implements PaymentMethodLocalDataSource {
  final AppDatabase db;

  const PaymentMethodDriftDataSource(this.db);

  @override
  Future<List<PaymentMethodModel>> loadPaymentMethods() async {
    try {
      final rows = await db.select(db.paymentMethodsTable).get();
      return rows.map((row) {
        return PaymentMethodModel(
          id: row.id,
          nickname: row.nickname,
          type: PaymentMethodType.values.firstWhere(
            (e) => e.name == row.type,
            orElse: () => PaymentMethodType.creditCard,
          ),
          brand: CardBrand.values.firstWhere(
            (e) => e.name == row.brand,
            orElse: () => CardBrand.visa,
          ),
          last4: row.last4,
          expiryDate: row.expiryDate,
          cardColorValue: row.cardColorValue,
          isDefault: row.isDefault,
          statementDay: row.statementDay,
        );
      }).toList();
    } catch (e) {
      throw StorageException('Failed to read payment methods from SQLite', e);
    }
  }

  PaymentMethodsTableCompanion _toCompanion(PaymentMethodModel m) {
    return PaymentMethodsTableCompanion.insert(
      id: m.id,
      nickname: m.nickname,
      type: m.type.name,
      brand: m.brand.name,
      last4: Value(m.last4),
      expiryDate: Value(m.expiryDate),
      cardColorValue: Value(m.cardColorValue),
      isDefault: Value(m.isDefault),
      statementDay: Value(m.statementDay),
    );
  }

  @override
  Future<void> savePaymentMethods(List<PaymentMethodModel> methods) async {
    try {
      await db.transaction(() async {
        await db.delete(db.paymentMethodsTable).go();
        if (methods.isNotEmpty) {
          await db.batch((batch) {
            batch.insertAll(db.paymentMethodsTable, methods.map(_toCompanion).toList());
          });
        }
      });
    } catch (e) {
      throw StorageException('Failed to save payment methods to SQLite', e);
    }
  }

  @override
  Future<void> upsertPaymentMethods(List<PaymentMethodModel> methods) async {
    if (methods.isEmpty) return;
    try {
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.paymentMethodsTable, methods.map(_toCompanion).toList());
      });
    } catch (e) {
      throw StorageException('Failed to upsert payment methods to SQLite', e);
    }
  }

  @override
  Future<void> deletePaymentMethods(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await (db.delete(db.paymentMethodsTable)..where((tbl) => tbl.id.isIn(ids))).go();
    } catch (e) {
      throw StorageException('Failed to delete payment methods from SQLite', e);
    }
  }
}
