import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SubscriptionStore.instance,
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final totalMonthly = store.totalMonthlySpend;
        final totalYearly = totalMonthly * 12;

        // Group by category
        final Map<SubscriptionCategory, double> categorySpend = {};
        for (var sub in store.subscriptions) {
          categorySpend[sub.category] = (categorySpend[sub.category] ?? 0) + sub.monthlyCost;
        }

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Spending patterns and forecasts',
                    style: TextStyle(
                      fontSize: 15,
                      color: OneUITheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Big Stats Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: OneUITheme.surfaceCard,
                      borderRadius: OneUITheme.cardBorderRadius,
                      border: OneUITheme.subtleBorder,
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
                        color: OneUITheme.surfaceCard,
                        borderRadius: OneUITheme.cardBorderRadius,
                        border: OneUITheme.subtleBorder,
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
        );
      },
    );
  }
}
