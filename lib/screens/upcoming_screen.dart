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
      animation: SubscriptionStore.instance,
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final list = store.upcomingDue;
        final dateFormat = DateFormat('EEEE, MMM d');

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
                  subtitle: 'Next 30 days renewal timeline',
                  hasBigHeader: true,
                  expandedHeight: 270.0,
                  actions: [
                    OneUIHeaderAction(
                      icon: Icons.calendar_month_outlined,
                      tooltip: 'Calendar view',
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

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notification alert pill card
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: OneUITheme.accentTeal.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: OneUITheme.accentTeal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Reminders Active',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'You will receive push alerts before renewals',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grouped Renewals Card
                      OneUISection(
                        title: 'Renewals calendar',
                        child: OneUIGroupCard(
                          items: list.map((sub) {
                            final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                            return OneUIGroupItem(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: sub.brandColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(sub.iconData, color: Colors.white, size: 20),
                              ),
                              title: sub.name,
                              subtitle: '${dateFormat.format(sub.nextBillingDate)} • in $days days',
                              subtitleColor: days <= 5 ? OneUITheme.accentRed : OneUITheme.accentBlue,
                              trailing: Text(
                                '${sub.currency}${sub.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.textPrimary,
                                ),
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
                          }).toList(),
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
