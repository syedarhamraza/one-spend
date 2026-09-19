import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIHeroCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color badgeColor;
  final Widget? bottomContent;

  const OneUIHeroCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeColor,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OneUITheme.surfaceCard,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.subtleBorder,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Icon Badge (Matches Teal Circle in Screenshot 3)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),

          // Title (Matches "Color filter" in Screenshot 3)
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle / Description (Matches description in Screenshot 3)
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w400,
              color: OneUITheme.textSecondary,
            ),
          ),

          if (bottomContent != null) ...[
            const SizedBox(height: 16),
            bottomContent!,
          ],
        ],
      ),
    );
  }
}
