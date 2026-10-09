import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/currency/domain/currency.dart';
import '../../features/backup/domain/backup_snapshot.dart';
import '../../features/backup/domain/restore_point.dart';
import '../../features/payment_methods/domain/entities/payment_method.dart';
import '../../features/subscriptions/domain/entities/subscription_enums.dart';
import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../screens/add_subscription_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../features/reports/presentation/export_share_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/billing_cycle_picker_screen.dart';
import '../../screens/category_editor_screen.dart';
import '../../screens/category_picker_screen.dart';
import '../../screens/date_picker_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/icon_picker_screen.dart';
import '../../screens/payment_history_screen.dart';
import '../../screens/payment_method_editor_screen.dart';
import '../../screens/payment_method_picker_screen.dart';
import '../../screens/popular_presets_screen.dart';
import '../../screens/reminder_picker_screen.dart';
import '../../screens/settings/about_screen.dart';
import '../../screens/settings/appearance_settings_screen.dart';
import '../../screens/settings/author_screen.dart';
import '../../screens/settings/backup_data_screen.dart';
import '../../screens/settings/budget_currency_screen.dart';
import '../../screens/settings/categories_screen.dart';
import '../../screens/settings/changelog_screen.dart';
import '../../screens/settings/coming_soon_screen.dart';
import '../../screens/settings/currency_picker_screen.dart';
import '../../screens/settings/exchange_rates_screen.dart';
import '../../screens/settings/developer_options_screen.dart';
import '../../screens/settings/help_feedback_screen.dart';
import '../../screens/settings/licenses_screen.dart';
import '../../screens/settings/notification_settings_screen.dart';
import '../../screens/settings/vibration_settings_screen.dart';
import '../../screens/settings/planned_feature.dart';
import '../../screens/settings/restore_points_screen.dart';
import '../../screens/settings/restore_preview_screen.dart';
import '../../screens/settings/security_settings_screen.dart';
import '../../screens/settings/software_update_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/subscription_card_customizer_screen.dart';
import '../../screens/subscription_detail_customizer_screen.dart';
import '../../screens/subscription_detail_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../screens/time_picker_screen.dart';
import '../../screens/upcoming_schedule_screen.dart';
import '../../screens/upcoming_screen.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/reminder_format.dart';
import '../../features/subscriptions/domain/entities/logo_transform.dart';

/// Centralized route paths.
class AppRoutes {
  const AppRoutes._();

  // Bottom navigation tabs
  static const subscriptions = '/subscriptions';

  /// First-run welcome (onboarding), shown instead of the tabs on a fresh install.
  static const welcome = '/welcome';
  static const upcoming = '/upcoming';
  static const analytics = '/analytics';
  static const settings = '/settings';

  // Full-screen pages (pushed above the tab shell)
  static const addSubscription = '/subscriptions/new';
  static String subscriptionDetail(String id) => '/subscriptions/${Uri.encodeComponent(id)}';
  static String paymentHistory(String id) => '${subscriptionDetail(id)}/history';
  static String upcomingSchedule(String id) => '${subscriptionDetail(id)}/schedule';
  static const paymentMethods = '/payment-methods';
  static const paymentMethodEditor = '/payment-methods/editor';
  static String methodSubscriptions(String methodId) =>
      '$paymentMethods/${Uri.encodeComponent(methodId)}/subscriptions';
  static const popularPresets = '/presets';
  static const categoryPicker = '/pickers/category';

  /// Create (no `extra`) or edit (`extra`: the custom category id) a custom category.
  static const categoryEditor = '/categories/editor';
  static const billingCyclePicker = '/pickers/billing-cycle';
  static const reminderPicker = '/pickers/reminder';
  static const iconPicker = '/pickers/icon';
  static const timePicker = '/pickers/time';
  static const datePicker = '/pickers/date';
  static const cardStudio = '/settings/card-studio';
  static const detailStudio = '/settings/detail-studio';

