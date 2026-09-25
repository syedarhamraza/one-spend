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

  @override
  Future<void> savePaymentMethods(List<PaymentMethodModel> methods) async {
    try {
      await db.transaction(() async {
        await db.delete(db.paymentMethodsTable).go();
        if (methods.isNotEmpty) {
          final companions = methods.map((m) {
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
          }).toList();
          await db.batch((batch) {
            batch.insertAll(db.paymentMethodsTable, companions);
          });
        }
      });
    } catch (e) {
      throw StorageException('Failed to save payment methods to SQLite', e);
    }
  }
}
