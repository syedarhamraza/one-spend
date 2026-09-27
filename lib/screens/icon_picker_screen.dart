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

enum IconPickerMode {
  brandPresets,
  systemIcons,
  customUrl,
}

/// Samsung One UI Subscription Icon Picker Subpage.
/// Redesigned with authentic One UI aesthetics:
/// - Standalone Live Hero Preview Card with ambient underglow
/// - Horizontal color swatch palette with illuminated selection rings
/// - Stadium-style Segmented Capsule Bar (Brand presets | System icons | Custom URL)
/// - Unified, natural single-scroll hierarchy without nested scrollbars or height caps
/// - Instant search for curated brand presets with sharp vector logos
/// - One-handed Floating Cancel | Save Pill with progressive bottom vignette
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
  IconPickerMode _activeMode = IconPickerMode.brandPresets;
  late Color _selectedColor;
  late IconData _selectedIcon;
  late String? _selectedLogoUrl;
  late String? _selectedPresetId;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Color> _swatches = [
    Color(0xFFE50914), // Red
    Color(0xFF1DB954), // Spotify Green
    Color(0xFF0066FF), // One UI Blue
    Color(0xFF8A2BE2), // Purple
    Color(0xFFFF9500), // Orange
    Color(0xFF00C7BE), // Teal
    Color(0xFFFF2D55), // Pink
    Color(0xFF34AADC), // Light Blue
    Color(0xFF10A37F), // Mint / OpenAI
    Color(0xFF2C3440), // Dark Slate
    Color(0xFF5856D6), // Indigo
    Color(0xFF555555), // Charcoal
  ];

  static const List<IconData> _systemIcons = [
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

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _selectedIcon = widget.initialIcon;
    _selectedLogoUrl = widget.initialLogoUrl;
    _selectedPresetId = widget.initialPresetId;
    _urlController.text = widget.initialLogoUrl ?? '';

    // Automatically initialize active mode based on initial values
    if (widget.initialLogoUrl != null && widget.initialLogoUrl!.isNotEmpty) {
      _activeMode = IconPickerMode.customUrl;
    } else if (widget.initialPresetId != null) {
      _activeMode = IconPickerMode.brandPresets;
    } else {
      _activeMode = IconPickerMode.brandPresets;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                      // 1. Standalone Live Hero Preview Card
                      _buildHeroPreviewCard(),
                      const SizedBox(height: 16),

                      // 2. Background Color Palette
                      OneUISection(
                        title: 'Background color',
                        child: _buildColorPaletteCard(),
                      ),
                      const SizedBox(height: 16),

                      // 3. Icon Style Segmented Capsule Bar
                      OneUISection(
                        title: 'Icon style',
                        child: _buildSegmentedCapsuleBar(),
                      ),
                      const SizedBox(height: 16),

                      // 4. Dynamic Body Content based on active mode
                      _buildActiveContent(),
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

  /// Live Interactive Hero Preview Card matching One UI settings styling
  Widget _buildHeroPreviewCard() {
    final effectiveName = widget.subscriptionName.trim().isNotEmpty
        ? widget.subscriptionName
        : 'Icon Preview';

    final glowColor = OneUIBrandCatalog.getGlowColor(
      color: _selectedColor,
      presetId: _selectedPresetId,
      name: effectiveName,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
        boxShadow: OneUITheme.cardShadow,
      ),
      child: Row(
        children: [
          // Icon with dynamic ambient glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.36),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              OneUIBrandIcon(
                name: effectiveName,
                brandColor: _selectedColor,
                iconData: _selectedIcon,
                logoUrl: _selectedLogoUrl,
                brandPresetId: _selectedPresetId,
                size: 66,
                borderRadius: 21,
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  effectiveName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: OneUITheme.surfacePill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _selectedPresetId != null
                        ? (OneUIBrandCatalog.findById(_selectedPresetId)?.name ?? _selectedPresetId!)
                        : (_selectedLogoUrl != null && _selectedLogoUrl!.isNotEmpty
                            ? 'Custom Web Link'
                            : 'System Icon'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: OneUITheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal Background Color Palette Card with smooth circle swatches
  Widget _buildColorPaletteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: OneUITheme.cardBorderRadius,
        border: OneUITheme.cardBorder,
      ),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _swatches.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final color = _swatches[index];
            final isSelected = _selectedColor.toARGB32() == color.toARGB32();

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedColor = color);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.16),
                    width: isSelected ? 2.5 : 1.0,
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
                    ? const Icon(Icons.check_rounded, size: 19, color: Colors.white)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Samsung One UI Segmented Capsule Bar (Replaces ugly tabs)
  Widget _buildSegmentedCapsuleBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: OneUITheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: OneUITheme.cardBorder,
      ),
      child: Row(
        children: [
          _buildSegmentItem('Brand presets', IconPickerMode.brandPresets),
          _buildSegmentItem('System icons', IconPickerMode.systemIcons),
          _buildSegmentItem('Custom URL', IconPickerMode.customUrl),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String label, IconPickerMode mode) {
    final isSelected = _activeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? OneUITheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: OneUITheme.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : OneUITheme.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveContent() {
    switch (_activeMode) {
      case IconPickerMode.brandPresets:
        return _buildBrandPresetsView();
      case IconPickerMode.systemIcons:
        return _buildSystemIconsView();
      case IconPickerMode.customUrl:
        return _buildCustomUrlView();
    }
  }

  Widget _buildBrandPresetsView() {
    final allPresets = OneUIBrandCatalog.presets;
    final filtered = _searchQuery.trim().isEmpty
        ? allPresets
        : allPresets.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // One UI Search Capsule
        Container(
          height: 44,
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
                    HapticFeedback.selectionClick();
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.cancel_rounded, size: 18, color: OneUITheme.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: OneUITheme.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                const Text(
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
                      _selectedColor = preset.color;
                      _selectedIcon = preset.icon;
                      _selectedLogoUrl = preset.logoUrl;
                    });
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
    );
  }

  Widget _buildSystemIconsView() {
    return Container(
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
        itemCount: _systemIcons.length,
        itemBuilder: (context, index) {
          final icon = _systemIcons[index];
          final isSelected = _selectedPresetId == null &&
              _selectedLogoUrl == null &&
              _selectedIcon.codePoint == icon.codePoint;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPresetId = null;
                _selectedLogoUrl = null;
                _selectedIcon = icon;
              });
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
    );
  }

  Widget _buildCustomUrlView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OneUIGroupCard(
          items: [
            OneUIGroupItem(
              title: 'Image link / URL',
              subtitle: _selectedLogoUrl != null && _selectedLogoUrl!.isNotEmpty
                  ? _selectedLogoUrl!
                  : 'Tap to enter or paste link',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_urlController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20, color: OneUITheme.textSecondary),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _urlController.clear();
                        setState(() {
                          _selectedLogoUrl = null;
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
                        _urlController.text = pasted;
                        setState(() {
                          _selectedLogoUrl = pasted;
                          _selectedPresetId = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: OneUITheme.cardColor,
            borderRadius: OneUITheme.cardBorderRadius,
            border: OneUITheme.cardBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _urlController,
            onChanged: (val) {
              setState(() {
                _selectedLogoUrl = val.trim().isNotEmpty ? val.trim() : null;
                _selectedPresetId = null;
              });
            },
            style: const TextStyle(fontSize: 14, color: OneUITheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'https://example.com/logo.png',
              hintStyle: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.link_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 10),
          child: Text(
            'Supported formats: PNG, WebP, or SVG web links (e.g. from company website or CDN). The image scales automatically to fit the One UI squircle.',
            style: TextStyle(
              fontSize: 12.5,
              color: OneUITheme.textSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
