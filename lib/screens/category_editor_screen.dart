import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subpage.dart';
import '../widgets/one_ui_toast.dart';
import 'category_picker_screen.dart';
import '../core/telemetry/events.dart';
import '../core/telemetry/telemetry.dart';

/// Create or edit a custom category: name, icon and colour, with a live preview.
/// Pops with the saved [SubscriptionCategory], or nothing when cancelled or deleted.
class CategoryEditorScreen extends StatefulWidget {
  /// The custom category being edited; null creates a new one.
  final String? categoryId;

  const CategoryEditorScreen({super.key, this.categoryId});

  static Future<SubscriptionCategory?> open(BuildContext context, {String? categoryId}) {
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
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
      final picked = await CategoryPickerScreen.open(context, initialCategory: moveTo);
      if (picked == null || !mounted) return;
      moveTo = picked == category ? SubscriptionCategory.utilities : picked;
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
    HapticFeedback.mediumImpact();
    _store.deleteCustomCategory(editing.id, moveTo: moveTo);
    OneUIToast.show(context, '${editing.name} deleted');
    Navigator.pop(context);
  }

  Widget _preview() {
    final name = _trimmedName.isEmpty ? 'New category' : _trimmedName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(_icon, color: _color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: OneUITheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(OneUITheme.radiusBadge),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _color),
            ),
          ),
        ],
      ),
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

  Widget _grid<T>({
    required List<T> items,
    required bool Function(T item) selected,
    required void Function(T item) onTap,
    required Widget Function(T item, bool isSelected) build,
    required String Function(T item) label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            Semantics(
              button: true,
              selected: selected(item),
              label: label(item),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => onTap(item));
                },
                child: build(item, selected(item)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconGrid() => _grid<IconData>(
        items: supportedSubscriptionIcons,
        selected: (icon) => icon == _icon,
        onTap: (icon) => _icon = icon,
        label: (icon) => 'Icon',
        build: (icon, isSelected) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? _color.withValues(alpha: 0.22) : OneUITheme.surfaceCardHighlight,
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? _color : Colors.transparent, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: isSelected ? _color : OneUITheme.textSecondary),
        ),
      );

  Widget _colorGrid() => _grid<Color>(
        items: OneUITheme.categorySwatches,
        selected: (color) => color.toARGB32() == _color.toARGB32(),
        onTap: (color) => _color = color,
        label: (color) => 'Colour',
        build: (color, isSelected) => AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? OneUITheme.textPrimary : Colors.transparent, width: 3),
          ),
          child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
        ),
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
        _preview(),
        OneUISection(title: 'Name', child: _nameField()),
        OneUISection(title: 'Icon', child: _iconGrid()),
        OneUISection(title: 'Colour', child: _colorGrid()),
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
