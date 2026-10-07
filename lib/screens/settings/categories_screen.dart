import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/haptics.dart';
import '../../core/router/app_router.dart';
import '../../features/subscriptions/presentation/utils/category_descriptions.dart';
import '../../models/subscription.dart';
import '../../theme/one_ui_theme.dart';
import '../../widgets/one_ui_bottom_vignette.dart';
import '../../widgets/one_ui_cancel_save_pill.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_category_hero.dart';
import '../../widgets/one_ui_collapsible_header.dart';
import '../../widgets/one_ui_floating_action_bar.dart';
import '../../widgets/one_ui_floating_menu.dart';
import '../../widgets/one_ui_floating_modal.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_radio.dart';
import '../../widgets/one_ui_selection_header_pills.dart';
import '../../widgets/one_ui_subpage.dart';
import '../../widgets/one_ui_toast.dart';
import '../category_editor_screen.dart';
import '../category_picker_screen.dart';

/// The one categories page, laid out like Samsung's category lists: a hero card, your own
/// categories (in your order), then the built-in ones. Rows are a name and a description;
/// only the hero shows an icon.
///
/// * **Settings › Categories** ([pickInitial] null): the hero sums up your categories;
///   + in the header makes one, long-press selects several (Edit, Delete), ⋮ › Reorder.
/// * **Picking a subscription's category** (via `CategoryPickerScreen.open`): rows have
///   radios, the hero shows the chosen one, and Cancel | Save pops it. [exclude] leaves
///   categories out (e.g. the ones being deleted).
class CategoriesScreen extends StatefulWidget {
  /// The category selected when picking; null shows Settings › Categories.
  final SubscriptionCategory? pickInitial;
  final Set<SubscriptionCategory> exclude;

  const CategoriesScreen({super.key, this.pickInitial, this.exclude = const {}});

  bool get picking => pickInitial != null;

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
  late SubscriptionCategory? _picked = widget.pickInitial;
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  List<CustomCategory> get _custom => _store.customCategories;

  List<SubscriptionCategory> get _customCategories => [
        for (final c in _custom)
          if (!widget.exclude.contains(SubscriptionCategory.custom(c.id))) SubscriptionCategory.custom(c.id),
      ];

  List<SubscriptionCategory> get _builtInCategories => [
        for (final c in SubscriptionCategory.values)
          if (!widget.exclude.contains(c)) c,
      ];

  String _describe(SubscriptionCategory category, {bool long = false}) =>
      categoryDescription(category, usage: _store.subscriptionCountIn(category), long: long);

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

  void _pick(SubscriptionCategory category) {
    Haptics.select();
    setState(() => _picked = category);
  }

  Future<void> _create() async {
    final created = await CategoryEditorScreen.open(context);
    if (created != null && mounted && widget.picking) setState(() => _picked = created);
  }

  void _save() {
    Haptics.confirm();
    Navigator.pop(context, _picked);
  }

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
        OneUIFloatingMenuItem(label: 'New category', onTap: _create),
      ],
    );
  }

  Future<void> _deleteSelected() async {
    final ids = Set.of(_selectedIds);
    if (ids.isEmpty) return;
    final categories = [for (final c in _custom) if (ids.contains(c.id)) c];
    final deleting = {for (final id in ids) SubscriptionCategory.custom(id)};
    final count = deleting.fold(0, (sum, c) => sum + _store.subscriptionCountIn(c));
    var moveTo = SubscriptionCategory.utilities;
    if (count > 0) {
      final picked = await CategoryPickerScreen.open(context, initialCategory: moveTo, exclude: deleting);
      if (picked == null || !mounted) return;
      moveTo = picked;
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

  /// Picking: the chosen category. Settings: a summary, with the most-used category's icon.
  Widget _hero() {
    final picked = _picked;
    if (picked != null) {
      return OneUICategoryHero(
        icon: picked.icon,
        color: picked.color,
        title: picked.label,
        subtitle: _describe(picked, long: true),
      );
    }
    SubscriptionCategory? mostUsed;
    var most = 0;
    for (final c in SubscriptionCategory.all) {
      final n = _store.subscriptionCountIn(c);
      if (n > most) (most, mostUsed) = (n, c);
    }
    final own = _custom.length;
    return OneUICategoryHero(
      icon: mostUsed?.icon ?? Icons.label_rounded,
      color: mostUsed?.color ?? OneUITheme.accentBlue,
      title: 'Categories',
      subtitle: '${SubscriptionCategory.values.length} built in · '
          '${own == 0 ? 'none' : own} of your own',
    );
  }

  Widget _selectionCircle(bool selected) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 22,
        height: 22,
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

  OneUIGroupItem _row(SubscriptionCategory category) {
    final custom = category.isCustom;
    final id = category.name;
    if (widget.picking) {
      return OneUIGroupItem(
        title: category.label,
        subtitle: _describe(category),
        subtitleColor: OneUITheme.textSecondary,
        trailing: OneUIRadio(isSelected: category == _picked),
        onTap: () => _pick(category),
      );
    }
    return OneUIGroupItem(
      leading: _selecting && custom ? _selectionCircle(_selectedIds.contains(id)) : null,
      title: category.label,
      subtitle: _describe(category),
      subtitleColor: OneUITheme.textSecondary,
      // Your categories open to edit (chevron); built-in ones can't be changed.
      trailing: custom && !_selecting ? null : const SizedBox.shrink(),
      onTap: !custom
          ? null
          : _selecting
              ? () => _toggle(id)
              : () => CategoryEditorScreen.open(context, categoryId: id),
      onLongPress: !custom ? null : (_selecting ? () => _toggle(id) : () => _enterSelection(id)),
    );
  }

  Widget _yourCategories() {
    final custom = _customCategories;
    if (custom.isEmpty && !widget.picking) {
      return OneUIEmptyCard(
        icon: Icons.label_outline_rounded,
        title: 'No categories of your own',
        message: 'Make one for anything the built-in ones miss, with your own name, icon and colour.',
        actionLabel: 'New category',
        onAction: _create,
      );
    }
    return OneUIGroupCard(
      margin: EdgeInsets.zero,
      items: [
        for (final c in custom) _row(c),
        if (custom.isEmpty)
          OneUIGroupItem(
            title: 'New category',
            subtitle: 'Your own name, icon and colour',
            subtitleColor: OneUITheme.textSecondary,
            trailing: const Icon(Icons.add_rounded, color: OneUITheme.accentBlue, size: 22),
            onTap: _create,
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
              items: [for (final c in _builtInCategories) _row(c)],
            ),
          ),
        ),
      );

  Widget _bottomBar() {
    if (widget.picking) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: OneUIFloatingCancelSavePill(onCancel: () => Navigator.pop(context), onSave: _save),
            ),
          ),
        ),
      );
    }
    return AnimatedPositioned(
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
    );
  }

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
          // A category deleted elsewhere drops out of the selection (or the pick).
          _selectedIds.removeWhere((id) => !_custom.any((c) => c.id == id));
          final picked = _picked;
          if (picked != null && picked.isCustom && picked.custom == null) _picked = SubscriptionCategory.utilities;
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
                        title: _selecting ? '' : (widget.picking ? 'Category' : 'Categories'),
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
                          OneUIHeaderAction(icon: Icons.add, size: 26, tooltip: 'New category', onTap: _create),
                          if (!widget.picking)
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
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _hero(),
                            OneUISection(title: 'Your categories', child: _yourCategories()),
                            _builtIn(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Positioned(left: 0, right: 0, bottom: 0, child: OneUIBottomVignette()),
                _bottomBar(),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
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
