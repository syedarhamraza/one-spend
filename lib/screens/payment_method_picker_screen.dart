import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_action_bar.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_toast.dart';
import 'payment_method_editor_screen.dart';

/// Samsung One UI Unified Payment Card Picker & Management Subpage.
/// Combines in-place card management and single-subscription card selection:
/// - In Normal Mode:
///   - Perfectly left-aligned brand badges (no left checkmark circle to prevent weird offsets)
///   - Displays card nickname, masked details, and linked subscriptions
///   - Trailing 1-tap edit pencil icon to update cards immediately
///   - Trailing blue checkmark on the selected card (and top hero banner)
///   - Floating Cancel | Save stadium pill to confirm selection
/// - In Multi-Selection Mode (triggered by hold-pressing/long-pressing any card):
///   - AnimatedSize checkmark circle slides into view on the left, shifting the brand logo gracefully
///   - Header transforms to One UI selection counter pill [(O) N] and [Cancel] pill
///   - Bottom Floating Action Bar appears with Move Subs (Icons.swap_horiz_rounded) and Delete (Icons.delete_outline_rounded)
///   - Safe non-forceful deletion modal when deleting cards tied to active subscriptions
class PaymentMethodPickerScreen extends StatefulWidget {
  final String? initialMethodId;
  final bool isManageOnly;

  const PaymentMethodPickerScreen({
    super.key,
    this.initialMethodId,
    this.isManageOnly = false,
  });

  static Future<PaymentMethod?> open(
    BuildContext context, {
    String? currentMethodId,
    bool isManageOnly = false,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPickerScreen(
          initialMethodId: currentMethodId,
          isManageOnly: isManageOnly,
        ),
      ),
    );
  }

  @override
  State<PaymentMethodPickerScreen> createState() => _PaymentMethodPickerScreenState();
}

