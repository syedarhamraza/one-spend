import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/subscriptions/domain/services/spending_insights.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_category_ring.dart';

/// Digital Wellbeing "Screen time today" style card: a big monthly total beside a donut,
/// then a legend of colour bar · icon · name · amount. Tapping a row selects that category.
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: OneUITheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: _bigAmount(amount),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected == null
                          ? '${categories.length} ${categories.length == 1 ? 'category' : 'categories'}'
                          : '${(selected.share * 100).round()}% of spending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OneUICategoryRing(
                size: 140,
                strokeWidth: 26,
                segments: [for (final c in categories) (color: c.category.color, value: c.monthly)],
                highlightedIndex: selectedIndex >= 0 ? selectedIndex : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final c in visible) _legendRow(c, dimmed: selected != null && c.category != widget.selected),
          if (collapsible && selectedIndex < OneUICategoryBreakdownCard.collapsedRows)
            _moreRow(categories.length - OneUICategoryBreakdownCard.collapsedRows),
        ],
      ),
    );
  }

  /// "$83.96 /mo" with whole units large, as in "53 m".
  Widget _bigAmount(double amount) {
    final text = formatMoney(amount, widget.currency, style: MoneyStyle.summary);
    final decimals = RegExp(r'\.\d+').firstMatch(text);
    final whole = decimals == null ? text : text.substring(0, decimals.start);
    final rest = decimals == null ? '' : text.substring(decimals.start);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: whole),
          if (rest.isNotEmpty) TextSpan(text: rest, style: const TextStyle(fontSize: 26)),
          const TextSpan(
            text: ' /mo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: OneUITheme.textSecondary),
          ),
        ],
      ),
      maxLines: 1,
      style: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: OneUITheme.textPrimary,
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
          HapticFeedback.selectionClick();
          widget.onSelect(isSelected ? null : c.category);
        },
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(color: c.category.color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: c.category.color, shape: BoxShape.circle),
                  child: Icon(c.category.icon, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 10),
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
                  formatMoney(c.monthly, widget.currency, style: MoneyStyle.summary),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
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
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            const SizedBox(width: 14),
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
