import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../datasources/payment_method_local_datasource.dart';
import '../models/payment_method_model.dart';

/// Concrete Repository implementation for Payment Methods.
class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodLocalDataSource _dataSource;

  const PaymentMethodRepositoryImpl(this._dataSource);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final models = await _dataSource.loadPaymentMethods();
    return models;
  }

  @override
  Future<void> savePaymentMethods(List<PaymentMethod> methods) async {
    final models = methods.map((m) => m is PaymentMethodModel ? m : PaymentMethodModel.fromEntity(m)).toList();
    await _dataSource.savePaymentMethods(models);
  }

  @override
  Future<void> addPaymentMethod(PaymentMethod method) async {
    final current = await getPaymentMethods();
    final updated = List<PaymentMethod>.from(current)..add(method);
    await savePaymentMethods(updated);
  }

  @override
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    final current = await getPaymentMethods();
    final index = current.indexWhere((m) => m.id == method.id);
    if (index != -1) {
      final updated = List<PaymentMethod>.from(current)..[index] = method;
      await savePaymentMethods(updated);
    }
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    final current = await getPaymentMethods();
    final updated = current.where((m) => m.id != id).toList();
    await savePaymentMethods(updated);
  }
}
