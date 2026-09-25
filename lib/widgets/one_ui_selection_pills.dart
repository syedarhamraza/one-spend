import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

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
        final is3d = OneUIEffectsController.instance.floating3dEffect;
        final isAllSelected = totalCount > 0 && selectedCount == totalCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Pill: Select Counter & Select All toggle
            GestureDetector(
              onTap: onToggleSelectAll,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: OneUITheme.floatingShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: OneUITheme.blurSigma,
                      sigmaY: OneUITheme.blurSigma,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: is3d ? null : OneUITheme.floatingColor,
                        gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: is3d ? 0.12 : 0.08),
                          width: 0.85,
                        ),
                      ),
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
                ),
              ),
            ),

            // Right Pill: Cancel button
            GestureDetector(
              onTap: onCancel,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: OneUITheme.floatingShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: OneUITheme.blurSigma,
                      sigmaY: OneUITheme.blurSigma,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: is3d ? null : OneUITheme.floatingColor,
                        gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: is3d ? 0.12 : 0.08),
                          width: 0.85,
                        ),
                      ),
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
