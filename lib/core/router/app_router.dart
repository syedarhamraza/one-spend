import 'package:flutter/material.dart';
import '../../features/payment_methods/domain/entities/payment_method.dart';
import '../../features/subscriptions/domain/entities/subscription.dart';
import '../../features/subscriptions/domain/entities/subscription_enums.dart';
import '../../screens/add_subscription_screen.dart';
import '../../screens/category_picker_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/icon_picker_screen.dart';
import '../../screens/payment_history_screen.dart';
import '../../screens/payment_method_editor_screen.dart';
import '../../screens/payment_method_picker_screen.dart';
import '../../screens/payment_methods_screen.dart';
import '../../screens/popular_presets_screen.dart';
import '../../screens/reminder_picker_screen.dart';
import '../../screens/subscription_detail_screen.dart';
import '../../screens/upcoming_schedule_screen.dart';
import '../../utils/one_ui_brand_catalog.dart';
import '../../widgets/one_ui_icon_picker_modal.dart';

/// Centralized Router Paths
class AppRoutes {
  static const home = '/';
  static const addSubscription = '/subscriptions/add';
  static const subscriptionDetail = '/subscriptions/detail';
  static const paymentHistory = '/payment-history';
  static const upcomingSchedule = '/upcoming-schedule';
  static const paymentMethods = '/payment-methods';
  static const paymentMethodEditor = '/payment-methods/editor';
  static const paymentMethodPicker = '/payment-methods/picker';
  static const categoryPicker = '/picker/category';
  static const iconPicker = '/picker/icon';
  static const reminderPicker = '/picker/reminder';
  static const popularPresets = '/presets';
}

/// Centralized Navigation Service providing type-safe routing across screens
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  // --- Type-safe Route Navigators ---
  static Future<void> toHome(BuildContext context) {
    return push(context, const HomeScreen());
  }

  static Future<void> toAddSubscription(BuildContext context, {Subscription? subscriptionToEdit}) {
    return push(context, AddSubscriptionScreen(subscriptionToEdit: subscriptionToEdit));
  }

  static Future<void> toSubscriptionDetail(BuildContext context, Subscription subscription) {
    return push(context, SubscriptionDetailScreen(subscription: subscription));
  }

  static Future<void> toPaymentHistory(BuildContext context, String subscriptionId) {
    return push(context, PaymentHistoryScreen(subscriptionId: subscriptionId));
  }

  static Future<void> toUpcomingSchedule(BuildContext context, Subscription subscription) {
    return push(context, UpcomingScheduleScreen(subscription: subscription));
  }

  static Future<void> toPaymentMethods(BuildContext context) {
    return push(context, const PaymentMethodsScreen());
  }

  static Future<PaymentMethod?> toPaymentMethodEditor(BuildContext context, {PaymentMethod? initialMethod}) {
    return push<PaymentMethod>(context, PaymentMethodEditorScreen(initialMethod: initialMethod));
  }

  static Future<PaymentMethod?> toPaymentMethodPicker(BuildContext context, {String? currentMethodId}) {
    return push<PaymentMethod>(context, PaymentMethodPickerScreen(initialMethodId: currentMethodId));
  }

  static Future<SubscriptionCategory?> toCategoryPicker(BuildContext context, {required SubscriptionCategory currentCategory}) {
    return push<SubscriptionCategory>(context, CategoryPickerScreen(initialCategory: currentCategory));
  }

  static Future<IconPickerResult?> toIconPicker(BuildContext context, {required IconData currentIcon, required Color currentColor}) {
    return push<IconPickerResult>(context, IconPickerScreen(initialIcon: currentIcon, initialColor: currentColor));
  }

  static Future<int?> toReminderPicker(BuildContext context, {required int currentDays}) {
    return push<int>(context, ReminderPickerScreen(initialDays: currentDays));
  }

  static Future<BrandPreset?> toPopularPresets(BuildContext context) {
    return push<BrandPreset>(context, const PopularPresetsScreen());
  }
}
