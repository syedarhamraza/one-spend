import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Interactive Dynamic Controller for 3D Elevation, Shadows, and Frosted Glass Blur
class OneUIEffectsController extends ChangeNotifier {
  static final OneUIEffectsController instance = OneUIEffectsController._internal();
  factory OneUIEffectsController() => instance;
  OneUIEffectsController._internal() {
    _loadSettings();
  }

  // 3D & Vignette Effect Toggles
  bool _card3dEffect = false;       // All cards across UI (disabled by default matching One UI settings)
  bool _floating3dEffect = true;    // Floating pills, buttons, and navbar
  bool _navbar3dEffect = true;      // 3D tactile navbar matching One UI phone dialer screenshot
  bool _bottomVignetteEffect = true;// Edge-to-edge progressive bottom gradient vignette

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _card3dEffect = prefs.getBool('card3dEffect') ?? false;
      _floating3dEffect = prefs.getBool('floating3dEffect') ?? true;
      _navbar3dEffect = prefs.getBool('navbar3dEffect') ?? true;
      _bottomVignetteEffect = prefs.getBool('bottomVignetteEffect') ?? true;
      _invalidateCache();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  bool get card3dEffect => _card3dEffect;
  set card3dEffect(bool val) {
    if (_card3dEffect != val) {
      _card3dEffect = val;
      _saveSetting('card3dEffect', val);
      _invalidateCache();
      notifyListeners();
    }
  }

  bool get floating3dEffect => _floating3dEffect;
  set floating3dEffect(bool val) {
    if (_floating3dEffect != val) {
      _floating3dEffect = val;
      _saveSetting('floating3dEffect', val);
      _invalidateCache();
      notifyListeners();
    }
  }

  bool get navbar3dEffect => _navbar3dEffect;
  set navbar3dEffect(bool val) {
    if (_navbar3dEffect != val) {
      _navbar3dEffect = val;
      _saveSetting('navbar3dEffect', val);
      _invalidateCache();
      notifyListeners();
    }
  }

  bool get bottomVignetteEffect => _bottomVignetteEffect;
  set bottomVignetteEffect(bool val) {
    if (_bottomVignetteEffect != val) {
      _bottomVignetteEffect = val;
      _saveSetting('bottomVignetteEffect', val);
      _invalidateCache();
      notifyListeners();
    }
  }

  // Caching variables
  Border? _cachedCardBorder;
  List<BoxShadow>? _cachedCardShadow;
  Gradient? _cachedFloatingGradient;
  Border? _cachedFloatingBorder;
  List<BoxShadow>? _cachedFabShadow;

  void _invalidateCache() {
    _cachedCardBorder = null;
    _cachedCardShadow = null;
    _cachedFloatingGradient = null;
    _cachedFloatingBorder = null;
    _cachedFabShadow = null;
  }

  // Compatibility getter
  double get depthIntensity => 1.2;

  // Dynamic Card Properties
  Color get cardColor => _card3dEffect ? const Color(0xFF222224) : const Color(0xFF1C1C1E);
  
  Border? get cardBorder {
    if (!_card3dEffect) return null;
    return _cachedCardBorder ??= Border.all(
      color: Colors.white.withValues(alpha: 0.09),
      width: 0.85,
    );
  }
  
  List<BoxShadow> get cardShadow {
    if (!_card3dEffect) return const [];
    return _cachedCardShadow ??= [
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
    ];
  }

  // Dynamic Floating Elements Properties
  Color get floatingColor => _floating3dEffect
      ? const Color(0x9E26262B) // ~62% translucent smoked glass
      : const Color(0xB3222226); // ~70% flat translucent

  Gradient? get floatingGradient {
    if (!_floating3dEffect) return null;
    return _cachedFloatingGradient ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x9935353A), // ~60% smoked charcoal top highlight
        Color(0xB31E1E22), // ~70% deeper smoked glass bottom
      ],
    );
  }

  Border? get floatingBorder {
    if (!_floating3dEffect) return null;
    return _cachedFloatingBorder ??= Border.all(
      color: Colors.white.withValues(alpha: 0.15),
      width: 0.85,
    );
  }

  List<BoxShadow> get floatingShadow {
    if (!_floating3dEffect) return const [];
    return _cachedFloatingBorder != null
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        : const [];
  }

  List<BoxShadow> get fabShadow {
    if (!_floating3dEffect) return const [];
    return _cachedFabShadow ??= [
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
    ];
  }

  double get blurSigma => 20.0;

  // Backward compatibility
  Border? get subtleBorder => null;
}

/// Samsung One UI 9 Design System Tokens and Theme
class OneUITheme {
  // --- Pure OLED Black & Neutral Charcoal Surfaces ---
  static const Color surfacePitch = Color(0xFF000000); // True AMOLED Black
  static const Color surfaceCard = Color(0xFF1C1C1E); // Neutral Dark Charcoal Card Surface
  static const Color surfaceCardHighlight = Color(0xFF262628);
  static const Color surfacePill = Color(0xFF2C2C2E); // Distinct One UI Gray Floating Capsule Surface
  static const Color surfacePillActive = Color(0xFF3E3E42); // Active Tab Capsule
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

  // --- Dynamic Card & Floating Properties ---
  static Color get cardColor => OneUIEffectsController.instance.cardColor;
  static Border? get cardBorder => OneUIEffectsController.instance.cardBorder;
  static List<BoxShadow> get cardShadow => OneUIEffectsController.instance.cardShadow;
  static Color get floatingColor => OneUIEffectsController.instance.floatingColor;
  static Gradient? get floatingGradient => OneUIEffectsController.instance.floatingGradient;
  static Border? get floatingBorder => OneUIEffectsController.instance.floatingBorder;
  static List<BoxShadow> get floatingShadow => OneUIEffectsController.instance.floatingShadow;
  static List<BoxShadow> get fabShadow => OneUIEffectsController.instance.fabShadow;
  static double get blurSigma => OneUIEffectsController.instance.blurSigma;
  static bool get bottomVignetteEffect => OneUIEffectsController.instance.bottomVignetteEffect;

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
