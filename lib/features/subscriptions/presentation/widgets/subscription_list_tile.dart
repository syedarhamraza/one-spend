import 'package:flutter/material.dart';
import '../../../../theme/one_ui_theme.dart';
import '../../../../widgets/one_ui_brand_icon.dart';
import '../../../../widgets/one_ui_group_card.dart';
import '../../../currency/domain/money_format.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';

/// Reusable Samsung One UI Subscription List Group Item
class SubscriptionGroupItem extends OneUIGroupItem {
  SubscriptionGroupItem({
    required Subscription subscription,
    bool isSelected = false,
    bool isSelectionMode = false,
    PaymentMethod? linkedMethod,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) : super(
          leading: _buildLeading(subscription, isSelected, isSelectionMode),
          title: subscription.name,
          customSubtitle: _buildSubtitle(subscription, isSelectionMode, linkedMethod),
          trailing: _buildTrailing(subscription, isSelectionMode),
          onTap: onTap,
          onLongPress: onLongPress,
        );

  static Widget _buildLeading(Subscription sub, bool isSelected, bool isSelectionMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: isSelectionMode
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2C69FF) : Colors.white.withValues(alpha: 0.55),
                        width: 2.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        OneUIBrandIcon(
          subscription: sub,
          size: 40,
          borderRadius: 12,
        ),
      ],
    );
  }

  static Widget? _buildSubtitle(Subscription sub, bool isSelectionMode, PaymentMethod? linkedMethod) {
    if (isSelectionMode) return null;

    final hasNoCard = sub.paymentMethodId == null || linkedMethod == null;
    final isCardExpiring = linkedMethod != null && (linkedMethod.isExpiringSoon || linkedMethod.isExpired);

    final subtitleText = hasNoCard
        ? '${sub.category.label} • ${sub.billingCycle.label}'
        : '${sub.category.label} • ${sub.billingCycle.label} • ${linkedMethod.nickname}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: OneUITheme.textSecondary,
            ),
          ),
        ),
        if (hasNoCard) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: OneUITheme.accentRed.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'No card',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: OneUITheme.accentRed,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ] else if (isCardExpiring) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: OneUITheme.accentAmber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              linkedMethod.isExpired ? 'Card expired' : 'Card expiring soon',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: OneUITheme.accentAmber,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static Widget? _buildTrailing(Subscription sub, bool isSelectionMode) {
    if (isSelectionMode) return null;

    final days = sub.daysRemaining;
    final isPaused = sub.status == SubscriptionStatus.paused;

    Color badgeColor;
    String badgeText;
    if (isPaused) {
      badgeColor = OneUITheme.textSecondary;
      badgeText = 'Paused';
    } else if (days < 0) {
      badgeColor = OneUITheme.accentRed;
      badgeText = 'Overdue ${-days}d';
    } else if (days == 0) {
      badgeColor = OneUITheme.accentRed;
      badgeText = 'Due today';
    } else if (days == 1) {
      badgeColor = OneUITheme.accentRed;
      badgeText = 'Tomorrow';
    } else if (days <= 3) {
      badgeColor = OneUITheme.accentRed;
      badgeText = 'In $days days';
    } else if (days <= 7) {
      badgeColor = OneUITheme.accentAmber;
      badgeText = 'In $days days';
    } else {
      badgeColor = OneUITheme.accentBlue;
      badgeText = 'In $days days';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatMoney(sub.price, sub.currency),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: OneUITheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          badgeText,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: badgeColor,
          ),
        ),
      ],
    );
  }
}
