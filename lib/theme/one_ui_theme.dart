import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Card background color & surface style
enum SubscriptionCardBackground {
  oneUiDark,       // Classic One UI charcoal surface (0xFF1C1C1E)
  pureBlack,       // Deep pitch black OLED surface (0xFF090A0D)
  brandTinted,     // Translucent background wash matching the brand color
  midnightNavy,    // Sleek modern slate navy (0xFF151B27)
  deepAmethyst,    // Luxurious deep violet slate (0xFF1E172E)
  frostedGlass,    // Translucent frosted glass with backdrop blur
  custom,          // User selected custom background color
}

/// Main card layout architecture
enum SubscriptionCardLayout {
  oneUiFluent,      // Native One UI grouped list with soft dividers
  bentoElevated,    // Distinct standalone elevated cards with ambient shadow
  compact,          // High-density minimal rows for rapid scanning
}

/// Brand color expression on the card
enum SubscriptionBrandAccent {
  leftStrip,        // Sleek 3.5px vertical indicator bar on left
  ambientGlow,      // Gentle translucent gradient wash in card background
  borderHighlight,  // Delicate 1px brand-tinted border
  neutral,          // Classic dark card without brand tint
}

/// Price presentation mode
enum SubscriptionPriceMode {
  billedAmount,     // Billed amount prominent ($120/yr), monthly secondary ($10/mo)
  monthlyEquivalent,// Monthly equivalent prominent ($10/mo), billed secondary ($120/yr)
  rawAmount,        // Simple raw price only
}

/// Renewal date badge format
enum SubscriptionRenewalBadgeMode {
  countdown,        // "Due in 4 days" / "Due today"
  exactDate,        // "Sep 29" / "Oct 4"
  combined,         // "In 4 days (Sep 29)"
}

/// Payment badge placement style on subscription cards
enum PaymentBadgeStyle {
  cornerBadge,      // 20x13 card logo anchored on corner of brand icon (prevents text clipping)
  inlineSubtitle,   // Inline inside subtitle text next to card nickname
}

/// Upcoming renewals presentation style
enum UpcomingSectionStyle {
  carousel,         // Horizontal swipeable reel with calendar chips
  groupedList,      // Standard One UI grouped list card
  spotlight,        // Single hero card with 1-tap "Mark Paid"
}

/// Icon shape style for subscription detail settings
enum DetailIconShape {
  squircle,         // Classic One UI rounded rectangle (12px radius)
  circle,           // Circular badge
}

/// Leading icon presentation style for payment method on subscription detail screen
enum DetailPaymentIconStyle {
  cardBrand,        // Authentic payment card rectangle (never deformed into circle/squircle)
  iconBadge,        // Uniform One UI icon badge (morphs to squircle or circle with detailIconShape)
}

