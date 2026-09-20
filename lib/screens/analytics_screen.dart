import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SubscriptionStore.instance,
        OneUIEffectsController.instance,
      ]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final totalMonthly = store.totalMonthlySpend;
        final totalYearly = totalMonthly * 12;

        final Map<SubscriptionCategory, double> categorySpend = {};
        for (var sub in store.subscriptions) {
          categorySpend[sub.category] = (categorySpend[sub.category] ?? 0) + sub.monthlyCost;
        }

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // One UI Signature Collapsible Header
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Analytics',
                  subtitle: 'Spending patterns and forecasts',
                  hasBigHeader: true,
                  expandedHeight: 270.0,
                  actions: [
                    OneUIHeaderAction(
                      icon: Icons.share_outlined,
                      tooltip: 'Share report',
                      onTap: () {},
                    ),
                    OneUIHeaderAction(
                      icon: Icons.more_vert_rounded,
                      tooltip: 'More options',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Annual & Monthly Stats Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Annual Cost',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${totalYearly.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: OneUITheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Monthly Avg', style: TextStyle(fontSize: 12, color: OneUITheme.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${totalMonthly.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: OneUITheme.accentGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Active Services', style: TextStyle(fontSize: 12, color: OneUITheme.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${store.totalActiveCount} Services',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: OneUITheme.accentBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Category Breakdown Section
                      OneUISection(
                        title: 'Spending by category',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                            boxShadow: OneUITheme.cardShadow,
                          ),
                          child: Column(
                            children: categorySpend.entries.map((entry) {
                              final category = entry.key;
                              final amount = entry.value;
                              final percentage = totalMonthly > 0 ? (amount / totalMonthly) : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(category.icon, size: 18, color: OneUITheme.textSecondary),
                                            const SizedBox(width: 10),
                                            Text(
                                              category.label,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: OneUITheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '\$${amount.toStringAsFixed(2)} (${(percentage * 100).toStringAsFixed(0)}%)',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: OneUITheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                                        valueColor: const AlwaysStoppedAnimation<Color>(OneUITheme.accentBlue),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
