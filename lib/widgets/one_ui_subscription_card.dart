import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import 'one_ui_brand_icon.dart';
import 'one_ui_group_card.dart';

/// Unified Samsung One UI Subscription Card Widget
/// Adapts dynamically to layout archetypes (One UI Fluent Grouped, Bento Elevated, Compact),
/// background surface colors, brand accents, cycle progress bars, and metadata chips.
class OneUISubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<String>? onToggleSelect;
  final String? paymentMethodNickname;
  final bool isCardExpiring;
  final bool hasNoCard;

  // Optional overrides for live preview studio
  final SubscriptionCardBackground? overrideBackground;
  final Color? overrideCustomBackgroundColor;
  final SubscriptionCardLayout? overrideLayout;
  final SubscriptionBrandAccent? overrideBrandAccent;
  final SubscriptionPriceMode? overridePriceMode;
  final SubscriptionRenewalBadgeMode? overrideRenewalBadgeMode;
  final bool? overrideShowCycleProgress;
  final bool? overrideShowPaymentMethodChip;
  final bool? overrideShowCategoryChip;
  final bool? overrideShowDailyEquivalent;

  const OneUISubscriptionCard({
    super.key,
    required this.subscription,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
    this.paymentMethodNickname,
    this.isCardExpiring = false,
    this.hasNoCard = false,
    this.overrideBackground,
    this.overrideCustomBackgroundColor,
    this.overrideLayout,
    this.overrideBrandAccent,
    this.overridePriceMode,
    this.overrideRenewalBadgeMode,
    this.overrideShowCycleProgress,
    this.overrideShowPaymentMethodChip,
    this.overrideShowCategoryChip,
    this.overrideShowDailyEquivalent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final ctrl = OneUIEffectsController.instance;

        final layout = overrideLayout ?? ctrl.cardLayout;
        final bgType = overrideBackground ?? ctrl.cardBackground;
        final brandAccent = overrideBrandAccent ?? ctrl.brandAccent;
        final priceMode = overridePriceMode ?? ctrl.priceMode;
        final badgeMode = overrideRenewalBadgeMode ?? ctrl.renewalBadgeMode;
        final showProgress = overrideShowCycleProgress ?? ctrl.showCycleProgress;
        final showPaymentChip = overrideShowPaymentMethodChip ?? ctrl.showPaymentMethodChip;
        final showCatChip = overrideShowCategoryChip ?? ctrl.showCategoryChip;
        final showDaily = overrideShowDailyEquivalent ?? ctrl.showDailyEquivalent;

        switch (layout) {
          case SubscriptionCardLayout.bentoElevated:
            return _buildBentoCard(
              context,
              bgType: bgType,
              brandAccent: brandAccent,
              priceMode: priceMode,
              badgeMode: badgeMode,
              showProgress: showProgress,
              showPaymentChip: showPaymentChip,
              showCatChip: showCatChip,
              showDaily: showDaily,
            );
          case SubscriptionCardLayout.compact:
            return _buildCompactRow(
              context,
              bgType: bgType,
              brandAccent: brandAccent,
              priceMode: priceMode,
              badgeMode: badgeMode,
              showPaymentChip: showPaymentChip,
              showCatChip: showCatChip,
            );
          case SubscriptionCardLayout.oneUiFluent:
            return _buildOneUiFluentItem(
              context,
              bgType: bgType,
              brandAccent: brandAccent,
              priceMode: priceMode,
              badgeMode: badgeMode,
              showProgress: showProgress,
              showPaymentChip: showPaymentChip,
              showCatChip: showCatChip,
              showDaily: showDaily,
            );
        }
      },
    );
  }

  // --- 1. Bento Elevated Standalone Card ---
  Widget _buildBentoCard(
    BuildContext context, {
    required SubscriptionCardBackground bgType,
    required SubscriptionBrandAccent brandAccent,
    required SubscriptionPriceMode priceMode,
    required SubscriptionRenewalBadgeMode badgeMode,
    required bool showProgress,
    required bool showPaymentChip,
    required bool showCatChip,
    required bool showDaily,
  }) {
    final sub = subscription;
    final brandColor = sub.brandColor;
    final ctrl = OneUIEffectsController.instance;
    final resolvedBg = ctrl.resolveCardBackground(
      backgroundType: bgType,
      brandColor: brandColor,
    );

    final isGlow = brandAccent == SubscriptionBrandAccent.ambientGlow;
    final isBorderHighlight = brandAccent == SubscriptionBrandAccent.borderHighlight;
    final isLeftStrip = brandAccent == SubscriptionBrandAccent.leftStrip;
    final progress = _calculateCycleProgress(sub);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              HapticFeedback.selectionClick();
              onToggleSelect?.call(sub.id);
            } else {
              onTap?.call();
            }
          },
          onLongPress: () {
            if (!isSelectionMode) {
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isGlow ? null : resolvedBg,
              gradient: isGlow
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(brandColor.withValues(alpha: 0.22), resolvedBg),
                        resolvedBg,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: isBorderHighlight
                  ? Border.all(
                      color: brandColor.withValues(alpha: 0.40),
                      width: 1.2,
                    )
                  : (OneUITheme.cardBorder ??
                      Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                        width: 0.8,
                      )),
              boxShadow: OneUITheme.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  if (bgType == SubscriptionCardBackground.frostedGlass)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: const SizedBox.shrink(),
                    ),

                  // Left vertical accent strip
                  if (isLeftStrip)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: brandColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(isLeftStrip ? 18 : 16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isSelectionMode) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildSelectionIndicator(isSelected),
                              ),
                            ],
                            OneUIBrandIcon(
                              subscription: sub,
                              size: 44,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sub.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                      color: OneUITheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (!isSelectionMode) ...[
                                    const SizedBox(height: 3),
                                    _buildMetadataChipsRow(
                                      sub,
                                      showCatChip: showCatChip,
                                      showPaymentChip: showPaymentChip,
                                      paymentMethodNickname: paymentMethodNickname,
                                      isCardExpiring: isCardExpiring,
                                      hasNoCard: hasNoCard,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPriceDisplay(sub, priceMode: priceMode),
                                const SizedBox(height: 4),
                                _buildRenewalBadge(sub, badgeMode: badgeMode),
                              ],
                            ),
                          ],
                        ),

                        // Cycle Progress Bar
                        if (showProgress) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 3.5,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      sub.daysRemaining <= 3
                                          ? OneUITheme.accentRed
                                          : (brandAccent != SubscriptionBrandAccent.neutral
                                              ? brandColor
                                              : OneUITheme.accentBlue),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: OneUITheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Daily Equivalent
                        if (showDaily) ...[
                          const SizedBox(height: 6),
                          Text(
                            '~${sub.currency}${(sub.monthlyCost / 30).toStringAsFixed(2)} / day',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Compact Minimalist Row ---
  Widget _buildCompactRow(
    BuildContext context, {
    required SubscriptionCardBackground bgType,
    required SubscriptionBrandAccent brandAccent,
    required SubscriptionPriceMode priceMode,
    required SubscriptionRenewalBadgeMode badgeMode,
    required bool showPaymentChip,
    required bool showCatChip,
  }) {
    final sub = subscription;
    final brandColor = sub.brandColor;
    final ctrl = OneUIEffectsController.instance;
    final resolvedBg = ctrl.resolveCardBackground(
      backgroundType: bgType,
      brandColor: brandColor,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            HapticFeedback.selectionClick();
            onToggleSelect?.call(sub.id);
          } else {
            onTap?.call();
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: resolvedBg.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 0.8,
              ),
            ),
          ),
          child: Row(
            children: [
              if (isSelectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildSelectionIndicator(isSelected),
                ),
              ],
              OneUIBrandIcon(
                subscription: sub,
                size: 34,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sub.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (brandAccent == SubscriptionBrandAccent.leftStrip) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: brandColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sub.category.label} • ${OneUIDateFormats.monthDay.format(sub.nextBillingDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: OneUITheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPriceDisplay(sub, priceMode: priceMode, isCompact: true),
                  const SizedBox(height: 2),
                  _buildRenewalBadge(sub, badgeMode: badgeMode, isCompact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. One UI Fluent Grouped Item (Standalone Card Representation) ---
  Widget _buildOneUiFluentItem(
    BuildContext context, {
    required SubscriptionCardBackground bgType,
    required SubscriptionBrandAccent brandAccent,
    required SubscriptionPriceMode priceMode,
    required SubscriptionRenewalBadgeMode badgeMode,
    required bool showProgress,
    required bool showPaymentChip,
    required bool showCatChip,
    required bool showDaily,
  }) {
    final sub = subscription;
    final brandColor = sub.brandColor;
    final ctrl = OneUIEffectsController.instance;

    final groupItem = toGroupItem(
      subscription: sub,
      onTap: onTap,
      onLongPress: onLongPress,
      isSelectionMode: isSelectionMode,
      isSelected: isSelected,
      onToggleSelect: onToggleSelect,
      paymentMethodNickname: paymentMethodNickname,
      isCardExpiring: isCardExpiring,
      hasNoCard: hasNoCard,
      overrideBrandAccent: brandAccent,
      overridePriceMode: priceMode,
      overrideRenewalBadgeMode: badgeMode,
      overrideShowCycleProgress: showProgress,
      overrideShowPaymentMethodChip: showPaymentChip,
      overrideShowCategoryChip: showCatChip,
      overrideShowDailyEquivalent: showDaily,
    );

    final resolvedBg = ctrl.resolveCardBackground(
      backgroundType: bgType,
      brandColor: brandColor,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: OneUIGroupItemTile(
        item: groupItem,
        isFirst: true,
        isLast: true,
      ),
    );
  }

  /// Transforms a [Subscription] into a Samsung One UI grouped list item [OneUIGroupItem]
  /// for use inside [OneUIGroupCard].
  static OneUIGroupItem toGroupItem({
    required Subscription subscription,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isSelectionMode = false,
    bool isSelected = false,
    ValueChanged<String>? onToggleSelect,
    String? paymentMethodNickname,
    bool isCardExpiring = false,
    bool hasNoCard = false,
    SubscriptionBrandAccent? overrideBrandAccent,
    SubscriptionPriceMode? overridePriceMode,
    SubscriptionRenewalBadgeMode? overrideRenewalBadgeMode,
    bool? overrideShowCycleProgress,
    bool? overrideShowPaymentMethodChip,
    bool? overrideShowCategoryChip,
    bool? overrideShowDailyEquivalent,
  }) {
    final ctrl = OneUIEffectsController.instance;
    final brandAccent = overrideBrandAccent ?? ctrl.brandAccent;
    final priceMode = overridePriceMode ?? ctrl.priceMode;
    final badgeMode = overrideRenewalBadgeMode ?? ctrl.renewalBadgeMode;
    final showProgress = overrideShowCycleProgress ?? ctrl.showCycleProgress;
    final showPaymentChip = overrideShowPaymentMethodChip ?? ctrl.showPaymentMethodChip;
    final showCatChip = overrideShowCategoryChip ?? ctrl.showCategoryChip;
    final showDaily = overrideShowDailyEquivalent ?? ctrl.showDailyEquivalent;

    final sub = subscription;
    final brandColor = sub.brandColor;
    final progress = _calculateCycleProgress(sub);
    final isLeftStrip = brandAccent == SubscriptionBrandAccent.leftStrip;

    Widget? subtitleWidget;
    if (!isSelectionMode) {
      subtitleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetadataChipsRow(
            sub,
            showCatChip: showCatChip,
            showPaymentChip: showPaymentChip,
            paymentMethodNickname: paymentMethodNickname,
            isCardExpiring: isCardExpiring,
            hasNoCard: hasNoCard,
          ),
          if (showProgress) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  sub.daysRemaining <= 3
                      ? OneUITheme.accentRed
                      : (brandAccent != SubscriptionBrandAccent.neutral ? brandColor : OneUITheme.accentBlue),
                ),
              ),
            ),
          ],
          if (showDaily) ...[
            const SizedBox(height: 4),
            Text(
              '~${sub.currency}${(sub.monthlyCost / 30).toStringAsFixed(2)} / day',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: OneUITheme.textSecondary,
              ),
            ),
          ],
        ],
      );
    }

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              OneUIBrandIcon(
                subscription: sub,
                size: 44,
                borderRadius: 14,
              ),
              if (isLeftStrip)
                Positioned(
                  left: -6,
                  top: 8,
                  bottom: 8,
                  width: 3.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: brandColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      title: sub.name,
      customSubtitle: subtitleWidget,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceDisplay(sub, priceMode: priceMode),
          const SizedBox(height: 3),
          _buildRenewalBadge(sub, badgeMode: badgeMode),
        ],
      ),
      onTap: () {
        if (isSelectionMode) {
          HapticFeedback.selectionClick();
          onToggleSelect?.call(sub.id);
        } else {
          onTap?.call();
        }
      },
      onLongPress: () {
        if (!isSelectionMode) {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        }
      },
    );
  }

  // --- Sub-Components & Formatters ---

  static Widget _buildPriceDisplay(
    Subscription sub, {
    required SubscriptionPriceMode priceMode,
    bool isCompact = false,
  }) {
    final currency = sub.currency;
    final price = sub.price;
    final cycle = sub.billingCycle;

    switch (priceMode) {
      case SubscriptionPriceMode.monthlyEquivalent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency${sub.monthlyCost.toStringAsFixed(2)}/mo',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: OneUITheme.textPrimary,
              ),
            ),
            if (cycle != BillingCycle.monthly && !isCompact) ...[
              const SizedBox(height: 1),
              Text(
                'Billed $currency${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: OneUITheme.textSecondary,
                ),
              ),
            ],
          ],
        );
      case SubscriptionPriceMode.rawAmount:
        return Text(
          '$currency${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: OneUITheme.textPrimary,
          ),
        );
      case SubscriptionPriceMode.billedAmount:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: OneUITheme.textPrimary,
              ),
            ),
            if (cycle != BillingCycle.monthly && !isCompact) ...[
              const SizedBox(height: 1),
              Text(
                '($currency${sub.monthlyCost.toStringAsFixed(2)}/mo)',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: OneUITheme.textSecondary,
                ),
              ),
            ],
          ],
        );
    }
  }

  static Widget _buildRenewalBadge(
    Subscription sub, {
    required SubscriptionRenewalBadgeMode badgeMode,
    bool isCompact = false,
  }) {
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

    if (badgeMode == SubscriptionRenewalBadgeMode.exactDate && !isPaused) {
      badgeText = OneUIDateFormats.monthDay.format(sub.nextBillingDate);
    } else if (badgeMode == SubscriptionRenewalBadgeMode.combined && !isPaused) {
      badgeText = '$badgeText (${OneUIDateFormats.monthDay.format(sub.nextBillingDate)})';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 5 : 7,
        vertical: isCompact ? 1.5 : 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: isCompact ? 9.5 : 10.5,
          fontWeight: FontWeight.w700,
          color: badgeColor,
        ),
      ),
    );
  }

  static Widget _buildMetadataChipsRow(
    Subscription sub, {
    required bool showCatChip,
    required bool showPaymentChip,
    String? paymentMethodNickname,
    bool isCardExpiring = false,
    bool hasNoCard = false,
  }) {
    final hasCard = !hasNoCard && paymentMethodNickname != null && paymentMethodNickname.isNotEmpty;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showCatChip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${sub.category.label} • ${sub.billingCycle.label}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: OneUITheme.textSecondary,
              ),
            ),
          )
        else
          Text(
            '${sub.category.label} • ${sub.billingCycle.label}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: OneUITheme.textSecondary,
            ),
          ),

        if (showPaymentChip && hasCard)
          Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: isCardExpiring
                  ? OneUITheme.accentAmber.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 11,
                  color: isCardExpiring ? OneUITheme.accentAmber : OneUITheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    paymentMethodNickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isCardExpiring ? OneUITheme.accentAmber : OneUITheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (hasNoCard)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
              ),
            ),
          ),
      ],
    );
  }

  static Widget _buildSelectionIndicator(bool selected) {
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

  static double _calculateCycleProgress(Subscription sub) {
    final now = DateTime.now();
    final next = sub.nextBillingDate;
    int cycleDays;
    switch (sub.billingCycle) {
      case BillingCycle.weekly:
        cycleDays = 7;
        break;
      case BillingCycle.monthly:
        cycleDays = 30;
        break;
      case BillingCycle.quarterly:
        cycleDays = 90;
        break;
      case BillingCycle.yearly:
        cycleDays = 365;
        break;
    }
    final daysRemaining = next.difference(now).inDays;
    if (daysRemaining <= 0) return 1.0;
    final elapsed = (cycleDays - daysRemaining).clamp(0, cycleDays);
    return (elapsed / cycleDays).clamp(0.0, 1.0);
  }
}
