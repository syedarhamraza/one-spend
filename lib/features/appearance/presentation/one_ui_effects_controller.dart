import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../../../theme/one_ui_theme.dart';
import '../../settings/domain/repositories/settings_repository.dart';

/// How high a floating glass surface sits, which picks its shadow.
enum OneUIGlassElevation {
  /// Pills, circular buttons, search capsules, action bars, menus.
  floating,

  /// The bottom tab bar (its shadow also lifts it over content scrolling under it).
  navbar,

  /// Bottom sheets and modals.
  modal,
}

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
/// How the Upcoming tab presents charges.
enum UpcomingViewMode {
  timeline, // Day-by-day agenda of every charge
  calendar, // Month grid with brand-colour dots per billing day
}

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
  OneUIEffectsController._internal();

  SettingsRepository? get _repository =>
      sl.isRegistered<SettingsRepository>() ? sl<SettingsRepository>() : null;

  /// "3D floating elements": raised glass look for the nav bar, floating buttons and pills.
  /// Off by default. Cards are always flat and the bottom vignette is always on.
  bool _floating3dEffect = false;

  // Card Studio Customizations
  SubscriptionCardBackground _cardBackground = SubscriptionCardBackground.oneUiDark;
  int _customCardBackgroundColorValue = 0xFF1C2230;
  SubscriptionCardLayout _cardLayout = SubscriptionCardLayout.oneUiFluent;
  SubscriptionBrandAccent _brandAccent = SubscriptionBrandAccent.neutral;
  SubscriptionPriceMode _priceMode = SubscriptionPriceMode.rawAmount;
  SubscriptionRenewalBadgeMode _renewalBadgeMode = SubscriptionRenewalBadgeMode.countdown;
  PaymentBadgeStyle _paymentBadgeStyle = PaymentBadgeStyle.cornerBadge;
  UpcomingSectionStyle _upcomingStyle = UpcomingSectionStyle.groupedList;
  UpcomingViewMode _upcomingViewMode = UpcomingViewMode.timeline;
  bool _showCycleProgress = true;
  bool _showPaymentMethodChip = false;
  bool _showCategoryChip = true;
  bool _showBillingCycle = false;
  bool _showDailyEquivalent = false;

  // Detail Screen Settings Customizations
  bool _detailShowItemIcons = true;
  DetailIconShape _detailIconShape = DetailIconShape.squircle;
  bool _detailHighlightSelectable = false;
  DetailPaymentIconStyle _detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
  bool _detailShowInlineCardBrand = true;

  /// Explicit initialization hook (useful for test suites and hot restarts)
  Future<void> init() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final repository = _repository;
      if (repository == null) return;
      final prefs = _StoredSettings(await repository.getAppearanceSettings());
      _floating3dEffect = prefs.getBool('floating3dEffect') ?? false;

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
      _detailHighlightSelectable = prefs.getBool('detailHighlightSelectable') ?? false;
      final detailPaymentIconStyleStr = prefs.getString('detailPaymentIconStyle');
      if (detailPaymentIconStyleStr != null) {
        _detailPaymentIconStyle = DetailPaymentIconStyle.values.firstWhere(
          (e) => e.name == detailPaymentIconStyleStr,
          orElse: () => DetailPaymentIconStyle.iconBadge,
        );
      }
      _detailShowInlineCardBrand = prefs.getBool('detailShowInlineCardBrand') ?? true;
      _upcomingViewMode = UpcomingViewMode.values.firstWhere(
        (e) => e.name == prefs.getString('upcomingViewMode'),
        orElse: () => UpcomingViewMode.timeline,
      );

      _invalidateCache();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _writeQueue = Future.value();

  void _write(String key, Object value) {
    final repository = _repository;
    if (repository == null) return;
    _writeQueue = _writeQueue
        .then((_) => repository.setAppearanceSettings({key: value.toString()}))
        .catchError((Object e) => debugPrint('OneSpend: Failed to save appearance setting $key: $e'));
  }

  void _saveSetting(String key, bool value) => _write(key, value);

  void _saveStringSetting(String key, String value) => _write(key, value);

  void _saveIntSetting(String key, int value) => _write(key, value);

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

  /// Remembered Upcoming tab view (timeline or calendar). Not reset by the card studio reset.
  UpcomingViewMode get upcomingViewMode => _upcomingViewMode;
  set upcomingViewMode(UpcomingViewMode val) {
    if (_upcomingViewMode != val) {
      _upcomingViewMode = val;
      _saveStringSetting('upcomingViewMode', val.name);
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
    _detailHighlightSelectable = false;
    _detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
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
    _detailHighlightSelectable = false;
    _detailPaymentIconStyle = DetailPaymentIconStyle.iconBadge;
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

  bool get floating3dEffect => _floating3dEffect;
  set floating3dEffect(bool val) {
    if (_floating3dEffect != val) {
      _floating3dEffect = val;
      _saveSetting('floating3dEffect', val);
      _invalidateCache();
      notifyListeners();
    }
  }

  // Caching variables
  Gradient? _cachedFloatingGradient;
  Border? _cachedFloatingBorder;
  List<BoxShadow>? _cachedFloatingShadow;
  List<BoxShadow>? _cachedNavbarShadow;
  List<BoxShadow>? _cachedFabShadow;

  List<BoxShadow>? _cachedModalShadow;

  void _invalidateCache() {
    _cachedModalShadow = null;
    _cachedFloatingGradient = null;
    _cachedFloatingBorder = null;
    _cachedFloatingShadow = null;
    _cachedNavbarShadow = null;
    _cachedFabShadow = null;
  }

  // Compatibility getter
  double get depthIntensity => 1.2;

  // Cards are always flat (the card 3D option was removed).
  Color get cardColor => const Color(0xFF1C1C1E);
  Border? get cardBorder => null;
  List<BoxShadow> get cardShadow => const [];

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
      // Flat: a single soft ambient halo, just enough to separate from content.
      return _cachedFloatingShadow ??= [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 14,
          offset: const Offset(0, 2),
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
    final is3d = _floating3dEffect;
    if (!is3d) {
      // Flat: one soft ambient halo so content scrolling under the bar stays separated.
      return _cachedNavbarShadow ??= [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, -1),
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

  // --- Glass surfaces (see OneUIGlassSurface) --------------------------------

  /// Shadow under a floating glass surface.
  List<BoxShadow> glassShadow(OneUIGlassElevation elevation) => switch (elevation) {
        OneUIGlassElevation.floating => floatingShadow,
        OneUIGlassElevation.navbar => navbarShadow,
        OneUIGlassElevation.modal => modalShadow,
      };

  /// Sheets and modals: no shadow when flat; a deep soft drop plus a contact shadow in 3D.
  List<BoxShadow> get modalShadow {
    if (!_floating3dEffect) return const [];
    return _cachedModalShadow ??= [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.55),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Flat fill for sheets and modals (denser than pills so long content stays legible).
  Color get modalColor => const Color(0xC4202024);

  /// 3D body for sheets and modals.
  Gradient? get modalGradient => _floating3dEffect ? _modalGradient : null;
  static const _modalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xB326262B), Color(0xCC1A1A1E)],
  );

  /// 3D rim light: bright along the top edge, fading out down the sides, the way
  /// One UI 8.5 glass catches light from above. Null when flat (no outline at all).
  Gradient? get floatingRimGradient => _floating3dEffect ? _rimGradient : null;
  static const _rimGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x3DFFFFFF), Color(0x12FFFFFF), Color(0x08FFFFFF)],
    stops: [0.0, 0.45, 1.0],
  );

  /// Selected-item capsule (nav bar, segmented pills). 3D: a soft radial sheen that
  /// is lighter near the top centre; flat: the plain active pill colour.
  Gradient? get activePillGradient => _floating3dEffect ? _activePillGradient : null;
  static const _activePillGradient = RadialGradient(
    center: Alignment(0, -0.7),
    radius: 1.4,
    colors: [Color(0xFF4D4D52), Color(0xFF38383C)],
  );

  Color get activePillColor => _floating3dEffect ? OneUITheme.navbar3dActivePill : OneUITheme.surfacePillActive;

  /// Rim on the selected capsule; fainter than the surface rim.
  Gradient? get activePillRimGradient => _floating3dEffect ? _activePillRim : null;
  static const _activePillRim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x2EFFFFFF), Color(0x05FFFFFF)],
  );

  // Backward compatibility
  Border? get subtleBorder => null;
}

/// Read-only typed view over raw appearance values loaded from [SettingsRepository].
class _StoredSettings {
  final Map<String, String> _values;

  const _StoredSettings(this._values);

  bool? getBool(String key) {
    final raw = _values[key];
    return raw == null ? null : raw == 'true';
  }

  String? getString(String key) => _values[key];

  int? getInt(String key) {
    final raw = _values[key];
    return raw == null ? null : int.tryParse(raw);
  }
}
