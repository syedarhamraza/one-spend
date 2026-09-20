import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_collapsible_header.dart';

enum FieldEditorType {
  text,
  number,
  category,
  billingCycle,
  date,
  reminder,
  notes,
}

/// Dedicated One UI subpage field editor matching reference Screenshot 2.
/// - Top One UI header with Back button & title.
/// - Clean rounded card input container.
/// - Floating "Cancel | Save" stadium pill right above the keyboard.
/// - System haptic feedback on actions.
class OneUIFieldEditorScreen<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final FieldEditorType type;
  final T initialValue;
  final String? prefixText;
  final String? hintText;
  final String currency;

  const OneUIFieldEditorScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.type,
    required this.initialValue,
    this.prefixText,
    this.hintText,
    this.currency = '\$',
  });

  static Future<T?> open<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required FieldEditorType type,
    required T initialValue,
    String? prefixText,
    String? hintText,
    String currency = '\$',
  }) {
    HapticFeedback.lightImpact();
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (_) => OneUIFieldEditorScreen<T>(
          title: title,
          subtitle: subtitle,
          type: type,
          initialValue: initialValue,
          prefixText: prefixText,
          hintText: hintText,
          currency: currency,
        ),
      ),
    );
  }

  @override
  State<OneUIFieldEditorScreen<T>> createState() => _OneUIFieldEditorScreenState<T>();
}

class _OneUIFieldEditorScreenState<T> extends State<OneUIFieldEditorScreen<T>> {
  late TextEditingController _textController;
  late dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    if (widget.type == FieldEditorType.text ||
        widget.type == FieldEditorType.number ||
        widget.type == FieldEditorType.notes) {
      final initialString = widget.initialValue?.toString() ?? '';
      _textController = TextEditingController(text: initialString);
    } else {
      _textController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSave() {
    HapticFeedback.mediumImpact();
    dynamic result;
    switch (widget.type) {
      case FieldEditorType.text:
      case FieldEditorType.notes:
        result = _textController.text.trim();
        break;
      case FieldEditorType.number:
        result = double.tryParse(_textController.text.trim()) ?? (widget.initialValue as double? ?? 0.0);
        break;
      case FieldEditorType.category:
      case FieldEditorType.billingCycle:
      case FieldEditorType.date:
      case FieldEditorType.reminder:
        result = _currentValue;
        break;
    }
    Navigator.pop(context, result as T);
  }

  void _onCancel() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final is3d = OneUIEffectsController.instance.floating3dEffect;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: widget.title,
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: _onCancel,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.subtitle != null) ...[
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: OneUITheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildEditorContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating "Cancel | Save" Pill right above keyboard (matching Screenshot 2)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 20,
            child: Center(
              child: _buildFloatingActionPill(is3d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionPill(bool is3d) {
    return Container(
      decoration: BoxDecoration(
        color: is3d ? null : const Color(0xE62A2A2E),
        gradient: is3d
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xF038383D),
                  Color(0xF0202024),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: is3d ? 0.18 : 0.10),
          width: 0.85,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cancel button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onCancel,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                // Subtle Vertical Divider
                Container(
                  width: 1,
                  height: 22,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                // Save button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onSave,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: OneUITheme.accentBlue,
                          letterSpacing: -0.2,
                        ),
                      ),
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

  Widget _buildEditorContent() {
    switch (widget.type) {
      case FieldEditorType.text:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: TextField(
            controller: _textController,
            autofocus: true,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: OneUITheme.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText ?? 'Enter value',
              hintStyle: const TextStyle(color: OneUITheme.textSecondary),
            ),
          ),
        );

      case FieldEditorType.number:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: [
              Text(
                widget.prefixText ?? widget.currency,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: OneUITheme.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: OneUITheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hintText ?? '0.00',
                    hintStyle: const TextStyle(color: OneUITheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        );

      case FieldEditorType.notes:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            style: const TextStyle(
              fontSize: 16,
              color: OneUITheme.textPrimary,
              height: 1.4,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText ?? 'Add notes about this subscription...',
              hintStyle: const TextStyle(color: OneUITheme.textSecondary),
            ),
          ),
        );

      case FieldEditorType.billingCycle:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          child: Column(
            children: BillingCycle.values.map((cycle) {
              final isSelected = _currentValue == cycle;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentValue = cycle;
                  });
                },
                borderRadius: OneUITheme.cardBorderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cycle.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Charged ${cycle.occurrencesPerYear} time${cycle.occurrencesPerYear == 1 ? '' : 's'} a year',
                              style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
                      else
                        Icon(Icons.radio_button_unchecked_rounded, color: Colors.white.withValues(alpha: 0.3), size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case FieldEditorType.category:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          child: Column(
            children: SubscriptionCategory.values.map((cat) {
              final isSelected = _currentValue == cat;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentValue = cat;
                  });
                },
                borderRadius: OneUITheme.cardBorderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? OneUITheme.accentBlue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          cat.icon,
                          size: 18,
                          color: isSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
                      else
                        Icon(Icons.radio_button_unchecked_rounded, color: Colors.white.withValues(alpha: 0.3), size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case FieldEditorType.reminder:
        final options = [
          {'days': 0, 'label': 'On renewal day'},
          {'days': 1, 'label': '1 day before'},
          {'days': 2, 'label': '2 days before (Recommended)'},
          {'days': 3, 'label': '3 days before'},
          {'days': 5, 'label': '5 days before'},
          {'days': 7, 'label': '1 week before'},
        ];
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          child: Column(
            children: options.map((opt) {
              final days = opt['days'] as int;
              final label = opt['label'] as String;
              final isSelected = _currentValue == days;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentValue = days;
                  });
                },
                borderRadius: OneUITheme.cardBorderRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? OneUITheme.textPrimary : OneUITheme.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
                      else
                        Icon(Icons.radio_button_unchecked_rounded, color: Colors.white.withValues(alpha: 0.3), size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );

      case FieldEditorType.date:
        final currentDate = _currentValue as DateTime;
        final dateFormat = DateFormat('MMMM dd, yyyy');
        return Container(
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
                  const Text(
                    'Renewal Date',
                    style: TextStyle(
                      fontSize: 14,
                      color: OneUITheme.textSecondary,
                    ),
                  ),
                  Text(
                    dateFormat.format(currentDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: OneUITheme.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CalendarDatePicker(
                initialDate: currentDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                onDateChanged: (newDate) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _currentValue = newDate;
                  });
                },
              ),
            ],
          ),
        );
    }
  }
}
