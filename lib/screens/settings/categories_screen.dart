import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/app_router.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_bottom_vignette.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_selection_header_pills.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../category_editor_screen.dart';
import '../category_picker_screen.dart';

/// Settings › Categories, laid out like Samsung's category lists: your own categories (in
/// your order) above the built-in ones, + in the header to make one, long-press to select
/// several, and ⋮ › Reorder.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static Future<void> open(BuildContext context) {
    Haptics.tap();
    return context.push(AppRoutes.settingsCategories);
  }

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _store = SubscriptionStore.instance;
  final GlobalKey _moreKey = GlobalKey();
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  List<CustomCategory> get _custom => _store.customCategories;

  String _usage(SubscriptionCategory category) {
    final count = _store.subscriptionCountIn(category);
    return count == 0 ? 'Not used yet' : '$count ${count == 1 ? 'subscription' : 'subscriptions'}';
  }

  void _enterSelection([String? id]) {
    Haptics.longPress();
    setState(() {
      _selecting = true;
      if (id != null) _selectedIds.add(id);
    });
  }

  void _exitSelection() => setState(() {
        _selecting = false;
        _selectedIds.clear();
      });

  void _toggle(String id) {
    Haptics.select();
    setState(() => _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id));
  }

  void _toggleAll() => setState(() {
        if (_selectedIds.length == _custom.length) {
          _selectedIds.clear();
        } else {
          _selectedIds.addAll(_custom.map((c) => c.id));
        }
      });

  void _showMenu() {
    Haptics.tap();
    OneUIFloatingMenu.show(
      context: context,
      anchorKey: _moreKey,
      fallbackTop: MediaQuery.paddingOf(context).top + 6.0,
      items: [
        if (_custom.isNotEmpty) OneUIFloatingMenuItem(label: 'Select', onTap: () => _enterSelection()),
        if (_custom.length > 1)
          OneUIFloatingMenuItem(
            label: 'Reorder',
            onTap: () {
              Haptics.tap();
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const _ReorderCategoriesScreen()));
            },
          ),
        OneUIFloatingMenuItem(label: 'New category', onTap: () => CategoryEditorScreen.open(context)),
      ],
    );
  }

  Future<void> _deleteSelected() async {
    final ids = Set.of(_selectedIds);
    if (ids.isEmpty) return;
    final categories = [for (final c in _custom) if (ids.contains(c.id)) c];
    final count = [
      for (final c in categories) _store.subscriptionCountIn(SubscriptionCategory.custom(c.id)),
    ].fold(0, (a, b) => a + b);
    var moveTo = SubscriptionCategory.utilities;
    if (count > 0) {
      final picked = await CategoryPickerScreen.open(context, initialCategory: moveTo);
      if (picked == null || !mounted) return;
      moveTo = picked.isCustom && ids.contains(picked.name) ? SubscriptionCategory.utilities : picked;
    }
    if (!mounted) return;
    final name = categories.length == 1 ? categories.single.name : '${categories.length} categories';
    final confirmed = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete $name?',
      message: count == 0
          ? 'No subscriptions use ${categories.length == 1 ? 'it' : 'them'}.'
          : '$count ${count == 1 ? 'subscription moves' : 'subscriptions move'} to ${moveTo.label}.',
      confirmLabel: 'Delete',
      confirmTextColor: OneUITheme.accentRed,
    );
    if (confirmed != true || !mounted) return;
    Haptics.warn();
    _store.deleteCustomCategories(ids, moveTo: moveTo);
    _exitSelection();
    OneUIToast.show(context, '$name deleted');
  }

  Widget _selectionCircle(bool selected) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 22,
        height: 22,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? OneUITheme.accentBlue : Colors.transparent,
          border: Border.all(
            color: selected ? OneUITheme.accentBlue : Colors.white.withValues(alpha: 0.35),
            width: 1.8,
          ),
        ),
        child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
      );

  Widget _yourCategories() {
    final custom = _custom;
    if (custom.isEmpty) {
      return OneUIEmptyCard(
        icon: Icons.label_outline_rounded,
        title: 'No categories of your own',
        message: 'Make one for anything the built-in ones miss, with your own name, icon and colour.',
        actionLabel: 'New category',
        onAction: () => CategoryEditorScreen.open(context),
      );
    }
    return OneUIGroupCard(
      margin: EdgeInsets.zero,
      items: [
        for (final c in custom)
          OneUIGroupItem(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: _selecting ? _selectionCircle(_selectedIds.contains(c.id)) : const SizedBox.shrink(),
                ),
                OneUIIconBadge(
                  SubscriptionCategory.custom(c.id).icon,
                  SubscriptionCategory.custom(c.id).color,
                ),
              ],
            ),
            title: c.name,
            subtitle: _usage(SubscriptionCategory.custom(c.id)),
            subtitleColor: OneUITheme.textSecondary,
            trailing: _selecting ? const SizedBox.shrink() : null,
            onTap: _selecting ? () => _toggle(c.id) : () => CategoryEditorScreen.open(context, categoryId: c.id),
            onLongPress: _selecting ? () => _toggle(c.id) : () => _enterSelection(c.id),
          ),
      ],
    );
  }

  /// Built-in categories don't take part in selection: kept in place, faded and inert.
  Widget _builtIn() => IgnorePointer(
        ignoring: _selecting,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _selecting ? 0.3 : 1,
          child: OneUISection(
            title: 'Built in',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                for (final category in SubscriptionCategory.values)
                  OneUIGroupItem(
                    leading: OneUIIconBadge(category.icon, category.color),
                    title: category.label,
                    subtitle: _usage(category),
                    subtitleColor: OneUITheme.textSecondary,
                    trailing: const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // System back leaves selection before leaving the page.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          // A category deleted elsewhere drops out of the selection.
          _selectedIds.removeWhere((id) => !_custom.any((c) => c.id == id));
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
                        title: _selecting ? '' : 'Categories',
                        hasBigHeader: false,
                        showBackButton: !_selecting,
                        onBack: () => Navigator.pop(context),
                        isSelectionMode: _selecting,
                        selectionLeading: OneUISelectionCountPill(
                          selectedCount: _selectedIds.length,
                          totalCount: _custom.length,
                          onToggleSelectAll: _toggleAll,
                        ),
                        onSelectionCancel: _exitSelection,
                        actions: [
                          OneUIHeaderAction(
                            icon: Icons.add,
                            size: 26,
                            tooltip: 'New category',
                            onTap: () => CategoryEditorScreen.open(context),
                          ),
                          OneUIHeaderAction(
                            icon: Icons.more_vert_rounded,
                            tooltip: 'More options',
                            actionKey: _moreKey,
                            onTap: _showMenu,
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OneUISection(title: 'Your categories', child: _yourCategories()),
                            _builtIn(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  left: 0,
                  right: 0,
                  bottom: _selecting ? 0 : -120,
                  child: IgnorePointer(
                    ignoring: !_selecting,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _selecting ? 1 : 0,
                      child: Center(
                        child: OneUIFloatingActionBar(
                          items: [
                            OneUIFloatingActionBarItem(
                              label: 'Edit',
                              icon: Icons.edit_rounded,
                              isEnabled: _selectedIds.length == 1,
                              onTap: () {
                                final id = _selectedIds.single;
                                _exitSelection();
                                CategoryEditorScreen.open(context, categoryId: id);
                              },
                            ),
                            OneUIFloatingActionBarItem(
                              label: 'Delete',
                              icon: Icons.delete_outline_rounded,
                              isEnabled: _selectedIds.isNotEmpty,
                              onTap: _deleteSelected,
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
      ),
    );
  }
}

/// ⋮ › Reorder: drag your categories by their handles, then Save. Pickers and lists follow
/// this order.
class _ReorderCategoriesScreen extends StatefulWidget {
  const _ReorderCategoriesScreen();

  @override
  State<_ReorderCategoriesScreen> createState() => _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState extends State<_ReorderCategoriesScreen> {
  late final List<CustomCategory> _order = List.of(SubscriptionStore.instance.customCategories);

  void _save() {
    Haptics.confirm();
    SubscriptionStore.instance.reorderCustomCategories([for (final c in _order) c.id]);
    Navigator.pop(context);
  }

  Widget _row(int index) {
    final c = _order[index];
    final category = SubscriptionCategory.custom(c.id);
    final first = index == 0, last = index == _order.length - 1;
    return Container(
      key: ValueKey(c.id),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: first ? const Radius.circular(26) : Radius.zero,
          bottom: last ? const Radius.circular(26) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          OneUIIconBadge(category.icon, category.color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, letterSpacing: -0.2, color: OneUITheme.textPrimary),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Semantics(
              label: 'Drag to move ${c.name}',
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.drag_handle_rounded, color: OneUITheme.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Reorder',
      bottomPill: OneUIFloatingCancelSavePill(onCancel: () => Navigator.pop(context), onSave: _save),
      builder: (context) => [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _order.length,
          onReorderStart: (_) => Haptics.longPress(),
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: Colors.black54,
            borderRadius: BorderRadius.circular(26),
            child: child,
          ),
          onReorderItem: (from, to) {
            Haptics.select();
            setState(() => _order.insert(to, _order.removeAt(from)));
          },
          itemBuilder: (context, index) => _row(index),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Drag ≡ to move a category. Category pickers and lists use this order.',
            style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
