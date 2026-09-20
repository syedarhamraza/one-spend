import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Item definition for the Samsung One UI Floating Expanded Menu.
class OneUIFloatingMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const OneUIFloatingMenuItem({
    required this.label,
    this.icon,
    required this.onTap,
  });
}

/// Samsung One UI Floating Expanded Menu matching Screenshot 3 1:1.
/// Features:
/// - Strictly transparent background barrier (NO dimming / NO dark overlay).
/// - Displays directly ON TOP OF (overlapping & covering) the floating pill.
/// - Exact same design tokens as the floating pills and buttons:
///   stadium curvature (26 radius), 3D gradient/border/shadow, OneUITheme tokens.
/// - Snappy top-right scale and fade transition.
class OneUIFloatingMenu {
  /// Global state tracking whether the expanded menu is currently active.
  /// Used by headers and floating action pills to gracefully fade out their
  /// anchor during menu display, preventing any corner slivers or background peeking.
  static final ValueNotifier<bool> isOpen = ValueNotifier<bool>(false);

  static Future<void> show({
    required BuildContext context,
    required List<OneUIFloatingMenuItem> items,
    GlobalKey? anchorKey,
    double fallbackTop = 54.0,
    double? fallbackBottom,
    double fallbackRight = 16.0,
    double width = 224.0,
  }) async {
    double? top = fallbackTop;
    double? bottom = fallbackBottom;
    double right = fallbackRight;
    bool isBottomAnchor = false;

    if (anchorKey?.currentContext != null) {
      final box = anchorKey!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final origin = box.localToGlobal(Offset.zero);
        final screenSize = MediaQuery.of(context).size;
        right = (screenSize.width - (origin.dx + box.size.width)).clamp(0.0, 50.0);

        if (origin.dy > screenSize.height * 0.5) {
          isBottomAnchor = true;
          bottom = (screenSize.height - origin.dy) + 8.0;
          top = null;
        } else {
          isBottomAnchor = false;
          top = origin.dy;
          bottom = null;
        }
      }
    } else if (fallbackBottom != null) {
      isBottomAnchor = true;
      top = null;
    }

    isOpen.value = true;
    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss menu',
        barrierColor: Colors.transparent, // STRICTLY TRANSPARENT - NO DARK OVERLAY
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, anim1, anim2) {
          return _OneUIFloatingMenuContent(
            items: items,
            top: top,
            bottom: bottom,
            right: right,
            width: width,
          );
        },
        transitionBuilder: (ctx, anim, secondaryAnim, child) {
          final isForward = anim.status == AnimationStatus.forward ||
              anim.status == AnimationStatus.completed;

          // Samsung One UI signature fluid deceleration curve
          final scaleCurve = isForward
              ? const Cubic(0.16, 1.0, 0.3, 1.0)
              : Curves.easeInCubic;

          // Rapid crisp fade in on open (solid within 110ms); gentle fade out on close
          final opacityCurve = isForward
              ? const Interval(0.0, 0.45, curve: Curves.easeOut)
              : const Interval(0.15, 1.0, curve: Curves.easeIn);

          final scaleAnimation = Tween<double>(
            begin: 0.80,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: scaleCurve));

          final opacityAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: opacityCurve));

          return FadeTransition(
            opacity: opacityAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: isBottomAnchor
                  ? const Alignment(0.90, 0.92)
                  : const Alignment(0.90, -0.92),
              child: child,
            ),
          );
        },
      );
    } finally {
      isOpen.value = false;
    }
  }
}

class _OneUIFloatingMenuContent extends StatelessWidget {
  final List<OneUIFloatingMenuItem> items;
  final double? top;
  final double? bottom;
  final double right;
  final double width;

  const _OneUIFloatingMenuContent({
    required this.items,
    this.top,
    this.bottom,
    required this.right,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final is3d = OneUIEffectsController.instance.floating3dEffect;

        return Stack(
          children: [
            Positioned(
              top: top,
              bottom: bottom,
              right: right,
              width: width,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: is3d
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        )
                      : const BoxDecoration(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: OneUITheme.blurSigma,
                        sigmaY: OneUITheme.blurSigma,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: is3d ? null : OneUITheme.floatingColor,
                          gradient: is3d ? OneUIEffectsController.instance.floatingGradient : null,
                          borderRadius: BorderRadius.circular(26),
                          border: is3d ? OneUIEffectsController.instance.floatingBorder : null,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            item.onTap();
                          },
                          borderRadius: BorderRadius.circular(18),
                          splashColor: Colors.white.withValues(alpha: 0.08),
                          highlightColor: Colors.white.withValues(alpha: 0.04),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  Icon(item.icon, size: 20, color: OneUITheme.textPrimary),
                                  const SizedBox(width: 14),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: OneUITheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    ],
        );
      },
    );
  }
}
