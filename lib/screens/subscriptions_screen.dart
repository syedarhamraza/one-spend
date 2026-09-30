import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_budget_card.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_filter_bottom_sheet.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_floating_search_field.dart';
import '../widgets/one_ui_scroll_to_top_button.dart';
import '../widgets/one_ui_selection_action_bar.dart';
import '../widgets/one_ui_sort_bottom_sheet.dart';
import '../widgets/one_ui_subscription_card.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_upcoming_carousel.dart';
import 'one_ui_field_editor_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  final ValueChanged<bool>? onSelectionModeChanged;
  final ValueChanged<bool>? onSearchModeChanged;
  final String? filterPaymentMethodId;

  const SubscriptionsScreen({
    super.key,
    this.onSelectionModeChanged,
    this.onSearchModeChanged,
    this.filterPaymentMethodId,
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
          onTap: () => _showEditBudgetDialog(),
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

  Future<void> _showEditBudgetDialog() async {
    final store = SubscriptionStore.instance;

    final result = await OneUIFieldEditorScreen.open<double>(
      context: context,
      title: 'Set Monthly Budget',
      subtitle: 'Enter your monthly subscription budget limit:',
      type: FieldEditorType.number,
      initialValue: store.monthlyBudget,
      prefixText: '${store.currency} ',
      hintText: '0',
      currency: store.currency,
    );

    if (result != null && mounted) {
      store.setMonthlyBudget(result.clamp(0.0, 999999.0));
      OneUIToast.show(
        context,
        'Budget updated to ${store.currency}${store.monthlyBudget.toStringAsFixed(0)}',
      );
    }
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
    return OneUIFloatingSearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onSubmitted: (val) {
        _searchFocusNode.unfocus();
        if (val.trim().isNotEmpty) {
          SubscriptionStore.instance.addRecentSearch(val.trim());
        }
      },
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _buildSubscriptionSection({
    required String title,
    required List<Subscription> subs,
  }) {
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
            cardBrand: method?.brand,
            cardBrandIcon: method?.brand.icon,
            isCardExpiring: isCardExpiring,
            hasNoCard: hasNoCard,
            onTap: () {
              if (_isSelectionMode) {
                HapticFeedback.selectionClick();
                _toggleSelectItem(sub.id);
              } else {
                if (_showSearch && _searchQuery.trim().isNotEmpty) {
                  SubscriptionStore.instance.addRecentSearch(_searchQuery.trim());
                }
                HapticFeedback.lightImpact();
                context.push(AppRoutes.subscriptionDetail(sub.id));
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
        final isCardFilter = widget.filterPaymentMethodId != null;
        final card = isCardFilter ? store.getPaymentMethod(widget.filterPaymentMethodId) : null;
        final cardTitle = card != null ? '${card.nickname} Subscriptions' : 'Card Subscriptions';
        final isTrueEmpty = allSubs.isEmpty;

        final filteredSubs = allSubs.where((s) {
          if (isCardFilter && s.paymentMethodId != widget.filterPaymentMethodId) {
            return false;
          }
          if (_filterCategory != null && s.category != _filterCategory) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.category.label.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.price.toString().contains(q) ||
                s.paymentMethod.toLowerCase().contains(q) ||
                s.notes.toLowerCase().contains(q);
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
                                : (isCardFilter ? cardTitle : 'Subscriptions')),
                        subtitle: _showSearch
                            ? null
                            : (_isSelectionMode
                                ? (_selectedIds.length == filteredSubs.length
                                    ? 'All selected • Tap (O) to deselect'
                                    : 'Tap (O) to select all')
                                : (isCardFilter
                                    ? '${filteredSubs.length} linked • ${store.currency}${filteredSubs.fold<double>(0.0, (sum, s) => sum + s.monthlyCost).toStringAsFixed(2)} / month'
                                    : '${store.totalActiveCount} active • ${store.currency}${store.totalMonthlySpend.toStringAsFixed(2)} / month')),
                        hasBigHeader: !_showSearch && !isCardFilter,
                        showBackButton: _showSearch || isCardFilter,
                        onBack: () {
                          if (_showSearch) {
                            _exitSearchMode();
                          } else if (isCardFilter) {
                            Navigator.pop(context);
                          }
                        },
                        expandedHeight: isCardFilter ? 120.0 : 270.0,
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
                        actions: (_isSelectionMode || _showSearch || isTrueEmpty)
                            ? null
                            : [
                                OneUIHeaderAction(
                                  icon: Icons.add,
                                  size: 26,
                                  tooltip: 'Add subscription',
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push(AppRoutes.addSubscription, extra: widget.filterPaymentMethodId);
                                  },
                                ),
                                OneUIHeaderAction(
                                  icon: Icons.search_rounded,
                                  tooltip: 'Search subscriptions',
                                  onTap: _enterSearchMode,
                                ),
                                if (!isCardFilter)
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
                        if (store.recentSearches.isEmpty)
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
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              searchPillBottom + 56,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Recent searches',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: OneUITheme.textSecondary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            store.clearRecentSearches();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                            child: Text(
                                              'Clear all',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: OneUITheme.accentBlue.withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: store.recentSearches.map((query) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: OneUITheme.surfacePill,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.08),
                                            width: 1,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(20),
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              _searchController.text = query;
                                              setState(() {
                                                _searchQuery = query;
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.history_rounded,
                                                    size: 15,
                                                    color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    query,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback.lightImpact();
                                                      store.removeRecentSearch(query);
                                                    },
                                                    behavior: HitTestBehavior.opaque,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(2),
                                                      child: Icon(
                                                        Icons.close_rounded,
                                                        size: 15,
                                                        color: OneUITheme.textSecondary.withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
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
                    ] else if (isTrueEmpty) ...[
                      // True Empty State (Database has no subscriptions)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: OneUITheme.accentBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.subscriptions_outlined,
                                  size: 36,
                                  color: OneUITheme.accentBlue,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'No subscriptions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: OneUITheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Track your recurring expenses in one place',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: OneUITheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.push(AppRoutes.addSubscription);
                                  },
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentBlue.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded, size: 19, color: OneUITheme.accentBlue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add a subscription',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: OneUITheme.accentBlue,
                                            letterSpacing: -0.1,
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
                    ] else ...[
                      // Monthly Budget Card (Suppressed when viewing card-filtered subscriptions)
                      if (!isCardFilter)
                        SliverToBoxAdapter(
                          child: OneUIBudgetCard(
                            store: store,
                            upcomingSubs: upcomingSubs,
                            onTap: () => _showEditBudgetDialog(),
                          ),
                        ),

                      // Section: Upcoming Renewals (Suppressed when viewing card-filtered subscriptions)
                      if (!isCardFilter && upcomingSubs.isNotEmpty && _filterCategory == null && _searchQuery.isEmpty)
                        SliverToBoxAdapter(
                          child: OneUIUpcomingRenewalsSection(
                            upcomingSubscriptions: upcomingSubs,
                            onTapSubscription: (sub) {
                              HapticFeedback.lightImpact();
                              context.push(AppRoutes.subscriptionDetail(sub.id));
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
                        if (isCardFilter)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.credit_card_off_rounded,
                                      size: 34,
                                      color: OneUITheme.accentBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'No linked subscriptions',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      'No subscriptions are currently linked to this payment method',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: OneUITheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        context.push(AppRoutes.addSubscription, extra: widget.filterPaymentMethodId);
                                      },
                                      borderRadius: BorderRadius.circular(100),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: OneUITheme.accentBlue.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded, size: 18, color: OneUITheme.accentBlue),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add a subscription',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: OneUITheme.accentBlue,
                                                letterSpacing: -0.1,
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
                          )
                        else
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
                                    const SizedBox(height: 18),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                            _filterCategory = null;
                                            _showSearch = false;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(100),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: OneUITheme.accentBlue.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: const Text(
                                            'Reset filters',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: OneUITheme.accentBlue,
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                      else if (store.groupByDate && _filterCategory == null && _searchQuery.isEmpty && !isCardFilter) ...[
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
                            title: isCardFilter
                                ? 'Linked subscriptions (${filteredSubs.length})'
                                : (_filterCategory != null
                                    ? '${_filterCategory!.label} (${filteredSubs.length})'
                                    : 'All subscriptions (${filteredSubs.length})'),
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

