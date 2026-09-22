import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_toast.dart';
import 'payment_method_editor_screen.dart';

/// Samsung One UI Payment Methods Management & Selection Screen.
/// Displays saved credit cards, debit cards, and digital wallets,
/// with expiry warnings, linked subscription counters, smart deletion & reassignment.
class PaymentMethodsScreen extends StatefulWidget {
  final bool isSelectMode;
  final String? currentMethodId;

  const PaymentMethodsScreen({
    super.key,
    this.isSelectMode = false,
    this.currentMethodId,
  });

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
    );
  }

  static Future<PaymentMethod?> select(BuildContext context, {String? currentMethodId}) {
    HapticFeedback.lightImpact();
    return Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodsScreen(
          isSelectMode: true,
          currentMethodId: currentMethodId,
        ),
      ),
    );
  }

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  void _openAddCard() async {
    final newCard = await PaymentMethodEditorScreen.open(context);
    if (newCard != null && mounted) {
      OneUIToast.show(context, 'Added ${newCard.nickname}');
      if (widget.isSelectMode) {
        Navigator.pop(context, newCard);
      }
    }
  }

  void _openEditCard(PaymentMethod method) async {
    final updated = await PaymentMethodEditorScreen.open(context, method: method);
    if (updated != null && mounted) {
      OneUIToast.show(context, 'Updated ${updated.nickname}');
    }
  }

  void _confirmDeleteCard(PaymentMethod method) {
    final store = SubscriptionStore.instance;
    final linkedSubs = store.getSubscriptionsForMethod(method.id);
    final count = linkedSubs.length;

    if (count == 0) {
      OneUIFloatingModal.showConfirmationDialog(
        context: context,
        title: 'Delete card',
        message: 'Are you sure you want to remove "${method.displayName}"?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        confirmTextColor: OneUITheme.accentRed,
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          store.deletePaymentMethod(method.id);
          OneUIToast.show(context, 'Removed ${method.nickname}');
        }
      });
      return;
    }

    // Smart Deletion Modal (Reassign OR Delete Anyway)
    final otherMethods = store.paymentMethods.where((m) => m.id != method.id).toList();
    String? selectedReplacementId = otherMethods.isNotEmpty ? otherMethods.first.id : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              decoration: BoxDecoration(
                color: OneUITheme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: OneUITheme.accentAmber.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: OneUITheme.accentAmber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Card In Use',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Linked to $count subscription${count > 1 ? "s" : ""}',
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
                  Text(
                    '${method.nickname} is currently used for ${linkedSubs.map((s) => s.name).take(3).join(", ")}${count > 3 ? " and more" : ""}. You can reassign these bills to another card or delete anyway.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: OneUITheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (otherMethods.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Select replacement card:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: OneUITheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: OneUITheme.surfacePill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedReplacementId,
                          isExpanded: true,
                          dropdownColor: OneUITheme.cardColor,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: OneUITheme.textPrimary,
                          ),
                          items: otherMethods.map((m) {
                            return DropdownMenuItem(
                              value: m.id,
                              child: Text('${m.displayName} (${m.brand.label})'),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              setModalState(() => selectedReplacementId = newId);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      // Delete Anyway Button (Non-forceful)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            store.deletePaymentMethod(method.id);
                            OneUIToast.show(context, 'Deleted card. Linked subs show "No card".');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: OneUITheme.accentRed.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Delete anyway',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: OneUITheme.accentRed,
                            ),
                          ),
                        ),
                      ),
                      if (otherMethods.isNotEmpty && selectedReplacementId != null) ...[
                        const SizedBox(width: 10),
                        // Reassign & Delete Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(modalCtx);
                              store.deletePaymentMethod(
                                method.id,
                                replacementMethodId: selectedReplacementId,
                              );
                              OneUIToast.show(context, 'Reassigned subscriptions & removed card');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OneUITheme.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Reassign & Delete',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionStore.instance,
      builder: (context, _) {
        final store = SubscriptionStore.instance;
        final methods = store.paymentMethods;
        final expiringCards = store.expiringPaymentMethods;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: widget.isSelectMode ? 'Select payment card' : 'Payment methods',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                  actions: [
                    OneUIHeaderAction(
                      icon: Icons.add,
                      size: 26,
                      tooltip: 'Add card',
                      onTap: _openAddCard,
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Expiry Warning Banner if any card is expiring
                      if (expiringCards.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OneUITheme.accentAmber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: OneUITheme.accentAmber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: OneUITheme.accentAmber,
                                size: 26,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${expiringCards.length} Card${expiringCards.length > 1 ? "s" : ""} Expiring Soon',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: OneUITheme.accentAmber,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Update linked subscriptions to avoid billing interruptions.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Unassigned / Missing Card Warning Option (in Select Mode)
                      if (widget.isSelectMode) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context, PaymentMethod.none);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: OneUITheme.cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentRed.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.credit_card_off_rounded,
                                      color: OneUITheme.accentRed,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'No payment method',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: OneUITheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Remove payment method from this bill',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: OneUITheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.currentMethodId == null)
                                    const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Saved Cards List
                      if (methods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.credit_card_off_rounded, size: 48, color: OneUITheme.textSecondary),
                                const SizedBox(height: 12),
                                const Text(
                                  'No saved payment methods',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _openAddCard,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Card'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: OneUITheme.accentBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: methods.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final m = methods[index];
                            final linkedCount = store.getLinkedSubscriptionCount(m.id);
                            final isSelectedInMode = widget.isSelectMode && widget.currentMethodId == m.id;
                            final expiryStatus = m.expiryStatus;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                if (widget.isSelectMode) {
                                  Navigator.pop(context, m);
                                } else {
                                  _openEditCard(m);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: OneUITheme.cardColor,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isSelectedInMode
                                        ? OneUITheme.accentBlue
                                        : Colors.white.withValues(alpha: 0.08),
                                    width: isSelectedInMode ? 1.8 : 0.8,
                                  ),
                                  boxShadow: OneUITheme.cardShadow,
                                ),
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Brand badge, Nickname & Actions
                                    Row(
                                      children: [
                                        // Card Color Squircle Icon
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: m.cardColor,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.15),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Icon(m.brand.icon, color: Colors.white, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      m.nickname,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: OneUITheme.textPrimary,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ),
                                                  if (m.isDefault) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: OneUITheme.accentBlue.withValues(alpha: 0.16),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'Default',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: OneUITheme.accentBlue,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${m.brand.label} ${m.maskedDisplay}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: OneUITheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.isSelectMode)
                                          Icon(
                                            isSelectedInMode
                                                ? Icons.check_circle_rounded
                                                : Icons.radio_button_unchecked_rounded,
                                            color: isSelectedInMode
                                                ? OneUITheme.accentBlue
                                                : OneUITheme.textSecondary.withValues(alpha: 0.5),
                                            size: 22,
                                          )
                                        else
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 20, color: OneUITheme.textSecondary),
                                            color: OneUITheme.cardColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                _openEditCard(m);
                                              } else if (val == 'delete') {
                                                _confirmDeleteCard(m);
                                              }
                                            },
                                            itemBuilder: (_) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit card', style: TextStyle(color: OneUITheme.textPrimary)),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete card', style: TextStyle(color: OneUITheme.accentRed)),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(height: 1),
                                    const SizedBox(height: 12),

                                    // Row 2: Linked Subscriptions Count & Expiry Badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.link_rounded,
                                                size: 15,
                                                color: linkedCount > 0 ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  linkedCount > 0
                                                      ? '$linkedCount linked subscription${linkedCount == 1 ? "" : "s"}'
                                                      : 'Not linked to any bill',
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: linkedCount > 0 ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (m.expiryDate.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: expiryStatus == CardExpiryStatus.valid
                                                  ? Colors.white.withValues(alpha: 0.05)
                                                  : (expiryStatus == CardExpiryStatus.expired
                                                      ? OneUITheme.accentRed.withValues(alpha: 0.15)
                                                      : OneUITheme.accentAmber.withValues(alpha: 0.15)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              m.expiryStatusText ?? 'Exp ${m.expiryDate}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: expiryStatus == CardExpiryStatus.valid
                                                    ? OneUITheme.textSecondary
                                                    : (expiryStatus == CardExpiryStatus.expired
                                                        ? OneUITheme.accentRed
                                                        : OneUITheme.accentAmber),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
