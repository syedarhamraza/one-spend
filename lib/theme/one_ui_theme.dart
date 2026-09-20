import 'package:flutter/material.dart';

/// Interactive Dynamic Controller for 3D Elevation, Shadows, and Frosted Glass Blur
class OneUIEffectsController extends ChangeNotifier {
  static final OneUIEffectsController instance = OneUIEffectsController._internal();
  factory OneUIEffectsController() => instance;
  OneUIEffectsController._internal();

  // 3D Effect Toggles
  bool _card3dEffect = false;       // All cards across UI (disabled by default matching One UI settings)
  bool _floating3dEffect = true;    // Floating pills, buttons, and navbar
  bool _navbar3dEffect = true;      // 3D tactile navbar matching One UI phone dialer screenshot

  bool get card3dEffect => _card3dEffect;
  set card3dEffect(bool val) {
    if (_card3dEffect != val) {
      _card3dEffect = val;
      notifyListeners();
    }
  }

  bool get floating3dEffect => _floating3dEffect;
  set floating3dEffect(bool val) {
    if (_floating3dEffect != val) {
      _floating3dEffect = val;
      notifyListeners();
    }
  }

  bool get navbar3dEffect => _navbar3dEffect;
  set navbar3dEffect(bool val) {
    if (_navbar3dEffect != val) {
      _navbar3dEffect = val;
      notifyListeners();
    }
  }

  // Compatibility getter
  double get depthIntensity => 1.2;

  // Dynamic Card Properties
  Color get cardColor => _card3dEffect ? const Color(0xFF202127) : const Color(0xFF1B1C21);
  Border? get cardBorder => _card3dEffect
      ? Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.85,
        )
      : null;
  List<BoxShadow> get cardShadow => _card3dEffect
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ]
      : const [];

  // Dynamic Floating Elements Properties
  Color get floatingColor => _floating3dEffect ? const Color(0xFF24252A) : const Color(0xFF2C2D34);

  Gradient? get floatingGradient => _floating3dEffect
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF28292E),
            Color(0xFF1F2023),
          ],
        )
      : null;

  Border? get floatingBorder => _floating3dEffect
      ? Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        )
      : null;

  List<BoxShadow> get floatingShadow => _floating3dEffect
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ]
      : const [];

  List<BoxShadow> get fabShadow => _floating3dEffect
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: OneUITheme.accentGreen.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
      : const [];

  double get blurSigma => 0.0;

  // Backward compatibility
  Border? get subtleBorder => null;
}

/// Samsung One UI 9 Design System Tokens and Theme
class OneUITheme {
  // --- Pure OLED Black Surfaces ---
  static const Color surfacePitch = Color(0xFF000000); // True AMOLED Black
  static const Color surfaceCard = Color(0xFF1B1C21); // Flat Dark Card Surface
  static const Color surfaceCardHighlight = Color(0xFF24252B);
  static const Color surfacePill = Color(0xFF2C2D34); // Distinct One UI Gray Floating Capsule Surface
  static const Color surfacePillActive = Color(0xFF42444E); // Active Tab Capsule
  static const Color surfacePillBorder = Colors.transparent;

  // --- 3D Floating Navbar Tokens (Matching Samsung One UI Phone Dialer Screenshot 1:1) ---
  static const Color navbar3dBarTop = Color(0xFF28292E);
  static const Color navbar3dBarBottom = Color(0xFF1F2023);
  static const Color navbar3dActivePill = Color(0xFF3D3F44); // Smooth flat active capsule
  static const Color navbar3dInactiveIcon = Color(0xFFDCDCE0);
  static const Color navbar3dInactiveText = Color(0xFFBEBEC4);

  // --- One UI Accent Palette ---
  static const Color accentGreen = Color(0xFF00C05A); // One UI Phone / Success Green
  static const Color accentBlue = Color(0xFF5390F5); // One UI Action Blue
  static const Color accentRed = Color(0xFFF07167); // One UI Alert Salmon
  static const Color accentTeal = Color(0xFF48B5A0); // One UI Routine Teal Badge
  static const Color accentPurple = Color(0xFF7E57C2);
  static const Color accentAmber = Color(0xFFF4A261);

  // --- High-Legibility Typography Colors ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9EA6);
  static const Color textTertiary = Color(0xFF6A6A70);

  // --- Radii & Geometry (One UI Curved Form Factor) ---
  static const double radiusPill = 34.0;
  static const double radiusCard = 26.0;
  static const double radiusInner = 20.0;
  static const double radiusBadge = 16.0;

  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get innerBorderRadius => BorderRadius.circular(radiusInner);

  // --- Dynamic Card & Floating Properties ---
  static Color get cardColor => OneUIEffectsController.instance.cardColor;
  static Border? get cardBorder => OneUIEffectsController.instance.cardBorder;
  static List<BoxShadow> get cardShadow => OneUIEffectsController.instance.cardShadow;
  static Color get floatingColor => OneUIEffectsController.instance.floatingColor;
  static Gradient? get floatingGradient => OneUIEffectsController.instance.floatingGradient;
  static Border? get floatingBorder => OneUIEffectsController.instance.floatingBorder;
  static List<BoxShadow> get floatingShadow => OneUIEffectsController.instance.floatingShadow;
  static List<BoxShadow> get fabShadow => OneUIEffectsController.instance.fabShadow;
  static double get blurSigma => 0.0;

  // Backward compatibility
  static Border? get subtleBorder => null;

  // --- ThemeData ---
  static ThemeData get darkTheme {
    return ThemeData(
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
