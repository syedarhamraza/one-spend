import 'package:flutter/material.dart';
import '../features/subscriptions/domain/services/spending_insights.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_category_ring.dart';
import '../core/haptics/haptics.dart';

/// Digital Wellbeing style card: a donut with the monthly total (or the selected category's)
/// in its centre, then a legend of icon · name · share · amount. Tapping a row selects that
/// category. Its title comes from the surrounding [OneUISection].
class OneUICategoryBreakdownCard extends StatefulWidget {
  /// Categories, largest first (see [SpendingInsights.byCategory]).
  final List<CategorySpend> categories;
  final String currency;
  final SubscriptionCategory? selected;

  /// Called with the tapped category, or null when the selected one is tapped again.
  final ValueChanged<SubscriptionCategory?> onSelect;

  /// Rows shown before "+N more".
  static const int collapsedRows = 5;

  const OneUICategoryBreakdownCard({
    super.key,
    required this.categories,
    required this.currency,
    required this.onSelect,
    this.selected,
  });

  @override
  State<OneUICategoryBreakdownCard> createState() => _OneUICategoryBreakdownCardState();
}

class _OneUICategoryBreakdownCardState extends State<OneUICategoryBreakdownCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final selectedIndex = widget.selected == null ? -1 : categories.indexWhere((c) => c.category == widget.selected);
    final selected = selectedIndex >= 0 ? categories[selectedIndex] : null;
    final total = categories.fold(0.0, (sum, c) => sum + c.monthly);
    final amount = selected?.monthly ?? total;

    // Keep a selected category visible even when it sits below the fold.
    final collapsible = categories.length > OneUICategoryBreakdownCard.collapsedRows + 1;
    final showAll = !collapsible || _expanded || selectedIndex >= OneUICategoryBreakdownCard.collapsedRows;
    final visible = showAll ? categories : categories.take(OneUICategoryBreakdownCard.collapsedRows).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: OneUICategoryRing(
              size: 168,
              strokeWidth: 22,
              segments: [for (final c in categories) (color: c.category.color, value: c.monthly)],
              highlightedIndex: selectedIndex >= 0 ? selectedIndex : null,
              centerValue: '${formatMoney(amount, widget.currency, style: MoneyStyle.summary)}/mo',
              centerLabel: selected != null
                  ? '${(selected.share * 100).round()}% of total'
                  : '${categories.length} ${categories.length == 1 ? 'category' : 'categories'}',
            ),
          ),
          const SizedBox(height: 12),
          for (final c in visible) _legendRow(c, dimmed: selected != null && c.category != widget.selected),
          if (collapsible && selectedIndex < OneUICategoryBreakdownCard.collapsedRows)
            _moreRow(categories.length - OneUICategoryBreakdownCard.collapsedRows),
        ],
      ),
    );
  }

  Widget _legendRow(CategorySpend c, {required bool dimmed}) {
    final isSelected = c.category == widget.selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Haptics.select();
          widget.onSelect(isSelected ? null : c.category);
        },
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: c.category.color, shape: BoxShape.circle),
                  child: Icon(c.category.icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(c.share * 100).round()}%',
                  style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  formatMoney(c.monthly, widget.currency, style: MoneyStyle.summary),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _moreRow(int hidden) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Haptics.select();
        setState(() => _expanded = !_expanded);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            const SizedBox(width: 2),
            Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 22,
              color: OneUITheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              _expanded ? 'Show less' : '+ $hidden more',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: OneUITheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
