import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';

/// Samsung One UI 9 "Filter by category" Modal Bottom Sheet matching Samsung One UI Reference 1:1.
class OneUIFilterBottomSheet extends StatefulWidget {
  final SubscriptionCategory? initialCategory;
  final void Function(SubscriptionCategory? category)? onApply;

  const OneUIFilterBottomSheet({
    super.key,
    required this.initialCategory,
    this.onApply,
  });

  /// Helper static method to display the modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required SubscriptionCategory? currentCategory,
    required ValueChanged<SubscriptionCategory?> onCategorySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (ctx) => OneUIFilterBottomSheet(
        initialCategory: currentCategory,
        onApply: onCategorySelected,
      ),
    );
  }

  @override
  State<OneUIFilterBottomSheet> createState() => _OneUIFilterBottomSheetState();
}

class _OneUIFilterBottomSheetState extends State<OneUIFilterBottomSheet> {
  late SubscriptionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + keyboardInset),
            child: Material(
              color: Colors.transparent,
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                elevation: OneUIGlassElevation.modal,
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Sheet Title (Matching Samsung One UI "Sort by")
                const Text(
                  'Filter by category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Scrollable category options matching Samsung One UI clean radio list
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.46,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "All categories" option
                        _buildRadioRow(
                          label: 'All categories',
                          isSelected: _selectedCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                        ),

                        // Categories list
                        ...SubscriptionCategory.all.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return _buildRadioRow(
                            label: cat.label,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Footer: "Cancel  |  Done" (Matching Screenshot 1:1)
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
                          widget.onApply?.call(_selectedCategory);
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

  Widget _buildRadioRow({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            // Samsung One UI 9 Custom Radio Button
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
                label,
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
  }
}
