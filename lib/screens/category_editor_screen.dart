import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_category_hero.dart';
import '../widgets/one_ui_radio.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subpage.dart';
import '../widgets/one_ui_toast.dart';
import 'category_picker_screen.dart';
import '../core/telemetry/events.dart';
import '../core/telemetry/telemetry.dart';
import '../core/haptics/haptics.dart';

/// Create or edit a custom category: name, icon and colour, with a live preview.
/// Pops with the saved [SubscriptionCategory], or nothing when cancelled or deleted.
class CategoryEditorScreen extends StatefulWidget {
  /// The custom category being edited; null creates a new one.
  final String? categoryId;

  const CategoryEditorScreen({super.key, this.categoryId});

  static Future<SubscriptionCategory?> open(BuildContext context, {String? categoryId}) {
    Haptics.tap();
    return context.push<SubscriptionCategory>(AppRoutes.categoryEditor, extra: categoryId);
  }

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  final _store = SubscriptionStore.instance;
  late final TextEditingController _name;
  late IconData _icon;
  late Color _color;
  CustomCategory? _editing;

  @override
  void initState() {
    super.initState();
    final id = widget.categoryId;
    _editing = id == null ? null : CustomCategoryRegistry.byId(id);
    final editing = _editing;
    _name = TextEditingController(text: editing?.name ?? '')..addListener(() => setState(() {}));
    _icon = resolveKnownIcon(editing?.iconCodePoint) ?? Icons.home_rounded;
    _color = editing == null ? OneUITheme.categorySwatches.first : Color(editing.colorValue);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();

  /// Why the name can't be saved, or null if it can.
  String? get _nameProblem {
    final name = _trimmedName.toLowerCase();
    if (name.isEmpty) return null;
    final taken = SubscriptionCategory.all.any(
      (c) => c.label.toLowerCase() == name && !(c.isCustom && c.name == _editing?.id),
    );
    return taken ? 'A category with this name already exists' : null;
  }

  bool get _canSave => _trimmedName.isNotEmpty && _nameProblem == null;

  void _save() {
    if (!_canSave) return;
    Haptics.confirm();
    final editing = _editing;
    final SubscriptionCategory saved;
    if (editing == null) {
      saved = _store.addCustomCategory(
        name: _trimmedName,
        iconCodePoint: _icon.codePoint,
        colorValue: _color.toARGB32(),
      );
      AppLog.event(TelemetryEvent.customCategoryCreated);
      OneUIToast.show(context, '$_trimmedName added');
    } else {
      _store.updateCustomCategory(
        editing.copyWith(name: _trimmedName, iconCodePoint: _icon.codePoint, colorValue: _color.toARGB32()),
      );
      saved = SubscriptionCategory.custom(editing.id);
    }
    Navigator.pop(context, saved);
  }

  Future<void> _delete() async {
    final editing = _editing;
    if (editing == null) return;
    final category = SubscriptionCategory.custom(editing.id);
    final count = _store.subscriptionCountIn(category);
    var moveTo = SubscriptionCategory.utilities;
    if (count > 0) {
      final picked = await CategoryPickerScreen.open(context, initialCategory: moveTo, exclude: {category});
      if (picked == null || !mounted) return;
      moveTo = picked;
    }
    final confirmed = await OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete ${editing.name}?',
      message: count == 0
          ? 'No subscriptions use this category.'
          : '$count ${count == 1 ? 'subscription moves' : 'subscriptions move'} to ${moveTo.label}.',
      confirmLabel: 'Delete',
      confirmTextColor: OneUITheme.accentRed,
    );
    if (confirmed != true || !mounted) return;
    Haptics.warn();
    _store.deleteCustomCategory(editing.id, moveTo: moveTo);
    OneUIToast.show(context, '${editing.name} deleted');
    Navigator.pop(context);
  }

  /// The category as it'll look, in the same hero card as the Categories page.
  Widget _hero() {
    final editing = _editing;
    final usage = editing == null ? 0 : _store.subscriptionCountIn(SubscriptionCategory.custom(editing.id));
    return OneUICategoryHero(
      icon: _icon,
      color: _color,
      title: _trimmedName.isEmpty ? 'New category' : _trimmedName,
      placeholderTitle: _trimmedName.isEmpty,
      subtitle: usage == 0 ? 'Your category' : '$usage ${usage == 1 ? 'subscription' : 'subscriptions'}',
    );
  }

