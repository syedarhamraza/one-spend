import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_filter_bottom_sheet.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_scroll_to_top_button.dart';
import '../widgets/one_ui_selection_action_bar.dart';
import '../widgets/one_ui_sort_bottom_sheet.dart';
import '../widgets/one_ui_subscription_card.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_upcoming_carousel.dart';
import 'add_subscription_screen.dart';
import 'subscription_detail_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  final ValueChanged<bool>? onSelectionModeChanged;
  final ValueChanged<bool>? onSearchModeChanged;

  const SubscriptionsScreen({
    super.key,
    this.onSelectionModeChanged,
    this.onSearchModeChanged,
  });

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  SubscriptionCategory? _filterCategory;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  final GlobalKey _actionPillKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey _selectionMoreButtonKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _showSearch = true;
    });
    widget.onSearchModeChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showSearch) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    HapticFeedback.lightImpact();
    _searchFocusNode.unfocus();
    setState(() {
      _showSearch = false;
      _searchQuery = '';
      _searchController.clear();
    });
    widget.onSearchModeChanged?.call(false);
  }

  void _showExpandedMenu(BuildContext context) {
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _actionPillKey,
      fallbackTop: MediaQuery.of(context).padding.top + 6.0,
      fallbackRight: 16.0,
      items: [
        OneUIFloatingMenuItem(
          label: 'Select',
          onTap: () => _enterSelectionMode(),
        ),
        OneUIFloatingMenuItem(
          label: 'Sort',
          onTap: () => OneUISortBottomSheet.show(context),
        ),
        OneUIFloatingMenuItem(
          label: 'Filter',
          onTap: () {
            OneUIFilterBottomSheet.show(
              context: context,
              currentCategory: _filterCategory,
              onCategorySelected: (cat) {
                setState(() {
                  _filterCategory = cat;
                });
              },
            );
          },
        ),
        OneUIFloatingMenuItem(
          label: 'Edit monthly budget',
          onTap: () => _showEditBudgetDialog(context),
        ),
        OneUIFloatingMenuItem(
          label: 'Export list (CSV)',
          onTap: () => _showExportDialog(context),
        ),
      ],
    );
  }

  void _enterSelectionMode([String? initialSelectedId]) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
      if (initialSelectedId != null) {
        _selectedIds.add(initialSelectedId);
      }
    });
    widget.onSelectionModeChanged?.call(true);
  }

  void _exitSelectionMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged?.call(false);
  }

  void _toggleSelectAll(List<Subscription> currentList) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.length == currentList.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(currentList.map((s) => s.id));
      }
    });
  }

  void _toggleSelectItem(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _handleMoveSelected() {
    if (_selectedIds.isEmpty) return;
    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Move to category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OneUITheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.40,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...SubscriptionCategory.values.map(
                    (cat) => InkWell(
                      onTap: () {
                        final count = _selectedIds.length;
                        SubscriptionStore.instance.batchChangeCategory(_selectedIds, cat);
                        _exitSelectionMode();
                        Navigator.pop(ctx);
                        OneUIToast.show(context, 'Moved $count subscriptions to ${cat.label}');
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 20, color: OneUITheme.textSecondary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: OneUITheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
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
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLockSelected() {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final selectedSubs = SubscriptionStore.instance.subscriptions
        .where((s) => _selectedIds.contains(s.id));
    final anyActive = selectedSubs.any((s) => s.status != SubscriptionStatus.paused);
    SubscriptionStore.instance.batchTogglePause(_selectedIds);
    _exitSelectionMode();
    OneUIToast.show(context, '${anyActive ? "Paused" : "Resumed"} $count subscription${count > 1 ? "s" : ""}');
  }

  Future<void> _handleShareSelected() async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    final subs = SubscriptionStore.instance.subscriptions.where((s) => _selectedIds.contains(s.id));
    final buffer = StringBuffer('Subscriptions Summary (${_selectedIds.length} items):\n\n');
    for (var sub in subs) {
      buffer.writeln('• ${sub.name}: ${sub.currency}${sub.price.toStringAsFixed(2)} / ${sub.billingCycle.label} (${sub.category.label}) - Due in ${sub.daysRemaining} days');
    }
    buffer.writeln('\nTracked with OneSpend');

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: buffer.toString().trim(),
          subject: 'OneSpend Subscriptions (${_selectedIds.length})',
        ),
      );
    } catch (_) {
      Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
      if (mounted) {
        OneUIToast.show(context, '${_selectedIds.length} subscriptions copied to clipboard');
      }
    }
  }

  void _handleDeleteSelected() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();
    final count = _selectedIds.length;
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete $count subscription${count > 1 ? "s" : ""}?',
      message: 'These subscriptions will be permanently deleted from your spend list.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () {
        HapticFeedback.mediumImpact();
        SubscriptionStore.instance.batchDelete(_selectedIds);
        _exitSelectionMode();
        OneUIToast.show(context, 'Deleted $count subscription${count > 1 ? "s" : ""}');
      },
    );
  }

  void _handleDuplicateSelected() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();
    final subs = SubscriptionStore.instance.subscriptions
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    final duplicates = subs.map((s) => s.copyWith(
      id: Subscription.generateUniqueId('copy'),
      name: '${s.name} (Copy)',
    )).toList();
    SubscriptionStore.instance.batchAdd(duplicates);
    final count = _selectedIds.length;
    _exitSelectionMode();
    OneUIToast.show(context, 'Duplicated $count subscriptions');
  }

  void _handleExportSelected() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    final subs = SubscriptionStore.instance.subscriptions
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    final buffer = StringBuffer(
        'id,name,price,currency,category,billingCycle,nextBillingDate,reminderDays,description,status\n');
    for (var s in subs) {
      buffer.writeln(
          '${s.id},"${s.name.replaceAll('"', '""')}",${s.price},"${s.currency}","${s.category.name}","${s.billingCycle.name}","${s.nextBillingDate.toIso8601String()}",${s.reminderDays},"${s.description.replaceAll('"', '""')}","${s.status.name}"');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _exitSelectionMode();
    OneUIToast.show(context, 'Selected subscriptions CSV copied');
  }

  void _handleMoreSelected() {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.lightImpact();
    final selectedSubs = SubscriptionStore.instance.subscriptions
        .where((s) => _selectedIds.contains(s.id));
    final anyActive = selectedSubs.any((s) => s.status != SubscriptionStatus.paused);
    final pauseOrResumeLabel = anyActive ? 'Pause' : 'Resume';

    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _selectionMoreButtonKey,
      fallbackBottom: 84.0,
      fallbackRight: 20.0,
      items: [
        OneUIFloatingMenuItem(
          label: 'Move to category',
          onTap: _handleMoveSelected,
        ),
        OneUIFloatingMenuItem(
          label: pauseOrResumeLabel,
          onTap: _handleLockSelected,
        ),
        OneUIFloatingMenuItem(
          label: 'Duplicate selected',
          onTap: _handleDuplicateSelected,
        ),
        OneUIFloatingMenuItem(
          label: 'Export selected (CSV)',
          onTap: _handleExportSelected,
        ),
      ],
    );
  }

  void _showEditBudgetDialog(BuildContext context) {
    final store = SubscriptionStore.instance;

    OneUIFloatingModal.showTextInputDialog(
      context: context,
      title: 'Set Monthly Budget',
      message: 'Enter your monthly subscription budget limit:',
      initialValue: store.monthlyBudget.toStringAsFixed(0),
      prefixText: '${store.currency} ',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
    ).then((result) {
      if (result != null) {
        final parsed = double.tryParse(result.trim().replaceAll(',', '.'));
        if (parsed != null && parsed >= 0) {
          store.setMonthlyBudget(parsed.clamp(0.0, 999999.0));
        }
      }
    });
  }

  void _showExportDialog(BuildContext context) {
    final csv = SubscriptionStore.instance.exportDataAsCsv();

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Export Subscriptions',
      message: 'Preview and copy your subscription database as a CSV file:',
      customContent: Container(
        height: 130,
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Text(
            csv,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: OneUITheme.textSecondary),
          ),
        ),
      ),
      cancelLabel: 'Close',
      confirmLabel: 'Copy CSV',
      onConfirm: () {
        Clipboard.setData(ClipboardData(text: csv));
        OneUIToast.show(context, 'CSV copied to clipboard');
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: OneUITheme.floatingShadow,
        ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCancelPill({
    required VoidCallback onCancel,
  }) {
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onCancel();
      },
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: OneUITheme.floatingShadow,
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: is3d ? null : OneUITheme.floatingColor,
                gradient: is3d ? OneUITheme.floatingGradient : null,
                borderRadius: BorderRadius.circular(24),
                border: OneUITheme.floatingBorder,
              ),
              alignment: Alignment.center,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSearchPill() {
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: OneUITheme.floatingShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: OneUITheme.blurSigma,
            sigmaY: OneUITheme.blurSigma,
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(32),
              border: OneUITheme.floatingBorder,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      _searchFocusNode.unfocus();
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'What are you looking for?',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E95B8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSubscriptionSection({
    required String title,
    required List<Subscription> subs,
  }) {
    final ctrl = OneUIEffectsController.instance;
    final layout = ctrl.cardLayout;

    if (layout == SubscriptionCardLayout.bentoElevated) {
      return OneUISection(
        title: title,
        child: Column(
          children: subs.map((sub) {
            final store = SubscriptionStore.instance;
            final method = store.getPaymentMethod(sub.paymentMethodId);
            final hasNoCard = sub.paymentMethodId == null || method == null;
            final isCardExpiring = method != null && (method.isExpiringSoon || method.isExpired);

            return OneUISubscriptionCard(
              subscription: sub,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedIds.contains(sub.id),
              onToggleSelect: _toggleSelectItem,
              paymentMethodNickname: method?.nickname,
              isCardExpiring: isCardExpiring,
              hasNoCard: hasNoCard,
              onTap: () {
                if (_isSelectionMode) {
                  HapticFeedback.selectionClick();
                  _toggleSelectItem(sub.id);
                } else {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscriptionDetailScreen(subscription: sub),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  HapticFeedback.mediumImpact();
                  _enterSelectionMode(sub.id);
                }
              },
            );
          }).toList(),
        ),
      );
    }

    if (layout == SubscriptionCardLayout.compact) {
      return OneUISection(
        title: title,
        child: Container(
          decoration: BoxDecoration(
            color: ctrl.resolveCardBackground(),
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: subs.map((sub) {
              final store = SubscriptionStore.instance;
              final method = store.getPaymentMethod(sub.paymentMethodId);
              final hasNoCard = sub.paymentMethodId == null || method == null;
              final isCardExpiring = method != null && (method.isExpiringSoon || method.isExpired);

              return OneUISubscriptionCard(
                subscription: sub,
                overrideLayout: SubscriptionCardLayout.compact,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedIds.contains(sub.id),
                onToggleSelect: _toggleSelectItem,
                paymentMethodNickname: method?.nickname,
                isCardExpiring: isCardExpiring,
                hasNoCard: hasNoCard,
                onTap: () {
                  if (_isSelectionMode) {
                    HapticFeedback.selectionClick();
                    _toggleSelectItem(sub.id);
                  } else {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubscriptionDetailScreen(subscription: sub),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    HapticFeedback.mediumImpact();
                    _enterSelectionMode(sub.id);
                  }
                },
              );
            }).toList(),
          ),
        ),
      );
    }

    // Default: One UI Fluent Grouped Card
    return OneUISection(
      title: title,
      child: OneUIGroupCard(
        items: subs.map((sub) {
          final store = SubscriptionStore.instance;
          final method = store.getPaymentMethod(sub.paymentMethodId);
          final hasNoCard = sub.paymentMethodId == null || method == null;
          final isCardExpiring = method != null && (method.isExpiringSoon || method.isExpired);

          return OneUISubscriptionCard.toGroupItem(
            subscription: sub,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedIds.contains(sub.id),
            onToggleSelect: _toggleSelectItem,
            paymentMethodNickname: method?.nickname,
            isCardExpiring: isCardExpiring,
            hasNoCard: hasNoCard,
            onTap: () {
              if (_isSelectionMode) {
                HapticFeedback.selectionClick();
                _toggleSelectItem(sub.id);
              } else {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubscriptionDetailScreen(subscription: sub),
                  ),
                );
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                HapticFeedback.mediumImpact();
                _enterSelectionMode(sub.id);
              }
            },
          );
        }).toList(),
      ),
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
        final store = SubscriptionStore.instance;
        final allSubs = store.sortedSubscriptions;

        final filteredSubs = allSubs.where((s) {
          if (_filterCategory != null && s.category != _filterCategory) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.category.label.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.price.toString().contains(q);
          }
          return true;
        }).toList();

        final upcomingSubs = List<Subscription>.from(store.upcomingDue);

        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        final searchPillBottom = math.max(bottomPadding + 16, bottomInset + 14);

        return PopScope(
          canPop: !_isSelectionMode && !_showSearch,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (_isSelectionMode) {
                _exitSelectionMode();
              } else if (_showSearch) {
                _exitSearchMode();
              }
            }
          },
          child: Scaffold(
            backgroundColor: OneUITheme.surfacePitch,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // One UI Signature Collapsible Header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: OneUICollapsibleHeaderDelegate(
                        title: _showSearch
                            ? 'Search'
                            : (_isSelectionMode
                                ? '${_selectedIds.length} selected'
                                : 'Subscriptions'),
                        subtitle: _showSearch
                            ? null
                            : (_isSelectionMode
                                ? (_selectedIds.length == filteredSubs.length
                                    ? 'All selected • Tap (O) to deselect'
                                    : 'Tap (O) to select all')
                                : '${store.totalActiveCount} active • ${store.currency}${store.totalMonthlySpend.toStringAsFixed(2)} / month'),
                        hasBigHeader: !_showSearch,
                        showBackButton: _showSearch,
                        onBack: _showSearch ? _exitSearchMode : null,
                        expandedHeight: 270.0,
                        collapsedHeight: 92.0,
                        actionsPillKey: _actionPillKey,
                        isSelectionMode: _isSelectionMode && !_showSearch,
                        selectionLeading: (_isSelectionMode && !_showSearch)
                            ? _buildSelectionCountPill(
                                selectedCount: _selectedIds.length,
                                totalCount: filteredSubs.length,
                                onToggleSelectAll: () => _toggleSelectAll(filteredSubs),
                              )
                            : null,
                        selectionTrailing: (_isSelectionMode && !_showSearch)
                            ? _buildSelectionCancelPill(
                                onCancel: _exitSelectionMode,
                              )
                            : null,
                        actions: (_isSelectionMode || _showSearch)
                            ? null
                            : [
                                OneUIHeaderAction(
                                  icon: Icons.add,
                                  size: 26,
                                  tooltip: 'Add subscription',
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AddSubscriptionScreen(),
                                      ),
                                    );
                                  },
                                ),
                                OneUIHeaderAction(
                                  icon: Icons.search_rounded,
                                  tooltip: 'Search subscriptions',
                                  onTap: _enterSearchMode,
                                ),
                                OneUIHeaderAction(
                                  actionKey: _moreButtonKey,
                                  icon: Icons.more_vert_rounded,
                                  tooltip: 'More options',
                                  size: 22,
                                  onTap: () => _showExpandedMenu(context),
                                ),
                              ],
                      ),
                    ),

                    // Search View (Matching One UI Screenshot 1:1)
                    if (_showSearch) ...[
                      if (_searchQuery.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: searchPillBottom + 56,
                            ),
                            child: Center(
                              child: Text(
                                'No recent searches',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (filteredSubs.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: searchPillBottom + 56,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: OneUITheme.textSecondary.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No results for "$_searchQuery"',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            searchPillBottom + 70,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _buildSubscriptionSection(
                              title: 'Results (${filteredSubs.length})',
                              subs: filteredSubs,
                            ),
                          ),
                        ),
                    ] else ...[
                      // Monthly Budget Card (One UI Device Care Style)
                      SliverToBoxAdapter(
                        child: _MonthlyBudgetCard(
                          store: store,
                          upcomingSubs: upcomingSubs,
                          onTap: () => _showEditBudgetDialog(context),
                        ),
                      ),

                    // Section: Upcoming Renewals (Adaptive Carousel / Spotlight / Grouped List)
                    if (upcomingSubs.isNotEmpty && _filterCategory == null && _searchQuery.isEmpty)
                      SliverToBoxAdapter(
                        child: OneUIUpcomingRenewalsSection(
                          upcomingSubscriptions: upcomingSubs,
                          onTapSubscription: (sub) {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubscriptionDetailScreen(subscription: sub),
                              ),
                            );
                          },
                          onLongPressSubscription: (sub) {
                            HapticFeedback.mediumImpact();
                            _enterSelectionMode(sub.id);
                          },
                          onMarkPaid: (sub) {
                            final nextDate = sub.calculateNextDateFrom(sub.nextBillingDate);
                            final updated = sub.copyWith(nextBillingDate: nextDate);
                            store.updateSubscription(updated);
                            OneUIToast.show(
                              context,
                              'Marked ${sub.name} as paid (${OneUIDateFormats.monthDay.format(nextDate)})',
                            );
                          },
                          isSelectionMode: _isSelectionMode,
                          selectedIds: _selectedIds,
                          onToggleSelect: _toggleSelectItem,
                        ),
                      ),

                    // Section: Subscriptions List
                    if (filteredSubs.isEmpty)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, _isSelectionMode ? 120 : 160),
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
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: OneUITheme.textSecondary),
                                const SizedBox(height: 12),
                                const Text(
                                  'No subscriptions found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: OneUITheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try adjusting your search or category filter',
                                  style: TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: OneUITheme.accentBlue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                      _filterCategory = null;
                                      _showSearch = false;
                                    });
                                  },
                                  child: const Text('Reset filters', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (store.groupByDate && _filterCategory == null && _searchQuery.isEmpty) ...[
                      // Group: Overdue
                      if (filteredSubs.any((s) => s.daysRemaining < 0))
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _buildSubscriptionSection(
                              title: 'Overdue',
                              subs: filteredSubs.where((s) => s.daysRemaining < 0).toList(),
                            ),
                          ),
                        ),
                      // Group: Due this week
                      if (filteredSubs.any((s) => s.daysRemaining >= 0 && s.daysRemaining <= 7))
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _buildSubscriptionSection(
                              title: 'Due this week',
                              subs: filteredSubs
                                  .where((s) => s.daysRemaining >= 0 && s.daysRemaining <= 7)
                                  .toList(),
                            ),
                          ),
                        ),
                      // Group: Due this month
                      if (filteredSubs.any((s) => s.daysRemaining > 7 && s.daysRemaining <= 30))
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _buildSubscriptionSection(
                              title: 'Due this month',
                              subs: filteredSubs
                                  .where((s) => s.daysRemaining > 7 && s.daysRemaining <= 30)
                                  .toList(),
                            ),
                          ),
                        ),
                      // Group: Later / Beyond 30 days
                      if (filteredSubs.any((s) => s.daysRemaining > 30))
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: _buildSubscriptionSection(
                              title: 'Later renewals',
                              subs: filteredSubs.where((s) => s.daysRemaining > 30).toList(),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: _isSelectionMode ? 120 : 160),
                      ),
                    ] else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: _buildSubscriptionSection(
                            title: _filterCategory != null
                                ? '${_filterCategory!.label} (${filteredSubs.length})'
                                : 'All subscriptions (${filteredSubs.length})',
                            subs: filteredSubs,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: _isSelectionMode ? 120 : 160),
                      ),
                    ],
                  ],
                ],
              ),

                // Bottom Gradient Vignette (Fades scrolling items into pitch black behind floating bars)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: OneUIBottomVignette(
                    isVisible: !_showSearch,
                  ),
                ),

                // Floating Scroll-To-Top circular button (only when not searching)
                if (!_showSearch)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).padding.bottom + (_isSelectionMode ? 86 : 94),
                    child: Center(
                      child: OneUIScrollToTopButton(
                        scrollController: _scrollController,
                      ),
                    ),
                  ),

                // Bottom Floating Multi-Selection Action Bar (Replaces main nav bar in-place!)
                if (_isSelectionMode && !_showSearch)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: OneUISelectionActionBar(
                      selectedCount: _selectedIds.length,
                      moreButtonKey: _selectionMoreButtonKey,
                      onMove: _handleMoveSelected,
                      onToggleLock: _handleLockSelected,
                      onShare: _handleShareSelected,
                      onDelete: _handleDeleteSelected,
                      onMore: _handleMoreSelected,
                    ),
                  ),

                // Floating Search Pill above keyboard (matching One UI reference screenshot)
                if (_showSearch)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    left: 18,
                    right: 18,
                    bottom: searchPillBottom,
                    child: RepaintBoundary(
                      child: _buildFloatingSearchPill(),
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

class _MonthlyBudgetCard extends StatelessWidget {
  final SubscriptionStore store;
  final List<Subscription> upcomingSubs;
  final VoidCallback onTap;

  const _MonthlyBudgetCard({
    required this.store,
    required this.upcomingSubs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final budget = store.monthlyBudget;
    final totalSpend = store.totalMonthlySpend;
    final remaining = budget > totalSpend ? budget - totalSpend : 0.0;
    final budgetProgress = budget > 0 ? (totalSpend / budget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = budget > 0 && totalSpend > budget;
    final budgetPercent = budget > 0 ? ((totalSpend / budget) * 100).round() : 0;
    final dailyAvg = totalSpend / 30.0;

    final Color statusBadgeBg;
    final Color statusBadgeText;
    final String statusBadgeLabel;
    if (budget <= 0) {
      statusBadgeBg = OneUITheme.surfacePill;
      statusBadgeText = OneUITheme.textSecondary;
      statusBadgeLabel = 'No limit set';
    } else if (isOverBudget) {
      statusBadgeBg = OneUITheme.accentRed.withValues(alpha: 0.15);
      statusBadgeText = OneUITheme.accentRed;
      statusBadgeLabel = '${store.currency}${(totalSpend - budget).toStringAsFixed(0)} over';
    } else {
      statusBadgeBg = OneUITheme.accentGreen.withValues(alpha: 0.15);
      statusBadgeText = OneUITheme.accentGreen;
      statusBadgeLabel = '${store.currency}${remaining.toStringAsFixed(0)} left';
    }

    final LinearGradient progressGradient = isOverBudget
        ? const LinearGradient(colors: [OneUITheme.accentAmber, OneUITheme.accentRed])
        : (budgetProgress > 0.8
            ? const LinearGradient(colors: [OneUITheme.accentAmber, OneUITheme.accentOrange])
            : const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Label & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Monthly budget',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.mode_edit_outline_rounded,
                        size: 14,
                        color: OneUITheme.textSecondary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusBadgeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusBadgeText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Spend Metric & Percentage
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${store.currency}${totalSpend.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: OneUITheme.textPrimary,
                    ),
                  ),
                  if (budget > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '/ ${store.currency}${budget.toStringAsFixed(0)} limit',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: OneUITheme.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (budget > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: (isOverBudget ? OneUITheme.accentRed : OneUITheme.accentBlue)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$budgetPercent%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isOverBudget ? OneUITheme.accentRed : OneUITheme.accentBlue,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // One UI Gradient Progress Bar
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final fillWidth = totalWidth * budgetProgress;
                  return Container(
                    height: 8,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: fillWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: progressGradient,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: (isOverBudget
                                      ? OneUITheme.accentRed
                                      : OneUITheme.accentBlue)
                                  .withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Contextual Metrics Footer
              Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '~${store.currency}${dailyAvg.toStringAsFixed(2)}/day',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (upcomingSubs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: OneUITheme.surfacePill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: OneUITheme.accentBlue,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Next: ${upcomingSubs.first.name} (${OneUIDateFormats.monthDay.format(upcomingSubs.first.nextBillingDate)})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: OneUITheme.textPrimary,
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
      ),
    );
  }
}

