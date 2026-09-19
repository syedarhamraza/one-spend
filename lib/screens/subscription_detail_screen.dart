import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_hero_card.dart';

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
  bool _isRoutineDemoMode = false; // Toggle to preview Screenshot 3 exact labels

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

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          // Scrollable Content matching Screenshot 3
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Pill & Demo Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: OneUITheme.surfacePill,
                          shape: BoxShape.circle,
                          border: OneUITheme.subtleBorder,
                          boxShadow: OneUITheme.floatingShadow,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: OneUITheme.textPrimary,
                        ),
                      ),
                    ),
                    // Quick One UI Mode switcher pill (shows exact Screenshot 3 labels vs Subscription labels)
                    GestureDetector(
                      onTap: _toggleRoutineDemo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isRoutineDemoMode
                              ? OneUITheme.accentTeal.withValues(alpha: 0.2)
                              : OneUITheme.surfacePill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isRoutineDemoMode
                                ? OneUITheme.accentTeal
                                : OneUITheme.surfacePillBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRoutineDemoMode ? Icons.palette_rounded : Icons.tune_rounded,
                              size: 16,
                              color: _isRoutineDemoMode
                                  ? OneUITheme.accentTeal
                                  : OneUITheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isRoutineDemoMode ? 'Routine Spec Mode' : 'Subscription Mode',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                const SizedBox(height: 20),

                // Hero Card (1:1 with Screenshot 3 Top Card)
                OneUIHeroCard(
                  title: _isRoutineDemoMode ? 'Color filter' : _sub.name,
                  description: _isRoutineDemoMode
                      ? 'Make text easier to read by applying a color filter to the screen while using selected apps.'
                      : _sub.description,
                  icon: _isRoutineDemoMode ? Icons.menu_book_rounded : _sub.iconData,
                  badgeColor: _isRoutineDemoMode ? OneUITheme.accentTeal : _sub.brandColor,
                  bottomContent: _isRoutineDemoMode
                      ? null
                      : Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: OneUITheme.surfacePillActive,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_sub.currency}${_sub.price.toStringAsFixed(2)} / ${_sub.billingCycle.label.toLowerCase()} • Renews in $daysRemaining days',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textPrimary,
                            ),
                          ),
                        ),
                ),

                // Section 1: "If" Header (1:1 with Screenshot 3)
                OneUISection(
                  title: _isRoutineDemoMode ? 'If' : 'Overview',
                  child: OneUICard(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 20,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                    title: _isRoutineDemoMode ? 'App opened' : 'Subscription status',
                    subtitle: _isRoutineDemoMode ? 'Not set' : _sub.status.label,
                    subtitleColor: _isRoutineDemoMode
                        ? OneUITheme.accentRed
                        : _sub.status.color,
                  ),
                ),

                // Section 2: "Then" Header (1:1 with Screenshot 3)
                OneUISection(
                  title: _isRoutineDemoMode ? 'Then' : 'Billing cycle',
                  child: OneUICard(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                    title: _isRoutineDemoMode ? 'Color filter' : '${_sub.billingCycle.label} renewal',
                    subtitle: _isRoutineDemoMode ? 'On' : formattedDate,
                    subtitleColor: _isRoutineDemoMode
                        ? OneUITheme.accentBlue
                        : OneUITheme.accentBlue,
                  ),
                ),

                // Section 3: "When routine ends" Header (1:1 with Screenshot 3)
                OneUISection(
                  title: _isRoutineDemoMode ? 'When routine ends' : 'Payment & reminders',
                  child: OneUICard(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                    title: _isRoutineDemoMode ? 'Color filter' : _sub.paymentMethod,
                    subtitle: _isRoutineDemoMode
                        ? 'Return to status before routine ran'
                        : 'Reminder: ${_sub.reminderDays} days before next charge',
                    subtitleColor: OneUITheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
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
