import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';

class OneUIFloatingActionBarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const OneUIFloatingActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
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
        final is3d = OneUIEffectsController.instance.navbar3dEffect || OneUIEffectsController.instance.floating3dEffect;

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
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 0.8,
                            ),
                          )
                        : BoxDecoration(
                            color: OneUITheme.floatingColor,
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 0.8,
                            ),
                          ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: items.map((item) {
                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              item.onTap();
                            },
                            borderRadius: BorderRadius.circular(26),
                            splashColor: Colors.white.withValues(alpha: 0.08),
                            highlightColor: Colors.white.withValues(alpha: 0.04),
                            child: SizedBox(
                              width: 68,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 21,
                                    color: item.color ?? OneUITheme.textPrimary,
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
                                      color: item.color ?? OneUITheme.textPrimary,
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
