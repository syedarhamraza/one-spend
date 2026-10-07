import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/haptics/haptics.dart';
import '../core/router/app_router.dart';
import '../models/subscription.dart';
import 'settings/categories_screen.dart';

/// Picks a subscription's category: the Categories page in picking mode (hero card, radio
/// rows, Cancel | Save). Pops the chosen category, or nothing when cancelled.
class CategoryPickerScreen extends StatelessWidget {
  final SubscriptionCategory initialCategory;

  /// Categories left out of the list, e.g. the ones being deleted.
  final Set<SubscriptionCategory> exclude;

  const CategoryPickerScreen({super.key, required this.initialCategory, this.exclude = const {}});

  static Future<SubscriptionCategory?> open(
    BuildContext context, {
    required SubscriptionCategory initialCategory,
    Set<SubscriptionCategory> exclude = const {},
  }) {
    Haptics.tap();
    final initial = exclude.contains(initialCategory) ? SubscriptionCategory.utilities : initialCategory;
    return context.push<SubscriptionCategory>(
      AppRoutes.categoryPicker,
      extra: (initial: initial, exclude: exclude),
    );
  }

  @override
  Widget build(BuildContext context) => CategoriesScreen(pickInitial: initialCategory, exclude: exclude);
}
