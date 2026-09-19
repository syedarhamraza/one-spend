import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_alternative_options_card.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_group_card.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({
    super.key,
    required this.subscription,
  });

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  late Subscription _sub;
  bool _isRoutineDemoMode = false; // Toggle to preview Screenshot 3 exact routine labels

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
  }

  void _toggleRoutineDemo() {
    setState(() {
      _isRoutineDemoMode = !_isRoutineDemoMode;
    });
  }

  void _deleteSubscription() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OneUITheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: OneUITheme.cardBorderRadius,
        ),
        title: const Text(
          'Delete Subscription?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: OneUITheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove ${_sub.name} from OneSpend?',
          style: const TextStyle(color: OneUITheme.textSecondary),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: OneUITheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OneUITheme.accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              SubscriptionStore.instance.removeSubscription(_sub.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_sub.name} removed'),
                  backgroundColor: OneUITheme.surfacePill,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(_sub.nextBillingDate);
    final daysRemaining = _sub.nextBillingDate.difference(DateTime.now()).inDays;

    final displayTitle = _isRoutineDemoMode ? 'Color filter' : _sub.name;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // One UI Signature Collapsible Header with Back Button (Matches Screenshots 1, 2, 3, 4)
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: displayTitle,
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                  actions: [
                    // Mode switcher pill with 3D navbar capsule styling
                    GestureDetector(
                      onTap: _toggleRoutineDemo,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: _isRoutineDemoMode
                              ? OneUITheme.accentTeal.withValues(alpha: 0.25)
                              : OneUITheme.floatingColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRoutineDemoMode ? Icons.palette_rounded : Icons.tune_rounded,
                              size: 15,
                              color: _isRoutineDemoMode
                                  ? OneUITheme.accentTeal
                                  : OneUITheme.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isRoutineDemoMode ? 'Routine Spec' : 'Subscription Mode',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                                color: _isRoutineDemoMode
                                    ? OneUITheme.accentTeal
                                    : OneUITheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Body Content matching Screenshots 1, 2, 3
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Hero Device/Plan Card (Matches Galaxy S25 card in Screenshot 1 & 2)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Badge / Device icon matching Screenshot 1
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: _isRoutineDemoMode ? OneUITheme.accentTeal : _sub.brandColor,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _isRoutineDemoMode ? Icons.menu_book_rounded : _sub.iconData,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _isRoutineDemoMode ? 'Color filter routine' : '${_sub.name} Plan',
                                              style: const TextStyle(
                                                fontSize: 17.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                                color: OneUITheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.edit_outlined, size: 18, color: OneUITheme.textSecondary),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _isRoutineDemoMode
                                            ? 'App display accessibility preset'
                                            : '${_sub.currency}${_sub.price.toStringAsFixed(2)} • ${_sub.billingCycle.label}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            // Quick specs row matching Screenshot 1 (eSIM / Model Info)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Status', style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                                Text(
                                  _isRoutineDemoMode ? 'Enabled' : _sub.status.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _isRoutineDemoMode ? OneUITheme.accentBlue : _sub.status.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Next renewal', style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _isRoutineDemoMode ? 'Instant' : '$formattedDate (in $daysRemaining days)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: OneUITheme.accentBlue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Section 1: "If" / Overview (Matches Screenshot 3)
                      OneUISection(
                        title: _isRoutineDemoMode ? 'If' : 'Overview',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.grid_view_rounded, size: 20, color: OneUITheme.textPrimary),
                              ),
                              title: _isRoutineDemoMode ? 'App opened' : 'Subscription status',
                              subtitle: _isRoutineDemoMode ? 'Not set' : _sub.status.label,
                              subtitleColor: _isRoutineDemoMode ? OneUITheme.accentRed : _sub.status.color,
                            ),
                          ],
                        ),
                      ),

                      // Section 2: "Then" / Billing cycle (Matches Screenshot 3)
                      OneUISection(
                        title: _isRoutineDemoMode ? 'Then' : 'Billing cycle',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.palette_outlined, size: 20, color: OneUITheme.textPrimary),
                              ),
                              title: _isRoutineDemoMode ? 'Color filter' : '${_sub.billingCycle.label} renewal',
                              subtitle: _isRoutineDemoMode ? 'On' : formattedDate,
                              subtitleColor: OneUITheme.accentBlue,
                            ),
                          ],
                        ),
                      ),

                      // Section 3: "When routine ends" / Payment & Reminders (Matches Screenshot 3)
                      OneUISection(
                        title: _isRoutineDemoMode ? 'When routine ends' : 'Payment & reminders',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.palette_outlined, size: 20, color: OneUITheme.textPrimary),
                              ),
                              title: _isRoutineDemoMode ? 'Color filter' : _sub.paymentMethod,
                              subtitle: _isRoutineDemoMode
                                  ? 'Return to status before routine ran'
                                  : 'Reminder: ${_sub.reminderDays} days before charge',
                              subtitleColor: OneUITheme.textSecondary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // "Looking for something else?" Card matching Screenshot 1
                      OneUIAlternativeOptionsCard(
                        title: 'Looking for something else?',
                        actions: [
                          OneUIAlternativeAction(
                            title: 'Payment history',
                            onTap: () {},
                          ),
                          OneUIAlternativeAction(
                            title: 'Change renewal cycle',
                            onTap: () {},
                          ),
                          OneUIAlternativeAction(
                            title: 'Cancel subscription at provider',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Bar at the Bottom (1:1 with Screenshot 3)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: OneUIFloatingActionBar(
                items: [
                  OneUIFloatingActionBarItem(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Edit ${_sub.name}'),
                          backgroundColor: OneUITheme.surfacePill,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                  OneUIFloatingActionBarItem(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Share details of ${_sub.name}'),
                          backgroundColor: OneUITheme.surfacePill,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    },
                  ),
                  OneUIFloatingActionBarItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: OneUITheme.accentRed,
                    onTap: _deleteSubscription,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
