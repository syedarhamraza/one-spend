import 'package:flutter/material.dart';

import '../core/haptics/haptics.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_radio.dart';
import '../widgets/one_ui_subpage.dart';

/// Picks the card that the subscriptions of [fromIds] move to: a radio list of the other
/// cards with Cancel | Save. Used by Payment methods' Move action, and before deleting cards
/// that subscriptions still use ([allowNone] adds "No card").
class MoveSubscriptionsScreen extends StatefulWidget {
  final Set<String> fromIds;
  final bool allowNone;
  final String saveLabel;

  const MoveSubscriptionsScreen({super.key, required this.fromIds, this.allowNone = false, this.saveLabel = 'Move'});

  /// The chosen card, [PaymentMethod.none] for "No card", or null when cancelled.
  static Future<PaymentMethod?> open(
    BuildContext context, {
    required Set<String> fromIds,
    bool allowNone = false,
    String saveLabel = 'Move',
  }) {
    Haptics.tap();
    return Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(
        builder: (_) => MoveSubscriptionsScreen(fromIds: fromIds, allowNone: allowNone, saveLabel: saveLabel),
      ),
    );
  }

  @override
  State<MoveSubscriptionsScreen> createState() => _MoveSubscriptionsScreenState();
}

class _MoveSubscriptionsScreenState extends State<MoveSubscriptionsScreen> {
  final _store = SubscriptionStore.instance;
  late final List<PaymentMethod> _targets = [
    for (final m in _store.paymentMethods)
      if (!widget.fromIds.contains(m.id)) m,
  ];
  late PaymentMethod? _selected = _targets.isNotEmpty ? _targets.first : (widget.allowNone ? PaymentMethod.none : null);

  int get _count => [for (final id in widget.fromIds) ..._store.getSubscriptionsForMethod(id)].length;

  void _pick(PaymentMethod method) {
    Haptics.select();
    setState(() => _selected = method);
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return OneUISubpage(
      title: 'Move to',
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        saveLabel: widget.saveLabel,
        canSave: _selected != null,
        onSave: () {
          Haptics.confirm();
          Navigator.pop(context, _selected);
        },
      ),
      builder: (context) => [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            '$count ${count == 1 ? 'subscription moves' : 'subscriptions move'} to the card you choose.',
            style: const TextStyle(fontSize: 14, height: 1.4, color: OneUITheme.textSecondary),
          ),
        ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            for (final m in _targets)
              OneUIGroupItem(
                leading: OneUIPaymentBrandIcon(brand: m.brand, width: 40, height: 28),
                title: m.displayName,
                subtitle: m.type.label,
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _selected?.id == m.id),
                onTap: () => _pick(m),
              ),
            if (widget.allowNone)
              OneUIGroupItem(
                title: 'No card',
                subtitle: 'Leave them without a payment method',
                subtitleColor: OneUITheme.textSecondary,
                trailing: OneUIRadio(isSelected: _selected?.id == PaymentMethod.none.id),
                onTap: () => _pick(PaymentMethod.none),
              ),
          ],
        ),
      ],
    );
  }
}
