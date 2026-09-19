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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: OneUITheme.floatingColor,
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: OneUITheme.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hintText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: OneUITheme.textSecondary,
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
  }
}
