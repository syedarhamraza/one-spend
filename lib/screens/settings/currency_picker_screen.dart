import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_subpage.dart';

/// "PKR · Pakistani rupee" for a currency code.
String currencyLabel(String code) {
  final c = CurrencyCatalog.of(code);
  return c.name == c.code ? c.code : '${c.code} · ${c.name}';
}

/// Currency picker subpage (search, currencies in use, then all; radio + Cancel | Save).
/// Returns the chosen ISO code.
class CurrencyPickerScreen extends StatefulWidget {
  final String initialCode;
  final String title;

  /// Shown under the list, e.g. what changing the main currency does.
  final String? footnote;

  const CurrencyPickerScreen({super.key, required this.initialCode, this.title = 'Currency', this.footnote});

  static Future<String?> open(
    BuildContext context, {
    required String initialCode,
    String title = 'Currency',
    String? footnote,
  }) {
    HapticFeedback.lightImpact();
    return context.push<String>(
      AppRoutes.settingsCurrency,
      extra: (initialCode: initialCode, title: title, footnote: footnote),
    );
  }

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  late String _selected = widget.initialCode;
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Currency c) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q) || c.symbol.toLowerCase() == q;
  }

  OneUIGroupItem _row(Currency c) {
    return OneUIGroupItem(
      leading: Container(
        width: 44,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              c.symbol,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
            ),
          ),
        ),
      ),
      title: c.name,
      subtitle: c.code,
      trailing: OneUIRadio(isSelected: c.code == _selected),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = c.code);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    final pinnedCodes = <String>{widget.initialCode, ...store.currenciesInUse};
    final pinned = [for (final code in pinnedCodes) CurrencyCatalog.of(code)].where(_matches).toList();
    final others = CurrencyCatalog.all.where((c) => !pinnedCodes.contains(c.code) && _matches(c)).toList();

    return OneUISubpage(
      title: widget.title,
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        onSave: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context, _selected);
        },
      ),
      builder: (context) => [
        Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: BorderRadius.circular(OneUITheme.radiusPill),
            border: OneUITheme.cardBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 22, color: OneUITheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 16, color: OneUITheme.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search currencies',
                    hintStyle: TextStyle(color: OneUITheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (pinned.isNotEmpty)
          OneUISection(
            title: 'In use',
            child: OneUIGroupCard(margin: EdgeInsets.zero, items: [for (final c in pinned) _row(c)]),
          ),
        if (others.isNotEmpty)
          OneUISection(
            title: 'All currencies',
            child: OneUIGroupCard(margin: EdgeInsets.zero, items: [for (final c in others) _row(c)]),
          ),
        if (pinned.isEmpty && others.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Center(
              child: Text('No matching currencies', style: TextStyle(fontSize: 15, color: OneUITheme.textSecondary)),
            ),
          ),
        if (widget.footnote != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(widget.footnote!, style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
          ),
      ],
    );
  }
}
