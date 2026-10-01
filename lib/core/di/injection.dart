import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/migration/shared_preferences_migrator.dart';
import '../../features/currency/data/exchange_rate_repository.dart';
import '../../features/currency/data/rates_remote_datasource.dart';
import '../../features/payment_methods/data/datasources/payment_method_drift_datasource.dart';
import '../../features/payment_methods/data/datasources/payment_method_local_datasource.dart';
import '../../features/payment_methods/data/repositories/payment_method_repository_impl.dart';
import '../../features/payment_methods/domain/repositories/payment_method_repository.dart';
import '../../features/notifications/data/local_notification_service.dart';
import '../../features/notifications/data/notification_service.dart';
import '../../features/notifications/presentation/notification_scheduler.dart';
import '../../features/settings/data/datasources/settings_drift_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/subscriptions/data/datasources/subscription_drift_datasource.dart';
import '../../features/subscriptions/data/datasources/subscription_local_datasource.dart';
import '../../features/subscriptions/data/repositories/subscription_repository_impl.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/backup/data/backup_service.dart';
import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_toast.dart';

final sl = GetIt.instance;

void setupDependencies({AppDatabase? database}) {
  if (database != null) {
    if (sl.isRegistered<BackupService>()) {
      sl.unregister<BackupService>();
    }
    if (sl.isRegistered<SubscriptionController>()) {
      sl.unregister<SubscriptionController>();
    }
    if (sl.isRegistered<ExchangeRateRepository>()) {
      sl.unregister<ExchangeRateRepository>();
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

  // Exchange rates: offline unless configureDependencies() registered the HTTP source
  if (!sl.isRegistered<ExchangeRateRepository>()) {
    sl.registerLazySingleton<ExchangeRateRepository>(
      () => ExchangeRateRepository(
        database: sl<AppDatabase>(),
        remote: sl.isRegistered<RatesRemoteDataSource>()
            ? sl<RatesRemoteDataSource>()
            : const OfflineRatesRemoteDataSource(),
      ),
    );
  }

  // 3. Controllers / State (Managed via GetIt)
  if (!sl.isRegistered<SubscriptionController>()) {
    sl.registerLazySingleton<SubscriptionController>(
      () => SubscriptionController(
        subscriptionRepository: sl<SubscriptionRepository>(),
        paymentMethodRepository: sl<PaymentMethodRepository>(),
        settingsRepository: sl<SettingsRepository>(),
        rates: sl<ExchangeRateRepository>(),
      ),
    );
  }

  if (!sl.isRegistered<BackupService>()) {
    sl.registerLazySingleton<BackupService>(
      () => BackupService(controller: sl<SubscriptionController>(), settings: sl<SettingsRepository>()),
    );
  }

  if (!sl.isRegistered<OneUIEffectsController>()) {
    sl.registerLazySingleton<OneUIEffectsController>(() => OneUIEffectsController.instance);
  }

  // 4. Notifications: a no-op unless configureDependencies() registered the platform service
  if (!sl.isRegistered<NotificationService>()) {
    sl.registerSingleton<NotificationService>(NoopNotificationService());
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

  // 4. Platform notifications (must be registered before setupDependencies falls back to the no-op)
  if (!sl.isRegistered<NotificationService>()) {
    final notifications = LocalNotificationService();
    try {
      await notifications.init();
      sl.registerSingleton<NotificationService>(notifications);
    } catch (e) {
      debugPrint('OneSpend: Notifications unavailable: $e');
    }
  }

  // Lets OneUIToast skip "Copied" toasts on Android 13+ (the system shows its own).
  unawaited(OneUIToast.init());

  // 5. Wire dependencies
  if (!sl.isRegistered<RatesRemoteDataSource>()) {
    sl.registerSingleton<RatesRemoteDataSource>(HttpRatesRemoteDataSource());
  }
  setupDependencies();

  // 6. Load persisted state before the first frame so nothing renders stale data.
  // Cached exchange rates load first; fresh ones download in the background.
  final rates = sl<ExchangeRateRepository>();
  await rates.load();
  unawaited(rates.refresh());
  AppLifecycleListener(onResume: () => unawaited(rates.refresh()));
  await sl<SubscriptionController>().load();
  await sl<OneUIEffectsController>().init();

  // 7. Keep scheduled reminders in sync with the data from now on
  if (!sl.isRegistered<NotificationScheduler>()) {
    final scheduler = NotificationScheduler(
      controller: sl<SubscriptionController>(),
      service: sl<NotificationService>(),
    );
    sl.registerSingleton<NotificationScheduler>(scheduler);
    scheduler.start();
  }
}