  // Settings subpages
  static const settingsCategories = '/settings/categories';
  static const settingsBudget = '/settings/budget';
  static const settingsCurrency = '/settings/budget/currency';
  static const settingsExchangeRates = '/settings/budget/rates';
  static const settingsNotifications = '/settings/notifications';
  static const settingsVibration = '/settings/vibration';
  static const settingsAppearance = '/settings/appearance';
  static const settingsSecurity = '/settings/security';
  static const settingsData = '/settings/data';
  static const settingsRestore = '/settings/data/restore';
  static const settingsRestorePoints = '/settings/data/restore-points';
  static const settingsHelp = '/settings/help';
  static const settingsAbout = '/settings/about';
  static const settingsAuthor = '/settings/about/developer';
  static const settingsLicenses = '/settings/about/licenses';
  static const settingsSoftwareUpdate = '/settings/software-update';
  static const settingsChangelog = '/settings/software-update/changelog';

  /// Export & share (PDF report, CSV, text, backup). `extra`: optional category.
  static const exportShare = '/export';
  static const settingsLicenseDetail = '/settings/about/licenses/detail';
  static const settingsDeveloperOptions = '/settings/developer-options';
  static const comingSoon = '/settings/coming-soon';
}

/// Arguments for [AppRoutes.paymentMethods].
typedef PaymentMethodPickerArgs = ({String? currentMethodId, bool isManageOnly});

/// Arguments for [AppRoutes.categoryPicker]: the selected category, and any to leave out.
typedef CategoryPickerArgs = ({SubscriptionCategory initial, Set<SubscriptionCategory> exclude, String? title});

/// `extra` for [AppRoutes.addSubscription]: start the new subscription from a
/// brand preset (e.g. a quick-add chip) and/or with a card pre-selected.
typedef AddSubscriptionArgs = ({String? paymentMethodId, String? presetId});

/// Arguments for [AppRoutes.settingsCurrency].
typedef CurrencyPickerArgs = ({String initialCode, String title, String? footnote});

/// Arguments for [AppRoutes.timePicker]; times are minutes after midnight.
typedef TimePickerArgs = ({int initialMinutes, String title, String? subtitle});

/// Arguments for [AppRoutes.datePicker].
typedef DatePickerArgs = ({
  DateTime initialDate,
  DateTime firstDate,
  DateTime lastDate,
  String title,
  String? subtitle,
});

/// Arguments for [AppRoutes.iconPicker].
typedef IconPickerArgs = ({
  Color initialColor,
  IconData initialIcon,
  String? initialLogoUrl,
  String? initialPresetId,
  String subscriptionName,
  LogoTransform? initialLogoTransform,
});

/// Resolves a subscription id from the path, or shows a fallback when it no longer exists.
Widget _withSubscription(GoRouterState state, Widget Function(String id) builder) {
  final id = state.pathParameters['id']!;
  if (SubscriptionController.instance.getSubscription(id) == null) {
    return const _SubscriptionNotFoundScreen();
  }
  return builder(id);
}

