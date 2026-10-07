import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_ambient_glow.dart';
import '../utils/one_ui_date_formats.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI Monthly Budget Card
///
/// Features a streamlined One UI Device Care visual hierarchy:
/// - Prominent spend typography ($83.96 in 32pt bold) with inline dimmed limit
/// - Single top-right status capsule with subtle 15% opacity tint
/// - Thick, rounded 12dp One UI progress track with state-based color transitions
/// - Prominent ambient Samsung Blue glow layered beneath the card, radiating through a translucent frosted glass surface
/// - Completely flat design with zero 3D rim bevels or drop shadows
/// - Samsung Device Care key-value rows with clean typography and zero icons
/// - Multi-line right-aligned Next Renewal block preventing any title truncation
class OneUIBudgetCard extends StatelessWidget {
  final SubscriptionStore store;
  final List<Subscription> upcomingSubs;
  final VoidCallback onTap;

  // One UI Track Bar Color Tokens
  static const Color trackBackground = Color(0xFF2C2D30);
  static const Color colorUnder75 = Color(0xFF0381FE); // Soft Samsung Blue
  static const Color color75to90 = Color(0xFFF59E0B);  // Soft Amber / Warning
  static const Color colorCrimson = Color(0xFFFF5C5C); // Vibrant One UI Crimson
  static const Color colorGreen = Color(0xFF00C05A);   // One UI Green

  /// Budget track gradient, blue → orange → red as spending approaches the limit.
  static const List<Color> trackColors = [
    // Several Blues (0% to ~45%)
    Color(0xFF0044B2), // Deep Royal Blue
    Color(0xFF0066FF), // Vivid Electric Blue
    Color(0xFF0381FE), // Samsung Signature Blue
    Color(0xFF4791FF), // Soft Bright Azure

    // Smooth Warm Transition (avoids green tint entirely)
    Color(0xFFE59078), // Warm Apricot Transition

    // Several Oranges (~55% to ~82%)
    Color(0xFFFF9E00), // Rich Golden Orange
    Color(0xFFFF8500), // Vivid One UI Orange
    Color(0xFFFF6200), // Deep Tangerine Orange
    Color(0xFFFF4500), // Sunset Fiery Orange

    // Several Reds (~82% to 100%)
    Color(0xFFFF2A2A), // Bright Warning Crimson
    Color(0xFFE50914), // Pure Vibrant Red
    Color(0xFFDC2626), // Deep Signal Red
    Color(0xFF8B0000), // Dark Ruby Red
  ];
  static const List<double> trackStops = [
    0.0,
    0.15,
    0.30,
    0.42,
    0.50,
    0.58,
    0.68,
    0.76,
    0.83,
    0.89,
    0.93,
    0.97,
    1.0,
  ];

  /// The track colour at progress [t] (0–1): the colour at the fill's leading edge.
  static Color trackColorAt(double t) {
    final x = t.clamp(0.0, 1.0);
    for (var i = 1; i < trackStops.length; i++) {
      if (x <= trackStops[i]) {
        final span = trackStops[i] - trackStops[i - 1];
        final f = span <= 0 ? 1.0 : (x - trackStops[i - 1]) / span;
        return Color.lerp(trackColors[i - 1], trackColors[i], f)!;
      }
    }
    return trackColors.last;
  }

