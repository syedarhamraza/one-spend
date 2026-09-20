import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_filter_bottom_sheet.dart';
import '../widgets/one_ui_floating_menu.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_scroll_to_top_button.dart';
import '../widgets/one_ui_selection_action_bar.dart';
import '../widgets/one_ui_selection_pills.dart';
import '../widgets/one_ui_sort_bottom_sheet.dart';
import 'add_subscription_screen.dart';
import 'subscription_detail_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  final ValueChanged<bool>? onSelectionModeChanged;

  const SubscriptionsScreen({
    super.key,
    this.onSelectionModeChanged,
  });

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SubscriptionCategory? _filterCategory;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  final GlobalKey _actionPillKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged?.call(false);
  }

  void _toggleSelectAll(List<Subscription> currentList) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Moved $count subscriptions to ${cat.label}'),
                            backgroundColor: OneUITheme.surfacePill,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        );
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
    SubscriptionStore.instance.batchTogglePause(_selectedIds);
    _exitSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated status for $count subscriptions'),
        backgroundColor: OneUITheme.surfacePill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleShareSelected() {
    if (_selectedIds.isEmpty) return;
    final subs = SubscriptionStore.instance.subscriptions.where((s) => _selectedIds.contains(s.id));
    final buffer = StringBuffer('Subscriptions Summary:\n\n');
    for (var sub in subs) {
      buffer.writeln('• ${sub.name}: ${sub.currency}${sub.price.toStringAsFixed(2)} / ${sub.billingCycle.label} (${sub.category.label})');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedIds.length} subscriptions copied to clipboard'),
        backgroundColor: OneUITheme.surfacePill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _handleDeleteSelected() {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete $count subscription${count > 1 ? "s" : ""}?',
      message: 'These subscriptions will be permanently deleted from your spend list.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
      onConfirm: () {
        SubscriptionStore.instance.batchDelete(_selectedIds);
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count subscription${count > 1 ? "s" : ""}'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  void _handleMoreSelected() {
    if (_selectedIds.isEmpty) return;
    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: OneUITheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              final subs = SubscriptionStore.instance.subscriptions
                  .where((s) => _selectedIds.contains(s.id))
                  .toList();
              for (var s in subs) {
                SubscriptionStore.instance.addSubscription(s.copyWith(
                  id: '${DateTime.now().millisecondsSinceEpoch}_${s.id}',
                  name: '${s.name} (Copy)',
                ));
              }
              final count = _selectedIds.length;
              _exitSelectionMode();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Duplicated $count subscriptions'),
                  backgroundColor: OneUITheme.surfacePill,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 20, color: OneUITheme.textSecondary),
                  SizedBox(width: 16),
                  Text(
                    'Duplicate selected',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: OneUITheme.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              final subs = SubscriptionStore.instance.subscriptions
                  .where((s) => _selectedIds.contains(s.id))
                  .toList();
              final buffer = StringBuffer(
                  'id,name,price,currency,category,billingCycle,nextBillingDate,reminderDays,description,status\n');
              for (var s in subs) {
                buffer.writeln(
                    '${s.id},"${s.name}",${s.price},"${s.currency}","${s.category.name}","${s.billingCycle.name}","${s.nextBillingDate.toIso8601String()}",${s.reminderDays},"${s.description}","${s.status.name}"');
              }
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              _exitSelectionMode();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Selected subscriptions CSV copied'),
                  backgroundColor: OneUITheme.surfacePill,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, size: 20, color: OneUITheme.textSecondary),
                  SizedBox(width: 16),
                  Text(
                    'Export selected as CSV',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: OneUITheme.textPrimary),
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

  void _showEditBudgetDialog(BuildContext context) {
    final store = SubscriptionStore.instance;
    final controller = TextEditingController(text: store.monthlyBudget.toStringAsFixed(0));

    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Set Monthly Budget',
      message: 'Enter your monthly subscription budget limit:',
      customContent: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: OneUITheme.surfacePill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '${store.currency} ',
            prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
            border: InputBorder.none,
          ),
        ),
      ),
      cancelLabel: 'Cancel',
      confirmLabel: 'Save',
      onConfirm: () {
        final newBudget = double.tryParse(controller.text.trim()) ?? store.monthlyBudget;
        store.setMonthlyBudget(newBudget);
      },
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('CSV copied to clipboard'),
            backgroundColor: OneUITheme.surfacePill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  Widget _buildSelectionIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.white : Colors.transparent,
        border: isSelected
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.8,
              ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 15,
              color: Colors.black,
            )
          : null,
    );
  }

  OneUIGroupItem _buildSubscriptionItem(Subscription sub) {
    final isSelected = _selectedIds.contains(sub.id);

    return OneUIGroupItem(
      leading: _isSelectionMode
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSelectionIndicator(isSelected),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sub.brandColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(sub.iconData, color: Colors.white, size: 20),
                ),
              ],
            )
          : Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sub.brandColor,
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(sub.iconData, color: Colors.white, size: 21),
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
        if (_isSelectionMode) {
          _toggleSelectItem(sub.id);
        } else {
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
          _enterSelectionMode(sub.id);
        }
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
        final dateFormat = DateFormat('MMM dd');

        final budget = store.monthlyBudget;
        final totalSpend = store.totalMonthlySpend;
        final budgetProgress = budget > 0 ? (totalSpend / budget).clamp(0.0, 1.0) : 0.0;
        final Color progressColor = budgetProgress < 0.8
            ? OneUITheme.accentGreen
            : (budgetProgress <= 1.0 ? OneUITheme.accentAmber : OneUITheme.accentRed);

        final topPadding = MediaQuery.of(context).padding.top;

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isSelectionMode) {
              _exitSelectionMode();
            }
          },
          child: Scaffold(
            backgroundColor: OneUITheme.surfacePitch,
            body: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // One UI Signature Collapsible Header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: OneUICollapsibleHeaderDelegate(
                        title: _isSelectionMode ? '' : 'Subscriptions',
                        subtitle: _isSelectionMode
                            ? null
                            : '${store.totalActiveCount} active • ${store.currency}${store.totalMonthlySpend.toStringAsFixed(2)} / month',
                        hasBigHeader: !_isSelectionMode,
                        expandedHeight: _isSelectionMode ? 0.0 : 270.0,
                        collapsedHeight: _isSelectionMode ? (topPadding + 62.0) : 92.0,
                        actionsPillKey: _actionPillKey,
                        actions: _isSelectionMode
                            ? null
                            : [
                                OneUIHeaderAction(
                                  icon: Icons.add,
                                  size: 26,
                                  tooltip: 'Add subscription',
                                  onTap: () {
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
                                  onTap: () {
                                    setState(() {
                                      _showSearch = !_showSearch;
                                      if (!_showSearch) {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      }
                                    });
                                  },
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

                    // Search bar if toggled
                    if (_showSearch && !_isSelectionMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: OneUITheme.cardColor,
                              borderRadius: OneUITheme.pillBorderRadius,
                              border: OneUITheme.cardBorder,
                              boxShadow: OneUITheme.cardShadow,
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
                        ),
                      ),

                    // Monthly Budget Card (Interactive)
                    if (!_isSelectionMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                          child: GestureDetector(
                            onTap: () => _showEditBudgetDialog(context),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Text(
                                            'Monthly Budget',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: OneUITheme.textSecondary,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(Icons.edit_outlined, size: 14, color: OneUITheme.textSecondary),
                                        ],
                                      ),
                                      Text(
                                        '${store.currency}${totalSpend.toStringAsFixed(0)} / ${store.currency}${budget.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13.5,
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
                                      value: budgetProgress,
                                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
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
                          ),
                        ),
                      ),

                    // Section: Upcoming Renewals (Top 2)
                    if (upcomingSubs.isNotEmpty && _filterCategory == null && _searchQuery.isEmpty && !_isSelectionMode)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: OneUISection(
                            title: 'Upcoming renewals',
                            child: OneUIGroupCard(
                              items: upcomingSubs.take(2).map((sub) {
                                final days = sub.daysRemaining;
                                return OneUIGroupItem(
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: sub.brandColor,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(sub.iconData, color: Colors.white, size: 21),
                                  ),
                                  title: sub.name,
                                  subtitle: days == 0
                                      ? 'Due today (${dateFormat.format(sub.nextBillingDate)})'
                                      : 'Due in $days days (${dateFormat.format(sub.nextBillingDate)})',
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
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                    // Section: Subscriptions List
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, _isSelectionMode ? 120 : 160),
                        child: filteredSubs.isEmpty
                            ? Container(
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
                              )
                            : (store.groupByDate && _filterCategory == null && _searchQuery.isEmpty)
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Group: Due this week
                                      if (filteredSubs.any((s) => s.daysRemaining <= 7))
                                        OneUISection(
                                          title: 'Due this week',
                                          child: OneUIGroupCard(
                                            items: filteredSubs
                                                .where((s) => s.daysRemaining <= 7)
                                                .map(_buildSubscriptionItem)
                                                .toList(),
                                          ),
                                        ),
                                      // Group: Due this month
                                      if (filteredSubs.any((s) => s.daysRemaining > 7 && s.daysRemaining <= 30))
                                        OneUISection(
                                          title: 'Due this month',
                                          child: OneUIGroupCard(
                                            items: filteredSubs
                                                .where((s) => s.daysRemaining > 7 && s.daysRemaining <= 30)
                                                .map(_buildSubscriptionItem)
                                                .toList(),
                                          ),
                                        ),
                                      // Group: Later / Beyond 30 days
                                      if (filteredSubs.any((s) => s.daysRemaining > 30))
                                        OneUISection(
                                          title: 'Later renewals',
                                          child: OneUIGroupCard(
                                            items: filteredSubs
                                                .where((s) => s.daysRemaining > 30)
                                                .map(_buildSubscriptionItem)
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  )
                                : OneUISection(
                                    title: _filterCategory != null
                                        ? '${_filterCategory!.label} (${filteredSubs.length})'
                                        : 'All subscriptions (${filteredSubs.length})',
                                    child: OneUIGroupCard(
                                      items: filteredSubs.map(_buildSubscriptionItem).toList(),
                                    ),
                                  ),
                      ),
                    ),
                  ],
                ),

                // Top Floating Selection Pills (Screenshot 1 & 2)
                if (_isSelectionMode)
                  Positioned(
                    top: topPadding + 8,
                    left: 16,
                    right: 16,
                    child: OneUISelectionPills(
                      selectedCount: _selectedIds.length,
                      totalCount: filteredSubs.length,
                      onToggleSelectAll: () => _toggleSelectAll(filteredSubs),
                      onCancel: _exitSelectionMode,
                    ),
                  ),

                // Floating Scroll-To-Top circular button (Screenshot 2, centered just above navbar)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _isSelectionMode ? 82 : 92,
                  child: Center(
                    child: OneUIScrollToTopButton(
                      scrollController: _scrollController,
                    ),
                  ),
                ),

                // Bottom Floating Multi-Selection Action Bar (Screenshot 1)
                if (_isSelectionMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: OneUISelectionActionBar(
                      selectedCount: _selectedIds.length,
                      onMove: _handleMoveSelected,
                      onToggleLock: _handleLockSelected,
                      onShare: _handleShareSelected,
                      onDelete: _handleDeleteSelected,
                      onMore: _handleMoreSelected,
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
