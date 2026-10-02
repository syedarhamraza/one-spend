import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_glass_surface.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_icon_picker_modal.dart';
import '../widgets/one_ui_radio.dart';
import '../widgets/one_ui_subpage.dart';
import '../widgets/one_ui_logo_framer.dart';
import '../features/subscriptions/domain/entities/logo_transform.dart';

/// Samsung One UI Subscription Icon Picker Subpage.
/// Redesigned to match One UI customization subpages (e.g. Subscription Detail Styling):
/// - Standalone Live Hero Preview Card with ambient under-card glow & frosted glass blur
/// - Settings structured as One UI Group Items that navigate to dedicated subpages:
///   1. Brand preset -> dedicated subpage with search & 4-column vector logo grid
///   2. System icon -> dedicated subpage with curated squircle icon tiles
///   3. Custom image URL -> dedicated subpage with link input & paste shortcut
///   4. Background color -> dedicated subpage with color options & underglow tuning
/// - Floating Cancel | Save Pill with progressive OLED bottom vignette
class IconPickerScreen extends StatefulWidget {
  final Color initialColor;
  final IconData initialIcon;
  final String? initialLogoUrl;
  final String? initialPresetId;
  final String subscriptionName;
  final LogoTransform? initialLogoTransform;

  const IconPickerScreen({
    super.key,
    required this.initialColor,
    required this.initialIcon,
    this.initialLogoUrl,
    this.initialPresetId,
    this.subscriptionName = '',
    this.initialLogoTransform,
  });

  static Future<IconPickerResult?> open(
    BuildContext context, {
    required Color currentColor,
    required IconData currentIcon,
    String? currentLogoUrl,
    String? currentPresetId,
    String subscriptionName = '',
    LogoTransform? currentLogoTransform,
  }) {
    HapticFeedback.lightImpact();
    return context.push<IconPickerResult>(
      AppRoutes.iconPicker,
      extra: (
        initialColor: currentColor,
        initialIcon: currentIcon,
        initialLogoUrl: currentLogoUrl,
        initialPresetId: currentPresetId,
        subscriptionName: subscriptionName,
        initialLogoTransform: currentLogoTransform,
      ),
    );
  }

  @override
  State<IconPickerScreen> createState() => _IconPickerScreenState();
}

class _IconPickerScreenState extends State<IconPickerScreen> {
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedLogoUrl;
  LogoTransform? _selectedLogoTransform;
  late String? _selectedPresetId;

  static const List<Color> swatches = [
    Color(0xFFE50914), // Red
    Color(0xFF1DB954), // Spotify Green
    Color(0xFF0066FF), // One UI Blue
    Color(0xFF8A2BE2), // Purple
    Color(0xFFFF9500), // Orange
    Color(0xFF00C7BE), // Teal
    Color(0xFFFF2D55), // Pink
    Color(0xFF34AADC), // Light Blue
    Color(0xFF10A37F), // Mint Green
    Color(0xFF2C3440), // Dark Slate
    Color(0xFF5856D6), // Indigo
    Color(0xFF555555), // Charcoal
    Color(0xFFFFFFFF), // White
  ];

  static String getColorHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  static final Map<int, String> swatchNames = {
    const Color(0xFFE50914).toARGB32(): 'Netflix Red',
    const Color(0xFF1DB954).toARGB32(): 'Spotify Green',
    const Color(0xFF0066FF).toARGB32(): 'One UI Blue',
    const Color(0xFF8A2BE2).toARGB32(): 'Electric Purple',
    const Color(0xFFFF9500).toARGB32(): 'Sunset Orange',
    const Color(0xFF00C7BE).toARGB32(): 'Ocean Teal',
    const Color(0xFFFF2D55).toARGB32(): 'Neon Pink',
    const Color(0xFF34AADC).toARGB32(): 'Sky Blue',
    const Color(0xFF10A37F).toARGB32(): 'Mint Green',
    const Color(0xFF2C3440).toARGB32(): 'Dark Slate',
    const Color(0xFF5856D6).toARGB32(): 'Deep Indigo',
    const Color(0xFF555555).toARGB32(): 'Charcoal Grey',
    const Color(0xFFFFFFFF).toARGB32(): 'White',
  };

