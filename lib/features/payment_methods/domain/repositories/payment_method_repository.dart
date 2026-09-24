import '../entities/payment_method.dart';

/// Pure Domain Repository contract for Payment Methods.
/// Ready for future database migration (e.g. to Drift).
abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<void> savePaymentMethods(List<PaymentMethod> methods);
  Future<void> addPaymentMethod(PaymentMethod method);
  Future<void> updatePaymentMethod(PaymentMethod method);
  Future<void> deletePaymentMethod(String id);
}
