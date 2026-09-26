import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';

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
      statusBadgeLabel = '${store.currency}${(totalSpend - budget).toStringAsFixed(0)} over';
    } else {
      statusBadgeBg = colorGreen.withValues(alpha: 0.15);
      statusBadgeText = colorGreen;
      statusBadgeLabel = '${store.currency}${remaining.toStringAsFixed(0)} left';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: ClipRRect(
        borderRadius: OneUITheme.cardBorderRadius,
        child: Stack(
          children: [
            // 1. Soft, balanced Samsung Blue ambient glow positioned BENEATH the card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2),
                    radius: 1.1,
                    colors: [
                      const Color(0xFF0381FE).withValues(alpha: 0.36), // Soft balanced blue core
                      const Color(0xFF0381FE).withValues(alpha: 0.16), // Gentle ambient fade
                      const Color(0xFF0381FE).withValues(alpha: 0.04), // Faint outer breath
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.50, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Frosted glass blur & translucent card body (completely flat, no 3D borders or shadows)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: const Color(0xFF191A1E).withValues(alpha: 0.64), // Balanced dark glass
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBadgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusBadgeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusBadgeText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Main Spend Metric & Right-Aligned Percentage
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${store.currency}${totalSpend.toStringAsFixed(2)}',
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
                                '/ ${store.currency}${budget.toStringAsFixed(0)}',
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
                            const Spacer(),
                            if (budget > 0)
                              Text(
                                '$budgetPercent%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: trackColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // One UI Track Bar (12dp thick, 100dp radius, dark slate graphite track)
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
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: fillFactor,
                                    child: Container(
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: trackColor,
                                        borderRadius: BorderRadius.circular(100),
                                        boxShadow: [
                                          BoxShadow(
                                            color: trackColor.withValues(alpha: 0.30),
                                            blurRadius: 6,
                                            offset: Offset.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                                  Text(
                                    '~${store.currency}${dailyAvg.toStringAsFixed(2)} / day',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
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
