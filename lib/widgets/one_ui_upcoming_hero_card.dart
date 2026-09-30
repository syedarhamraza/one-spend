import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../features/subscriptions/domain/entities/subscription.dart';
import '../features/subscriptions/domain/services/charge_schedule.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_brand_icon.dart';

/// Samsung One UI hero card for the Upcoming tab, the sibling of [OneUIBudgetCard]:
/// the same soft blue glow under a frosted glass body, a 32pt hero amount, a 12dp
/// track (here split by payment method) and a Device Care style key-value panel.
class OneUIUpcomingHeroCard extends StatelessWidget {
  /// e.g. "next 30 days".
  final String horizonPhrase;

  /// Every charge in the horizon, including overdue ones (paid charges are ignored).
  final List<UpcomingCharge> charges;

  /// Yearly subscriptions renewing soon (see [ChargeSchedule.annualRenewalsWithin]).
  final List<UpcomingCharge> annualSoon;
  final String currency;

  /// Track colour for a payment method id (null = no card).
  final Color Function(String? paymentMethodId) cardColor;
  final ValueChanged<Subscription>? onOpenSubscription;

  static const Color trackBackground = Color(0xFF2C2D30);
  static const Color colorCrimson = Color(0xFFFF5C5C);

  const OneUIUpcomingHeroCard({
    super.key,
    required this.horizonPhrase,
    required this.charges,
    required this.annualSoon,
    required this.currency,
    required this.cardColor,
    this.onOpenSubscription,
  });

  static final DateFormat _monthDay = DateFormat('MMM d');

  String _money(double amount) => '$currency${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final unpaid = charges.unpaid;
    final total = unpaid.fold(0.0, (sum, c) => sum + c.amount);
    final overdueCount = unpaid.where((c) => c.status == ChargeStatus.overdue).length;
    final byCard = charges.byPaymentMethod();
    final biggest = charges.biggest;
    final busiest = charges.busiestWeek();
    final annual = annualSoon.isEmpty ? null : annualSoon.first;

    final (String badgeLabel, Color badgeColor) = overdueCount > 0
        ? ('$overdueCount overdue', colorCrimson)
        : ('${unpaid.length} charge${unpaid.length == 1 ? '' : 's'}', OneUITheme.accentBlue);

    final rows = <Widget>[
      if (biggest != null)
        _row(
          label: 'Biggest charge',
          leading: OneUIBrandIcon(subscription: biggest.subscription, size: 20, borderRadius: 6),
          title: biggest.subscription.name,
          subtitle: '${_monthDay.format(biggest.date)} · ${_money(biggest.amount)}',
          onTap: onOpenSubscription == null ? null : () => onOpenSubscription!(biggest.subscription),
        ),
      if (busiest != null && busiest.count > 1)
        _row(
          label: 'Busiest week',
          title: _money(busiest.total),
          subtitle:
              '${_monthDay.format(busiest.start)} – ${_monthDay.format(busiest.start.add(const Duration(days: 6)))} · ${busiest.count} charges',
        ),
      if (annual != null)
        _row(
          label: 'Yearly renewal',
          leading: OneUIBrandIcon(subscription: annual.subscription, size: 20, borderRadius: 6),
          title: annual.subscription.name,
          subtitle: '${_monthDay.format(annual.date)} · ${_money(annual.amount)}',
          onTap: onOpenSubscription == null ? null : () => onOpenSubscription!(annual.subscription),
        ),
    ];

    return ClipRRect(
      borderRadius: OneUITheme.cardBorderRadius,
      child: Stack(
        children: [
          // Soft Samsung Blue ambient glow beneath the glass (matches the budget card).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.2),
                  radius: 1.05,
                  colors: [
                    const Color(0xFF0381FE).withValues(alpha: 0.26),
                    const Color(0xFF0381FE).withValues(alpha: 0.11),
                    const Color(0xFF0381FE).withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.50, 0.85, 1.0],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF1B1C20).withValues(alpha: 0.68),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Due in the $horizonPhrase',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: OneUITheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _money(total),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _cardTrack(byCard, total),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) Divider(height: 14, thickness: 0.6, color: Colors.white.withValues(alpha: 0.06)),
                            rows[i],
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 12dp One UI track split into one segment per payment method, sized by its share.
  Widget _cardTrack(Map<String?, ({double total, int count})> byCard, double total) {
    return Semantics(
      label: 'Split by payment method',
      child: Container(
        height: 12,
        decoration: BoxDecoration(color: trackBackground, borderRadius: BorderRadius.circular(100)),
        clipBehavior: Clip.antiAlias,
        child: total <= 0
            ? null
            : Row(
                children: [
                  for (final (i, entry) in byCard.entries.indexed)
                    Expanded(
                      flex: (entry.value.total / total * 1000).round().clamp(1, 1000),
                      child: Container(
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                        color: cardColor(entry.key),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  /// Device Care style key-value row: label on the left, title + subtitle right-aligned.
  Widget _row({
    required String label,
    required String title,
    required String subtitle,
    Widget? leading,
    VoidCallback? onTap,
  }) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: OneUITheme.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (leading != null) ...[leading, const SizedBox(width: 6)],
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: OneUITheme.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: OneUITheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: content,
    );
  }
}
