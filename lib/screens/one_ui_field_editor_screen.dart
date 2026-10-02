import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_bottom_vignette.dart';

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

  /// ISO code; its symbol prefixes number fields unless [prefixText] is given.
  final String currency;

  const OneUIFieldEditorScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.type,
    required this.initialValue,
    this.prefixText,
    this.hintText,
    this.currency = 'USD',
  });

  static Future<T?> open<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required FieldEditorType type,
    required T initialValue,
    String? prefixText,
    String? hintText,
    String currency = 'USD',
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
      if (widget.type == FieldEditorType.number && widget.initialValue is num) {
        final num val = widget.initialValue as num;
        final initialString = val == val.roundToDouble()
            ? val.toInt().toString()
            : val.toString();
        _textController = TextEditingController(text: initialString);
      } else {
        final initialString = widget.initialValue?.toString() ?? '';
        _textController = TextEditingController(text: initialString);
      }
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
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
        final normalized = _textController.text.trim().replaceAll(',', '.');
        final parsed = double.tryParse(normalized);
        result = parsed != null ? parsed.clamp(0.0, SubscriptionStore.maxAmount) : (widget.initialValue as double? ?? 0.0);
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

          // Progressive OLED Bottom Vignette Scrim
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          // Floating "Cancel | Save" Pill right above keyboard (matching One UI specification)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _textController,
                    builder: (context, _) {
                      bool canSave = true;
                      if (widget.type == FieldEditorType.text) {
                        final text = _textController.text.trim();
                        canSave = text.isNotEmpty && text.length <= 100;
                      } else if (widget.type == FieldEditorType.notes) {
                        canSave = _textController.text.length <= 500;
                      } else if (widget.type == FieldEditorType.number) {
                        final parsed = double.tryParse(_textController.text.trim().replaceAll(',', '.'));
                        canSave = parsed != null && parsed >= 0 && parsed <= SubscriptionStore.maxAmount;
                      }
                      return OneUIFloatingCancelSavePill(
                        onCancel: _onCancel,
                        onSave: _onSave,
                        canSave: canSave,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent() {
    switch (widget.type) {
      case FieldEditorType.text:
        return Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.fieldBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: TextField(
            controller: _textController,
            autofocus: true,
            maxLength: 100,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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
            borderRadius: OneUITheme.fieldBorderRadius,
            border: OneUITheme.cardBorder,
            boxShadow: OneUITheme.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: Row(
            children: [
              Text(
                widget.prefixText ?? currencyPrefix(widget.currency).trim(),
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
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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
                              switch (cycle) {
                                BillingCycle.monthly => 'Billed once every month (12x/yr)',
                                BillingCycle.yearly => 'Billed once every year (1x/yr)',
                                BillingCycle.weekly => 'Billed every week (52x/yr)',
                                BillingCycle.quarterly => 'Billed every 3 months (4x/yr)',
                              },
                              style: const TextStyle(fontSize: 12.5, color: OneUITheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? OneUITheme.accentBlue : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? OneUITheme.accentBlue
                                : Colors.white.withValues(alpha: 0.3),
                            width: isSelected ? 0 : 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
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
            children: SubscriptionCategory.all.map((cat) {
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
        final dateFormat = OneUIDateFormats.fullMonthDayYear;
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