/// Every full-screen page route. Shared by the app router and widget tests.
List<RouteBase> buildPageRoutes() {
  return [
    GoRoute(path: AppRoutes.welcome, builder: (context, state) => const OnboardingScreen()),
    GoRoute(
      path: AppRoutes.exportShare,
      builder: (context, state) => ExportShareScreen(category: state.extra as SubscriptionCategory?),
    ),
    GoRoute(
      path: AppRoutes.addSubscription,
      // Optional `extra`: a payment method id (String) to pre-select, or
      // [AddSubscriptionArgs] to also start from a brand preset.
      builder: (context, state) {
        final extra = state.extra;
        return switch (extra) {
          AddSubscriptionArgs(:final paymentMethodId, :final presetId) =>
            AddSubscriptionScreen(initialPaymentMethodId: paymentMethodId, initialPresetId: presetId),
          String id => AddSubscriptionScreen(initialPaymentMethodId: id),
          _ => const AddSubscriptionScreen(),
        };
      },
    ),
    GoRoute(
      path: '/subscriptions/:id',
      builder: (context, state) => _withSubscription(
        state,
        (id) => SubscriptionDetailScreen(subscription: SubscriptionController.instance.getSubscription(id)!),
      ),
      routes: [
        GoRoute(
          path: 'history',
          builder: (context, state) => _withSubscription(state, (id) => PaymentHistoryScreen(subscriptionId: id)),
        ),
        GoRoute(
          path: 'schedule',
          builder: (context, state) => _withSubscription(
            state,
            (id) => UpcomingScheduleScreen(subscription: SubscriptionController.instance.getSubscription(id)!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.paymentMethods,
      builder: (context, state) {
        final args = state.extra as PaymentMethodPickerArgs?;
        return PaymentMethodPickerScreen(
          initialMethodId: args?.currentMethodId,
          isManageOnly: args?.isManageOnly ?? true,
        );
      },
    ),
    GoRoute(
      path: '/payment-methods/:methodId/subscriptions',
      // Card-filtered list pushed above the shell; no HomeChrome callbacks so it never hides the tab bar.
      builder: (context, state) => SubscriptionsScreen(filterPaymentMethodId: state.pathParameters['methodId']),
    ),
    GoRoute(
      path: AppRoutes.paymentMethodEditor,
      builder: (context, state) => PaymentMethodEditorScreen(initialMethod: state.extra as PaymentMethod?),
    ),
    GoRoute(path: AppRoutes.popularPresets, builder: (context, state) => const PopularPresetsScreen()),
    GoRoute(
      path: AppRoutes.categoryPicker,
      builder: (context, state) {
        final args = state.extra as CategoryPickerArgs?;
        return CategoryPickerScreen(
          initialCategory: args?.initial ?? SubscriptionCategory.utilities,
          exclude: args?.exclude ?? const {},
          title: args?.title,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.categoryEditor,
      builder: (context, state) => CategoryEditorScreen(categoryId: state.extra as String?),
    ),
    GoRoute(path: AppRoutes.settingsCategories, builder: (context, state) => const CategoriesScreen()),
    GoRoute(
      path: AppRoutes.billingCyclePicker,
      builder: (context, state) =>
          BillingCyclePickerScreen(initialCycle: state.extra as BillingCycle? ?? BillingCycle.monthly),
    ),
    GoRoute(
      path: AppRoutes.timePicker,
      builder: (context, state) {
        final args = state.extra as TimePickerArgs?;
        return TimePickerScreen(
          initialMinutes: args?.initialMinutes ?? 9 * 60,
          title: args?.title ?? 'Reminder time',
          subtitle: args?.subtitle,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.datePicker,
      builder: (context, state) {
        final args = state.extra! as DatePickerArgs;
        return DatePickerScreen(
          initialDate: args.initialDate,
          firstDate: args.firstDate,
          lastDate: args.lastDate,
          title: args.title,
          subtitle: args.subtitle,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.reminderPicker,
      builder: (context, state) {
        final initial = state.extra as ReminderSetting?;
        return ReminderPickerScreen(
          initialDays: initial?.days ?? 2,
          initialTimeMinutes: initial?.timeMinutes ?? 9 * 60,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.iconPicker,
      builder: (context, state) {
        final args = state.extra! as IconPickerArgs;
        return IconPickerScreen(
          initialColor: args.initialColor,
          initialIcon: args.initialIcon,
          initialLogoUrl: args.initialLogoUrl,
          initialPresetId: args.initialPresetId,
          subscriptionName: args.subscriptionName,
          initialLogoTransform: args.initialLogoTransform,
        );
      },
    ),
    GoRoute(path: AppRoutes.cardStudio, builder: (context, state) => const SubscriptionCardCustomizerScreen()),
    GoRoute(path: AppRoutes.detailStudio, builder: (context, state) => const SubscriptionDetailCustomizerScreen()),
    GoRoute(path: AppRoutes.settingsBudget, builder: (context, state) => const BudgetCurrencyScreen()),
    GoRoute(
      path: AppRoutes.settingsCurrency,
      builder: (context, state) {
        final args = state.extra as CurrencyPickerArgs?;
        return CurrencyPickerScreen(
          initialCode: args?.initialCode ?? CurrencyCatalog.defaultCode,
          title: args?.title ?? 'Currency',
          footnote: args?.footnote,
        );
      },
    ),
    GoRoute(path: AppRoutes.settingsExchangeRates, builder: (context, state) => const ExchangeRatesScreen()),
    GoRoute(path: AppRoutes.settingsNotifications, builder: (context, state) => const NotificationSettingsScreen()),
    GoRoute(path: AppRoutes.settingsVibration, builder: (context, state) => const VibrationSettingsScreen()),
    GoRoute(path: AppRoutes.settingsAppearance, builder: (context, state) => const AppearanceSettingsScreen()),
    GoRoute(path: AppRoutes.settingsSecurity, builder: (context, state) => const SecuritySettingsScreen()),
    GoRoute(path: AppRoutes.settingsData, builder: (context, state) => const BackupDataScreen()),
    GoRoute(
      path: AppRoutes.settingsRestore,
      builder: (context, state) => switch (state.extra) {
        final RestorePoint point => RestorePreviewScreen(backup: point.snapshot, restorePoint: point),
        final extra => RestorePreviewScreen(backup: extra! as BackupSnapshot),
      },
    ),
    GoRoute(path: AppRoutes.settingsRestorePoints, builder: (context, state) => const RestorePointsScreen()),
    GoRoute(path: AppRoutes.settingsHelp, builder: (context, state) => const HelpFeedbackScreen()),
    GoRoute(path: AppRoutes.settingsAbout, builder: (context, state) => const AboutScreen()),
    GoRoute(path: AppRoutes.settingsAuthor, builder: (context, state) => const AuthorScreen()),
    GoRoute(path: AppRoutes.settingsLicenses, builder: (context, state) => const LicensesScreen()),
    GoRoute(path: AppRoutes.settingsSoftwareUpdate, builder: (context, state) => const SoftwareUpdateScreen()),
    GoRoute(path: AppRoutes.settingsChangelog, builder: (context, state) => const ChangelogScreen()),
    GoRoute(
      path: AppRoutes.settingsLicenseDetail,
      builder: (context, state) => LicenseDetailScreen(packageName: state.extra as String? ?? ''),
    ),
    GoRoute(path: AppRoutes.settingsDeveloperOptions, builder: (context, state) => const DeveloperOptionsScreen()),
    GoRoute(
      path: AppRoutes.comingSoon,
      builder: (context, state) => ComingSoonScreen(feature: state.extra as PlannedFeature? ?? PlannedFeature.widgets),
    ),
  ];
}

/// Builds the app router: a four-tab shell with full-screen pages pushed above it.
GoRouter createAppRouter({String initialLocation = AppRoutes.subscriptions}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.subscriptions),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.subscriptions,
                builder: (context, state) => SubscriptionsScreen(
                  onSelectionModeChanged: (active) => HomeChrome.selectionActive.value = active,
                  onSearchModeChanged: (active) => HomeChrome.searchActive.value = active,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.upcoming, builder: (context, state) => const UpcomingScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.analytics, builder: (context, state) => const AnalyticsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen())],
          ),
        ],
      ),
      ...buildPageRoutes(),
    ],
  );
}

class _SubscriptionNotFoundScreen extends StatelessWidget {
  const _SubscriptionNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      appBar: AppBar(backgroundColor: OneUITheme.surfacePitch),
      body: const Center(
        child: Text(
          'This subscription no longer exists',
          style: TextStyle(color: OneUITheme.textSecondary, fontSize: 15),
        ),
      ),
    );
  }
}
