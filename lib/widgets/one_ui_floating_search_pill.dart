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

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 52,
            decoration: BoxDecoration(
              color: is3d ? null : OneUITheme.floatingColor,
              gradient: is3d ? OneUITheme.floatingGradient : null,
              borderRadius: BorderRadius.circular(26),
              border: OneUITheme.floatingBorder,
              boxShadow: OneUITheme.floatingShadow,
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
                const Icon(
                  Icons.mic_rounded,
                  color: OneUITheme.textPrimary,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