/// Interactive Dynamic Controller for 3D Elevation, Shadows, Frosted Glass Blur, and Card Styles
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

  // Card Studio Customizations
  SubscriptionCardBackground _cardBackground = SubscriptionCardBackground.oneUiDark;
  int _customCardBackgroundColorValue = 0xFF1C2230;
  SubscriptionCardLayout _cardLayout = SubscriptionCardLayout.oneUiFluent;
  SubscriptionBrandAccent _brandAccent = SubscriptionBrandAccent.neutral;
  SubscriptionPriceMode _priceMode = SubscriptionPriceMode.rawAmount;
  SubscriptionRenewalBadgeMode _renewalBadgeMode = SubscriptionRenewalBadgeMode.countdown;
  PaymentBadgeStyle _paymentBadgeStyle = PaymentBadgeStyle.cornerBadge;
  UpcomingSectionStyle _upcomingStyle = UpcomingSectionStyle.groupedList;
  bool _showCycleProgress = true;
  bool _showPaymentMethodChip = false;
  bool _showCategoryChip = true;
  bool _showBillingCycle = false;
  bool _showDailyEquivalent = false;

  // Detail Screen Settings Customizations
  bool _detailShowItemIcons = true;
  DetailIconShape _detailIconShape = DetailIconShape.squircle;
  bool _detailHighlightSelectable = true;
  DetailPaymentIconStyle _detailPaymentIconStyle = DetailPaymentIconStyle.cardBrand;
  bool _detailShowInlineCardBrand = true;

  /// Explicit initialization hook (useful for test suites and hot restarts)
  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _card3dEffect = prefs.getBool('card3dEffect') ?? false;
      _floating3dEffect = prefs.getBool('floating3dEffect') ?? true;
      _navbar3dEffect = prefs.getBool('navbar3dEffect') ?? true;
      _bottomVignetteEffect = prefs.getBool('bottomVignetteEffect') ?? true;

      final bgStr = prefs.getString('cardBackground');
      if (bgStr != null) {
        _cardBackground = SubscriptionCardBackground.values.firstWhere(
          (e) => e.name == bgStr,
          orElse: () => SubscriptionCardBackground.oneUiDark,
        );
      }
      _customCardBackgroundColorValue = prefs.getInt('customCardBackgroundColorValue') ?? 0xFF1C2230;

      final layoutStr = prefs.getString('cardLayout');
      if (layoutStr != null) {
        _cardLayout = SubscriptionCardLayout.values.firstWhere(
          (e) => e.name == layoutStr,
          orElse: () => SubscriptionCardLayout.oneUiFluent,
        );
      }

      final accentStr = prefs.getString('brandAccent');
      if (accentStr != null) {
        _brandAccent = SubscriptionBrandAccent.values.firstWhere(
          (e) => e.name == accentStr,
          orElse: () => SubscriptionBrandAccent.leftStrip,
        );
      }

      final priceStr = prefs.getString('priceMode');
      if (priceStr != null) {
        _priceMode = SubscriptionPriceMode.values.firstWhere(
          (e) => e.name == priceStr,
          orElse: () => SubscriptionPriceMode.rawAmount,
        );
      }

      final badgeStr = prefs.getString('renewalBadgeMode');
      if (badgeStr != null) {
        _renewalBadgeMode = SubscriptionRenewalBadgeMode.values.firstWhere(
          (e) => e.name == badgeStr,
          orElse: () => SubscriptionRenewalBadgeMode.countdown,
        );
      }

      final badgeStyleStr = prefs.getString('paymentBadgeStyle');
      if (badgeStyleStr != null) {
        _paymentBadgeStyle = PaymentBadgeStyle.values.firstWhere(
          (e) => e.name == badgeStyleStr,
          orElse: () => PaymentBadgeStyle.cornerBadge,
        );
      }

      final upcomingStr = prefs.getString('upcomingStyle');
      if (upcomingStr != null) {
        _upcomingStyle = UpcomingSectionStyle.values.firstWhere(
          (e) => e.name == upcomingStr,
          orElse: () => UpcomingSectionStyle.groupedList,
        );
      }

      _showCycleProgress = prefs.getBool('showCycleProgress') ?? true;
      _showPaymentMethodChip = prefs.getBool('showPaymentMethodChip') ?? false;
      _showCategoryChip = prefs.getBool('showCategoryChip') ?? true;
      _showBillingCycle = prefs.getBool('showBillingCycle') ?? false;
      _showDailyEquivalent = prefs.getBool('showDailyEquivalent') ?? false;

      _detailShowItemIcons = prefs.getBool('detailShowItemIcons') ?? true;
      final detailIconShapeStr = prefs.getString('detailIconShape');
      if (detailIconShapeStr != null) {
        _detailIconShape = DetailIconShape.values.firstWhere(
          (e) => e.name == detailIconShapeStr,
          orElse: () => DetailIconShape.squircle,
        );
      }
      _detailHighlightSelectable = prefs.getBool('detailHighlightSelectable') ?? true;
      final detailPaymentIconStyleStr = prefs.getString('detailPaymentIconStyle');
      if (detailPaymentIconStyleStr != null) {
        _detailPaymentIconStyle = DetailPaymentIconStyle.values.firstWhere(
          (e) => e.name == detailPaymentIconStyleStr,
          orElse: () => DetailPaymentIconStyle.cardBrand,
        );
      }
      _detailShowInlineCardBrand = prefs.getBool('detailShowInlineCardBrand') ?? true;

      _invalidateCache();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveStringSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveIntSetting(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  // Card Studio Getters & Setters
  SubscriptionCardBackground get cardBackground => _cardBackground;
  set cardBackground(SubscriptionCardBackground val) {
    if (_cardBackground != val) {
      _cardBackground = val;
      _saveStringSetting('cardBackground', val.name);
      notifyListeners();
    }
  }

  Color get customCardBackgroundColor => Color(_customCardBackgroundColorValue);
  int get customCardBackgroundColorValue => _customCardBackgroundColorValue;
  set customCardBackgroundColor(Color val) {
    final colorVal = val.toARGB32();
    if (_customCardBackgroundColorValue != colorVal) {
      _customCardBackgroundColorValue = colorVal;
      _saveIntSetting('customCardBackgroundColorValue', colorVal);
      notifyListeners();
    }
  }

  SubscriptionCardLayout get cardLayout => _cardLayout;
  set cardLayout(SubscriptionCardLayout val) {
    if (_cardLayout != val) {
      _cardLayout = val;
      _saveStringSetting('cardLayout', val.name);
      notifyListeners();
    }
  }

  SubscriptionBrandAccent get brandAccent => _brandAccent;
  set brandAccent(SubscriptionBrandAccent val) {
    if (_brandAccent != val) {
      _brandAccent = val;
      _saveStringSetting('brandAccent', val.name);
      notifyListeners();
    }
  }

  SubscriptionPriceMode get priceMode => _priceMode;
  set priceMode(SubscriptionPriceMode val) {
    if (_priceMode != val) {
      _priceMode = val;
      _saveStringSetting('priceMode', val.name);
      notifyListeners();
    }
  }

  SubscriptionRenewalBadgeMode get renewalBadgeMode => _renewalBadgeMode;
  set renewalBadgeMode(SubscriptionRenewalBadgeMode val) {
    if (_renewalBadgeMode != val) {
      _renewalBadgeMode = val;
      _saveStringSetting('renewalBadgeMode', val.name);
      notifyListeners();
    }
  }

  UpcomingSectionStyle get upcomingStyle => _upcomingStyle;
  set upcomingStyle(UpcomingSectionStyle val) {
    if (_upcomingStyle != val) {
      _upcomingStyle = val;
      _saveStringSetting('upcomingStyle', val.name);
      notifyListeners();
    }
  }

  bool get showCycleProgress => _showCycleProgress;
  set showCycleProgress(bool val) {
    if (_showCycleProgress != val) {
      _showCycleProgress = val;
      _saveSetting('showCycleProgress', val);
      notifyListeners();
    }
  }

  bool get showPaymentMethodChip => _showPaymentMethodChip;
  set showPaymentMethodChip(bool val) {
    if (_showPaymentMethodChip != val) {
      _showPaymentMethodChip = val;
      _saveSetting('showPaymentMethodChip', val);
      notifyListeners();
    }
  }

  bool get showCategoryChip => _showCategoryChip;
  set showCategoryChip(bool val) {
    if (_showCategoryChip != val) {
      _showCategoryChip = val;
      _saveSetting('showCategoryChip', val);
      notifyListeners();
    }
  }

  bool get showBillingCycle => _showBillingCycle;
  set showBillingCycle(bool val) {
    if (_showBillingCycle != val) {
      _showBillingCycle = val;
      _saveSetting('showBillingCycle', val);
      notifyListeners();
    }
  }

  bool get showDailyEquivalent => _showDailyEquivalent;
  set showDailyEquivalent(bool val) {
    if (_showDailyEquivalent != val) {
      _showDailyEquivalent = val;
      _saveSetting('showDailyEquivalent', val);
      notifyListeners();
    }
  }

  PaymentBadgeStyle get paymentBadgeStyle => _paymentBadgeStyle;
  set paymentBadgeStyle(PaymentBadgeStyle val) {
    if (_paymentBadgeStyle != val) {
      _paymentBadgeStyle = val;
      _saveStringSetting('paymentBadgeStyle', val.name);
      notifyListeners();
    }
  }

  UpcomingSectionStyle get upcomingSectionStyle => _upcomingStyle;
  set upcomingSectionStyle(UpcomingSectionStyle val) => upcomingStyle = val;

  // Detail Screen Settings Getters & Setters
  bool get detailShowItemIcons => _detailShowItemIcons;
  set detailShowItemIcons(bool val) {
    if (_detailShowItemIcons != val) {
      _detailShowItemIcons = val;
      _saveSetting('detailShowItemIcons', val);
      notifyListeners();
    }
  }

  DetailIconShape get detailIconShape => _detailIconShape;
  set detailIconShape(DetailIconShape val) {
    if (_detailIconShape != val) {
      _detailIconShape = val;
      _saveStringSetting('detailIconShape', val.name);
      notifyListeners();
    }
  }

  bool get detailHighlightSelectable => _detailHighlightSelectable;
  set detailHighlightSelectable(bool val) {
    if (_detailHighlightSelectable != val) {
      _detailHighlightSelectable = val;
      _saveSetting('detailHighlightSelectable', val);
      notifyListeners();
    }
  }

  DetailPaymentIconStyle get detailPaymentIconStyle => _detailPaymentIconStyle;
  set detailPaymentIconStyle(DetailPaymentIconStyle val) {
    if (_detailPaymentIconStyle != val) {
      _detailPaymentIconStyle = val;
      _saveStringSetting('detailPaymentIconStyle', val.name);
      notifyListeners();
    }
  }

  bool get detailShowInlineCardBrand => _detailShowInlineCardBrand;
  set detailShowInlineCardBrand(bool val) {
    if (_detailShowInlineCardBrand != val) {
      _detailShowInlineCardBrand = val;
      _saveSetting('detailShowInlineCardBrand', val);
      notifyListeners();
    }
  }

  /// Resets subscription detail screen styling back to default One UI specs
  void resetDetailStyle() {
    _detailShowItemIcons = true;
    _detailIconShape = DetailIconShape.squircle;
    _detailHighlightSelectable = true;
    _detailPaymentIconStyle = DetailPaymentIconStyle.cardBrand;
    _detailShowInlineCardBrand = true;

    _saveSetting('detailShowItemIcons', _detailShowItemIcons);
    _saveStringSetting('detailIconShape', _detailIconShape.name);
    _saveSetting('detailHighlightSelectable', _detailHighlightSelectable);
    _saveStringSetting('detailPaymentIconStyle', _detailPaymentIconStyle.name);
    _saveSetting('detailShowInlineCardBrand', _detailShowInlineCardBrand);

    notifyListeners();
  }

  /// Resets all subscription card styling & studio preferences back to default Samsung One UI specs
  void resetCardStyle() {
    _cardBackground = SubscriptionCardBackground.oneUiDark;
    _customCardBackgroundColorValue = 0xFF1C2230;
    _cardLayout = SubscriptionCardLayout.oneUiFluent;
    _brandAccent = SubscriptionBrandAccent.neutral;
    _priceMode = SubscriptionPriceMode.rawAmount;
    _renewalBadgeMode = SubscriptionRenewalBadgeMode.countdown;
    _paymentBadgeStyle = PaymentBadgeStyle.cornerBadge;
    _upcomingStyle = UpcomingSectionStyle.groupedList;
    _showCycleProgress = true;
    _showPaymentMethodChip = false;
    _showCategoryChip = true;
    _showBillingCycle = false;
    _showDailyEquivalent = false;

    _detailShowItemIcons = true;
    _detailIconShape = DetailIconShape.squircle;
    _detailHighlightSelectable = true;
    _detailPaymentIconStyle = DetailPaymentIconStyle.cardBrand;
    _detailShowInlineCardBrand = true;

    _saveStringSetting('cardBackground', _cardBackground.name);
    _saveIntSetting('customCardBackgroundColorValue', _customCardBackgroundColorValue);
    _saveStringSetting('cardLayout', _cardLayout.name);
    _saveStringSetting('brandAccent', _brandAccent.name);
    _saveStringSetting('priceMode', _priceMode.name);
    _saveStringSetting('renewalBadgeMode', _renewalBadgeMode.name);
    _saveStringSetting('paymentBadgeStyle', _paymentBadgeStyle.name);
    _saveStringSetting('upcomingStyle', _upcomingStyle.name);
    _saveSetting('showCycleProgress', _showCycleProgress);
    _saveSetting('showPaymentMethodChip', _showPaymentMethodChip);
    _saveSetting('showCategoryChip', _showCategoryChip);
    _saveSetting('showBillingCycle', _showBillingCycle);
    _saveSetting('showDailyEquivalent', _showDailyEquivalent);

    _saveSetting('detailShowItemIcons', _detailShowItemIcons);
    _saveStringSetting('detailIconShape', _detailIconShape.name);
    _saveSetting('detailHighlightSelectable', _detailHighlightSelectable);
    _saveStringSetting('detailPaymentIconStyle', _detailPaymentIconStyle.name);
    _saveSetting('detailShowInlineCardBrand', _detailShowInlineCardBrand);

    _invalidateCache();
    notifyListeners();
  }

  /// Resolves the effective background color for a subscription card
  Color resolveCardBackground({
    SubscriptionCardBackground? backgroundType,
    Color? brandColor,
  }) {
    final bg = backgroundType ?? _cardBackground;
    final bColor = brandColor ?? const Color(0xFF5390F5);

    switch (bg) {
      case SubscriptionCardBackground.oneUiDark:
        return cardColor;
      case SubscriptionCardBackground.pureBlack:
        return const Color(0xFF090A0D);
      case SubscriptionCardBackground.brandTinted:
        return Color.alphaBlend(bColor.withValues(alpha: 0.13), const Color(0xFF131417));
      case SubscriptionCardBackground.midnightNavy:
        return const Color(0xFF151B27);
      case SubscriptionCardBackground.deepAmethyst:
        return const Color(0xFF1E172E);
      case SubscriptionCardBackground.frostedGlass:
        return const Color(0xFF22242B).withValues(alpha: 0.72);
      case SubscriptionCardBackground.custom:
        return Color(_customCardBackgroundColorValue);
    }
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
  List<BoxShadow>? _cachedFloatingShadow;
  List<BoxShadow>? _cachedNavbarShadow;
  List<BoxShadow>? _cachedFabShadow;

  void _invalidateCache() {
    _cachedCardBorder = null;
    _cachedCardShadow = null;
    _cachedFloatingGradient = null;
    _cachedFloatingBorder = null;
    _cachedFloatingShadow = null;
    _cachedNavbarShadow = null;
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
        spreadRadius: 1.0,
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
    if (!_floating3dEffect) {
      return _cachedFloatingShadow ??= [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 3),
          spreadRadius: 1.0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 6,
          offset: const Offset(0, 1),
          spreadRadius: 0.5,
        ),
      ];
    }
    return _cachedFloatingShadow ??= [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.60),
        blurRadius: 20,
        offset: const Offset(0, 4),
        spreadRadius: 1.0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 8,
        offset: const Offset(0, 1),
        spreadRadius: 1.0,
      ),
    ];
  }

  List<BoxShadow> get navbarShadow {
    final is3d = _navbar3dEffect || _floating3dEffect;
    if (!is3d) {
      return _cachedNavbarShadow ??= [
        // Upward ambient lift over content entering from the top of the navbar
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, -2),
          spreadRadius: 0.5,
        ),
        // Perimeter halo
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 8,
          offset: const Offset(0, 1),
          spreadRadius: 1.0,
        ),
      ];
    }
    return _cachedNavbarShadow ??= [
      // 3D mode enhanced lift
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.60),
        blurRadius: 22,
        offset: const Offset(0, -2),
        spreadRadius: 1.0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 10,
        offset: const Offset(0, 2),
        spreadRadius: 1.5,
      ),
    ];
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
  static List<BoxShadow> get navbarShadow => OneUIEffectsController.instance.navbarShadow;
  static List<BoxShadow> get fabShadow => OneUIEffectsController.instance.fabShadow;
  static double get blurSigma => OneUIEffectsController.instance.blurSigma;
  static bool get bottomVignetteEffect => OneUIEffectsController.instance.bottomVignetteEffect;

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
