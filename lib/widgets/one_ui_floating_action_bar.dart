import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

class OneUIFloatingActionBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isEnabled;

  const OneUIFloatingActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isEnabled = true,
  });
}

class OneUIFloatingActionBar extends StatelessWidget {
  final List<OneUIFloatingActionBarItem> items;

  const OneUIFloatingActionBar({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: items.map((item) {
                          final itemColor = item.isEnabled
                              ? (item.color ?? OneUITheme.textPrimary)
                              : OneUITheme.textSecondary.withValues(alpha: 0.35);

                          return InkWell(
                            onTap: item.isEnabled
                                ? () {
                                    HapticFeedback.lightImpact();
                                    item.onTap();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(26),
                            splashColor: item.isEnabled ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                            highlightColor: item.isEnabled ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
                            child: SizedBox(
                              width: 68,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 21,
                                    color: itemColor,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      color: itemColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
