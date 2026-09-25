import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUINavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const OneUINavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

class OneUIFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<OneUINavItem> items;

  const OneUIFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.navbar3dEffect ||
            OneUIEffectsController.instance.floating3dEffect;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: OneUITheme.navbarShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: OneUITheme.blurSigma,
                        sigmaY: OneUITheme.blurSigma,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: 60,
                        decoration: BoxDecoration(
                          color: is3d ? null : OneUITheme.floatingColor,
                          gradient: is3d ? OneUITheme.floatingGradient : null,
                          borderRadius: BorderRadius.circular(34),
                          border: OneUITheme.floatingBorder,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final isSelected = index == currentIndex;

                            return SizedBox(
                              width: 74,
                              child: GestureDetector(
                                onTap: () => onTap(index),
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  height: double.infinity,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (is3d
                                            ? OneUITheme.navbar3dActivePill
                                            : OneUITheme.surfacePillActive)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected ? item.activeIcon : item.inactiveIcon,
                                        size: 21,
                                        color: isSelected
                                            ? OneUITheme.textPrimary
                                            : (is3d
                                                ? OneUITheme.navbar3dInactiveIcon
                                                : OneUITheme.textSecondary),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          letterSpacing: -0.2,
                                          color: isSelected
                                              ? OneUITheme.textPrimary
                                              : (is3d
                                                  ? OneUITheme.navbar3dInactiveText
                                                  : OneUITheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
