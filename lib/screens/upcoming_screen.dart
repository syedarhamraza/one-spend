import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
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
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: OneUITheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Next 30 days renewal timeline',
                          style: const TextStyle(
                            fontSize: 15,
                            color: OneUITheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Notification alert pill
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OneUITheme.surfaceCard,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.subtleBorder,
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
                      ],
                    ),
                  ),
                ),

                // Timeline List
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    child: OneUISection(
                      title: 'Renewals calendar',
                      child: Column(
                        children: list.map((sub) {
                          final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OneUICard(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sub.brandColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(sub.iconData, color: Colors.white, size: 22),
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
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