  const OneUIBudgetCard({
    super.key,
    required this.store,
    required this.upcomingSubs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final budget = store.monthlyBudget;
    final totalSpend = store.totalMonthlySpend;
    final remaining = budget > totalSpend ? budget - totalSpend : 0.0;
    final budgetProgress = budget > 0 ? (totalSpend / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = budget > 0 && totalSpend > budget;
    final budgetPercent = budget > 0 ? ((totalSpend / budget) * 100).round() : 0;
    final dailyAvg = totalSpend / 30.0;

    // Next renewal formatted subtext
    final String renewalSubtext;
    if (upcomingSubs.isNotEmpty) {
      final nextSub = upcomingSubs.first;
      final dateStr = OneUIDateFormats.monthDay.format(nextSub.nextBillingDate);
      final days = nextSub.daysRemaining;
      final String relativeStr;
      if (days < 0) {
        relativeStr = '${-days}d overdue';
      } else if (days == 0) {
        relativeStr = 'today';
      } else if (days == 1) {
        relativeStr = 'tomorrow';
      } else {
        relativeStr = 'in $days days';
      }
      renewalSubtext = '$dateStr · $relativeStr';
    } else {
      renewalSubtext = '';
    }

    // Determine track and status color
    final Color trackColor;
    if (isOverBudget || budgetProgress > 0.90) {
      trackColor = colorCrimson;
    } else if (budgetProgress >= 0.75) {
      trackColor = color75to90;
    } else {
      trackColor = colorUnder75;
    }

    // Top-right single status capsule
    final Color statusBadgeBg;
    final Color statusBadgeText;
    final String statusBadgeLabel;
    if (budget <= 0) {
      statusBadgeBg = Colors.white.withValues(alpha: 0.08);
      statusBadgeText = OneUITheme.textSecondary;
      statusBadgeLabel = 'No limit set';
    } else if (isOverBudget) {
      statusBadgeBg = colorCrimson.withValues(alpha: 0.15);
      statusBadgeText = colorCrimson;
      statusBadgeLabel = '${formatMoney((totalSpend - budget), store.currency, decimals: 0)} over';
    } else {
      statusBadgeBg = colorGreen.withValues(alpha: 0.15);
      statusBadgeText = colorGreen;
      statusBadgeLabel = '${formatMoney(remaining, store.currency, decimals: 0)} left';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: ClipRRect(
        borderRadius: OneUITheme.cardBorderRadius,
        child: Stack(
          children: [
            // 1. Ambient glow beneath the glass, tinted like the track's leading edge.
            OneUIAmbientGlow(
              // glowTint lifts the dark ends of the gradient (deep blue, ruby) so they still glow.
              color: budget > 0 ? OneUITheme.glowTint(trackColorAt(budgetProgress)) : OneUITheme.glowDefault,
            ),

            // 2. Frosted glass blur & translucent card body (completely flat, no 3D borders or shadows)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: const Color(0xFF1B1C20).withValues(alpha: 0.68), // Understated dark glass
                child: InkWell(
                  onTap: () {
                    Haptics.tap();
                    onTap();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row: Title with subtle chevron & single status badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Monthly budget',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: OneUITheme.textTertiary.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Large-unit currencies (Rp, ₫) shrink to fit instead of overflowing.
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBadgeBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    statusBadgeLabel,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: statusBadgeText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Main Spend Metric & Right-Aligned Percentage
                        Row(
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      formatMoney(totalSpend, store.currency, style: MoneyStyle.summary),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.8,
                                        color: OneUITheme.textPrimary,
                                      ),
                                    ),
                                    if (budget > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '/ ${formatMoney(budget, store.currency, decimals: 0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      const Text(
                                        'spent this month',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (budget > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '$budgetPercent%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: trackColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // One UI Track Bar (12dp thick, 100dp radius, dark slate graphite track with multi-tone gradient fill)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final totalWidth = constraints.maxWidth;
                            final fillFactor = budgetProgress.clamp(0.0, 1.0);
                            return Container(
                              height: 12,
                              width: totalWidth,
                              decoration: BoxDecoration(
                                color: trackBackground,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Stack(
                                  children: [
                                    if (fillFactor > 0)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          width: totalWidth * fillFactor,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(100),
                                            boxShadow: [
                                              BoxShadow(
                                                color: trackColor.withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: Offset.zero,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(100),
                                            child: OverflowBox(
                                              alignment: Alignment.centerLeft,
                                              minWidth: totalWidth,
                                              maxWidth: totalWidth,
                                              minHeight: 12,
                                              maxHeight: 12,
                                              child: Container(
                                                height: 12,
                                                width: totalWidth,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: trackColors,
                                                    stops: trackStops,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Samsung Device Care-Style Key-Value Container (Flat, No Border, No Icons, No Truncation)
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
                              // Row 1: Daily Burn (clean typography, no icon)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Daily burn',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '~${formatMoney(dailyAvg, store.currency, style: MoneyStyle.approximate)} / day',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: OneUITheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: 14,
                                thickness: 0.6,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              // Row 2: Next Renewal (clean typography, no icon, zero clipping even for long titles)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Text(
                                      'Next renewal',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: OneUITheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: upcomingSubs.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${upcomingSubs.first.name}\u200B',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: OneUITheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                renewalSubtext,
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: OneUITheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'None scheduled',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: OneUITheme.textSecondary,
                                            ),
                                          ),
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
          ],
        ),
      ),
    );
  }
}
