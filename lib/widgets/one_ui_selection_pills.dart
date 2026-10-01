import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';
import 'one_ui_glass_surface.dart';

/// Top floating selection pill row matching Samsung One UI Screenshots 1 & 2.
/// - Left: Stadium capsule showing selected count (`○ 2` or `○ 0`), taps to select all.
/// - Right: Stadium capsule with `Cancel`, taps to exit selection mode.
class OneUISelectionPills extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onCancel;

  const OneUISelectionPills({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleSelectAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final isAllSelected = totalCount > 0 && selectedCount == totalCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Pill: Select Counter & Select All toggle
            GestureDetector(
              onTap: onToggleSelectAll,
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAllSelected ? OneUITheme.accentBlue : Colors.transparent,
                              border: Border.all(
                                color: isAllSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                                width: 1.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isAllSelected
                                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$selectedCount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: OneUITheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // Right Pill: Cancel button
            GestureDetector(
              onTap: onCancel,
              child: OneUIGlassSurface(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: OneUITheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
