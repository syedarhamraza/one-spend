import 'package:flutter/material.dart';
import '../features/appearance/presentation/one_ui_effects_controller.dart';

export '../features/appearance/presentation/one_ui_effects_controller.dart';

/// Samsung One UI 9 Design System Tokens and Theme
class OneUITheme {
  // --- Pure OLED Black & Neutral Charcoal Surfaces ---
  static const Color surfacePitch = Color(0xFF000000); // True AMOLED Black
  static const Color surfaceCard = Color(0xFF1C1C1E); // Neutral Dark Charcoal Card Surface
  static const Color surfaceCardHighlight = Color(0xFF262628);
  static const Color surfacePill = Color(0xFF2C2C2E); // Distinct One UI Gray Floating Capsule Surface
  static const Color surfacePillActive = Color(0xFF3E3E42); // Active Tab Capsule
  static const Color surfaceInset = Color(0x0AFFFFFF); // Panel nested inside a card (with innerBorderRadius)
  static const Color surfaceButtonLight = Color(0xFFB5B5BA); // Light grey pill button (Digital Wellbeing tip cards)
  static const Color textOnLight = Color(0xFF0E0E10); // Label on surfaceButtonLight
  static const Color surfacePillBorder = Colors.transparent;

  // --- 3D Floating Navbar Tokens (Matching Samsung One UI Phone Dialer Screenshot 1:1) ---
  static const Color navbar3dBarTop = Color(0x9935353A);
  static const Color navbar3dBarBottom = Color(0xB31E1E22);
  static const Color navbar3dActivePill = Color(0xFF3E3E42); // Smooth flat active capsule
  static const Color navbar3dInactiveIcon = Color(0xFFD4D4D8);
  static const Color navbar3dInactiveText = Color(0xFFB4B4B8);

  // --- One UI Accent Palette ---
  static const Color accentGreen = Color(0xFF00C05A); // One UI Phone / Success Green
  static const Color accentBlue = Color(0xFF5390F5); // One UI Action Blue
  static const Color accentRed = Color(0xFFF07167); // One UI Alert Salmon
  static const Color accentTeal = Color(0xFF48B5A0); // One UI Routine Teal Badge
  static const Color accentPurple = Color(0xFF7E57C2);
  static const Color accentAmber = Color(0xFFF4A261);
  static const Color accentOrange = Color(0xFFFB8C00);

  /// Colours a custom category can use: distinct on black, in the donut and as chip tints.
  static const List<Color> categorySwatches = [
    Color(0xFFF07167), // Coral
    Color(0xFFFB8C00), // Orange
    Color(0xFFF4A261), // Amber
    Color(0xFFFFD166), // Yellow
    Color(0xFF00C05A), // Green
    Color(0xFF48B5A0), // Teal
    Color(0xFF34AADC), // Sky
    Color(0xFF5390F5), // Blue
    Color(0xFF7E57C2), // Purple
    Color(0xFFB388FF), // Lavender
    Color(0xFFEF6C9A), // Pink
    Color(0xFFA1887F), // Mocha
  ];

  // --- Ambient Glow (hero cards) ---
  static const Color glowDefault = Color(0xFF0381FE); // Samsung Signature Blue

  /// Turns a brand or category colour into a glow that reads on black: greys, near-black
  /// and near-white fall back to [glowDefault]; others get a mid lightness and enough saturation.
  static Color glowTint(Color color) {
    final hsl = HSLColor.fromColor(color);
    if (hsl.saturation < 0.18 || hsl.lightness < 0.12 || hsl.lightness > 0.92) return glowDefault;
    return hsl
        .withLightness(hsl.lightness.clamp(0.45, 0.62))
        .withSaturation(hsl.saturation < 0.55 ? 0.55 : hsl.saturation)
        .toColor();
  }

  // --- High-Legibility Typography Colors ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA4);
  static const Color textTertiary = Color(0xFF6A6A70);

  // --- Radii & Geometry (One UI Curved Form Factor) ---
  static const double radiusPill = 34.0;
  static const double radiusCard = 26.0;
  static const double radiusInner = 20.0;
  static const double radiusBadge = 16.0;

  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get innerBorderRadius => BorderRadius.circular(radiusInner);

  /// Single-line text fields are pills; multi-line ones (notes) keep [cardBorderRadius].
  static BorderRadius get fieldBorderRadius => pillBorderRadius;

  // --- Dynamic Card & Floating Properties ---
  static Color get cardColor => OneUIEffectsController.instance.cardColor;
  static Border? get cardBorder => OneUIEffectsController.instance.cardBorder;
  static List<BoxShadow> get cardShadow => OneUIEffectsController.instance.cardShadow;
  static Color get floatingColor => OneUIEffectsController.instance.floatingColor;
  static Gradient? get floatingGradient => OneUIEffectsController.instance.floatingGradient;
  static Border? get floatingBorder => OneUIEffectsController.instance.floatingBorder;
  static List<BoxShadow> get floatingShadow => OneUIEffectsController.instance.floatingShadow;
  static List<BoxShadow> get navbarShadow => OneUIEffectsController.instance.navbarShadow;
  static List<BoxShadow> get fabShadow => OneUIEffectsController.instance.fabShadow;
  static double get blurSigma => OneUIEffectsController.instance.blurSigma;

  // --- Card Studio Properties ---
  static SubscriptionCardBackground get cardBackground => OneUIEffectsController.instance.cardBackground;
  static Color get customCardBackgroundColor => OneUIEffectsController.instance.customCardBackgroundColor;
  static SubscriptionCardLayout get cardLayout => OneUIEffectsController.instance.cardLayout;
  static SubscriptionBrandAccent get brandAccent => OneUIEffectsController.instance.brandAccent;
  static SubscriptionPriceMode get priceMode => OneUIEffectsController.instance.priceMode;
  static SubscriptionRenewalBadgeMode get renewalBadgeMode => OneUIEffectsController.instance.renewalBadgeMode;
  static PaymentBadgeStyle get paymentBadgeStyle => OneUIEffectsController.instance.paymentBadgeStyle;
  static UpcomingSectionStyle get upcomingStyle => OneUIEffectsController.instance.upcomingStyle;
  static bool get showCycleProgress => OneUIEffectsController.instance.showCycleProgress;
  static bool get showPaymentMethodChip => OneUIEffectsController.instance.showPaymentMethodChip;
  static bool get showCategoryChip => OneUIEffectsController.instance.showCategoryChip;
  static bool get showDailyEquivalent => OneUIEffectsController.instance.showDailyEquivalent;

  // Backward compatibility
  static Border? get subtleBorder => null;

  // --- ThemeData ---
  static ThemeData? _cachedDarkTheme;

  static ThemeData get darkTheme {
    return _cachedDarkTheme ??= ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfacePitch,
      primaryColor: accentBlue,
      canvasColor: surfacePitch,
      cardColor: cardColor,
      fontFamily: 'Roboto', // Clean sans-serif resembling Samsung One
      colorScheme: const ColorScheme.dark(
        surface: surfacePitch,
        primary: accentBlue,
        secondary: accentGreen,
        error: accentRed,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 0.8,
      ),
    );
  }
}