  Widget _nameField() {
    final problem = _nameProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.fieldBorderRadius),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: TextField(
            controller: _name,
            autofocus: _editing == null,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: OneUITheme.textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. Kids, Home, Work',
              hintStyle: TextStyle(color: OneUITheme.textSecondary),
            ),
          ),
        ),
        if (problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
            child: Text(problem, style: const TextStyle(fontSize: 13, color: OneUITheme.accentRed)),
          ),
      ],
    );
  }

  Future<void> _pickColour() async {
    Haptics.tap();
    final picked = await Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (_) => _OptionListScreen<Color>(
          title: 'Colour',
          options: OneUITheme.categorySwatches,
          initial: _color,
          same: (a, b) => a.toARGB32() == b.toARGB32(),
          label: OneUITheme.swatchName,
          leading: (c) => _Swatch(c),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _color = picked);
  }

  Future<void> _pickIcon() async {
    Haptics.tap();
    final color = _color;
    final picked = await Navigator.push<IconData>(
      context,
      MaterialPageRoute(
        builder: (_) => _OptionListScreen<IconData>(
          title: 'Icon',
          options: supportedSubscriptionIcons,
          initial: _icon,
          same: (a, b) => a == b,
          label: subscriptionIconName,
          leading: (icon) => Icon(icon, color: color, size: 24),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  /// Colour and Icon: each row shows the current choice and opens its list.
  Widget _looks() => OneUIGroupCard(
        margin: EdgeInsets.zero,
        items: [
          OneUIGroupItem(
            leading: _Swatch(_color),
            title: 'Colour',
            subtitle: OneUITheme.swatchName(_color),
            subtitleColor: OneUITheme.accentBlue,
            onTap: _pickColour,
          ),
          OneUIGroupItem(
            leading: SizedBox(width: 24, child: Icon(_icon, color: _color, size: 24)),
            title: 'Icon',
            subtitle: subscriptionIconName(_icon),
            subtitleColor: OneUITheme.accentBlue,
            onTap: _pickIcon,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    return OneUISubpage(
      title: editing == null ? 'New category' : 'Edit category',
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        onSave: _save,
        canSave: _canSave,
      ),
      builder: (context) => [
        _hero(),
        OneUISection(title: 'Name', child: _nameField()),
        OneUISection(title: 'Colour & icon', child: _looks()),
        if (editing != null) ...[
          const SizedBox(height: 14),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Delete category',
                trailing: const Icon(Icons.delete_outline_rounded, color: OneUITheme.accentRed, size: 22),
                onTap: _delete,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A colour as a 24 dp dot, for the Colour row and list.
class _Swatch extends StatelessWidget {
  final Color color;

  const _Swatch(this.color);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// A list of options with radios and a Cancel | Save pill, like the app's other pickers.
/// Pops the chosen option, or nothing when cancelled.
class _OptionListScreen<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final T initial;
  final bool Function(T a, T b) same;
  final String Function(T option) label;
  final Widget Function(T option) leading;

  const _OptionListScreen({
    super.key,
    required this.title,
    required this.options,
    required this.initial,
    required this.same,
    required this.label,
    required this.leading,
  });

  @override
  State<_OptionListScreen<T>> createState() => _OptionListScreenState<T>();
}

class _OptionListScreenState<T> extends State<_OptionListScreen<T>> {
  late T _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: widget.title,
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        onSave: () {
          Haptics.confirm();
          Navigator.pop(context, _selected);
        },
      ),
      builder: (context) => [
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            for (final option in widget.options)
              OneUIGroupItem(
                leading: SizedBox(width: 24, child: Center(child: widget.leading(option))),
                title: widget.label(option),
                trailing: OneUIRadio(isSelected: widget.same(option, _selected)),
                onTap: () {
                  Haptics.select();
                  setState(() => _selected = option);
                },
              ),
          ],
        ),
      ],
    );
  }
}
