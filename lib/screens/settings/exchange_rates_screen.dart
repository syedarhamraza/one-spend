import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../one_ui_field_editor_screen.dart';

/// Settings › Budget & currency › Exchange rates: rate status, "Update now", and a row per
/// currency in use where the user can pin their own rate.
class ExchangeRatesScreen extends StatelessWidget {
  const ExchangeRatesScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsExchangeRates);
  }

  static final DateFormat _dayFormat = DateFormat('MMM d, h:mm a');

  /// "Updated 3 h ago" style status for the downloaded rates.
  static String statusText(SubscriptionStore store, {DateTime? now}) {
    final rates = store.rates;
    final updated = rates.lastUpdated;
    if (rates.isRefreshing) return 'Updating…';
    if (updated == null) {
      return rates.lastRefreshFailed ? 'Offline · using built-in rates' : 'Using built-in rates';
    }
    final age = (now ?? DateTime.now()).difference(updated);
    final when = age.inMinutes < 1
        ? 'just now'
        : age.inHours < 1
            ? '${age.inMinutes} min ago'
            : age.inHours < 24
                ? '${age.inHours} h ago'
                : _dayFormat.format(updated);
    return 'Updated $when${rates.lastRefreshFailed ? ' · offline' : ''}';
  }

  static final NumberFormat _twoDecimals = NumberFormat('#,##0.00');
  static final NumberFormat _upToFourDecimals = NumberFormat('#,##0.####');

  /// Rate text with sensible precision: 282.45, 1.0873, 0.003546.
  static String formatRate(double rate) {
    if (rate >= 100) return _twoDecimals.format(rate);
    if (rate >= 1) return _upToFourDecimals.format(rate);
    return rate.toStringAsPrecision(4);
  }

  static String _sourceLabel(RateSource? source) => switch (source) {
        RateSource.custom => 'Custom',
        RateSource.live => 'Live',
        RateSource.builtIn => 'Built-in',
        null => 'No rate',
      };

  static Color _sourceColor(RateSource? source) => switch (source) {
        RateSource.custom => OneUITheme.accentAmber,
        RateSource.live => OneUITheme.accentGreen,
        RateSource.builtIn => OneUITheme.textSecondary,
        null => OneUITheme.accentRed,
      };

  Future<void> _refresh(BuildContext context, SubscriptionStore store) async {
    HapticFeedback.lightImpact();
    final ok = await store.rates.refresh(force: true);
    if (!context.mounted) return;
    OneUIToast.show(context, ok && !store.rates.lastRefreshFailed ? 'Exchange rates updated' : 'Couldn\'t update rates. Check your connection.');
  }

  Future<void> _editRate(BuildContext context, SubscriptionStore store, String code) async {
    final main = store.currency;
    final current = store.converter.rate(code, main);
    final result = await OneUIFieldEditorScreen.open<double>(
      context: context,
      title: '1 $code in $main',
      subtitle: 'Set your own rate, e.g. the one your bank charges. Set to 0 to use the automatic rate.',
      type: FieldEditorType.number,
      initialValue: current == null ? 0.0 : double.parse(current.toStringAsPrecision(6)),
      hintText: '0',
      currency: main,
    );
    if (result == null || !context.mounted) return;
    await store.rates.setOverride(code, rate: result > 0 ? result : null, base: main);
    if (!context.mounted) return;
    OneUIToast.show(context, result > 0 ? 'Custom rate saved' : 'Using the automatic rate');
  }

  OneUIGroupItem _rateRow(BuildContext context, SubscriptionStore store, String code) {
    final main = store.currency;
    final rate = store.converter.rate(code, main);
    final source = store.converter.sourceOf(code);
    return OneUIGroupItem(
      title: '1 $code',
      subtitle: rate == null ? 'No rate available' : '= ${currencyPrefix(main)}${formatRate(rate)}',
      subtitleColor: rate == null ? OneUITheme.accentRed : OneUITheme.accentBlue,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: _sourceColor(source).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
        ),
        child: Text(
          _sourceLabel(source),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sourceColor(source)),
        ),
      ),
      onTap: () => _editRate(context, store, code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;
    return OneUISubpage(
      title: 'Exchange rates',
      listenable: store,
      builder: (context) {
        final main = store.currency;
        final inUse = store.currenciesInUse.where((c) => c != main).toList();
        final pinnedOnly = store.rates.overrides.keys.where((c) => c != main && !inUse.contains(c)).toList()..sort();
        return [
          OneUISection(
            title: 'Rates',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                OneUIGroupItem(
                  title: 'Update now',
                  subtitle: statusText(store),
                  subtitleColor: OneUITheme.textSecondary,
                  trailing: store.rates.isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: OneUITheme.accentBlue),
                        )
                      : const Icon(Icons.refresh_rounded, size: 22, color: OneUITheme.accentBlue),
                  onTap: store.rates.isRefreshing ? null : () => _refresh(context, store),
                ),
              ],
            ),
          ),
          OneUISection(
            title: 'In $main',
            child: inUse.isEmpty && pinnedOnly.isEmpty
                ? const OneUIGroupCard(
                    margin: EdgeInsets.zero,
                    items: [
                      OneUIGroupItem(
                        title: 'All subscriptions use your main currency',
                        subtitle: 'Rates appear here when a subscription is billed in another currency',
                      ),
                    ],
                  )
                : OneUIGroupCard(
                    margin: EdgeInsets.zero,
                    items: [for (final code in [...inUse, ...pinnedOnly]) _rateRow(context, store, code)],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'Totals are estimates. Live rates come from open.er-api.com and refresh a few times a '
              'day; your bank\'s rate may differ slightly. Tap a currency to set your own rate.',
              style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
            ),
          ),
        ];
      },
    );
  }
}
