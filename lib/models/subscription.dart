// Backward-compatibility Facade for legacy subscription imports.
// Re-exports Clean Architecture subscriptions and payment_methods feature modules.
library;

export '../features/subscriptions/domain/entities/subscription.dart';
export '../features/subscriptions/domain/entities/subscription_enums.dart';
export '../features/subscriptions/presentation/utils/subscription_ui_adapters.dart';
export '../features/subscriptions/data/fixtures/popular_catalog.dart';
export '../features/subscriptions/presentation/controllers/subscription_controller.dart';
export '../features/payment_methods/domain/entities/payment_method.dart';
export '../features/payment_methods/presentation/utils/payment_brand_ui_adapters.dart';
export '../features/payment_methods/data/fixtures/default_payment_methods.dart';
export 'payment_method.dart';
export 'spending_trend.dart';

import '../features/subscriptions/presentation/controllers/subscription_controller.dart';

typedef SubscriptionStore = SubscriptionController;
