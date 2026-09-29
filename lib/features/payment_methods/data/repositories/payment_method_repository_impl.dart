import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../datasources/payment_method_local_datasource.dart';
import '../models/payment_method_model.dart';

/// Concrete Repository implementation for Payment Methods.
class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodLocalDataSource _dataSource;

  const PaymentMethodRepositoryImpl(this._dataSource);

  static PaymentMethodModel _toModel(PaymentMethod m) =>
      m is PaymentMethodModel ? m : PaymentMethodModel.fromEntity(m);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final models = await _dataSource.loadPaymentMethods();
    return models;
  }

  @override
  Future<void> replaceAll(List<PaymentMethod> methods) {
    return _dataSource.savePaymentMethods(methods.map(_toModel).toList());
  }

  @override
  Future<void> upsert(Iterable<PaymentMethod> methods) {
    return _dataSource.upsertPaymentMethods(methods.map(_toModel).toList());
  }

  @override
  Future<void> delete(Iterable<String> ids) {
    return _dataSource.deletePaymentMethods(ids.toList());
  }
}
