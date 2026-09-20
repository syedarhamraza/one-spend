import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_alternative_options_card.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import 'add_subscription_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _sub = widget.subscription;
  }

  void _syncFromStore() {
    final updated = SubscriptionStore.instance.subscriptions.firstWhere(
      (s) => s.id == _sub.id,
      orElse: () => _sub,
    );
    setState(() {
      _sub = updated;
    });
  }

  Future<void> _editSubscription() async {
    final updated = await Navigator.push<Subscription>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSubscriptionScreen(subscriptionToEdit: _sub),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _sub = updated;
      });
    }
  }

  void _markRenewed() {
    SubscriptionStore.instance.renewSubscription(_sub.id);
    _syncFromStore();
    final dateFormat = DateFormat('MMM dd, yyyy');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Renewed ${_sub.name}! Next renewal: ${dateFormat.format(_sub.nextBillingDate)}'),
        backgroundColor: OneUITheme.surfacePill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _togglePause() {
    SubscriptionStore.instance.togglePauseSubscription(_sub.id);
    _syncFromStore();
    final isPaused = _sub.status == SubscriptionStatus.paused;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPaused ? '${_sub.name} paused' : '${_sub.name} resumed'),
        backgroundColor: OneUITheme.surfacePill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _shareSubscription() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(_sub.nextBillingDate);
    final summaryText = '''
${_sub.name} Subscription Details:
• Price: ${_sub.currency}${_sub.price.toStringAsFixed(2)} / ${_sub.billingCycle.label}
• Category: ${_sub.category.label}
• Next Renewal: $formattedDate (${_sub.daysRemaining} days remaining)
• Status: ${_sub.status.label}
• Payment Method: ${_sub.paymentMethod}
• Monthly Equivalent: \$${_sub.monthlyCost.toStringAsFixed(2)}/mo
• Annual Equivalent: \$${_sub.yearlyCost.toStringAsFixed(2)}/yr
Tracked with OneSpend
'''.trim();

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Share ${_sub.name}',
      message: 'Preview and share subscription details:',
      customContent: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          summaryText,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: OneUITheme.textSecondary,
          ),
        ),
      ),
      cancelLabel: 'Close',
      confirmLabel: 'Copy',
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: summaryText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Details copied to clipboard'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  void _deleteSubscription() {
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete ${_sub.name}?',
      message: 'Are you sure you want to remove ${_sub.name} from your active subscriptions?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () {
        SubscriptionStore.instance.removeSubscription(_sub.id);
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
        final dateFormat = DateFormat('MMM dd, yyyy');
        final formattedDate = dateFormat.format(_sub.nextBillingDate);
        final daysRemaining = _sub.daysRemaining;

        String daysText;
        if (daysRemaining < 0) {
          daysText = 'Overdue by ${-daysRemaining} days';
        } else if (daysRemaining == 0) {
          daysText = 'Due today';
        } else if (daysRemaining == 1) {
          daysText = 'Due tomorrow';
        } else {
          daysText = 'in $daysRemaining days';
        }

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // One UI Signature Collapsible Header with Back Button
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: _sub.name,
                      hasBigHeader: false,
                      showBackButton: true,
                      onBack: () => Navigator.pop(context),
                      actions: [
                        // Edit action in header
                        OneUIHeaderAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit subscription',
                          onTap: _editSubscription,
                        ),
                      ],
                    ),
                  ),

                  // Detail Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Hero Device/Plan Card
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
                                    // Brand badge icon
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: _sub.brandColor,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _sub.iconData,
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
                                                  '${_sub.name} Plan',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: -0.2,
                                                    color: OneUITheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${_sub.currency}${_sub.price.toStringAsFixed(2)} • ${_sub.billingCycle.label}',
                                            style: const TextStyle(
                                              fontSize: 13.5,
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
                                // Quick specs row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Status', style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _sub.status.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _sub.status.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _sub.status.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Next renewal', style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '$formattedDate ($daysText)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: daysRemaining <= 3 ? OneUITheme.accentRed : OneUITheme.accentBlue,
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

                          // Section 1: Plan & Billing Details
                          OneUISection(
                            title: 'Plan & Billing',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.repeat_rounded, size: 20, color: OneUITheme.accentBlue),
                                  ),
                                  title: 'Billing cycle',
                                  subtitle: '${_sub.billingCycle.label} (${_sub.billingCycle.occurrencesPerYear}x / year)',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: Text(
                                    '${_sub.currency}${_sub.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: OneUITheme.textPrimary, fontSize: 15),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.calendar_month_rounded, size: 20, color: OneUITheme.accentGreen),
                                  ),
                                  title: 'Next renewal date',
                                  subtitle: formattedDate,
                                  subtitleColor: OneUITheme.accentBlue,
                                ),
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentPurple.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.calculate_outlined, size: 20, color: OneUITheme.accentPurple),
                                  ),
                                  title: 'Cost breakdown',
                                  subtitle: '\$${_sub.monthlyCost.toStringAsFixed(2)} / month • \$${_sub.yearlyCost.toStringAsFixed(2)} / year',
                                  subtitleColor: OneUITheme.textSecondary,
                                ),
                              ],
                            ),
                          ),

                          // Section 2: Payment & Reminders
                          OneUISection(
                            title: 'Payment & Reminders',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentAmber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.payment_rounded, size: 20, color: OneUITheme.accentAmber),
                                  ),
                                  title: 'Payment method',
                                  subtitle: _sub.paymentMethod,
                                  subtitleColor: OneUITheme.textSecondary,
                                ),
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.notifications_active_rounded, size: 20, color: OneUITheme.accentTeal),
                                  ),
                                  title: 'Renewal notification',
                                  subtitle: 'Alert ${_sub.reminderDays} days before renewal',
                                  subtitleColor: OneUITheme.textSecondary,
                                ),
                              ],
                            ),
                          ),

                          // Section 3: Notes (if present)
                          if (_sub.notes.isNotEmpty) ...[
                            OneUISection(
                              title: 'Notes',
                              child: OneUIGroupCard(
                                items: [
                                  OneUIGroupItem(
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.notes_rounded, size: 20, color: OneUITheme.textPrimary),
                                    ),
                                    title: 'Plan Notes',
                                    subtitle: _sub.notes,
                                    subtitleColor: OneUITheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Section 4: Renewal History
                          OneUISection(
                            title: 'Renewal History',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.history_rounded, size: 20, color: OneUITheme.accentGreen),
                                  ),
                                  title: _sub.paymentHistory.isNotEmpty
                                      ? 'Last renewed on ${dateFormat.format(_sub.paymentHistory.first)}'
                                      : 'No past renewals logged',
                                  subtitle: _sub.paymentHistory.isNotEmpty
                                      ? '${_sub.paymentHistory.length} recorded payments in OneSpend'
                                      : 'Tap "Mark Renewed Today" below when charged',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: const Icon(Icons.check_circle_outline_rounded, color: OneUITheme.accentGreen, size: 20),
                                  onTap: _markRenewed,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // "Looking for something else?" Card
                          OneUIAlternativeOptionsCard(
                            title: 'Looking for something else?',
                            actions: [
                              OneUIAlternativeAction(
                                title: 'Mark as renewed today',
                                onTap: _markRenewed,
                              ),
                              OneUIAlternativeAction(
                                title: _sub.status == SubscriptionStatus.paused
                                    ? 'Resume subscription'
                                    : 'Pause subscription',
                                onTap: _togglePause,
                              ),
                              OneUIAlternativeAction(
                                title: 'Edit plan specifications',
                                onTap: _editSubscription,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Action Bar at the Bottom (Edit, Share, Delete)
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
                        onTap: _editSubscription,
                      ),
                      OneUIFloatingActionBarItem(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: _shareSubscription,
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
      },
    );
  }
}
