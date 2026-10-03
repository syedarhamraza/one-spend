import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../category_editor_screen.dart';

/// Settings › Categories: the built-in categories and the user's own.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsCategories);
  }

  String _usage(SubscriptionController store, SubscriptionCategory category) {
    final count = store.subscriptionCountIn(category);
    return count == 0 ? 'Not used yet' : '$count ${count == 1 ? 'subscription' : 'subscriptions'}';
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Categories',
      listenable: store,
      builder: (context) {
        final custom = [
          for (final c in SubscriptionCategory.all)
            if (c.isCustom) c,
        ];
        return [
          OneUISection(
            title: 'Your categories',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                for (final category in custom)
                  OneUIGroupItem(
                    leading: OneUIIconBadge(category.icon, category.color),
                    title: category.label,
                    subtitle: _usage(store, category),
                    subtitleColor: OneUITheme.textSecondary,
                    onTap: () => CategoryEditorScreen.open(context, categoryId: category.name),
                  ),
                OneUIGroupItem(
                  leading: const OneUIIconBadge(Icons.add_rounded, OneUITheme.accentBlue),
                  title: 'New category',
                  subtitle: 'Your own name, icon and colour',
                  subtitleColor: OneUITheme.textSecondary,
                  onTap: () => CategoryEditorScreen.open(context),
                ),
              ],
            ),
          ),
          OneUISection(
            title: 'Built in',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                for (final category in SubscriptionCategory.values)
                  OneUIGroupItem(
                    leading: OneUIIconBadge(category.icon, category.color),
                    title: category.label,
                    subtitle: _usage(store, category),
                    subtitleColor: OneUITheme.textSecondary,
                    trailing: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ];
      },
    );
  }
}
