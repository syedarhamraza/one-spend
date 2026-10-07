import 'package:flutter/material.dart';

import '../theme/one_ui_theme.dart';

/// The card at the top of the category pages: the icon in a tinted squircle on the left,
/// a bold title and a grey line under it. Colour and icon changes animate.
///
/// Used by Settings › Categories (a summary), the category picker (the selected category)
/// and the category editor (the category being made).
class OneUICategoryHero extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  /// Greys the title, e.g. while a new category has no name yet.
  final bool placeholderTitle;

  const OneUICategoryHero({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.placeholderTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: OneUITheme.cardColor,
          borderRadius: OneUITheme.cardBorderRadius,
          border: OneUITheme.cardBorder,
          boxShadow: OneUITheme.cardShadow,
        ),
        child: child,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Icon(icon, key: ValueKey(icon), color: color, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: placeholderTitle ? OneUITheme.textTertiary : OneUITheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: OneUITheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