class _PaymentMethodPickerScreenState extends State<PaymentMethodPickerScreen> {
  late String? _selectedMethodId;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedMethodId = widget.initialMethodId;
  }

  PaymentMethod? _resolveSelectedMethod(List<PaymentMethod> methods) {
    if (_selectedMethodId == null || _selectedMethodId == '__none__') {
      return null;
    }
    try {
      return methods.firstWhere((m) => m.id == _selectedMethodId);
    } catch (_) {
      return null;
    }
  }

  void _save(List<PaymentMethod> methods) {
    HapticFeedback.mediumImpact();
    if (_selectedMethodId == null || _selectedMethodId == '__none__') {
      Navigator.pop(context, PaymentMethod.none);
    } else {
      final method = _resolveSelectedMethod(methods);
      Navigator.pop(context, method ?? PaymentMethod.none);
    }
  }

  void _openAddCard() async {
    final newCard = await PaymentMethodEditorScreen.open(context);
    if (newCard != null && mounted) {
      OneUIToast.show(context, 'Added ${newCard.nickname}');
      setState(() {
        _selectedMethodId = newCard.id;
      });
    }
  }

  void _openEditCard(PaymentMethod method) async {
    final updated = await PaymentMethodEditorScreen.open(context, method: method);
    if (updated != null && mounted) {
      OneUIToast.show(context, 'Updated ${updated.nickname}');
      setState(() {});
    }
  }

  void _toggleSelectAll(List<PaymentMethod> methods) {
    setState(() {
      if (_selectedIds.length == methods.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(methods.map((m) => m.id));
      }
    });
  }

  void _deleteSelectedCards(List<PaymentMethod> methods) {
    final selected = methods.where((m) => _selectedIds.contains(m.id)).toList();
    if (selected.isEmpty) return;

    final store = SubscriptionStore.instance;
    final hasLinked = selected.any((m) => store.getSubscriptionsForMethod(m.id).isNotEmpty);

    if (selected.length == 1 && hasLinked) {
      final card = selected.first;
      final linkedSubs = store.getSubscriptionsForMethod(card.id);
      final count = linkedSubs.length;
      final otherMethods = store.paymentMethods.where((m) => m.id != card.id).toList();
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
                    const SizedBox(height: 18),
                    Text(
                      'Removing "${card.nickname}" will leave linked subscriptions without a payment card. You can move them to another card or delete anyway.',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: OneUITheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (otherMethods.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedReplacementId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Move subscriptions to',
                          labelStyle: const TextStyle(color: OneUITheme.textSecondary),
                        ),
                        dropdownColor: OneUITheme.cardColor,
                        items: otherMethods.map((m) {
                          return DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              m.displayName,
                              style: const TextStyle(color: OneUITheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedReplacementId = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final replacementId = selectedReplacementId;
                          if (replacementId != null) {
                            store.reassignSubscriptions(fromMethodId: card.id, toMethodId: replacementId);
                          }
                          store.deletePaymentMethod(card.id);
                          Navigator.pop(modalCtx);
                          setState(() {
                            if (_selectedMethodId == card.id) {
                              _selectedMethodId = selectedReplacementId;
                            }
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                          OneUIToast.show(context, 'Subscriptions moved & card removed');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OneUITheme.accentBlue,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Move subscriptions & Delete', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: OneUITheme.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              store.deletePaymentMethod(card.id);
                              Navigator.pop(modalCtx);
                              setState(() {
                                if (_selectedMethodId == card.id) {
                                  _selectedMethodId = null;
                                }
                                _isSelectionMode = false;
                                _selectedIds.clear();
                              });
                              OneUIToast.show(context, 'Removed ${card.nickname}');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: OneUITheme.accentRed,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Delete anyway', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      return;
    }

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: selected.length == 1 ? 'Delete card' : 'Delete payment methods',
      message: hasLinked
          ? 'Some selected methods are linked to active subscriptions. Deleting them will leave those subscriptions unlinked.'
          : (selected.length == 1
              ? 'Are you sure you want to remove "${selected.first.displayName}"?'
              : 'Are you sure you want to remove the ${selected.length} selected payment methods?'),
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmTextColor: OneUITheme.accentRed,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        for (final m in selected) {
          store.deletePaymentMethod(m.id);
          if (_selectedMethodId == m.id) {
            _selectedMethodId = null;
          }
        }
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
        OneUIToast.show(
          context,
          selected.length == 1 ? 'Removed ${selected.first.nickname}' : 'Removed ${selected.length} payment methods',
        );
      }
    });
  }

  void _showBatchReassignModal(List<PaymentMethod> selected) {
    if (selected.isEmpty) return;
    final store = SubscriptionStore.instance;
    final selectedIdsSet = selected.map((m) => m.id).toSet();
    final otherMethods = store.paymentMethods.where((m) => !selectedIdsSet.contains(m.id)).toList();

    if (otherMethods.isEmpty) {
      OneUIToast.show(context, 'No alternative payment method available');
      return;
    }

    String selectedReplacementId = otherMethods.first.id;

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
                  const Text(
                    'Move Subscriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Transfer subscriptions linked to selected cards to another payment card.',
                    style: TextStyle(
                      fontSize: 13,
                      color: OneUITheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReplacementId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      labelText: 'Select destination card',
                      labelStyle: const TextStyle(color: OneUITheme.textSecondary),
                    ),
                    dropdownColor: OneUITheme.cardColor,
                    items: otherMethods.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          m.displayName,
                          style: const TextStyle(color: OneUITheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedReplacementId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: OneUITheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            for (final m in selected) {
                              store.reassignSubscriptions(fromMethodId: m.id, toMethodId: selectedReplacementId);
                            }
                            Navigator.pop(modalCtx);
                            setState(() {
                              _isSelectionMode = false;
                              _selectedIds.clear();
                            });
                            OneUIToast.show(context, 'Moved subscriptions successfully');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OneUITheme.accentBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Move subscriptions', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
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

  Widget _buildSelectionCountPill({
    required int selectedCount,
    required int totalCount,
    required VoidCallback onToggleSelectAll,
  }) {
    final allSelected = selectedCount > 0 && selectedCount == totalCount;
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onToggleSelectAll();
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: OneUITheme.blurSigma,
            sigmaY: OneUITheme.blurSigma,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(24),
              border: OneUITheme.floatingBorder,
              boxShadow: is3d
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: allSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                    border: Border.all(
                      color: allSelected ? const Color(0xFF2C69FF) : Colors.white.withValues(alpha: 0.55),
                      width: 2.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: allSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '$selectedCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Offstage(
                  offstage: true,
                  child: Text('$selectedCount selected'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCancelPill({required VoidCallback onCancel}) {
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onCancel();
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: OneUITheme.blurSigma,
            sigmaY: OneUITheme.blurSigma,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(24),
              border: OneUITheme.floatingBorder,
              boxShadow: is3d
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: OneUITheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final methods = store.paymentMethods;
        final selectedMethod = _resolveSelectedMethod(methods);
        final isNone = _selectedMethodId == null || _selectedMethodId == '__none__';

        final headerTitle = _isSelectionMode
            ? ''
            : (widget.isManageOnly ? 'Payment methods' : 'Payment method');

        final linkedSubsByMethod = <String, List<Subscription>>{};
        for (final s in store.subscriptions) {
          if (s.paymentMethodId != null) {
            linkedSubsByMethod.putIfAbsent(s.paymentMethodId!, () => []).add(s);
          }
        }

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: headerTitle,
                      hasBigHeader: false,
                      showBackButton: !_isSelectionMode,
                      onBack: () => Navigator.pop(context),
                      isSelectionMode: _isSelectionMode,
                      selectionLeading: _buildSelectionCountPill(
                        selectedCount: _selectedIds.length,
                        totalCount: methods.length,
                        onToggleSelectAll: () => _toggleSelectAll(methods),
                      ),
                      selectionTrailing: _buildSelectionCancelPill(
                        onCancel: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                      ),
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
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Hero Status Banner
                          if (!widget.isManageOnly) ...[
                            AnimatedBuilder(
                              animation: OneUIEffectsController.instance,
                              builder: (context, child) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: OneUITheme.cardColor,
                                    borderRadius: OneUITheme.cardBorderRadius,
                                    border: OneUITheme.cardBorder,
                                    boxShadow: OneUITheme.cardShadow,
                                  ),
                                  child: child,
                                );
                              },
                              child: Row(
                                children: [
                                  if (selectedMethod != null) ...[
                                    OneUIPaymentBrandIcon(
                                      brand: selectedMethod.brand,
                                      width: 48,
                                      height: 32,
                                      showShadow: true,
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
                                                  selectedMethod.nickname,
                                                  style: const TextStyle(
                                                    fontSize: 16.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: OneUITheme.textPrimary,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (selectedMethod.isDefault) ...[
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
                                            selectedMethod.subtitleDisplay,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: OneUITheme.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: OneUITheme.accentRed.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.credit_card_off_rounded,
                                        color: OneUITheme.accentRed,
                                        size: 22,
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
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w700,
                                              color: OneUITheme.textPrimary,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'This subscription has no card linked',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: OneUITheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section Label 1: Saved cards
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'SAVED PAYMENT CARDS',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.textSecondary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (methods.isNotEmpty)
                            OneUIGroupCard(
                              margin: EdgeInsets.zero,
                              items: [
                                for (final m in methods)
                                  _buildMethodItem(
                                    m,
                                    isPicked: _selectedMethodId == m.id,
                                    isSelectedInSelection: _selectedIds.contains(m.id),
                                    linkedSubs: linkedSubsByMethod[m.id] ?? const [],
                                  ),
                              ],
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              decoration: BoxDecoration(
                                color: OneUITheme.cardColor,
                                borderRadius: OneUITheme.cardBorderRadius,
                                border: OneUITheme.cardBorder,
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.credit_card_outlined, size: 40, color: OneUITheme.textTertiary.withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No cards saved yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: OneUITheme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Add your payment card to link it to subscriptions.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _openAddCard,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add payment card'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: OneUITheme.accentBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Other options (Only shown when not in selection mode and not manage-only)
                          if (!_isSelectionMode && !widget.isManageOnly) ...[
                            const SizedBox(height: 24),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'OTHER OPTIONS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.textSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OneUIGroupCard(
                              margin: EdgeInsets.zero,
                              items: [
                                OneUIGroupItem(
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentRed.withValues(alpha: isNone ? 0.20 : 0.10),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.credit_card_off_rounded,
                                      color: OneUITheme.accentRed,
                                      size: 19,
                                    ),
                                  ),
                                  title: 'No payment method',
                                  subtitle: 'Remove payment method from this subscription',
                                  trailing: isNone
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: OneUITheme.accentBlue,
                                          size: 20,
                                        )
                                      : const SizedBox.shrink(),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedMethodId = '__none__';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Education Tip
                          if (!_isSelectionMode)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Tip: Tap the edit icon to edit card details.\nHold press any card to enter selection mode to move subs or delete cards.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: OneUITheme.textTertiary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Floating Controls: Seamless transition between Normal Mode (Save Pill) and Selection Mode (Action Bar)
              if (!widget.isManageOnly)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  left: 0,
                  right: 0,
                  bottom: _isSelectionMode ? -120 : 0,
                  child: IgnorePointer(
                    ignoring: _isSelectionMode,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      opacity: _isSelectionMode ? 0.0 : 1.0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: OneUIFloatingCancelSavePill(
                              cancelLabel: 'Cancel',
                              saveLabel: 'Save',
                              onCancel: () => Navigator.pop(context),
                              onSave: () => _save(methods),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: _isSelectionMode ? 0 : -120,
                child: IgnorePointer(
                  ignoring: !_isSelectionMode,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    opacity: _isSelectionMode ? 1.0 : 0.0,
                    child: Center(
                      child: OneUIFloatingActionBar(
                        items: [
                          if (_selectedIds.length == 1)
                            OneUIFloatingActionBarItem(
                              label: 'Edit',
                              icon: Icons.edit_rounded,
                              onTap: () {
                                final m = methods.firstWhere((item) => item.id == _selectedIds.first);
                                _openEditCard(m);
                              },
                            ),
                          OneUIFloatingActionBarItem(
                            label: 'Move subs',
                            icon: Icons.swap_horiz_rounded,
                            onTap: () => _showBatchReassignModal(
                              methods.where((m) => _selectedIds.contains(m.id)).toList(),
                            ),
                          ),
                          OneUIFloatingActionBarItem(
                            label: 'Delete',
                            icon: Icons.delete_outline_rounded,
                            color: OneUITheme.accentRed,
                            onTap: () => _deleteSelectedCards(methods),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  OneUIGroupItem _buildMethodItem(
    PaymentMethod m, {
    required bool isPicked,
    required bool isSelectedInSelection,
    required List<Subscription> linkedSubs,
  }) {
    return OneUIGroupItem(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _isSelectionMode
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelectedInSelection ? const Color(0xFF2C69FF) : Colors.transparent,
                        border: Border.all(
                          color: isSelectedInSelection
                              ? const Color(0xFF2C69FF)
                              : Colors.white.withValues(alpha: 0.55),
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isSelectedInSelection
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: (isPicked && !widget.isManageOnly && !_isSelectionMode)
                  ? OneUITheme.accentBlue.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border.all(
                color: (isPicked && !widget.isManageOnly && !_isSelectionMode)
                    ? OneUITheme.accentBlue
                    : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: (isPicked && !widget.isManageOnly && !_isSelectionMode)
                  ? [
                      BoxShadow(
                        color: OneUITheme.accentBlue.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 1.5,
                      ),
                    ]
                  : null,
            ),
            child: OneUIPaymentBrandIcon(
              brand: m.brand,
              width: 44,
              height: 29,
              showShadow: true,
            ),
          ),
        ],
      ),
      title: m.nickname,
      customSubtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  m.subtitleDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: OneUITheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (m.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: OneUITheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            linkedSubs.isNotEmpty
                ? '${linkedSubs.length} linked subscription${linkedSubs.length > 1 ? "s" : ""}: ${linkedSubs.map((s) => s.name).join(", ")}'
                : 'No subscriptions linked',
            style: TextStyle(
              fontSize: 12,
              color: linkedSubs.isNotEmpty ? OneUITheme.accentGreen : OneUITheme.textTertiary,
              fontWeight: linkedSubs.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: _isSelectionMode
          ? const SizedBox.shrink()
          : IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                size: 19,
                color: OneUITheme.textTertiary,
              ),
              tooltip: 'Edit card details',
              onPressed: () => _openEditCard(m),
            ),
      onTap: () {
        if (_isSelectionMode) {
          HapticFeedback.selectionClick();
          setState(() {
            if (isSelectedInSelection) {
              _selectedIds.remove(m.id);
            } else {
              _selectedIds.add(m.id);
            }
          });
        } else {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedMethodId = m.id;
          });
        }
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        setState(() {
          if (!_isSelectionMode) {
            _isSelectionMode = true;
            _selectedIds.add(m.id);
          } else {
            if (isSelectedInSelection) {
              _selectedIds.remove(m.id);
            } else {
              _selectedIds.add(m.id);
            }
          }
        });
      },
    );
  }
}