  static String getSwatchName(Color color) {
    return swatchNames[color.toARGB32()] ?? 'Custom Color';
  }

  static const List<IconData> systemIcons = [
    Icons.movie_filter_rounded,
    Icons.tv_rounded,
    Icons.music_note_rounded,
    Icons.album_rounded,
    Icons.headphones_rounded,
    Icons.auto_awesome_rounded,
    Icons.psychology_rounded,
    Icons.terminal_rounded,
    Icons.code_rounded,
    Icons.cloud_rounded,
    Icons.storage_rounded,
    Icons.sports_esports_rounded,
    Icons.videogame_asset_rounded,
    Icons.brush_rounded,
    Icons.palette_rounded,
    Icons.fitness_center_rounded,
    Icons.shopping_bag_rounded,
    Icons.school_rounded,
    Icons.wifi_rounded,
    Icons.shield_rounded,
    Icons.attach_money_rounded,
    Icons.subscriptions_rounded,
    Icons.star_rounded,
    Icons.home_repair_service_rounded,
  ];

  static final Map<IconData, String> systemIconNames = {
    Icons.movie_filter_rounded: 'Movie & Video',
    Icons.tv_rounded: 'Television',
    Icons.music_note_rounded: 'Music Note',
    Icons.album_rounded: 'Music Album',
    Icons.headphones_rounded: 'Audio & Podcast',
    Icons.auto_awesome_rounded: 'AI & Magic',
    Icons.psychology_rounded: 'Psychology & Logic',
    Icons.terminal_rounded: 'Terminal CLI',
    Icons.code_rounded: 'Code & Dev',
    Icons.cloud_rounded: 'Cloud Storage',
    Icons.storage_rounded: 'Database Server',
    Icons.sports_esports_rounded: 'Gaming Controller',
    Icons.videogame_asset_rounded: 'Video Game',
    Icons.brush_rounded: 'Art Brush',
    Icons.palette_rounded: 'Color Palette',
    Icons.fitness_center_rounded: 'Fitness & Gym',
    Icons.shopping_bag_rounded: 'Shopping Bag',
    Icons.school_rounded: 'Education',
    Icons.wifi_rounded: 'Network & Wi-Fi',
    Icons.shield_rounded: 'Security Shield',
    Icons.attach_money_rounded: 'Finance & Money',
    Icons.subscriptions_rounded: 'Subscriptions',
    Icons.star_rounded: 'Star',
    Icons.home_repair_service_rounded: 'Productivity Tool',
  };

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _selectedIcon = widget.initialIcon;
    _selectedLogoUrl = widget.initialLogoUrl;
    _selectedLogoTransform = widget.initialLogoTransform;
    _selectedPresetId = widget.initialPresetId;
    if (_selectedPresetId == null && (_selectedLogoUrl == null || _selectedLogoUrl!.isEmpty)) {
      final autoMatch = OneUIBrandCatalog.findPreset(widget.subscriptionName);
      if (autoMatch != null) {
        _selectedPresetId = autoMatch.id;
      }
    }
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      IconPickerResult(
        iconData: _selectedIcon,
        brandColor: _selectedColor,
        logoUrl: _selectedLogoUrl,
        brandPresetId: _selectedPresetId,
        logoTransform: _selectedLogoUrl == null ? null : _selectedLogoTransform,
      ),
    );
  }

  String _getColorName(Color color) {
    return getColorHex(color);
  }

  String _getSystemIconName(IconData icon) {
    for (final entry in systemIconNames.entries) {
      if (entry.key.codePoint == icon.codePoint) {
        return entry.value;
      }
    }
    return 'Icon Glyph';
  }

  void _openBrandPresetSubpage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<_BrandPresetResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _BrandPresetPickerSubpage(
          currentPresetId: (_selectedPresetId == '__none__' ? null : _selectedPresetId),
          currentColor: _selectedColor,
          currentIcon: _selectedIcon,
          currentLogoUrl: _selectedLogoUrl,
          subscriptionName: widget.subscriptionName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedPresetId = result.preset.id;
        _selectedColor = result.preset.color;
        _selectedIcon = result.preset.icon;
        _selectedLogoUrl = null;
        _selectedLogoTransform = null; // Brand logo vector replaces any custom URL!
      });
    }
  }

  void _openSystemIconSubpage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<IconData>(
      context,
      MaterialPageRoute(
        builder: (_) => _SystemIconPickerSubpage(
          currentIcon: _selectedIcon,
          currentColor: _selectedColor,
          currentPresetId: _selectedPresetId,
          currentLogoUrl: _selectedLogoUrl,
          subscriptionName: widget.subscriptionName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedIcon = result;
        _selectedPresetId = '__none__';
        _selectedLogoUrl = null;
        _selectedLogoTransform = null;
      });
    }
  }

  void _openCustomUrlSubpage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<_CustomUrlResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomUrlPickerSubpage(
          currentUrl: _selectedLogoUrl,
          currentTransform: _selectedLogoTransform,
          currentColor: _selectedColor,
          currentIcon: _selectedIcon,
          currentPresetId: _selectedPresetId,
          subscriptionName: widget.subscriptionName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        final clean = result.url?.trim();
        _selectedLogoUrl = (clean != null && clean.isNotEmpty) ? clean : null;
        _selectedLogoTransform = _selectedLogoUrl == null ? null : result.transform;
        if (_selectedLogoUrl != null) {
          _selectedPresetId = '__none__';
        }
      });
    }
  }

  void _openBackgroundColorSubpage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<Color>(
      context,
      MaterialPageRoute(
        builder: (_) => _BackgroundColorPickerSubpage(
          currentColor: _selectedColor,
          currentIcon: _selectedIcon,
          currentPresetId: _selectedPresetId,
          currentLogoUrl: _selectedLogoUrl,
          subscriptionName: widget.subscriptionName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedColor = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final effectiveName = widget.subscriptionName.trim().isNotEmpty
        ? widget.subscriptionName
        : 'Icon Preview';

    final isPresetSelected = _selectedPresetId != null && _selectedPresetId != '__none__';
    final isCustomUrlSelected = _selectedLogoUrl != null && _selectedLogoUrl!.isNotEmpty;
    final isSystemIconSelected = !isPresetSelected && !isCustomUrlSelected;

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Subscription icon',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Top Hero Card (Frosted Glass & Ambient Under-Card Glow like Subs Detail Hero)
                      _IconHeroPreviewCard(
                        subscriptionName: effectiveName,
                        brandColor: _selectedColor,
                        iconData: _selectedIcon,
                        logoUrl: _selectedLogoUrl,
                        logoTransform: _selectedLogoTransform,
                        brandPresetId: _selectedPresetId,
                      ),
                      const SizedBox(height: 16),

                      // 2. Icon source & geometry group items
                      OneUISection(
                        title: 'Icon style',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Brand logos',
                              subtitle: isPresetSelected
                                  ? (OneUIBrandCatalog.findById(_selectedPresetId)?.name ?? _selectedPresetId!)
                                  : 'None',
                              subtitleColor: isPresetSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: _openBrandPresetSubpage,
                            ),
                            OneUIGroupItem(
                              title: 'System icon',
                              subtitle: isSystemIconSelected
                                  ? _getSystemIconName(_selectedIcon)
                                  : 'None',
                              subtitleColor: isSystemIconSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: _openSystemIconSubpage,
                            ),
                            OneUIGroupItem(
                              title: 'Custom image URL',
                              subtitle: isCustomUrlSelected
                                  ? _selectedLogoUrl!
                                  : 'None',
                              subtitleColor: isCustomUrlSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: OneUITheme.textSecondary,
                              ),
                              onTap: _openCustomUrlSubpage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Color Appearance group item
                      OneUISection(
                        title: 'Appearance',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Background color',
                              subtitle: _getColorName(_selectedColor),
                              subtitleColor: OneUITheme.accentBlue,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ],
                              ),
                              onTap: _openBackgroundColorSubpage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progressive OLED Bottom Vignette Scrim
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          // Floating Cancel | Save Stadium Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: OneUIFloatingCancelSavePill(
                    onCancel: () => Navigator.pop(context),
                    onSave: _save,
                    saveLabel: 'Save',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone One UI Hero Preview Card with Frosted Glass Blur & Ambient Under-Card Glow
/// Completely flat surface matching Samsung One UI design without 3D rims or borders.
class _IconHeroPreviewCard extends StatelessWidget {
  final String subscriptionName;
  final Color brandColor;
  final IconData iconData;
  final String? logoUrl;
  final String? brandPresetId;
  final LogoTransform? logoTransform;

  const _IconHeroPreviewCard({
    required this.subscriptionName,
    required this.brandColor,
    required this.iconData,
    this.logoUrl,
    this.brandPresetId,
    this.logoTransform,
  });

  @override
  Widget build(BuildContext context) {
    final heroGlowColor = OneUIBrandCatalog.getGlowColor(
      color: brandColor,
      presetId: (brandPresetId == '__none__' ? null : brandPresetId),
      name: subscriptionName,
    );

    final isPreset = brandPresetId != null && brandPresetId != '__none__';
    final isCustomUrl = logoUrl != null && logoUrl!.isNotEmpty;

    final String sourceSubtitle;
    if (isPreset) {
      sourceSubtitle = 'Official Brand Vector';
    } else if (isCustomUrl) {
      sourceSubtitle = 'Network Image Asset';
    } else {
      sourceSubtitle = 'Curated Vector Glyph';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      child: ClipRRect(
        borderRadius: OneUITheme.cardBorderRadius,
        child: Stack(
          children: [
            // 1. Soft, understated ambient glow positioned BENEATH the card surface (not on the icon)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2),
                    radius: 1.05,
                    colors: [
                      heroGlowColor.withValues(alpha: 0.28),
                      heroGlowColor.withValues(alpha: 0.12),
                      heroGlowColor.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.50, 0.85, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Frosted glass blur & flat translucent card body (completely flat, NO border, NO 3D rims)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: const Color(0xFF1B1C20).withValues(alpha: 0.68),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(
                    borderRadius: OneUITheme.cardBorderRadius,
                  ),
                  child: Row(
                    children: [
                      // Squircle Brand Icon (completely flat, clean, without icon glow)
                      OneUIBrandIcon(
                        name: subscriptionName,
                        brandColor: brandColor,
                        iconData: iconData,
                        logoUrl: logoUrl,
                        logoTransform: logoTransform,
                        brandPresetId: brandPresetId,
                        size: 60,
                        borderRadius: 18,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subscriptionName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: OneUITheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sourceSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPresetResult {
  final BrandPreset preset;
  const _BrandPresetResult(this.preset);
}

class _CustomUrlResult {
  final String? url;
  final LogoTransform? transform;
  const _CustomUrlResult(this.url, [this.transform]);
}

/// Dedicated subpage to select Brand Preset with live interactive Hero Preview
class _BrandPresetPickerSubpage extends StatefulWidget {
  final String? currentPresetId;
  final Color currentColor;
  final IconData currentIcon;
  final String? currentLogoUrl;
  final String subscriptionName;

  const _BrandPresetPickerSubpage({
    required this.currentPresetId,
    required this.currentColor,
    required this.currentIcon,
    this.currentLogoUrl,
    required this.subscriptionName,
  });

  @override
  State<_BrandPresetPickerSubpage> createState() => _BrandPresetPickerSubpageState();
}

class _BrandPresetPickerSubpageState extends State<_BrandPresetPickerSubpage> {
  late String? _selectedPresetId;
  late Color _previewColor;
  late IconData _previewIcon;
  late String? _previewLogoUrl;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _selectedPresetId = widget.currentPresetId;
    _previewColor = widget.currentColor;
    _previewIcon = widget.currentIcon;
    _previewLogoUrl = widget.currentLogoUrl;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _exitSearchMode() {
    _searchFocusNode.unfocus();
    setState(() {
      _showSearch = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildFloatingSearchPill() {
    return OneUIGlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(32)),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      _searchFocusNode.unfocus();
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search brand logos',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E95B8),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPresets = OneUIBrandCatalog.presets;
    final filtered = _searchQuery.trim().isEmpty
        ? allPresets
        : allPresets.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final effectiveName = widget.subscriptionName.trim().isNotEmpty
        ? widget.subscriptionName
        : 'Icon Preview';

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final searchPillBottom = math.max(bottomPadding + 16, bottomInset + 14);

    return PopScope(
      canPop: !_showSearch,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showSearch) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
        backgroundColor: OneUITheme.surfacePitch,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OneUICollapsibleHeaderDelegate(
                    title: _showSearch ? 'Search logos' : 'Brand logos',
                    hasBigHeader: false,
                    showBackButton: true,
                    onBack: () {
                      HapticFeedback.lightImpact();
                      if (_showSearch) {
                        _exitSearchMode();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    actions: _showSearch
                        ? null
                        : [
                            OneUIHeaderAction(
                              icon: Icons.search_rounded,
                              tooltip: 'Search brand logos',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _showSearch = true);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _searchFocusNode.requestFocus();
                                });
                              },
                            ),
                          ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, _showSearch ? (searchPillBottom + 70) : 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Hero Preview Card
                        _IconHeroPreviewCard(
                          subscriptionName: effectiveName,
                          brandColor: _previewColor,
                          iconData: _previewIcon,
                          logoUrl: _previewLogoUrl,
                          brandPresetId: _selectedPresetId,
                        ),
                        const SizedBox(height: 16),

                        // Brand Logos Grid wrapped in OneUISection and group container
                        OneUISection(
                          title: 'Brand logos',
                          child: filtered.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  decoration: BoxDecoration(
                                    color: OneUIEffectsController.instance.resolveCardBackground(),
                                    borderRadius: OneUITheme.cardBorderRadius,
                                    border: OneUITheme.cardBorder,
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.search_off_rounded, size: 44, color: OneUITheme.textSecondary),
                                      SizedBox(height: 12),
                                      Text(
                                        'No matching brand logos found',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : OneUIGroupCard(
                                  items: filtered.map((preset) {
                                    final isSelected = _selectedPresetId == preset.id;
                                    return OneUIGroupItem(
                                      leading: OneUIBrandIcon(
                                        brandPresetId: preset.id,
                                        name: preset.name,
                                        brandColor: preset.color,
                                        size: 38,
                                        borderRadius: 12,
                                      ),
                                      title: preset.name,
                                      subtitle: preset.category.label,
                                      trailing: OneUIRadio(isSelected: isSelected),
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        Navigator.pop(context, _BrandPresetResult(preset));
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: OneUIBottomVignette(hasFloatingElements: _showSearch),
            ),

            // Floating Search Pill above keyboard
            if (_showSearch)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: 18,
                right: 18,
                bottom: searchPillBottom,
                child: RepaintBoundary(
                  child: _buildFloatingSearchPill(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated subpage to select System Icon with live interactive Hero Preview
class _SystemIconPickerSubpage extends StatefulWidget {
  final IconData currentIcon;
  final Color currentColor;
  final String? currentPresetId;
  final String? currentLogoUrl;
  final String subscriptionName;

  const _SystemIconPickerSubpage({
    required this.currentIcon,
    required this.currentColor,
    this.currentPresetId,
    this.currentLogoUrl,
    required this.subscriptionName,
  });

  @override
  State<_SystemIconPickerSubpage> createState() => _SystemIconPickerSubpageState();
}

class _SystemIconPickerSubpageState extends State<_SystemIconPickerSubpage> {
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.currentIcon;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = widget.subscriptionName.trim().isNotEmpty
        ? widget.subscriptionName
        : 'Icon Preview';

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'System icon',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Hero Preview Card
                      _IconHeroPreviewCard(
                        subscriptionName: effectiveName,
                        brandColor: widget.currentColor,
                        iconData: _selectedIcon,
                        logoUrl: null,
                        brandPresetId: '__none__',
                      ),
                      const SizedBox(height: 16),

                      OneUISection(
                        title: 'Curated icons',
                        child: OneUIGroupCard(
                          items: _IconPickerScreenState.systemIcons.map((icon) {
                            final isSelected = _selectedIcon.codePoint == icon.codePoint;
                            final name = _IconPickerScreenState.systemIconNames[icon] ?? 'System Icon';
                            return OneUIGroupItem(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: widget.currentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(icon, size: 20, color: widget.currentColor),
                              ),
                              title: name,
                              trailing: OneUIRadio(isSelected: isSelected),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, icon);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(hasFloatingElements: false),
          ),
        ],
      ),
    );
  }
}

/// Custom image subpage: paste a logo link, then frame it in the image editor
/// (pinch to zoom, drag to move). Follows the subpage recipe: Cancel | Save pill.
class _CustomUrlPickerSubpage extends StatefulWidget {
  final String? currentUrl;
  final LogoTransform? currentTransform;
  final Color currentColor;
  final IconData currentIcon;
  final String? currentPresetId;
  final String subscriptionName;

  const _CustomUrlPickerSubpage({
    required this.currentUrl,
    this.currentTransform,
    required this.currentColor,
    required this.currentIcon,
    this.currentPresetId,
    required this.subscriptionName,
  });

  @override
  State<_CustomUrlPickerSubpage> createState() => _CustomUrlPickerSubpageState();
}

class _CustomUrlPickerSubpageState extends State<_CustomUrlPickerSubpage> {
  final TextEditingController _controller = TextEditingController();
  late LogoTransform _transform;

  /// The link the preview shows. Follows the field only after typing pauses, so
  /// half-typed links aren't fetched on every keystroke.
  late String _previewUrl;
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.currentUrl ?? '';
    _previewUrl = _url;
    _transform = widget.currentTransform ?? LogoTransform.identity;
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _url => _controller.text.trim();

  static bool _isLink(String url) => url.startsWith('http://') || url.startsWith('https://');

  bool get _isValid => _url.isEmpty || _isLink(_url);

  bool get _hasImage => _previewUrl.isNotEmpty && _isLink(_previewUrl);

  void _onLinkChanged() {
    setState(() => _transform = LogoTransform.identity); // a new image starts unframed
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _previewUrl = _url);
    });
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      _CustomUrlResult(_url.isEmpty ? null : _url, _transform.isIdentity ? null : _transform),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final pasted = data?.text?.trim() ?? '';
    if (pasted.isEmpty || !mounted) return;
    HapticFeedback.selectionClick();
    _previewDebounce?.cancel();
    setState(() {
      _controller.text = pasted;
      _previewUrl = pasted;
      _transform = LogoTransform.identity; // a new image starts unframed
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.subscriptionName.trim().isNotEmpty ? widget.subscriptionName : 'Icon preview';
    final hadImage = widget.currentUrl != null && widget.currentUrl!.isNotEmpty;

    return OneUISubpage(
      title: 'Custom image',
      bottomPill: OneUIFloatingCancelSavePill(
        onCancel: () => Navigator.pop(context),
        onSave: _isValid ? _save : null,
        canSave: _isValid,
      ),
      builder: (context) => [
        if (_hasImage)
          OneUISection(
            title: 'Position & size',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
              decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
              child: Center(
                child: OneUILogoFramer(
                  url: _previewUrl,
                  name: name,
                  background: widget.currentColor,
                  value: _transform,
                  onChanged: (t) => setState(() => _transform = t),
                ),
              ),
            ),
          )
        else
          _IconHeroPreviewCard(
            subscriptionName: name,
            brandColor: widget.currentColor,
            iconData: widget.currentIcon,
            logoUrl: null,
            brandPresetId: '__none__',
          ),
        OneUISection(
          title: 'Image link',
          child: Container(
            decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.fieldBorderRadius),
            padding: const EdgeInsets.only(left: 20, right: 6),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, size: 22, color: OneUITheme.accentBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onChanged: (_) => _onLinkChanged(),
                    style: const TextStyle(fontSize: 15, color: OneUITheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'https://example.com/logo.png',
                      hintStyle: TextStyle(fontSize: 14.5, color: OneUITheme.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20, color: OneUITheme.textSecondary),
                    tooltip: 'Clear',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _previewDebounce?.cancel();
                      setState(() {
                        _controller.clear();
                        _previewUrl = '';
                        _transform = LogoTransform.identity;
                      });
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 20, color: OneUITheme.accentBlue),
                    tooltip: 'Paste link',
                    onPressed: _paste,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            _isValid
                ? 'Use a PNG, WebP or JPG link, e.g. the logo from the service\'s website.'
                : 'Links start with http:// or https://',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: _isValid ? OneUITheme.textSecondary : OneUITheme.accentRed,
            ),
          ),
        ),
        if (hadImage) ...[
          const SizedBox(height: 24),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                leading: const Icon(Icons.delete_outline_rounded, color: OneUITheme.accentRed, size: 22),
                title: 'Remove custom image',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, const _CustomUrlResult(null));
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Dedicated subpage to select Background Color with live interactive Hero Preview
class _BackgroundColorPickerSubpage extends StatefulWidget {
  final Color currentColor;
  final IconData currentIcon;
  final String? currentPresetId;
  final String? currentLogoUrl;
  final String subscriptionName;

  const _BackgroundColorPickerSubpage({
    required this.currentColor,
    required this.currentIcon,
    this.currentPresetId,
    this.currentLogoUrl,
    required this.subscriptionName,
  });

  @override
  State<_BackgroundColorPickerSubpage> createState() => _BackgroundColorPickerSubpageState();
}

class _BackgroundColorPickerSubpageState extends State<_BackgroundColorPickerSubpage> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = widget.subscriptionName.trim().isNotEmpty
        ? widget.subscriptionName
        : 'Icon Preview';

    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Background color',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, _selectedColor);
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Hero Preview Card (reflects the updated color and underglow live!)
                      _IconHeroPreviewCard(
                        subscriptionName: effectiveName,
                        brandColor: _selectedColor,
                        iconData: widget.currentIcon,
                        logoUrl: widget.currentLogoUrl,
                        brandPresetId: widget.currentPresetId,
                      ),
                      const SizedBox(height: 16),

                      // Swatches Grid wrapped in OneUISection
                      OneUISection(
                        title: 'Color presets',
                        child: OneUIGroupCard(
                          items: _IconPickerScreenState.swatches.map((color) {
                            final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                            final name = _IconPickerScreenState.getSwatchName(color);
                            final hex = _IconPickerScreenState.getColorHex(color);

                            return OneUIGroupItem(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              title: name,
                              subtitle: hex,
                              trailing: OneUIRadio(isSelected: isSelected),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, color);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(hasFloatingElements: false),
          ),
        ],
      ),
    );
  }
}
