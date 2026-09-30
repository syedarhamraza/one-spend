import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import 'one_ui_brand_icon.dart';
import 'one_ui_card.dart';
import 'one_ui_fit_amount.dart';
import 'one_ui_group_card.dart';

/// Samsung One UI Upcoming Renewals Section
/// Supports 3 presentation styles:
/// 1. carousel: Horizontal swipeable reel with calendar chips and 1-tap "Mark Paid"
/// 2. spotlight: Hero card focusing on the single next due subscription
/// 3. groupedList: Standard One UI list card
class OneUIUpcomingRenewalsSection extends StatelessWidget {
  final List<Subscription> upcomingSubscriptions;
  final ValueChanged<Subscription> onTapSubscription;
  final ValueChanged<Subscription>? onLongPressSubscription;
  final ValueChanged<Subscription>? onMarkPaid;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggleSelect;

  const OneUIUpcomingRenewalsSection({
    super.key,
    required this.upcomingSubscriptions,
    required this.onTapSubscription,
    this.onLongPressSubscription,
    this.onMarkPaid,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (upcomingSubscriptions.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final style = OneUIEffectsController.instance.upcomingStyle;

        switch (style) {
          case UpcomingSectionStyle.carousel:
            return _buildCarousel(context);
          case UpcomingSectionStyle.spotlight:
            return _buildSpotlight(context);
          case UpcomingSectionStyle.groupedList:
            return _buildGroupedList(context);
        }
      },
    );
  }

  // --- 1. Horizontal Carousel ---
  Widget _buildCarousel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming renewals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: OneUITheme.textSecondary,
                  ),
                ),
                Text(
                  '${upcomingSubscriptions.length} due soon',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: OneUITheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: upcomingSubscriptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final sub = upcomingSubscriptions[index];
                final days = sub.daysRemaining;
                final isUrgent = days <= 3;
                final isSelected = selectedIds.contains(sub.id);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isSelectionMode) {
                        HapticFeedback.selectionClick();
                        onToggleSelect?.call(sub.id);
                      } else {
                        onTapSubscription(sub);
                      }
                    },
                    onLongPress: () {
                      if (!isSelectionMode) {
                        HapticFeedback.mediumImpact();
                        onLongPressSubscription?.call(sub);
                      }
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OneUIEffectsController.instance.resolveCardBackground(
                          brandColor: sub.brandColor,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? OneUITheme.accentBlue
                              : (isUrgent
                                  ? OneUITheme.accentRed.withValues(alpha: 0.35)
                                  : Colors.white.withValues(alpha: 0.08)),
                          width: isSelected ? 2.0 : (isUrgent ? 1.2 : 0.8),
                        ),
                        boxShadow: OneUITheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OneUIBrandIcon(
                                subscription: sub,
                                size: 32,
                                borderRadius: 10,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isUrgent ? OneUITheme.accentRed : OneUITheme.accentBlue)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  days == 0
                                      ? 'Today'
                                      : (days == 1 ? 'Tmrw' : '${days}d left'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isUrgent ? OneUITheme.accentRed : OneUITheme.accentBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatMoney(sub.price, sub.currency),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                  if (onMarkPaid != null && !isSelectionMode)
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.mediumImpact();
                                        onMarkPaid!(sub);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: OneUITheme.accentGreen.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Paid',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: OneUITheme.accentGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Spotlight Hero Card ---
  Widget _buildSpotlight(BuildContext context) {
    final nextSub = upcomingSubscriptions.first;
    final days = nextSub.daysRemaining;
    final isUrgent = days <= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Next upcoming renewal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: OneUITheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OneUIEffectsController.instance.resolveCardBackground(
                brandColor: nextSub.brandColor,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUrgent
                    ? OneUITheme.accentRed.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.08),
                width: isUrgent ? 1.2 : 0.8,
              ),
              boxShadow: OneUITheme.cardShadow,
            ),
            child: Row(
              children: [
                OneUIBrandIcon(
                  subscription: nextSub,
                  size: 46,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nextSub.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isUrgent ? OneUITheme.accentRed : OneUITheme.accentBlue)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              days == 0
                                  ? 'Due today'
                                  : (days == 1 ? 'Tomorrow' : 'In $days days'),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isUrgent ? OneUITheme.accentRed : OneUITheme.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${OneUIDateFormats.monthDayYear.format(nextSub.nextBillingDate)} • ${formatMoney(nextSub.price, nextSub.currency)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onMarkPaid != null && !isSelectionMode)
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onMarkPaid!(nextSub);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OneUITheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Grouped List Card (Classic) ---
  Widget _buildGroupedList(BuildContext context) {
    final dateFormat = OneUIDateFormats.monthDayYear;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: OneUISection(
        title: 'Upcoming renewals',
        child: OneUIGroupCard(
          items: upcomingSubscriptions.take(2).map((sub) {
            final days = sub.daysRemaining;
            final isSelected = selectedIds.contains(sub.id);
            return OneUIGroupItem(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: isSelectionMode
                        ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildSelectionIndicator(isSelected),
                          )
                        : const SizedBox.shrink(),
                  ),
                  OneUIBrandIcon(
                    subscription: sub,
                    size: 42,
                    borderRadius: 14,
                  ),
                ],
              ),
              title: sub.name,
              subtitle: isSelectionMode
                  ? null
                  : (days == 0
                      ? 'Due today (${dateFormat.format(sub.nextBillingDate)})'
                      : 'Due in $days days (${dateFormat.format(sub.nextBillingDate)})'),
              subtitleColor: days <= 5 ? OneUITheme.accentRed : OneUITheme.accentBlue,
              trailing: OneUIFitAmount(
                formatMoney(sub.price, sub.currency),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: OneUITheme.textPrimary,
                ),
              ),
              onTap: () {
                if (isSelectionMode) {
                  HapticFeedback.selectionClick();
                  onToggleSelect?.call(sub.id);
                } else {
                  onTapSubscription(sub);
                }
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  HapticFeedback.mediumImpact();
                  onLongPressSubscription?.call(sub);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? OneUITheme.accentBlue : Colors.transparent,
        border: Border.all(
          color: selected ? OneUITheme.accentBlue : Colors.white.withValues(alpha: 0.35),
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}
