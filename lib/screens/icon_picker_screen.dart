import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_icon_picker_modal.dart';

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

  const IconPickerScreen({
    super.key,
    required this.initialColor,
    required this.initialIcon,
    this.initialLogoUrl,
    this.initialPresetId,
    this.subscriptionName = '',
  });

  static Future<IconPickerResult?> open(
    BuildContext context, {
    required Color currentColor,
    required IconData currentIcon,
    String? currentLogoUrl,
    String? currentPresetId,
    String subscriptionName = '',
  }) {
    HapticFeedback.lightImpact();
    return Navigator.push<IconPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => IconPickerScreen(
          initialColor: currentColor,
          initialIcon: currentIcon,
          initialLogoUrl: currentLogoUrl,
          initialPresetId: currentPresetId,
          subscriptionName: subscriptionName,
        ),
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
  ];

  static const Map<int, String> colorNames = {
    0xFFE50914: 'Netflix Red',
    0xFF1DB954: 'Spotify Green',
    0xFF0066FF: 'One UI Blue',
    0xFF8A2BE2: 'Purple',
    0xFFFF9500: 'Orange',
    0xFF00C7BE: 'Teal',
    0xFFFF2D55: 'Pink',
    0xFF34AADC: 'Light Blue',
    0xFF10A37F: 'Mint Green',
    0xFF2C3440: 'Slate Dark',
    0xFF5856D6: 'Indigo',
    0xFF555555: 'Charcoal',
  };

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
    _selectedPresetId = widget.initialPresetId;
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      IconPickerResult(
        iconData: _selectedIcon,
        brandColor: _selectedColor,
        logoUrl: _selectedLogoUrl,
        brandPresetId: (_selectedPresetId == '__none__' || _selectedPresetId == null)
            ? null
            : _selectedPresetId,
      ),
    );
  }

  String _getColorName(Color color) {
    return colorNames[color.toARGB32()] ??
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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
        _selectedLogoUrl = result.preset.logoUrl;
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
      });
    }
  }

  void _openCustomUrlSubpage() async {
    HapticFeedback.lightImpact();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomUrlPickerSubpage(
          currentUrl: _selectedLogoUrl,
          currentColor: _selectedColor,
          currentIcon: _selectedIcon,
          currentPresetId: _selectedPresetId,
          subscriptionName: widget.subscriptionName,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        final clean = result.trim();
        _selectedLogoUrl = clean.isNotEmpty ? clean : null;
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
                        brandPresetId: _selectedPresetId,
                      ),
                      const SizedBox(height: 16),

                      // 2. Icon source & geometry group items
                      OneUISection(
                        title: 'Icon style',
                        child: OneUIGroupCard(
                          items: [
                            OneUIGroupItem(
                              title: 'Brand preset',
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
/// Identical in architecture to the hero card in SubscriptionDetailScreen and OneUIBudgetCard.
class _IconHeroPreviewCard extends StatelessWidget {
  final String subscriptionName;
  final Color brandColor;
  final IconData iconData;
  final String? logoUrl;
  final String? brandPresetId;

  const _IconHeroPreviewCard({
    required this.subscriptionName,
    required this.brandColor,
    required this.iconData,
    this.logoUrl,
    this.brandPresetId,
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

    final String sourceTitle;
    final String sourceSubtitle;
    final IconData sourceBadgeIcon;

    if (isPreset) {
      final preset = OneUIBrandCatalog.findById(brandPresetId);
      sourceTitle = preset?.name ?? brandPresetId!;
      sourceSubtitle = 'Official Brand Vector';
      sourceBadgeIcon = Icons.verified_rounded;
    } else if (isCustomUrl) {
      sourceTitle = 'Custom Web Link';
      sourceSubtitle = 'Network Image Asset';
      sourceBadgeIcon = Icons.link_rounded;
    } else {
      sourceTitle = _IconPickerScreenState.systemIconNames[iconData] ?? 'System Icon';
      sourceSubtitle = 'Curated Vector Glyph';
      sourceBadgeIcon = Icons.category_rounded;
    }

    final colorHex = '#${brandColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final colorName = _IconPickerScreenState.colorNames[brandColor.toARGB32()] ?? colorHex;

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

            // 2. Frosted glass blur & flat translucent card body (no 3D borders or elevated rims)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: const Color(0xFF1B1C20).withValues(alpha: 0.68),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: OneUITheme.cardBorderRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Squircle Brand Icon (completely flat, clean, without icon glow)
                          OneUIBrandIcon(
                            name: subscriptionName,
                            brandColor: brandColor,
                            iconData: iconData,
                            logoUrl: logoUrl,
                            brandPresetId: brandPresetId,
                            size: 60,
                            borderRadius: 18,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(width: 8),
                          // Status Badge Capsule matching Subs Detail & Budget Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: OneUITheme.accentBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: OneUITheme.accentBlue.withValues(alpha: 0.20),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  sourceBadgeIcon,
                                  size: 13,
                                  color: OneUITheme.accentBlue,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPreset ? 'Preset' : (isCustomUrl ? 'Web URL' : 'System'),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: OneUITheme.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 0.8,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      const SizedBox(height: 14),

                      // Device Care Style Spec Metadata Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Selected Element Name
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    isPreset
                                        ? Icons.stars_rounded
                                        : (isCustomUrl ? Icons.link_rounded : iconData),
                                    size: 16,
                                    color: OneUITheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      sourceTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: OneUITheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right: Color preview with colored dot & label
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: brandColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  colorName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                              ],
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
    super.dispose();
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

    return PopScope(
      canPop: !_showSearch,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_showSearch) {
          setState(() {
            _showSearch = false;
            _searchQuery = '';
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: OneUITheme.surfacePitch,
        body: Stack(
          children: [
            CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OneUICollapsibleHeaderDelegate(
                    title: _showSearch ? 'Search presets' : 'Brand preset',
                    hasBigHeader: false,
                    showBackButton: true,
                    onBack: () {
                      HapticFeedback.lightImpact();
                      if (_showSearch) {
                        setState(() {
                          _showSearch = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    actions: _showSearch
                        ? null
                        : [
                            OneUIHeaderAction(
                              icon: Icons.search_rounded,
                              tooltip: 'Search brands',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _showSearch = true);
                              },
                            ),
                          ],
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
                          brandColor: _previewColor,
                          iconData: _previewIcon,
                          logoUrl: _previewLogoUrl,
                          brandPresetId: _selectedPresetId,
                        ),
                        const SizedBox(height: 16),

                        // One UI Search Capsule (only visible when search is toggled in header)
                        if (_showSearch) ...[
                          Container(
                            height: 44,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: OneUITheme.surfacePill,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 20, color: OneUITheme.textSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    onChanged: (val) => setState(() => _searchQuery = val),
                                    style: const TextStyle(fontSize: 14, color: OneUITheme.textPrimary),
                                    decoration: const InputDecoration(
                                      hintText: 'Search 40+ brands...',
                                      hintStyle: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.cancel_rounded, size: 18, color: OneUITheme.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],

                      // Brand Presets Grid
                      if (filtered.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 44, color: OneUITheme.textSecondary),
                              SizedBox(height: 12),
                              Text(
                                'No matching brand preset found',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: OneUITheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.80,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final preset = filtered[index];
                              final isSelected = _selectedPresetId == preset.id;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedPresetId = preset.id;
                                    _previewColor = preset.color;
                                    _previewIcon = preset.icon;
                                    _previewLogoUrl = preset.logoUrl;
                                  });
                                  Navigator.pop(context, _BrandPresetResult(preset));
                                },
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        OneUIBrandIcon(
                                          brandPresetId: preset.id,
                                          name: preset.name,
                                          brandColor: preset.color,
                                          size: 52,
                                          borderRadius: 16,
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3.5),
                                              decoration: const BoxDecoration(
                                                color: OneUITheme.accentBlue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      preset.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? OneUITheme.accentBlue : OneUITheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _IconPickerScreenState.systemIcons.length,
                          itemBuilder: (context, index) {
                            final icon = _IconPickerScreenState.systemIcons[index];
                            final isSelected = _selectedIcon.codePoint == icon.codePoint;

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedIcon = icon;
                                });
                                Navigator.pop(context, icon);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  color: isSelected ? OneUITheme.surfacePillActive : OneUITheme.surfacePill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? OneUITheme.accentBlue : Colors.transparent,
                                    width: 1.6,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  size: 26,
                                  color: isSelected ? OneUITheme.accentBlue : OneUITheme.textPrimary,
                                ),
                              ),
                            );
                          },
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

/// Dedicated subpage to edit/paste Custom Image URL with live interactive Hero Preview
class _CustomUrlPickerSubpage extends StatefulWidget {
  final String? currentUrl;
  final Color currentColor;
  final IconData currentIcon;
  final String? currentPresetId;
  final String subscriptionName;

  const _CustomUrlPickerSubpage({
    required this.currentUrl,
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
  late String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.currentUrl;
    _controller.text = widget.currentUrl ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  title: 'Custom image URL',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, _previewUrl);
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
                        iconData: widget.currentIcon,
                        logoUrl: _previewUrl,
                        brandPresetId: '__none__',
                      ),
                      const SizedBox(height: 16),

                      // URL input card
                      Container(
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 22, color: OneUITheme.accentBlue),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onChanged: (val) {
                                  setState(() {
                                    _previewUrl = val.trim().isNotEmpty ? val.trim() : null;
                                  });
                                },
                                style: const TextStyle(fontSize: 14, color: OneUITheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'https://example.com/logo.png',
                                  hintStyle: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_controller.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20, color: OneUITheme.textSecondary),
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _controller.clear();
                                  setState(() {
                                    _previewUrl = null;
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.content_paste_rounded, size: 20, color: OneUITheme.accentBlue),
                              tooltip: 'Paste from clipboard',
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
                                  HapticFeedback.selectionClick();
                                  final pasted = data.text!.trim();
                                  _controller.text = pasted;
                                  setState(() {
                                    _previewUrl = pasted;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                        child: Text(
                          'Supported formats: PNG, WebP, or SVG web links (e.g. from an official website or CDN). The image scales automatically to fit inside the squircle icon.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: OneUITheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Done Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context, _previewUrl);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OneUITheme.accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply URL',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
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

                      // Swatches Grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: _IconPickerScreenState.swatches.length,
                          itemBuilder: (context, index) {
                            final color = _IconPickerScreenState.swatches[index];
                            final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                            final colorName = _IconPickerScreenState.colorNames[color.toARGB32()] ?? 'Color';

                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedColor = color;
                                });
                                Navigator.pop(context, color);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.16),
                                        width: isSelected ? 2.6 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(alpha: 0.45),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    colorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
