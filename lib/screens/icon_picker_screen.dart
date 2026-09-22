import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_icon_picker_modal.dart';

/// Dedicated Samsung One UI Icon Picker Subpage.
/// Replaces the bottom modal sheet with a full One UI subpage with live preview,
/// categorized tabs, color swatches, and a floating Cancel | Save pill.
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

class _IconPickerScreenState extends State<IconPickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    Icons.newspaper_rounded,
    Icons.school_rounded,
    Icons.wifi_rounded,
    Icons.shield_rounded,
    Icons.attach_money_rounded,
    Icons.subscriptions_rounded,
    Icons.star_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedColor = widget.initialColor;
    _selectedIcon = widget.initialIcon;
    _selectedLogoUrl = widget.initialLogoUrl;
    _selectedPresetId = widget.initialPresetId;
    _urlController.text = widget.initialLogoUrl ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                  onBack: () => Navigator.pop(context),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    children: [
                      // Top Live Preview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            OneUIBrandIcon(
                              name: widget.subscriptionName.isNotEmpty ? widget.subscriptionName : 'Icon Preview',
                              brandColor: _selectedColor,
                              iconData: _selectedIcon,
                              logoUrl: _selectedLogoUrl,
                              brandPresetId: _selectedPresetId,
                              size: 64,
                              borderRadius: 20,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.subscriptionName.isNotEmpty ? widget.subscriptionName : 'Live Preview',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedPresetId != null
                                        ? 'Brand Preset: ${_selectedPresetId!}'
                                        : (_selectedLogoUrl != null && _selectedLogoUrl!.isNotEmpty
                                            ? 'Custom Logo URL'
                                            : 'Custom Icon Glyph'),
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
                      const SizedBox(height: 16),

                      // Color Palette Row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Background Color',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 38,
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
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Bar & Container
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                        ),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorColor: OneUITheme.accentBlue,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.white.withValues(alpha: 0.06),
                              labelColor: OneUITheme.accentBlue,
                              unselectedLabelColor: OneUITheme.textSecondary,
                              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                              unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              tabs: const [
                                Tab(text: 'Brand Presets'),
                                Tab(text: 'System Icons'),
                                Tab(text: 'Custom URL'),
                              ],
                            ),
                            SizedBox(
                              height: 380,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildBrandPresetsTab(),
                                  _buildSystemIconsTab(),
                                  _buildCustomUrlTab(),
                                ],
                              ),
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

          // Floating Cancel | Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? (bottomInset + 12.0) : 24.0,
            child: Center(
              child: OneUIFloatingCancelSavePill(
                onCancel: () => Navigator.pop(context),
                onSave: _save,
                saveLabel: 'Save',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandPresetsTab() {
    final allPresets = OneUIBrandCatalog.presets;
    final filtered = _searchQuery.trim().isEmpty
        ? allPresets
        : allPresets.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: OneUITheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 13.5, color: OneUITheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search 40+ brands...',
                      hintStyle: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
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
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: OneUITheme.accentBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
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

  Widget _buildSystemIconsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
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
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? OneUITheme.surfacePillActive : OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? OneUITheme.accentBlue : Colors.transparent,
                width: 1.5,
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
    );
  }

  Widget _buildCustomUrlTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paste Direct Image or Icon URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Supports PNG, WebP, or SVG web links (e.g. from company website).',
            style: TextStyle(
              fontSize: 12.5,
              color: OneUITheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _urlController,
              onChanged: (val) {
                setState(() {
                  _selectedLogoUrl = val.trim().isNotEmpty ? val.trim() : null;
                  _selectedPresetId = null;
                });
              },
              style: const TextStyle(fontSize: 13.5, color: OneUITheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'https://example.com/logo.png',
                hintStyle: TextStyle(fontSize: 13.5, color: OneUITheme.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
