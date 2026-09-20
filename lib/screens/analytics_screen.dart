import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  void _shareReport(BuildContext context, SubscriptionStore store) {
    final totalMonthly = store.totalMonthlySpend;
    final totalYearly = store.totalYearlySpend;
    final categorySpend = store.categorySpendMap;

    final buffer = StringBuffer();
    buffer.writeln('OneSpend Analytics Report');
    buffer.writeln('---------------------------');
    buffer.writeln('Estimated Annual Cost: ${store.currency}${totalYearly.toStringAsFixed(2)}');
    buffer.writeln('Monthly Average Spend: ${store.currency}${totalMonthly.toStringAsFixed(2)}');
    buffer.writeln('Active Subscriptions: ${store.totalActiveCount}');
    buffer.writeln('\nCategory Breakdown:');
    for (var entry in categorySpend.entries) {
      final pct = totalMonthly > 0 ? ((entry.value / totalMonthly) * 100).toStringAsFixed(1) : '0';
      buffer.writeln('• ${entry.key.label}: ${store.currency}${entry.value.toStringAsFixed(2)} ($pct%)');
    }
    final reportText = buffer.toString();

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Spend Analytics Summary',
      message: 'Preview and share your monthly spending report:',
      customContent: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          reportText,
          style: const TextStyle(fontSize: 12.5, height: 1.4, color: OneUITheme.textSecondary),
        ),
      ),
      cancelLabel: 'Close',
      confirmLabel: 'Copy Report',
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: reportText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Analytics report copied to clipboard'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

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
        final totalYearly = store.totalYearlySpend;
        final categorySpend = store.categorySpendMap;
        final highestSub = store.highestCostSubscription;

        final monthlySubsCount = store.subscriptions.where((s) => s.billingCycle == BillingCycle.monthly && s.status != SubscriptionStatus.paused).length;
        final yearlySubsCount = store.subscriptions.where((s) => s.billingCycle == BillingCycle.yearly && s.status != SubscriptionStatus.paused).length;
        final otherSubsCount = store.totalActiveCount - monthlySubsCount - yearlySubsCount;

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
                      onTap: () => _shareReport(context, store),
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
                              '${store.currency}${totalYearly.toStringAsFixed(2)}',
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
                                          '${store.currency}${totalMonthly.toStringAsFixed(2)}',
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

                      const SizedBox(height: 12),

                      // Smart Insights Card
                      if (highestSub != null) ...[
                        OneUISection(
                          title: 'Smart Insights',
                          child: OneUIGroupCard(
                            items: [
                              OneUIGroupItem(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: OneUITheme.accentAmber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, color: OneUITheme.accentAmber, size: 20),
                                ),
                                title: 'Top Single Expense',
                                subtitle: '${highestSub.name} accounts for ${store.currency}${highestSub.monthlyCost.toStringAsFixed(2)}/mo (${totalMonthly > 0 ? ((highestSub.monthlyCost / totalMonthly) * 100).toStringAsFixed(0) : 0}% of budget)',
                                subtitleColor: OneUITheme.textSecondary,
                              ),
                              OneUIGroupItem(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: OneUITheme.accentTeal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.savings_outlined, color: OneUITheme.accentTeal, size: 20),
                                ),
                                title: 'Annual Plan Savings',
                                subtitle: 'Switching monthly subscriptions to annual billing can save an estimated 10-15% annually.',
                                subtitleColor: OneUITheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Billing Cycle Distribution Card
                      OneUISection(
                        title: 'Billing cycle commitments',
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                            boxShadow: OneUITheme.cardShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCycleStat('Monthly', monthlySubsCount, OneUITheme.accentBlue),
                              _buildDivider(),
                              _buildCycleStat('Yearly', yearlySubsCount, OneUITheme.accentGreen),
                              _buildDivider(),
                              _buildCycleStat('Other', otherSubsCount, OneUITheme.accentPurple),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

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
                          child: categorySpend.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text('No active category spend', style: TextStyle(color: OneUITheme.textSecondary)),
                                  ),
                                )
                              : Column(
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
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Icon(category.icon, size: 18, color: OneUITheme.textSecondary),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        category.label,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: OneUITheme.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${store.currency}${amount.toStringAsFixed(2)} / mo (${(percentage * 100).toStringAsFixed(0)}%)',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
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
                                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                _getCategoryColor(category),
                                              ),
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

  Widget _buildDivider() {
    return Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08));
  }

  Widget _buildCycleStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: OneUITheme.textSecondary)),
      ],
    );
  }

  Color _getCategoryColor(SubscriptionCategory category) {
    switch (category) {
      case SubscriptionCategory.entertainment:
        return const Color(0xFFE50914);
      case SubscriptionCategory.music:
        return const Color(0xFF1DB954);
      case SubscriptionCategory.productivity:
        return OneUITheme.accentBlue;
      case SubscriptionCategory.cloud:
        return const Color(0xFF34AADC);
      case SubscriptionCategory.gaming:
        return OneUITheme.accentPurple;
      case SubscriptionCategory.design:
        return const Color(0xFFFF4B4B);
      case SubscriptionCategory.developer:
        return const Color(0xFF6E5494);
      case SubscriptionCategory.utilities:
        return OneUITheme.accentTeal;
      case SubscriptionCategory.finance:
        return OneUITheme.accentGreen;
      case SubscriptionCategory.health:
        return OneUITheme.accentAmber;
    }
  }
}
