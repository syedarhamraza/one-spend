import '../entities/payment_method.dart';

/// Pure Domain Repository contract for Payment Methods.
abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> getPaymentMethods();

  /// Replaces every stored payment method with [methods].
  Future<void> replaceAll(List<PaymentMethod> methods);

  /// Inserts or updates [methods] by id.
  Future<void> upsert(Iterable<PaymentMethod> methods);

  Future<void> delete(Iterable<String> ids);
}
