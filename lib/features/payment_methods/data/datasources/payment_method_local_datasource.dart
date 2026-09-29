import '../models/payment_method_model.dart';

/// Abstract Local DataSource contract for Payment Methods.
abstract class PaymentMethodLocalDataSource {
  Future<List<PaymentMethodModel>> loadPaymentMethods();

  /// Replaces every stored payment method with [methods].
  Future<void> savePaymentMethods(List<PaymentMethodModel> methods);

  /// Inserts or updates [methods] by id, leaving other rows untouched.
  Future<void> upsertPaymentMethods(List<PaymentMethodModel> methods);

  Future<void> deletePaymentMethods(List<String> ids);
}
