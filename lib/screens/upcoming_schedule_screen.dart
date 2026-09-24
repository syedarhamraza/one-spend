import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';

class UpcomingScheduleScreen extends StatelessWidget {
  final Subscription subscription;

  const UpcomingScheduleScreen({
    super.key,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = OneUIDateFormats.fullDate;
    final shortFormat = OneUIDateFormats.monthDayYear;
    final upcomingDates = subscription.getUpcomingBillingDates(12);

    final totalProjected = upcomingDates.length * subscription.price;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: OneUICollapsibleHeaderDelegate(
                title: 'Upcoming schedule',
                hasBigHeader: false,
                showBackButton: true,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Top Subscription Summary Card
                    AnimatedBuilder(
                      animation: OneUIEffectsController.instance,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: OneUIEffectsController.instance.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUIEffectsController.instance.cardBorder,
                            boxShadow: OneUIEffectsController.instance.cardShadow,
                          ),
                          child: child,
                        );
                      },
                      child: Row(
                        children: [
                          OneUIBrandIcon(
                            subscription: subscription,
                            size: 48,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subscription.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: OneUITheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${subscription.currency}${subscription.price.toStringAsFixed(2)} / ${subscription.billingCycle.label}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                '12-Cycle Est.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: OneUITheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${subscription.currency}${totalProjected.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.accentBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Section Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          const Text(
                            'PROJECTED BILLING DATES',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: OneUITheme.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${upcomingDates.length} occurrences',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Group Card of 12 Upcoming Occurrences
                    OneUIGroupCard(
                      margin: EdgeInsets.zero,
                      items: [
                        for (int i = 0; i < upcomingDates.length; i++)
                          _buildScheduleItem(
                            index: i + 1,
                            date: upcomingDates[i],
                            dateFormat: dateFormat,
                            shortFormat: shortFormat,
                            isNext: i == 0,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Info note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: OneUITheme.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Projections are automatically calculated according to your ${subscription.billingCycle.label.toLowerCase()} billing cycle. Reminders will notify you before each cycle date.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OneUIGroupItem _buildScheduleItem({
    required int index,
    required DateTime date,
    required DateFormat dateFormat,
    required DateFormat shortFormat,
    required bool isNext,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diffDays = target.difference(today).inDays;

    String countdown;
    if (diffDays == 0) {
      countdown = 'Today';
    } else if (diffDays == 1) {
      countdown = 'Tomorrow';
    } else if (diffDays < 30) {
      countdown = 'In $diffDays days';
    } else {
      final months = (diffDays / 30).round();
      countdown = 'In ~$months ${months == 1 ? 'month' : 'months'}';
    }

    return OneUIGroupItem(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isNext ? OneUITheme.accentBlue : Colors.white).withValues(alpha: isNext ? 0.16 : 0.07),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$index',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isNext ? OneUITheme.accentBlue : OneUITheme.textSecondary,
          ),
        ),
      ),
      title: shortFormat.format(date),
      subtitle: '${dateFormat.format(date)} • $countdown',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isNext) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: OneUITheme.accentBlue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: OneUITheme.accentBlue,
                ),
              ),
            ),
          ],
          Text(
            '${subscription.currency}${subscription.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isNext ? OneUITheme.textPrimary : OneUITheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
