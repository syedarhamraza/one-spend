// Backward-compatibility Facade for legacy payment method imports.
// Re-exports Clean Architecture payment_methods feature modules.
library;

export '../features/payment_methods/domain/entities/payment_method.dart';
export '../features/payment_methods/presentation/utils/payment_brand_ui_adapters.dart';
export '../features/payment_methods/data/fixtures/default_payment_methods.dart';
