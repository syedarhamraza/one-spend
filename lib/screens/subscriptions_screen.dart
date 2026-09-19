import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_fab.dart';
import '../widgets/one_ui_floating_header.dart';
import 'add_subscription_screen.dart';
import 'subscription_detail_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SubscriptionStore.instance,
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final allSubs = store.subscriptions;

        final filteredSubs = allSubs.where((s) {
          if (_searchQuery.isEmpty) return true;
          return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.category.label.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final upcomingSubs = List<Subscription>.from(filteredSubs)
          ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));

        final dateFormat = DateFormat('MMM dd');

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // One UI Signature Viewing Area (Collapsible Header)
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Floating Action Header Island matching Screenshot 2
                            OneUIFloatingHeader(
                              title: 'OneSpend',
                              leadingIcon: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: OneUITheme.accentBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.all_inclusive_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              onSearch: () {
                                setState(() {
                                  _showSearch = !_showSearch;
                                  if (!_showSearch) {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  }
                                });
                              },
                              onMore: () {
                                _showMoreBottomSheet(context);
                              },
                            ),

                            const SizedBox(height: 24),

                            // Search bar if toggled
                            if (_showSearch) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: OneUITheme.surfaceCard,
                                  borderRadius: OneUITheme.pillBorderRadius,
                                  border: OneUITheme.subtleBorder,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Search subscriptions...',
                                    hintStyle: TextStyle(color: OneUITheme.textSecondary),
                                    border: InputBorder.none,
                                    icon: Icon(Icons.search_rounded, color: OneUITheme.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Viewing Area Big Heading (Samsung One UI Standard)
                            const Text(
                              'Subscriptions',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: OneUITheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${store.totalActiveCount} active • \$${store.totalMonthlySpend.toStringAsFixed(2)} / month',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: OneUITheme.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // One UI Summary Pill / Budget Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: OneUITheme.surfaceCard,
                                borderRadius: OneUITheme.cardBorderRadius,
                                border: OneUITheme.subtleBorder,
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Monthly Budget',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '\$${store.totalMonthlySpend.toStringAsFixed(0)} / \$150.00',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: OneUITheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: (store.totalMonthlySpend / 150.0).clamp(0.0, 1.0),
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: const AlwaysStoppedAnimation<Color>(OneUITheme.accentGreen),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Next: ${upcomingSubs.isNotEmpty ? upcomingSubs.first.name : "None"}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: OneUITheme.accentBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        upcomingSubs.isNotEmpty
                                            ? 'Due ${dateFormat.format(upcomingSubs.first.nextBillingDate)}'
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: OneUITheme.textSecondary,
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

                  // Section 1: Upcoming Renewals
                  if (upcomingSubs.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: OneUISection(
                          title: 'Upcoming renewals',
                          child: Column(
                            children: upcomingSubs.take(2).map((sub) {
                              final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OneUICard(
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: sub.brandColor,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(sub.iconData, color: Colors.white, size: 22),
                                  ),
                                  title: sub.name,
                                  subtitle: 'Due in $days days (${dateFormat.format(sub.nextBillingDate)})',
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

                  // Section 2: All Subscriptions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                      child: OneUISection(
                        title: 'All subscriptions (${filteredSubs.length})',
                        child: Column(
                          children: filteredSubs.map((sub) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OneUICard(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: sub.brandColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(sub.iconData, color: Colors.white, size: 22),
                                ),
                                title: sub.name,
                                subtitle: '${sub.category.label} • ${sub.billingCycle.label}',
                                subtitleColor: OneUITheme.textSecondary,
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${sub.currency}${sub.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: OneUITheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sub.status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sub.status.color,
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Green Circular FAB matching Screenshot 4
              Positioned(
                right: 22,
                bottom: 78, // Positioned right above the floating navigation pill
                child: OneUIFAB(
                  icon: Icons.add_rounded,
                  tooltip: 'Add Subscription',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OneUITheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_rounded, color: Colors.white),
              title: const Text('Sort by price', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined, color: Colors.white),
              title: const Text('Export subscription list', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
