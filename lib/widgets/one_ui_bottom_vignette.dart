import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI Bottom Vignette (Edge-to-Edge Progressive Darkening Scrim).
///
/// Smoothly dissolves scrolling list items and background surfaces into pitch black
/// as they reach the bottom of the screen, creating depth and preventing visual clutter
/// behind floating navigation bars, scroll-to-top buttons, and action pills.
class OneUIBottomVignette extends StatelessWidget {
  /// Custom height of the vignette. Defaults to safeArea.bottom + 170.0.
  final double? height;

  /// Whether the vignette is visible. Allows smooth animated fades during search/modal transitions.
  final bool isVisible;

  const OneUIBottomVignette({
    super.key,
    this.height,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final isEnabled = OneUIEffectsController.instance.bottomVignetteEffect && isVisible;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        final effectiveHeight = height ?? (bottomPadding + 170.0);

        return IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            opacity: isEnabled ? 1.0 : 0.0,
            child: RepaintBoundary(
              child: SizedBox(
                height: effectiveHeight,
                width: double.infinity,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x0A000000), // ~4% black
                        Color(0x2E000000), // ~18% black
                        Color(0x6E000000), // ~43% black
                        Color(0xB8000000), // ~72% black
                        Color(0xF0000000), // ~94% black
                        Color(0xFF000000), // 100% OLED pitch black
                      ],
                      stops: [0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0],
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
