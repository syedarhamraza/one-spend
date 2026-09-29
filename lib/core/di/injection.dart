import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/migration/shared_preferences_migrator.dart';
import '../../features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import '../../features/payment_methods/data/datasources/payment_method_local_datasource.dart';
import '../../features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import '../../features/payment_methods/domain/repositories/payment_method_repository.dart';
import '../../features/settings/data/datasources/settings_drift_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import '../../features/subscriptions/data/datasources/subscription_local_datasource.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../theme/one_ui_theme.dart';

final sl = GetIt.instance;

void setupDependencies({AppDatabase? database}) {
  if (database != null) {
    if (sl.isRegistered<SubscriptionController>()) {
      sl.unregister<SubscriptionController>();
    }
    if (sl.isRegistered<SubscriptionRepository>()) {
      sl.unregister<SubscriptionRepository>();
    }
    if (sl.isRegistered<PaymentMethodRepository>()) {
      sl.unregister<PaymentMethodRepository>();
    }
    if (sl.isRegistered<SettingsRepository>()) {
      sl.unregister<SettingsRepository>();
    }
    if (sl.isRegistered<SubscriptionLocalDataSource>()) {
      sl.unregister<SubscriptionLocalDataSource>();
    }
    if (sl.isRegistered<PaymentMethodLocalDataSource>()) {
      sl.unregister<PaymentMethodLocalDataSource>();
    }
    if (sl.isRegistered<AppDatabase>()) {
      sl.unregister<AppDatabase>();
    }
    sl.registerSingleton<AppDatabase>(database);
  } else if (!sl.isRegistered<AppDatabase>()) {
    sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  }

  // 1. DataSources (using Drift SQLite)
  if (!sl.isRegistered<SubscriptionLocalDataSource>()) {
    sl.registerLazySingleton<SubscriptionLocalDataSource>(
      () => SubscriptionDriftDataSource(sl<AppDatabase>()),
    );
  }

  if (!sl.isRegistered<PaymentMethodLocalDataSource>()) {
    sl.registerLazySingleton<PaymentMethodLocalDataSource>(
      () => PaymentMethodDriftDataSource(sl<AppDatabase>()),
    );
  }

  // 2. Repositories (Pure domain interfaces bound to implementations)
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(SettingsDriftDataSource(sl<AppDatabase>())),
    );
  }
  if (!sl.isRegistered<SubscriptionRepository>()) {
    sl.registerLazySingleton<SubscriptionRepository>(
      () => SubscriptionRepositoryImpl(sl<SubscriptionLocalDataSource>()),
    );
  }
  if (!sl.isRegistered<PaymentMethodRepository>()) {
    sl.registerLazySingleton<PaymentMethodRepository>(
      () => PaymentMethodRepositoryImpl(sl<PaymentMethodLocalDataSource>()),
    );
  }

  // 3. Controllers / State (Managed via GetIt)
  if (!sl.isRegistered<SubscriptionController>()) {
    sl.registerLazySingleton<SubscriptionController>(
      () => SubscriptionController(
        subscriptionRepository: sl<SubscriptionRepository>(),
        paymentMethodRepository: sl<PaymentMethodRepository>(),
        settingsRepository: sl<SettingsRepository>(),
      ),
    );
  }

  if (!sl.isRegistered<OneUIEffectsController>()) {
    sl.registerLazySingleton<OneUIEffectsController>(() => OneUIEffectsController.instance);
  }
}

Future<void> configureDependencies({AppDatabase? database}) async {
  // 1. SharedPreferences for bootstrap/theme keys and legacy migration
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
  }

  // 2. Database
  if (database != null) {
    if (sl.isRegistered<AppDatabase>()) {
      sl.unregister<AppDatabase>();
    }
    sl.registerSingleton<AppDatabase>(database);
  } else if (!sl.isRegistered<AppDatabase>()) {
    sl.registerSingleton<AppDatabase>(AppDatabase());
  }

  // 3. One-time legacy migration check
  final migrator = SharedPreferencesMigrator(
    prefs: sl<SharedPreferences>(),
    db: sl<AppDatabase>(),
  );
  await migrator.checkAndMigrate();

  // 4. Wire dependencies
  setupDependencies();

  // 5. Load persisted state before the first frame so nothing renders stale data
  await sl<SubscriptionController>().load();
  await sl<OneUIEffectsController>().init();
}
