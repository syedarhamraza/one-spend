import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_subpage.dart';

/// Currencies offered in Settings: the symbol shown on amounts and a readable name.
const List<({String symbol, String name})> supportedCurrencies = [
  (symbol: '\$', name: 'US, Australian & Canadian dollar'),
  (symbol: '€', name: 'Euro'),
  (symbol: '£', name: 'British pound'),
  (symbol: '¥', name: 'Japanese yen & Chinese yuan'),
  (symbol: '₹', name: 'Indian rupee'),
  (symbol: '₩', name: 'Korean won'),
  (symbol: 'Rs', name: 'Pakistani rupee'),
  (symbol: 'CHF', name: 'Swiss franc'),
  (symbol: 'AED', name: 'UAE dirham'),
];

/// "€ Euro" for a stored symbol; the bare symbol if it isn't in the list.
String currencyLabel(String symbol) {
  for (final c in supportedCurrencies) {
    if (c.symbol == symbol) return '${c.symbol}  ${c.name}';
  }
  return symbol;
}

/// Currency picker subpage (radio list + Cancel | Save). Returns the chosen symbol.
class CurrencyPickerScreen extends StatefulWidget {
  final String initialSymbol;

  const CurrencyPickerScreen({super.key, required this.initialSymbol});

  static Future<String?> open(BuildContext context, {required String initialSymbol}) {
    HapticFeedback.lightImpact();
    return context.push<String>(AppRoutes.settingsCurrency, extra: initialSymbol);
  }

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  late String _selected = widget.initialSymbol;

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Currency',
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        onSave: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context, _selected);
        },
      ),
      builder: (context) => [
        OneUISection(
          title: 'Currency symbol',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              for (final c in supportedCurrencies)
                OneUIGroupItem(
                  leading: SizedBox(
                    width: 40,
                    child: Text(
                      c.symbol,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                    ),
                  ),
                  title: c.name,
                  trailing: OneUIRadio(isSelected: c.symbol == _selected),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = c.symbol);
                  },
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Changes the symbol shown on amounts. Prices aren\'t converted.',
            style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
