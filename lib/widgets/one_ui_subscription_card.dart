import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import 'one_ui_brand_icon.dart';
import 'one_ui_group_card.dart';
import 'one_ui_payment_brand_icon.dart';

/// Unified Samsung One UI Subscription Card Widget
/// Adapts dynamically to layout archetypes (One UI Fluent Grouped, Bento Elevated, Compact),
/// background surface colors, brand accents, and metadata chips.
class OneUISubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<String>? onToggleSelect;
  final String? paymentMethodNickname;
  final CardBrand? cardBrand;
  final IconData? cardBrandIcon;
  final bool isCardExpiring;
  final bool hasNoCard;

  // Optional overrides for live preview studio
  final SubscriptionCardBackground? overrideBackground;
  final Color? overrideCustomBackgroundColor;
  final SubscriptionCardLayout? overrideLayout;
  final SubscriptionBrandAccent? overrideBrandAccent;
  final SubscriptionPriceMode? overridePriceMode;
  final SubscriptionRenewalBadgeMode? overrideRenewalBadgeMode;
  final PaymentBadgeStyle? overridePaymentBadgeStyle;
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
    this.cardBrand,
    this.cardBrandIcon,
    this.isCardExpiring = false,
    this.hasNoCard = false,
    this.overrideBackground,
    this.overrideCustomBackgroundColor,
    this.overrideLayout,
    this.overrideBrandAccent,
    this.overridePriceMode,
    this.overrideRenewalBadgeMode,
    this.overridePaymentBadgeStyle,
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
        final badgeStyle = overridePaymentBadgeStyle ?? ctrl.paymentBadgeStyle;
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
              badgeStyle: badgeStyle,
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
              badgeStyle: badgeStyle,
              showPaymentChip: showPaymentChip,
              showCatChip: showCatChip,
              showDaily: showDaily,
            );
          case SubscriptionCardLayout.oneUiFluent:
            return _buildOneUiFluentItem(
              context,
              bgType: bgType,
              brandAccent: brandAccent,
              priceMode: priceMode,
              badgeMode: badgeMode,
              badgeStyle: badgeStyle,
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
    required PaymentBadgeStyle badgeStyle,
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            _buildBrandIconWithBadge(
                              subscription: sub,
                              size: 44,
                              borderRadius: 14,
                              showPaymentChip: showPaymentChip,
                              badgeStyle: badgeStyle,
                              cardBrand: cardBrand,
                              cardBrandIcon: cardBrandIcon,
                              isCardExpiring: isCardExpiring,
                              hasNoCard: hasNoCard,
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
                                      badgeStyle: badgeStyle,
                                      paymentMethodNickname: paymentMethodNickname,
                                      cardBrand: cardBrand,
                                      cardBrandIcon: cardBrandIcon,
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
                                _buildPriceDisplay(sub, priceMode: priceMode, showDaily: showDaily),
                                const SizedBox(height: 4),
                                _buildRenewalBadge(sub, badgeMode: badgeMode),
                              ],
                            ),
                          ],
                        ),
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
    required PaymentBadgeStyle badgeStyle,
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
              _buildBrandIconWithBadge(
                subscription: sub,
                size: 34,
                borderRadius: 10,
                showPaymentChip: showPaymentChip,
                badgeStyle: badgeStyle,
                cardBrand: cardBrand,
                cardBrandIcon: cardBrandIcon,
                isCardExpiring: isCardExpiring,
                hasNoCard: hasNoCard,
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
                  _buildPriceDisplay(sub, priceMode: priceMode, showDaily: showDaily, isCompact: true),
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
    required PaymentBadgeStyle badgeStyle,
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
      cardBrand: cardBrand,
      cardBrandIcon: cardBrandIcon,
      isCardExpiring: isCardExpiring,
      hasNoCard: hasNoCard,
      overrideBrandAccent: brandAccent,
      overridePriceMode: priceMode,
      overrideRenewalBadgeMode: badgeMode,
      overridePaymentBadgeStyle: badgeStyle,
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
    CardBrand? cardBrand,
    IconData? cardBrandIcon,
    bool isCardExpiring = false,
    bool hasNoCard = false,
    SubscriptionBrandAccent? overrideBrandAccent,
    SubscriptionPriceMode? overridePriceMode,
    SubscriptionRenewalBadgeMode? overrideRenewalBadgeMode,
    PaymentBadgeStyle? overridePaymentBadgeStyle,
    bool? overrideShowCycleProgress,
    bool? overrideShowPaymentMethodChip,
    bool? overrideShowCategoryChip,
    bool? overrideShowDailyEquivalent,
  }) {
    final ctrl = OneUIEffectsController.instance;
    final priceMode = overridePriceMode ?? ctrl.priceMode;
    final badgeMode = overrideRenewalBadgeMode ?? ctrl.renewalBadgeMode;
    final badgeStyle = overridePaymentBadgeStyle ?? ctrl.paymentBadgeStyle;
    final showPaymentChip = overrideShowPaymentMethodChip ?? ctrl.showPaymentMethodChip;
    final showCatChip = overrideShowCategoryChip ?? ctrl.showCategoryChip;
    final showDaily = overrideShowDailyEquivalent ?? ctrl.showDailyEquivalent;

    final sub = subscription;

    Widget? subtitleWidget;
    if (!isSelectionMode) {
      subtitleWidget = _buildMetadataChipsRow(
        sub,
        showCatChip: showCatChip,
        showPaymentChip: showPaymentChip,
        badgeStyle: badgeStyle,
        paymentMethodNickname: paymentMethodNickname,
        cardBrand: cardBrand,
        cardBrandIcon: cardBrandIcon,
        isCardExpiring: isCardExpiring,
        hasNoCard: hasNoCard,
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
          _buildBrandIconWithBadge(
            subscription: sub,
            size: 44,
            borderRadius: 14,
            showPaymentChip: showPaymentChip,
            badgeStyle: badgeStyle,
            cardBrand: cardBrand,
            cardBrandIcon: cardBrandIcon,
            isCardExpiring: isCardExpiring,
            hasNoCard: hasNoCard,
          ),
        ],
      ),
      title: sub.name,
      customSubtitle: subtitleWidget,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPriceDisplay(sub, priceMode: priceMode, showDaily: showDaily),
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
    bool showDaily = false,
    bool isCompact = false,
  }) {
    final currency = sub.currency;
    final price = sub.price;

    String text;
    switch (priceMode) {
      case SubscriptionPriceMode.monthlyEquivalent:
        text = '$currency${sub.monthlyCost.toStringAsFixed(2)}/mo';
        break;
      case SubscriptionPriceMode.billedAmount:
        final cycleSuffix = switch (sub.billingCycle) {
          BillingCycle.monthly => '/mo',
          BillingCycle.yearly => '/yr',
          BillingCycle.weekly => '/wk',
          BillingCycle.quarterly => '/qtr',
        };
        text = '$currency${price.toStringAsFixed(2)}$cycleSuffix';
        break;
      case SubscriptionPriceMode.rawAmount:
        text = '$currency${price.toStringAsFixed(2)}';
        break;
    }

    final priceWidget = Text(
      text,
      style: TextStyle(
        fontSize: isCompact ? 14 : 16,
        fontWeight: FontWeight.w700,
        color: OneUITheme.textPrimary,
        letterSpacing: -0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!showDaily) {
      return priceWidget;
    }

    final dailyText = '$currency${sub.dailyCost.toStringAsFixed(2)}/day';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        priceWidget,
        const SizedBox(height: 1),
        Text(
          dailyText,
          style: TextStyle(
            fontSize: isCompact ? 10.0 : 11.0,
            fontWeight: FontWeight.w500,
            color: OneUITheme.textSecondary,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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

  static Widget _buildBrandIconWithBadge({
    required Subscription subscription,
    required double size,
    required double borderRadius,
    required bool showPaymentChip,
    required PaymentBadgeStyle badgeStyle,
    CardBrand? cardBrand,
    IconData? cardBrandIcon,
    bool isCardExpiring = false,
    bool hasNoCard = false,
  }) {
    final baseIcon = OneUIBrandIcon(
      subscription: subscription,
      size: size,
      borderRadius: borderRadius,
    );

    final showCornerBadge = showPaymentChip &&
        !hasNoCard &&
        badgeStyle == PaymentBadgeStyle.cornerBadge &&
        (cardBrand != null || cardBrandIcon != null);

    if (!showCornerBadge) {
      return baseIcon;
    }

    final badgeWidth = size >= 40 ? 18.0 : 15.0;
    final badgeHeight = size >= 40 ? 11.5 : 9.5;

    Widget badgeChild;
    if (cardBrand != null) {
      badgeChild = OneUIPaymentBrandIcon(
        brand: cardBrand,
        width: badgeWidth,
        height: badgeHeight,
        borderRadius: 2.5,
        showShadow: true,
      );
    } else {
      badgeChild = Container(
        width: badgeWidth,
        height: badgeHeight,
        decoration: BoxDecoration(
          color: OneUITheme.cardColor,
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            cardBrandIcon ?? Icons.credit_card_rounded,
            size: size >= 40 ? 9.5 : 7.5,
            color: isCardExpiring ? OneUITheme.accentAmber : OneUITheme.textSecondary,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        Positioned(
          right: -1,
          bottom: -1,
          child: badgeChild,
        ),
      ],
    );
  }

  static Widget _buildMetadataChipsRow(
    Subscription sub, {
    required bool showCatChip,
    required bool showPaymentChip,
    PaymentBadgeStyle badgeStyle = PaymentBadgeStyle.cornerBadge,
    String? paymentMethodNickname,
    CardBrand? cardBrand,
    IconData? cardBrandIcon,
    bool isCardExpiring = false,
    bool hasNoCard = false,
  }) {
    final hasCard = !hasNoCard &&
        ((paymentMethodNickname != null && paymentMethodNickname.isNotEmpty) || cardBrand != null);

    final categoryText = showCatChip
        ? '${sub.category.label} • ${sub.billingCycle.label}'
        : sub.billingCycle.label;

    Widget? brandWidget;
    if (cardBrand != null) {
      brandWidget = OneUIPaymentBrandIcon(
        brand: cardBrand,
        width: 22,
        height: 14.5,
        borderRadius: 2.5,
      );
    } else {
      brandWidget = Icon(
        cardBrandIcon ?? Icons.credit_card_rounded,
        size: 13,
        color: isCardExpiring
            ? OneUITheme.accentAmber
            : OneUITheme.textSecondary.withValues(alpha: 0.9),
      );
    }

    final isCornerBadge = badgeStyle == PaymentBadgeStyle.cornerBadge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: categoryText,
                ),
                if (showPaymentChip && hasCard) ...[
                  if (isCornerBadge) ...[
                    // In corner badge mode, brand logo is on the app squircle
                    if (paymentMethodNickname != null && paymentMethodNickname.isNotEmpty) ...[
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: paymentMethodNickname,
                        style: TextStyle(
                          color: isCardExpiring ? OneUITheme.accentAmber : OneUITheme.textSecondary,
                          fontWeight: isCardExpiring ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ] else ...[
                    // In inline mode, show logo inline next to nickname
                    const TextSpan(text: ' • '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: brandWidget,
                      ),
                    ),
                    TextSpan(
                      text: paymentMethodNickname ?? cardBrand?.label ?? '',
                      style: TextStyle(
                        color: isCardExpiring ? OneUITheme.accentAmber : OneUITheme.textSecondary,
                        fontWeight: isCardExpiring ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: OneUITheme.textSecondary,
            ),
          ),
        ),
        if (showPaymentChip && hasNoCard) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: OneUITheme.accentRed.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
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
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Card expiring',
              style: TextStyle(
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
}
