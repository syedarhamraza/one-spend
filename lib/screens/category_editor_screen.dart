import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
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
    Haptics.warn();
    _store.deleteCustomCategory(editing.id, moveTo: moveTo);
    OneUIToast.show(context, '${editing.name} deleted');
    Navigator.pop(context);
  }

  /// The category as it'll look: a big icon circle in its colour, with the name under it
  /// (like the photo on a Samsung contact).
  Widget _hero() {
    final empty = _trimmedName.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 2)],
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(_icon, key: ValueKey(_icon), color: OneUIBrandCatalog.foregroundOn(_color), size: 46),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            empty ? 'New category' : _trimmedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: empty ? OneUITheme.textTertiary : OneUITheme.textPrimary,
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

  /// How many colours the row shows before "More colours", like Samsung Calendar.
  static const int _rowColors = 6;
  bool _allColors = false;

  bool _isColor(Color c) => c.toARGB32() == _color.toARGB32();

  Widget _colorDot(Color color, {double size = 40}) {
    final selected = _isColor(color);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Colour',
      child: GestureDetector(
        onTap: () {
          Haptics.select();
          setState(() => _color = color);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? OneUITheme.textPrimary : Colors.transparent, width: 2.5),
          ),
          child: selected ? Icon(Icons.check_rounded, color: OneUIBrandCatalog.foregroundOn(color), size: 20) : null,
        ),
      ),
    );
  }

  /// One row of colours and a "more" circle that opens the full palette.
  Widget _colors() {
    final swatches = OneUITheme.categorySwatches;
    final row = swatches.take(_rowColors).toList();
    // A colour picked from the full palette takes the row's last place, so it stays visible.
    if (!row.any(_isColor)) row[_rowColors - 1] = _color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final c in row) _colorDot(c),
              Semantics(
                button: true,
                label: _allColors ? 'Fewer colours' : 'More colours',
                child: GestureDetector(
                  onTap: () {
                    Haptics.tap();
                    setState(() => _allColors = !_allColors);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Color(0xFFF07167),
                          Color(0xFFFFD166),
                          Color(0xFF00C05A),
                          Color(0xFF34AADC),
                          Color(0xFF7E57C2),
                          Color(0xFFF07167),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: OneUITheme.cardColor, shape: BoxShape.circle),
                      child: AnimatedRotation(
                        turns: _allColors ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more_rounded, size: 20, color: OneUITheme.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _allColors
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [for (final c in swatches) _colorDot(c, size: 36)],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  /// The icons, the chosen one filled with the category colour.
  Widget _icons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (final icon in supportedSubscriptionIcons)
            Semantics(
              button: true,
              selected: icon == _icon,
              label: 'Icon',
              child: GestureDetector(
                onTap: () {
                  Haptics.select();
                  setState(() => _icon = icon);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: icon == _icon ? _color : OneUITheme.surfaceCardHighlight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 22,
                    color: icon == _icon ? OneUIBrandCatalog.foregroundOn(_color) : OneUITheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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
        OneUISection(title: 'Colour', child: _colors()),
        OneUISection(title: 'Icon', child: _icons()),
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
