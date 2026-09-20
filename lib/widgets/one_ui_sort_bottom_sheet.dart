import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI 9 "Sort by" Modal Bottom Sheet matching Reference Screenshot 1:1.
/// Features:
/// - "Sort by" bold title.
/// - One UI blue radio selector rows with circular inner dot.
/// - Subtle horizontal divider.
/// - "Group by date" row with One UI switch toggle.
/// - Footer: "Cancel  |  Done" in pure white separated by a subtle vertical divider.
class OneUISortBottomSheet extends StatefulWidget {
  final SubscriptionSortOption initialOption;
  final bool initialGroupByDate;
  final void Function(SubscriptionSortOption option, bool groupByDate)? onApply;

  const OneUISortBottomSheet({
    super.key,
    required this.initialOption,
    required this.initialGroupByDate,
    this.onApply,
  });

  /// Helper static method to display the modal bottom sheet
  static Future<void> show(BuildContext context) {
    final store = SubscriptionStore.instance;
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => OneUISortBottomSheet(
        initialOption: store.sortOption,
        initialGroupByDate: store.groupByDate,
        onApply: (option, groupByDate) {
          store.setSortOption(option);
          store.setGroupByDate(groupByDate);
        },
      ),
    );
  }

  @override
  State<OneUISortBottomSheet> createState() => _OneUISortBottomSheetState();
}

class _OneUISortBottomSheetState extends State<OneUISortBottomSheet> {
  late SubscriptionSortOption _selectedOption;
  late bool _groupByDate;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialOption;
    _groupByDate = widget.initialGroupByDate;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboardInset),
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: is3d ? null : const Color(0xFF212123),
                  gradient: is3d
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF262628),
                            Color(0xFF1C1C1E),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  border: is3d
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.85,
                        )
                      : null,
                  boxShadow: is3d
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : const [],
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Sheet Title
                const Text(
                  'Sort by',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Radio option list
                ...SubscriptionSortOption.values.map((option) {
                  final isSelected = _selectedOption == option;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOption = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                      child: Row(
                        children: [
                          // Samsung One UI Custom Blue Radio Button
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2C69FF) // Samsung Vivid Blue
                                    : const Color(0xFF5E5E62), // Neutral Gray
                                width: isSelected ? 2.0 : 1.6,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isSelected
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2C69FF),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: OneUITheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 6),
                // Horizontal subtle divider
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 28,
                  thickness: 0.8,
                ),

                // "Group by date" switch row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Group by date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: OneUITheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Switch.adaptive(
                        value: _groupByDate,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF2C69FF),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                        inactiveThumbColor: Colors.white70,
                        onChanged: (val) {
                          setState(() {
                            _groupByDate = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Footer: "Cancel  |  Done"
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
                    Container(
                      width: 1,
                      height: 18,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          widget.onApply?.call(_selectedOption, _groupByDate);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: OneUITheme.textPrimary, // Clean White text matching Screenshot 1:1
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }
}
