import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/payment_methods/data/datasources/payment_method_local_datasource.dart';
import '../../features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import '../../features/payment_methods/domain/repositories/payment_method_repository.dart';
import '../../features/subscriptions/data/datasources/subscription_local_datasource.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../theme/one_ui_theme.dart';

final sl = GetIt.instance;

void setupDependencies() {
  if (sl.isRegistered<SubscriptionController>()) {
    return;
  }

  // 1. DataSources
  sl.registerLazySingleton<SubscriptionLocalDataSource>(
    () => SubscriptionPreferencesDataSource(
      sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
    ),
  );
  sl.registerLazySingleton<PaymentMethodLocalDataSource>(
    () => PaymentMethodPreferencesDataSource(
      sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
    ),
  );

  // 2. Repositories (Pure domain interfaces bound to implementations)
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(sl<SubscriptionLocalDataSource>()),
  );
  sl.registerLazySingleton<PaymentMethodRepository>(
    () => PaymentMethodRepositoryImpl(sl<PaymentMethodLocalDataSource>()),
  );

  // 3. Controllers / State (Managed via GetIt)
  sl.registerLazySingleton<SubscriptionController>(
    () => SubscriptionController(
      subscriptionRepository: sl<SubscriptionRepository>(),
      paymentMethodRepository: sl<PaymentMethodRepository>(),
    ),
  );

  if (!sl.isRegistered<OneUIEffectsController>()) {
    sl.registerLazySingleton<OneUIEffectsController>(() => OneUIEffectsController.instance);
  }
}

Future<void> configureDependencies() async {
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }
  setupDependencies();
}
