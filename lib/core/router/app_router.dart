import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/payment_methods/domain/entities/payment_method.dart';
import '../../features/subscriptions/domain/entities/subscription_enums.dart';
import '../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../screens/add_subscription_screen.dart';
import '../../screens/analytics_screen.dart';
import '../../screens/billing_cycle_picker_screen.dart';
import '../../screens/category_picker_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/icon_picker_screen.dart';
import '../../screens/payment_history_screen.dart';
import '../../screens/payment_method_editor_screen.dart';
import '../../screens/payment_method_picker_screen.dart';
import '../../screens/popular_presets_screen.dart';
import '../../screens/reminder_picker_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/subscription_card_customizer_screen.dart';
import '../../screens/subscription_detail_customizer_screen.dart';
import '../../screens/subscription_detail_screen.dart';
import '../../screens/subscriptions_screen.dart';
import '../../screens/upcoming_schedule_screen.dart';
import '../../screens/upcoming_screen.dart';
import '../../theme/one_ui_theme.dart';

/// Centralized route paths.
class AppRoutes {
  const AppRoutes._();

  // Bottom navigation tabs
  static const subscriptions = '/subscriptions';
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
  static const billingCyclePicker = '/pickers/billing-cycle';
  static const reminderPicker = '/pickers/reminder';
  static const iconPicker = '/pickers/icon';
  static const cardStudio = '/settings/card-studio';
  static const detailStudio = '/settings/detail-studio';
}

/// Arguments for [AppRoutes.paymentMethods].
typedef PaymentMethodPickerArgs = ({String? currentMethodId, bool isManageOnly});

/// Arguments for [AppRoutes.iconPicker].
typedef IconPickerArgs = ({
  Color initialColor,
  IconData initialIcon,
  String? initialLogoUrl,
  String? initialPresetId,
  String subscriptionName,
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
    GoRoute(
      path: AppRoutes.addSubscription,
      // Optional `extra`: a payment method id to pre-select on the new subscription.
      builder: (context, state) => AddSubscriptionScreen(initialPaymentMethodId: state.extra as String?),
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
      builder: (context, state) =>
          CategoryPickerScreen(initialCategory: state.extra as SubscriptionCategory? ?? SubscriptionCategory.utilities),
    ),
    GoRoute(
      path: AppRoutes.billingCyclePicker,
      builder: (context, state) =>
          BillingCyclePickerScreen(initialCycle: state.extra as BillingCycle? ?? BillingCycle.monthly),
    ),
    GoRoute(
      path: AppRoutes.reminderPicker,
      builder: (context, state) => ReminderPickerScreen(initialDays: state.extra as int? ?? 2),
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
        );
      },
    ),
    GoRoute(path: AppRoutes.cardStudio, builder: (context, state) => const SubscriptionCardCustomizerScreen()),
    GoRoute(path: AppRoutes.detailStudio, builder: (context, state) => const SubscriptionDetailCustomizerScreen()),
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
