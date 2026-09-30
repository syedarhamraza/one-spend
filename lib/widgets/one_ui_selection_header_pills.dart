import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

/// Frosted floating capsule shared by the selection header pills.
class _SelectionHeaderCapsule extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _SelectionHeaderCapsule({required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final is3d = OneUIEffectsController.instance.floating3dEffect;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: OneUITheme.floatingShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: OneUITheme.blurSigma, sigmaY: OneUITheme.blurSigma),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 42,
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(24),
              border: OneUITheme.floatingBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Selection-mode header pill (leading): a select-all circle plus the selected count.
/// Pass to `OneUICollapsibleHeaderDelegate.selectionLeading`.
class OneUISelectionCountPill extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onToggleSelectAll;

  const OneUISelectionCountPill({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount > 0 && selectedCount == totalCount;
    return Semantics(
      button: true,
      label: allSelected ? 'Deselect all' : 'Select all',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onToggleSelectAll();
        },
        child: _SelectionHeaderCapsule(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allSelected ? const Color(0xFF2C69FF) : Colors.transparent,
                  border: Border.all(
                    color: allSelected ? const Color(0xFF2C69FF) : Colors.white.withValues(alpha: 0.55),
                    width: 2.0,
                  ),
                ),
                child: allSelected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
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
    );
  }
}

/// Selection-mode header pill (trailing): "Cancel" exits selection mode.
/// Pass to `OneUICollapsibleHeaderDelegate.selectionTrailing`.
class OneUISelectionCancelPill extends StatelessWidget {
  final VoidCallback onCancel;

  const OneUISelectionCancelPill({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onCancel();
      },
      child: const _SelectionHeaderCapsule(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          'Cancel',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: OneUITheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
