import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_toast.dart';
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
        final dateFormat = OneUIDateFormats.weekdayMonthDay;

        final dueThisWeek = list.where((s) => s.daysRemaining >= 0 && s.daysRemaining <= 7).toList();
        final dueThisMonth = list.where((s) => s.daysRemaining > 7 && s.daysRemaining <= 30).toList();
        final dueLater = list.where((s) => s.daysRemaining > 30).toList();
        final overdue = list.where((s) => s.daysRemaining < 0).toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final windowEnd = today.add(const Duration(days: 30));

        final next30DaysSubs = list.where((s) => s.daysRemaining <= 30).toList();
        final totalNext30Days = next30DaysSubs.fold(0.0, (acc, s) {
          int occurrences = 0;
          DateTime d = DateTime(s.nextBillingDate.year, s.nextBillingDate.month, s.nextBillingDate.day);
          if (d.isBefore(today)) {
            occurrences++;
            d = s.calculateNextDateFrom(d);
          }
          while (!d.isAfter(windowEnd) && occurrences < 15) {
            occurrences++;
            d = s.calculateNextDateFrom(d);
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
                        OneUIToast.show(context, 'Smart reminders alert ${store.defaultReminderDays} days before renewals');
                      },
                    ),
                  ],
                ),
              ),

              // 30-Day Forecast Card
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(18),
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
                ),
              ),

              // Overdue (if any)
              if (overdue.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: OneUISection(
                      title: 'Overdue (${overdue.length})',
                      child: OneUIGroupCard(
                        items: overdue.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                      ),
                    ),
                  ),
                ),

              // Due This Week
              if (dueThisWeek.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: OneUISection(
                      title: 'Due this week (${dueThisWeek.length})',
                      child: OneUIGroupCard(
                        items: dueThisWeek.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                      ),
                    ),
                  ),
                ),

              // Later This Month
              if (dueThisMonth.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: OneUISection(
                      title: 'Later this month (${dueThisMonth.length})',
                      child: OneUIGroupCard(
                        items: dueThisMonth.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                      ),
                    ),
                  ),
                ),

              // Future Renewals
              if (dueLater.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: OneUISection(
                      title: 'Future renewals (${dueLater.length})',
                      child: OneUIGroupCard(
                        items: dueLater.map((sub) => _buildItem(context, sub, dateFormat, store)).toList(),
                      ),
                    ),
                  ),
                ),

              // Empty State
              if (list.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
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
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 140),
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
      leading: OneUIBrandIcon(
        subscription: sub,
        size: 42,
        borderRadius: 13,
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
                OneUIToast.show(context, 'Marked ${sub.name} as renewed!');
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
