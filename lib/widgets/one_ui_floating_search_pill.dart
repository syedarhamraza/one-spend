import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIFloatingSearchPill extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;

  const OneUIFloatingSearchPill({
    super.key,
    this.hintText = 'Search',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: OneUITheme.floatingShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: OneUITheme.blurSigma,
                  sigmaY: OneUITheme.blurSigma,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  decoration: BoxDecoration(
                    color: is3d ? null : OneUITheme.floatingColor,
                    gradient: is3d ? OneUITheme.floatingGradient : null,
                    borderRadius: BorderRadius.circular(26),
                    border: OneUITheme.floatingBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: is3d
                          ? OneUITheme.navbar3dInactiveIcon
                          : OneUITheme.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hintText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: is3d
                              ? OneUITheme.navbar3dInactiveText
                              : OneUITheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
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
