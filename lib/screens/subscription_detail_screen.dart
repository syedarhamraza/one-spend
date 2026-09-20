import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_icon_picker_modal.dart';
import '../widgets/one_ui_toast.dart';
import 'one_ui_field_editor_screen.dart';

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

  Future<void> _openUrl(String rawUrl) async {
    HapticFeedback.lightImpact();
    try {
      String target = rawUrl.trim();
      if (!target.startsWith('http://') && !target.startsWith('https://')) {
        target = 'https://$target';
      }
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) OneUIToast.show(context, 'Could not open website');
      }
    } catch (_) {
      if (mounted) OneUIToast.show(context, 'Invalid website URL');
    }
  }

  Future<void> _pickBrandIcon() async {
    final result = await OneUIIconPickerModal.show(
      context,
      currentColor: _sub.brandColor,
      currentIcon: _sub.iconData,
      currentLogoUrl: _sub.logoUrl,
      currentPresetId: _sub.brandPresetId,
    );
    if (!mounted || result == null) return;
    setState(() {
      _sub = _sub.copyWith(
        brandColor: result.brandColor,
        iconData: result.iconData,
        logoUrl: result.logoUrl,
        brandPresetId: result.brandPresetId,
      );
    });
    SubscriptionStore.instance.updateSubscription(_sub);
    OneUIToast.show(context, 'Updated brand icon');
  }

  Future<void> _editField<T>({
    required String title,
    String? subtitle,
    required FieldEditorType type,
    required T initialValue,
    required Function(T value) onApply,
    String? prefixText,
    String? hintText,
  }) async {
    final result = await OneUIFieldEditorScreen.open<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      type: type,
      initialValue: initialValue,
      prefixText: prefixText,
      hintText: hintText,
      currency: _sub.currency,
    );

    if (result != null && mounted) {
      onApply(result);
      SubscriptionStore.instance.updateSubscription(_sub);
      _syncFromStore();
      OneUIToast.show(context, '$title updated');
    }
  }

  void _markRenewed() {
    HapticFeedback.mediumImpact();
    SubscriptionStore.instance.renewSubscription(_sub.id);
    _syncFromStore();
    final dateFormat = DateFormat('MMM dd, yyyy');
    OneUIToast.show(context, 'Renewed ${_sub.name}! Next: ${dateFormat.format(_sub.nextBillingDate)}');
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    SubscriptionStore.instance.togglePauseSubscription(_sub.id);
    _syncFromStore();
    final isPaused = _sub.status == SubscriptionStatus.paused;
    OneUIToast.show(context, isPaused ? '${_sub.name} paused' : '${_sub.name} active');
  }

  Future<void> _shareSubscription() async {
    HapticFeedback.lightImpact();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(_sub.nextBillingDate);
    final summaryText = '''
${_sub.name} Subscription Details:
• Price: ${_sub.currency}${_sub.price.toStringAsFixed(2)} / ${_sub.billingCycle.label}
• Category: ${_sub.category.label}
• Next Renewal: $formattedDate (${_sub.daysRemaining} days remaining)
• Status: ${_sub.status.label}
• Payment Method: ${_sub.paymentMethod}
• Monthly Equivalent: ${_sub.currency}${_sub.monthlyCost.toStringAsFixed(2)}/mo
• Annual Equivalent: ${_sub.currency}${_sub.yearlyCost.toStringAsFixed(2)}/yr
${_sub.accountUrl.isNotEmpty ? '• Account URL: ${_sub.accountUrl}\n' : ''}${_sub.notes.isNotEmpty ? '• Notes: ${_sub.notes}\n' : ''}Tracked with OneSpend
'''.trim();

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: summaryText,
          subject: '${_sub.name} Subscription Details',
        ),
      );
    } catch (_) {
      // Fallback for environments where share sheet is unsupported
      await Clipboard.setData(ClipboardData(text: summaryText));
      if (mounted) {
        OneUIToast.show(context, 'Details copied to clipboard');
      }
    }
  }

  void _deleteSubscription() {
    HapticFeedback.mediumImpact();
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete ${_sub.name}?',
      message: 'Are you sure you want to remove ${_sub.name} from your active subscriptions?',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () {
        HapticFeedback.mediumImpact();
        final name = _sub.name;
        SubscriptionStore.instance.removeSubscription(_sub.id);
        Navigator.pop(context);
        OneUIToast.show(context, '$name removed');
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
        final currentSub = SubscriptionStore.instance.subscriptions.cast<Subscription?>().firstWhere(
          (s) => s!.id == _sub.id,
          orElse: () => null,
        );
        if (currentSub != null) {
          _sub = currentSub;
        }
        final dateFormat = DateFormat('MMM dd, yyyy');
        final formattedDate = dateFormat.format(_sub.nextBillingDate);
        final daysRemaining = _sub.daysRemaining;
        final isPaused = _sub.status == SubscriptionStatus.paused;

        String daysText;
        if (isPaused) {
          daysText = 'Subscription Paused';
        } else if (daysRemaining < 0) {
          daysText = 'Overdue by ${-daysRemaining} days';
        } else if (daysRemaining == 0) {
          daysText = 'Due today';
        } else if (daysRemaining == 1) {
          daysText = 'Due tomorrow';
        } else {
          daysText = 'Due in $daysRemaining days';
        }

        final recordedPayments = _sub.paymentHistory.length;
        final totalPaid = recordedPayments * _sub.price;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // One UI Signature Collapsible Header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: _sub.name,
                      hasBigHeader: false,
                      showBackButton: true,
                      onBack: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // Detail Body Content matching One UI Screenshot 3
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
                                    // Interactive Brand badge icon with squircle & icon picker
                                    GestureDetector(
                                      onTap: _pickBrandIcon,
                                      child: Stack(
                                        children: [
                                          OneUIBrandIcon(
                                            subscription: _sub,
                                            size: 58,
                                            borderRadius: 18,
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: OneUITheme.surfaceCardHighlight,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                size: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_sub.name} Plan',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.3,
                                              color: OneUITheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_sub.currency}${_sub.price.toStringAsFixed(2)} • ${_sub.billingCycle.label}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
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

                                // Quick Status Toggle & Countdown Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Subscription Status',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: OneUITheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _sub.status.color,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _sub.status.label,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _sub.status.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Switch.adaptive(
                                      value: !isPaused,
                                      activeTrackColor: OneUITheme.accentBlue,
                                      onChanged: (active) => _togglePause(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Next Renewal Banner
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_repeat_rounded,
                                            size: 16,
                                            color: isPaused
                                                ? OneUITheme.textSecondary
                                                : (daysRemaining <= 3 ? OneUITheme.accentRed : OneUITheme.accentBlue),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Next billing',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: OneUITheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          isPaused ? 'Paused' : '$formattedDate ($daysText)',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isPaused
                                                ? OneUITheme.textSecondary
                                                : (daysRemaining <= 3 ? OneUITheme.accentRed : OneUITheme.accentBlue),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Section 1: Plan & Billing (Matching One UI Screenshot 3 with tap-to-edit subpages)
                          OneUISection(
                            title: 'Plan & Billing',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.badge_outlined, OneUITheme.accentBlue),
                                  title: 'Service name',
                                  subtitle: _sub.name,
                                  subtitleColor: OneUITheme.textPrimary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<String>(
                                    title: 'Edit name',
                                    type: FieldEditorType.text,
                                    initialValue: _sub.name,
                                    onApply: (val) => _sub = _sub.copyWith(name: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.attach_money_rounded, OneUITheme.accentGreen),
                                  title: 'Price / Cost',
                                  subtitle: '${_sub.currency}${_sub.price.toStringAsFixed(2)} / ${_sub.billingCycle.label}',
                                  subtitleColor: OneUITheme.accentGreen,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<double>(
                                    title: 'Edit price',
                                    type: FieldEditorType.number,
                                    initialValue: _sub.price,
                                    onApply: (val) => _sub = _sub.copyWith(price: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.repeat_rounded, OneUITheme.accentPurple),
                                  title: 'Billing cycle',
                                  subtitle: '${_sub.billingCycle.label} (${_sub.billingCycle.occurrencesPerYear}x / year)',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<BillingCycle>(
                                    title: 'Edit billing cycle',
                                    type: FieldEditorType.billingCycle,
                                    initialValue: _sub.billingCycle,
                                    onApply: (val) => _sub = _sub.copyWith(billingCycle: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.calendar_month_rounded, OneUITheme.accentTeal),
                                  title: 'Next renewal date',
                                  subtitle: formattedDate,
                                  subtitleColor: OneUITheme.accentBlue,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<DateTime>(
                                    title: 'Edit renewal date',
                                    type: FieldEditorType.date,
                                    initialValue: _sub.nextBillingDate,
                                    onApply: (val) => _sub = _sub.copyWith(nextBillingDate: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.link_rounded, OneUITheme.accentBlue),
                                  title: 'Account / Website URL',
                                  subtitle: _sub.accountUrl.isNotEmpty
                                      ? _sub.accountUrl
                                      : 'Tap to add website or account login link',
                                  subtitleColor: _sub.accountUrl.isNotEmpty
                                      ? OneUITheme.accentBlue
                                      : OneUITheme.textSecondary.withValues(alpha: 0.6),
                                  trailing: _sub.accountUrl.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.accentBlue),
                                          onPressed: () => _openUrl(_sub.accountUrl),
                                        )
                                      : const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<String>(
                                    title: 'Edit account URL',
                                    type: FieldEditorType.text,
                                    initialValue: _sub.accountUrl,
                                    hintText: 'https://example.com/account',
                                    onApply: (val) => _sub = _sub.copyWith(accountUrl: val),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Section 2: Payment & Reminders (Matching One UI Screenshot 3 with tap-to-edit subpages)
                          OneUISection(
                            title: 'Payment & Reminders',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(_sub.category.icon, OneUITheme.accentPurple),
                                  title: 'Category',
                                  subtitle: _sub.category.label,
                                  subtitleColor: OneUITheme.textPrimary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<SubscriptionCategory>(
                                    title: 'Edit category',
                                    type: FieldEditorType.category,
                                    initialValue: _sub.category,
                                    onApply: (val) => _sub = _sub.copyWith(category: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.payment_rounded, OneUITheme.accentAmber),
                                  title: 'Payment method',
                                  subtitle: _sub.paymentMethod,
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<String>(
                                    title: 'Edit payment method',
                                    type: FieldEditorType.text,
                                    initialValue: _sub.paymentMethod,
                                    onApply: (val) => _sub = _sub.copyWith(paymentMethod: val),
                                  ),
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.notifications_active_rounded, OneUITheme.accentTeal),
                                  title: 'Renewal notification',
                                  subtitle: 'Alert ${_sub.reminderDays} days before renewal',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<int>(
                                    title: 'Edit reminder alert',
                                    type: FieldEditorType.reminder,
                                    initialValue: _sub.reminderDays,
                                    onApply: (val) => _sub = _sub.copyWith(reminderDays: val),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Section 3: Notes
                          OneUISection(
                            title: 'Notes',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.notes_rounded, Colors.white70),
                                  title: 'Plan notes',
                                  subtitle: _sub.notes.isNotEmpty ? _sub.notes : 'Tap to add notes, account details, or terms...',
                                  subtitleColor: _sub.notes.isNotEmpty ? OneUITheme.textSecondary : OneUITheme.textSecondary.withValues(alpha: 0.6),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: () => _editField<String>(
                                    title: 'Edit notes',
                                    type: FieldEditorType.notes,
                                    initialValue: _sub.notes,
                                    onApply: (val) => _sub = _sub.copyWith(notes: val),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Section 4: Renewal History & Stats
                          OneUISection(
                            title: 'Renewal History',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.history_rounded, OneUITheme.accentGreen),
                                  title: _sub.paymentHistory.isNotEmpty
                                      ? 'Last renewed on ${dateFormat.format(_sub.paymentHistory.first)}'
                                      : 'No past renewals logged',
                                  subtitle: _sub.paymentHistory.isNotEmpty
                                      ? '$recordedPayments recorded payments (${_sub.currency}${totalPaid.toStringAsFixed(2)} total)'
                                      : 'Tap button to log renewal',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: TextButton(
                                    onPressed: _markRenewed,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      backgroundColor: OneUITheme.accentGreen.withValues(alpha: 0.15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text(
                                      'Renewed',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: OneUITheme.accentGreen,
                                      ),
                                    ),
                                  ),
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

              // One UI Action Bar at the Bottom (Renew, Pause/Resume, Share, Delete)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: OneUIFloatingActionBar(
                    items: [
                      OneUIFloatingActionBarItem(
                        icon: Icons.refresh_rounded,
                        label: 'Renew',
                        onTap: _markRenewed,
                      ),
                      OneUIFloatingActionBarItem(
                        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        label: isPaused ? 'Resume' : 'Pause',
                        onTap: _togglePause,
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

  Widget _buildCategoryIconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}
