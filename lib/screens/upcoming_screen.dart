import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import 'subscription_detail_screen.dart';

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SubscriptionStore.instance,
        OneUIEffectsController.instance,
      ]),
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final list = store.upcomingDue;
        final dateFormat = DateFormat('EEE, MMM d');

        final dueThisWeek = list.where((s) => s.daysRemaining >= 0 && s.daysRemaining <= 7).toList();
        final dueThisMonth = list.where((s) => s.daysRemaining > 7 && s.daysRemaining <= 30).toList();
        final dueLater = list.where((s) => s.daysRemaining > 30).toList();
        final overdue = list.where((s) => s.daysRemaining < 0).toList();

        final next30DaysSubs = list.where((s) => s.daysRemaining >= 0 && s.daysRemaining <= 30).toList();
        final totalNext30Days = next30DaysSubs.fold(0.0, (acc, s) {
          // Count how many times this subscription renews within 30 days
          int occurrences = 1;
          if (s.billingCycle == BillingCycle.weekly) {
            // A weekly sub renews ~4 times in 30 days from its next billing date
            final daysInWindow = 30 - s.daysRemaining;
            occurrences = 1 + (daysInWindow ~/ 7);
          }
          return acc + (s.price * occurrences);
        });

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // One UI Signature Collapsible Header
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Upcoming',
                  subtitle: '${store.currency}${totalNext30Days.toStringAsFixed(2)} due in next 30 days',
                  hasBigHeader: true,
                  expandedHeight: 270.0,
                  actions: [
                    OneUIHeaderAction(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Reminders info',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Smart reminders alert ${store.defaultReminderDays} days before renewals'),
                            backgroundColor: OneUITheme.surfacePill,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 30-Day Forecast Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: OneUITheme.accentTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: OneUITheme.accentTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '30-Day Forecast',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${store.currency}${totalNext30Days.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                      color: OneUITheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${next30DaysSubs.length} subscriptions renewing',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: OneUITheme.surfacePill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_active_rounded, size: 14, color: OneUITheme.accentAmber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${store.defaultReminderDays}d alert',
                                    style: const TextStyle(fontSize: 11.5, color: OneUITheme.textPrimary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Overdue (if any)
                      if (overdue.isNotEmpty) ...[
                        OneUISection(
                          title: 'Overdue (${overdue.length})',
                          child: OneUIGroupCard(
                            items: overdue.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Due This Week
                      if (dueThisWeek.isNotEmpty) ...[
                        OneUISection(
                          title: 'Due this week (${dueThisWeek.length})',
                          child: OneUIGroupCard(
                            items: dueThisWeek.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Later This Month
                      if (dueThisMonth.isNotEmpty) ...[
                        OneUISection(
                          title: 'Later this month (${dueThisMonth.length})',
                          child: OneUIGroupCard(
                            items: dueThisMonth.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Future Renewals
                      if (dueLater.isNotEmpty) ...[
                        OneUISection(
                          title: 'Future renewals (${dueLater.length})',
                          child: OneUIGroupCard(
                            items: dueLater.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                          ),
                        ),
                      ],

                      // Empty State
                      if (list.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                            boxShadow: OneUITheme.cardShadow,
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.event_available_rounded, size: 48, color: OneUITheme.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'No upcoming renewals',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: OneUITheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Active subscriptions will appear here automatically',
                                style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                              ),
                            ],
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

  OneUIGroupItem _buildItem(
    BuildContext context,
    Subscription sub,
    DateFormat dateFormat,
    SubscriptionStore store,
  ) {
    final days = sub.daysRemaining;
    String subtitleText;
    Color subtitleColor;

    if (days < 0) {
      subtitleText = 'Overdue by ${-days} days';
      subtitleColor = OneUITheme.accentRed;
    } else if (days == 0) {
      subtitleText = 'Due today (${dateFormat.format(sub.nextBillingDate)})';
      subtitleColor = OneUITheme.accentRed;
    } else if (days == 1) {
      subtitleText = 'Due tomorrow (${dateFormat.format(sub.nextBillingDate)})';
      subtitleColor = OneUITheme.accentAmber;
    } else if (days <= 5) {
      subtitleText = 'in $days days (${dateFormat.format(sub.nextBillingDate)})';
      subtitleColor = OneUITheme.accentAmber;
    } else {
      subtitleText = '${dateFormat.format(sub.nextBillingDate)} • in $days days';
      subtitleColor = OneUITheme.accentBlue;
    }

    return OneUIGroupItem(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: sub.brandColor,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Icon(sub.iconData, color: Colors.white, size: 21),
      ),
      title: sub.name,
      subtitle: subtitleText,
      subtitleColor: subtitleColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${sub.currency}${sub.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                store.renewSubscription(sub.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Marked ${sub.name} as renewed!'),
                    backgroundColor: OneUITheme.surfacePill,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OneUITheme.accentGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: OneUITheme.accentGreen, size: 16),
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubscriptionDetailScreen(subscription: sub),
          ),
        );
      },
    );
  }
}
