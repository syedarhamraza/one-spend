import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// Samsung One UI Bottom Vignette (Edge-to-Edge Progressive Darkening Scrim).
///
/// Smoothly dissolves scrolling list items and background surfaces into pitch black
/// as they reach the bottom of the screen, creating depth and preventing visual clutter
/// behind floating navigation bars, scroll-to-top buttons, and action pills.
class OneUIBottomVignette extends StatelessWidget {
  /// Custom height of the vignette. Defaults to safeArea.bottom + (hasFloatingElements ? 160.0 : 44.0).
  final double? height;

  /// Whether the vignette is visible. Allows smooth animated fades during search/modal transitions.
  final bool isVisible;

  /// Whether floating elements (floating navigation bar, action bar, stadium pills, buttons)
  /// are present above this vignette.
  ///
  /// When true, renders full depth pitch-black OLED fade (height ~160px) to seamlessly dissolve
  /// scrolling items behind floating elements.
  /// When false, decreases the effect to a gentle ambient edge feathering (height ~44px, ~27% max opacity)
  /// that keeps bottom content fully visible and legible without harsh cuts.
  final bool hasFloatingElements;

  const OneUIBottomVignette({
    super.key,
    this.height,
    this.isVisible = true,
    this.hasFloatingElements = true,
  });

  static const LinearGradient normalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x0A000000), // ~4% black
      Color(0x2E000000), // ~18% black
      Color(0x6E000000), // ~43% black
      Color(0xB8000000), // ~72% black
      Color(0xFF000000), // 100% OLED pitch black
    ],
    stops: [0.0, 0.20, 0.40, 0.65, 0.85, 1.0],
  );

  static const LinearGradient decreasedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x03000000), // ~1% black
      Color(0x08000000), // ~3% black
      Color(0x14000000), // ~8% black
      Color(0x28000000), // ~16% black
      Color(0x45000000), // ~27% soft black
    ],
    stops: [0.0, 0.20, 0.40, 0.65, 0.85, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final isEnabled = OneUIEffectsController.instance.bottomVignetteEffect && isVisible;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;
        final normalHeight = bottomPadding + 160.0;
        final decreasedHeight = bottomPadding + 44.0;
        final effectiveHeight = height ?? (hasFloatingElements ? normalHeight : decreasedHeight);

        return IgnorePointer(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            opacity: isEnabled ? 1.0 : 0.0,
            child: RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                height: effectiveHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: hasFloatingElements ? normalGradient : decreasedGradient,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
