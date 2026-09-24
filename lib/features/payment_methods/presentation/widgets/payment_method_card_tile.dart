import 'package:flutter/material.dart';
import '../../../../theme/one_ui_theme.dart';
import '../../../../widgets/one_ui_group_card.dart';
import '../../../../widgets/one_ui_payment_brand_icon.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../domain/entities/payment_method.dart';

/// Reusable Samsung One UI Payment Method Group Item
class PaymentMethodGroupItem extends OneUIGroupItem {
  PaymentMethodGroupItem({
    required PaymentMethod method,
    required bool isPicked,
    bool isSelectionMode = false,
    bool isSelectedInSelection = false,
    bool isManageOnly = false,
    List<Subscription> linkedSubs = const [],
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    VoidCallback? onEdit,
  }) : super(
          leading: _buildLeading(method, isPicked, isSelectionMode, isSelectedInSelection, isManageOnly),
          title: method.nickname,
          customSubtitle: _buildSubtitle(method, linkedSubs),
          trailing: _buildTrailing(isSelectionMode, onEdit),
          onTap: onTap,
          onLongPress: onLongPress,
        );

  static Widget _buildLeading(
    PaymentMethod method,
    bool isPicked,
    bool isSelectionMode,
    bool isSelectedInSelection,
    bool isManageOnly,
  ) {
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
                      color: isSelectedInSelection ? const Color(0xFF2C69FF) : Colors.transparent,
                      border: Border.all(
                        color: isSelectedInSelection
                            ? const Color(0xFF2C69FF)
                            : Colors.white.withValues(alpha: 0.55),
                        width: 2.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isSelectedInSelection
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: (isPicked && !isManageOnly && !isSelectionMode)
                ? OneUITheme.accentBlue.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: (isPicked && !isManageOnly && !isSelectionMode)
                  ? OneUITheme.accentBlue
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: (isPicked && !isManageOnly && !isSelectionMode)
                ? [
                    BoxShadow(
                      color: OneUITheme.accentBlue.withValues(alpha: 0.55),
                      blurRadius: 8,
                      spreadRadius: 1.5,
                    ),
                  ]
                : null,
          ),
          child: OneUIPaymentBrandIcon(
            brand: method.brand,
            width: 44,
            height: 29,
            showShadow: true,
          ),
        ),
      ],
    );
  }

  static Widget _buildSubtitle(PaymentMethod method, List<Subscription> linkedSubs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                method.subtitleDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: OneUITheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (method.isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          linkedSubs.isNotEmpty
              ? '${linkedSubs.length} linked subscription${linkedSubs.length > 1 ? "s" : ""}: ${linkedSubs.map((s) => s.name).join(", ")}'
              : 'No subscriptions linked',
          style: TextStyle(
            fontSize: 12,
            color: linkedSubs.isNotEmpty ? OneUITheme.accentGreen : OneUITheme.textTertiary,
            fontWeight: linkedSubs.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static Widget? _buildTrailing(bool isSelectionMode, VoidCallback? onEdit) {
    if (isSelectionMode || onEdit == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(
        Icons.edit_rounded,
        size: 19,
        color: OneUITheme.textTertiary,
      ),
      tooltip: 'Edit card details',
      onPressed: onEdit,
    );
  }
}
