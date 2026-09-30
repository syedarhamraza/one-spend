import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../one_ui_field_editor_screen.dart';
import 'coming_soon_screen.dart';
import 'currency_picker_screen.dart';
import 'planned_feature.dart';

/// Settings › Budget & currency.
class BudgetCurrencyScreen extends StatelessWidget {
  const BudgetCurrencyScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsBudget);
  }

  Future<void> _pickCurrency(BuildContext context, SubscriptionStore store) async {
    final picked = await CurrencyPickerScreen.open(context, initialSymbol: store.currency);
    if (picked != null && picked != store.currency) store.setCurrency(picked);
  }

  Future<void> _editBudget(BuildContext context, SubscriptionStore store) async {
    final result = await OneUIFieldEditorScreen.open<double>(
      context: context,
      title: 'Monthly budget',
      subtitle: 'Set to 0 for no limit',
      type: FieldEditorType.number,
      initialValue: store.monthlyBudget,
      prefixText: '${store.currency} ',
      hintText: '0',
      currency: store.currency,
    );
    if (result == null || !context.mounted) return;
    store.setMonthlyBudget(result.clamp(0.0, 999999.0));
    OneUIToast.show(
      context,
      store.monthlyBudget <= 0
          ? 'Budget limit removed'
          : 'Budget set to ${store.currency}${store.monthlyBudget.toStringAsFixed(0)} a month',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Budget & currency',
      listenable: store,
      builder: (context) => [
        OneUISection(
          title: 'Budget',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Monthly budget',
                subtitle: store.monthlyBudget <= 0
                    ? 'No limit'
                    : '${store.currency}${store.monthlyBudget.toStringAsFixed(0)} a month',
                subtitleColor: OneUITheme.accentBlue,
                onTap: () => _editBudget(context, store),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'Currency',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Currency',
                subtitle: currencyLabel(store.currency),
                subtitleColor: OneUITheme.accentBlue,
                onTap: () => _pickCurrency(context, store),
              ),
              OneUIGroupItem(
                title: PlannedFeature.multiCurrency.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.multiCurrency),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
