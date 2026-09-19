import 'package:flutter/material.dart';

/// Interactive Dynamic Controller for 3D Elevation, Shadows, and Frosted Glass Blur
class OneUIEffectsController extends ChangeNotifier {
  static final OneUIEffectsController instance = OneUIEffectsController._internal();
  factory OneUIEffectsController() => instance;
  OneUIEffectsController._internal();

  // 3D Effect Toggles
  bool _card3dEffect = false;       // All cards across UI (disabled by default matching One UI settings)
  bool _floating3dEffect = true;    // Floating pills, buttons, and navbar

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

  // Compatibility getter
  double get depthIntensity => 1.2;

  // Dynamic Card Properties (Plain flat One UI design)
  Color get cardColor => const Color(0xFF1B1C21);
  Border? get cardBorder => null;
  List<BoxShadow> get cardShadow => const [];

  // Dynamic Floating Elements Properties (Lighter One UI floating gray surface)
  Color get floatingColor => const Color(0xFF2C2D34);
  Border? get floatingBorder => null;
  List<BoxShadow> get floatingShadow => const [];
  List<BoxShadow> get fabShadow => const [];
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

  // --- Dynamic Card & Floating Properties (Plain Flat Design) ---
  static Color get cardColor => const Color(0xFF1B1C21);
  static Border? get cardBorder => null;
  static List<BoxShadow> get cardShadow => const [];
  static Color get floatingColor => const Color(0xFF2C2D34);
  static Border? get floatingBorder => null;
  static List<BoxShadow> get floatingShadow => const [];
  static List<BoxShadow> get fabShadow => const [];
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
      cardColor: surfaceCard,
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
