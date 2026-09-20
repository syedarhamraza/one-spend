import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

class OneUIFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  const OneUIFAB({
    super.key,
    this.icon = Icons.add_rounded,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: color ?? OneUITheme.accentGreen,
            shape: BoxShape.circle,
            border: is3d
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.8,
                  )
                : null,
            boxShadow: is3d ? OneUITheme.fabShadow : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              splashColor: Colors.white.withValues(alpha: 0.2),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}
