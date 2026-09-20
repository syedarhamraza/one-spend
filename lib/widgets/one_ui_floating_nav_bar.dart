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
        final is3d = OneUIEffectsController.instance.navbar3dEffect;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: 60,
              decoration: is3d
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          OneUITheme.navbar3dBarTop,
                          OneUITheme.navbar3dBarBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.50),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: OneUITheme.floatingColor,
                      borderRadius: BorderRadius.circular(34),
                    ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        height: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 0),
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
        );
      },
    );
  }
}
