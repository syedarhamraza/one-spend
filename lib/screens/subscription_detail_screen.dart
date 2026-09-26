import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_switch.dart';
import 'category_picker_screen.dart';
import 'icon_picker_screen.dart';
import 'one_ui_field_editor_screen.dart';
import 'payment_history_screen.dart';
import 'payment_methods_screen.dart';
import 'reminder_picker_screen.dart';
import 'upcoming_schedule_screen.dart';

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
    final result = await IconPickerScreen.open(
      context,
      currentColor: _sub.brandColor,
      currentIcon: _sub.iconData,
      currentLogoUrl: _sub.logoUrl,
      currentPresetId: _sub.brandPresetId,
      subscriptionName: _sub.name,
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

  Future<void> _pickPaymentMethod() async {
    final result = await PaymentMethodsScreen.select(
      context,
      currentMethodId: _sub.paymentMethodId,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.id == '__none__') {
        _sub = _sub.copyWith(paymentMethodId: null, paymentMethod: '');
      } else {
        _sub = _sub.copyWith(paymentMethodId: result.id, paymentMethod: result.displayName);
      }
    });
    SubscriptionStore.instance.updateSubscription(_sub);
    OneUIToast.show(context, 'Payment method updated');
  }

  Future<void> _pickReminderDays() async {
    final result = await ReminderPickerScreen.open(
      context,
      initialDays: _sub.reminderDays,
    );
    if (result != null && mounted) {
      setState(() {
        _sub = _sub.copyWith(reminderDays: result);
      });
      SubscriptionStore.instance.updateSubscription(_sub);
      OneUIToast.show(context, 'Reminder alert updated');
    }
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
    OneUIToast.show(context, 'Renewed ${_sub.name}! Next: ${OneUIDateFormats.monthDayYear.format(_sub.nextBillingDate)}');
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
    final formattedDate = OneUIDateFormats.monthDayYear.format(_sub.nextBillingDate);
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
        final dateFormat = OneUIDateFormats.monthDayYear;
        final formattedDate = dateFormat.format(_sub.nextBillingDate);
        final daysRemaining = _sub.daysRemaining;
        final isPaused = _sub.status == SubscriptionStatus.paused;

        Color badgeColor;
        String badgeText;
        if (isPaused) {
          badgeColor = OneUITheme.textSecondary;
          badgeText = 'Paused';
        } else if (daysRemaining < 0) {
          badgeColor = OneUITheme.accentRed;
          badgeText = 'Overdue ${-daysRemaining}d';
        } else if (daysRemaining == 0) {
          badgeColor = OneUITheme.accentRed;
          badgeText = 'Due today';
        } else if (daysRemaining == 1) {
          badgeColor = OneUITheme.accentRed;
          badgeText = 'Tomorrow';
        } else if (daysRemaining <= 3) {
          badgeColor = OneUITheme.accentRed;
          badgeText = 'In $daysRemaining days';
        } else if (daysRemaining <= 7) {
          badgeColor = OneUITheme.accentAmber;
          badgeText = 'In $daysRemaining days';
        } else {
          badgeColor = OneUITheme.accentBlue;
          badgeText = 'In $daysRemaining days';
        }

        final recordedPayments = _sub.paymentHistory.length;
        final totalPaid = recordedPayments * _sub.price;
        final linkedCard = SubscriptionStore.instance.getPaymentMethod(_sub.paymentMethodId);
        final hasNoCard = _sub.paymentMethodId == null || linkedCard == null;
        final isCardExpiring = linkedCard != null && (linkedCard.isExpiringSoon || linkedCard.isExpired);

        final upcomingDates = _sub.getUpcomingBillingDates(6);
        final shortFormat = OneUIDateFormats.monthDay;
        final upcomingSubtitle = upcomingDates.length >= 2
            ? '${shortFormat.format(upcomingDates[0])} (${_sub.currency}${_sub.price.toStringAsFixed(2)}) • ${shortFormat.format(upcomingDates[1])} (${_sub.currency}${_sub.price.toStringAsFixed(2)})'
            : (upcomingDates.isNotEmpty ? shortFormat.format(upcomingDates[0]) : formattedDate);

        final heroGlowColor = (_sub.brandColor.computeLuminance() < 0.05)
            ? const Color(0xFF0381FE)
            : _sub.brandColor;

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
                          // Top Hero Device/Plan Card (Frosted Glass & Ambient Under-Card Glow)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            child: ClipRRect(
                              borderRadius: OneUITheme.cardBorderRadius,
                              child: Stack(
                                children: [
                                  // 1. Soft, understated ambient glow positioned BENEATH the card
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: const Alignment(0.0, -0.2),
                                          radius: 1.05,
                                          colors: [
                                            heroGlowColor.withValues(alpha: 0.26),
                                            heroGlowColor.withValues(alpha: 0.11),
                                            heroGlowColor.withValues(alpha: 0.02),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.50, 0.85, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 2. Frosted glass blur & translucent card body (completely flat, no 3D borders or shadows)
                                  BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                    child: Material(
                                      color: const Color(0xFF1B1C20).withValues(alpha: 0.68),
                                      child: Container(
                                        width: double.infinity,
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
                                                const SizedBox(width: 8),
                                                // Status Badge Capsule (Active / Paused) matching Monthly Budget Card
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isPaused
                                                        ? Colors.white.withValues(alpha: 0.08)
                                                        : const Color(0xFF00C05A).withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    isPaused ? 'Paused' : 'Active',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: isPaused
                                                          ? OneUITheme.textSecondary
                                                          : const Color(0xFF00C05A),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              height: 0.8,
                                              color: Colors.white.withValues(alpha: 0.06),
                                            ),
                                            const SizedBox(height: 14),

                                            // Unified Device Care Container (Auto-renew + Next billing)
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.04),
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Row 1: Auto-renew toggle with authentic OneUISwitch
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Text(
                                                            'Auto-renew',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                              color: OneUITheme.textSecondary,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 1),
                                                          Text(
                                                            isPaused ? 'Billing on hold' : 'Renews automatically',
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w400,
                                                              color: isPaused ? OneUITheme.textTertiary : Colors.white54,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Transform.scale(
                                                        scale: 0.88,
                                                        alignment: Alignment.centerRight,
                                                        child: OneUISwitch(
                                                          value: !isPaused,
                                                          activeTrackColor: OneUITheme.accentBlue,
                                                          onChanged: (_) => _togglePause(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Divider(
                                                    height: 14,
                                                    thickness: 0.6,
                                                    color: Colors.white.withValues(alpha: 0.06),
                                                  ),
                                                  // Row 2: Next billing
                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Padding(
                                                        padding: EdgeInsets.only(top: 1),
                                                        child: Text(
                                                          'Next billing',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w500,
                                                            color: OneUITheme.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              isPaused ? 'Billing on hold' : formattedDate,
                                                              textAlign: TextAlign.right,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w700,
                                                                color: isPaused
                                                                    ? OneUITheme.textSecondary
                                                                    : OneUITheme.textPrimary,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              badgeText,
                                                              textAlign: TextAlign.right,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w400,
                                                                color: badgeColor,
                                                              ),
                                                            ),
                                                          ],
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
                                ],
                              ),
                            ),
                          ),

                          // Context-Aware Due Date Action Banner (Concept 2)
                          if (!isPaused && daysRemaining <= 0) ...[
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (daysRemaining < 0
                                        ? OneUITheme.accentRed
                                        : OneUITheme.accentBlue)
                                    .withValues(alpha: 0.08),
                                borderRadius: OneUITheme.cardBorderRadius,
                                border: Border.all(
                                  color: (daysRemaining < 0
                                          ? OneUITheme.accentRed
                                          : OneUITheme.accentBlue)
                                      .withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: (daysRemaining < 0
                                                  ? OneUITheme.accentRed
                                                  : OneUITheme.accentBlue)
                                              .withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          daysRemaining < 0
                                              ? Icons.warning_amber_rounded
                                              : Icons.notifications_active_rounded,
                                          size: 20,
                                          color: daysRemaining < 0
                                              ? OneUITheme.accentRed
                                              : OneUITheme.accentBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              daysRemaining < 0
                                                  ? 'Payment overdue (${-daysRemaining}d)'
                                                  : 'Payment due today',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.2,
                                                color: daysRemaining < 0
                                                    ? OneUITheme.accentRed
                                                    : OneUITheme.accentBlue,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_sub.currency}${_sub.price.toStringAsFixed(2)} • ${linkedCard?.nickname ?? 'Linked payment method'}',
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: OneUITheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            SubscriptionStore.instance.skipSubscriptionCycle(_sub.id);
                                            _syncFromStore();
                                            OneUIToast.show(context, 'Cycle skipped');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              width: 0.8,
                                            ),
                                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                          ),
                                          child: const Text(
                                            'Skip cycle',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: OneUITheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            HapticFeedback.mediumImpact();
                                            SubscriptionStore.instance.markSubscriptionPaid(_sub.id);
                                            _syncFromStore();
                                            OneUIToast.show(context, 'Payment recorded & cycle advanced');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: OneUITheme.accentBlue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 11),
                                          ),
                                          child: const Text(
                                            'Mark as Paid',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

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
                                  onTap: () async {
                                    final newCat = await CategoryPickerScreen.open(
                                      context,
                                      initialCategory: _sub.category,
                                    );
                                    if (newCat == null || newCat == _sub.category) return;
                                    if (!mounted) return;
                                    setState(() {
                                      _sub = _sub.copyWith(category: newCat);
                                    });
                                    SubscriptionStore.instance.updateSubscription(_sub);
                                    if (context.mounted) {
                                      OneUIToast.show(context, 'Category updated to ${newCat.label}');
                                    }
                                  },
                                ),
                                OneUIGroupItem(
                                  leading: linkedCard != null
                                      ? OneUIPaymentBrandIcon(brand: linkedCard.brand, width: 36, height: 26)
                                      : _buildCategoryIconBadge(Icons.payment_rounded, OneUITheme.accentAmber),
                                  title: 'Payment method',
                                  subtitle: linkedCard != null
                                      ? linkedCard.displayName
                                      : (_sub.paymentMethod.isNotEmpty ? _sub.paymentMethod : 'No payment method linked'),
                                  customSubtitle: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          linkedCard != null
                                              ? linkedCard.displayName
                                              : (_sub.paymentMethod.isNotEmpty ? _sub.paymentMethod : 'No payment method linked'),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.normal,
                                            color: linkedCard != null ? OneUITheme.textPrimary : OneUITheme.accentRed,
                                          ),
                                        ),
                                      ),
                                      if (hasNoCard) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: OneUITheme.accentRed.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            'No card',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: OneUITheme.accentRed,
                                            ),
                                          ),
                                        ),
                                      ] else if (isCardExpiring) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: OneUITheme.accentAmber.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Text(
                                            linkedCard.isExpired ? 'Card expired' : 'Card expiring soon',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: OneUITheme.accentAmber,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: _pickPaymentMethod,
                                ),
                                OneUIGroupItem(
                                  leading: _buildCategoryIconBadge(Icons.notifications_active_rounded, OneUITheme.accentTeal),
                                  title: 'Renewal notification',
                                  subtitle: _sub.reminderDays == 0
                                      ? 'On renewal day (9:00 AM)'
                                      : 'Alert ${_sub.reminderDays} days before renewal',
                                  subtitleColor: OneUITheme.textSecondary,
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                  onTap: _pickReminderDays,
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

                          // Section 4: Spend & Billing Hub (Concepts 1, 2, 3)
                          OneUISection(
                            title: 'Spend & Billing',
                            child: Column(
                              children: [
                                // Lifetime Spend Overview Tile
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: OneUITheme.cardColor,
                                    borderRadius: OneUITheme.cardBorderRadius,
                                    border: OneUITheme.cardBorder,
                                    boxShadow: OneUITheme.cardShadow,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Lifetime spend',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: OneUITheme.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${_sub.currency}${totalPaid.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.4,
                                                  color: OneUITheme.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                            decoration: BoxDecoration(
                                              color: OneUITheme.accentBlue.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '$recordedPayments ${recordedPayments == 1 ? 'payment' : 'payments'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: OneUITheme.accentBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Estimated annual: ${_sub.currency}${_sub.yearlyCost.toStringAsFixed(2)}/yr',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Schedule & History Group Card
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      leading: _buildCategoryIconBadge(Icons.calendar_month_rounded, OneUITheme.accentBlue),
                                      title: 'Upcoming schedule',
                                      subtitle: upcomingSubtitle,
                                      subtitleColor: OneUITheme.textSecondary,
                                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => UpcomingScheduleScreen(subscription: _sub),
                                          ),
                                        );
                                      },
                                    ),
                                    OneUIGroupItem(
                                      leading: _buildCategoryIconBadge(Icons.receipt_long_rounded, OneUITheme.accentGreen),
                                      title: 'Payment history',
                                      subtitle: _sub.paymentHistory.isNotEmpty
                                          ? 'Last paid on ${dateFormat.format(_sub.paymentHistory.first)} • ${_sub.paymentHistory.length} records'
                                          : 'No recorded payments yet',
                                      subtitleColor: OneUITheme.textSecondary,
                                      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
                                      onTap: () => PaymentHistoryScreen.open(context, _sub.id),
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
                ],
              ),

              // Progressive OLED Bottom Vignette Scrim
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: OneUIBottomVignette(),
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
