import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
import 'one_ui_brand_icon.dart';

class IconPickerResult {
  final IconData iconData;
  final Color brandColor;
  final String? logoUrl;
  final String? brandPresetId;

  const IconPickerResult({
    required this.iconData,
    required this.brandColor,
    this.logoUrl,
    this.brandPresetId,
  });
}

/// Samsung One UI Brand Logo & Icon Picker Modal
class OneUIIconPickerModal extends StatefulWidget {
  final Color initialColor;
  final IconData initialIcon;
  final String? initialLogoUrl;
  final String? initialPresetId;

  const OneUIIconPickerModal({
    super.key,
    required this.initialColor,
    required this.initialIcon,
    this.initialLogoUrl,
    this.initialPresetId,
  });

  static Future<IconPickerResult?> show(
    BuildContext context, {
    required Color currentColor,
    required IconData currentIcon,
    String? currentLogoUrl,
    String? currentPresetId,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<IconPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OneUIIconPickerModal(
        initialColor: currentColor,
        initialIcon: currentIcon,
        initialLogoUrl: currentLogoUrl,
        initialPresetId: currentPresetId,
      ),
    );
  }

  @override
  State<OneUIIconPickerModal> createState() => _OneUIIconPickerModalState();
}

class _OneUIIconPickerModalState extends State<OneUIIconPickerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _urlController;
  String? _previewLogoUrl;

  static const List<IconData> _systemIcons = [
    Icons.subscriptions_rounded,
    Icons.movie_filter_rounded,
    Icons.smart_display_rounded,
    Icons.theaters_rounded,
    Icons.tv_rounded,
    Icons.music_note_rounded,
    Icons.album_rounded,
    Icons.headphones_rounded,
    Icons.auto_awesome_rounded,
    Icons.psychology_rounded,
    Icons.terminal_rounded,
    Icons.edit_note_rounded,
    Icons.palette_rounded,
    Icons.draw_rounded,
    Icons.brush_rounded,
    Icons.cloud_rounded,
    Icons.folder_shared_rounded,
    Icons.sports_esports_rounded,
    Icons.gamepad_rounded,
    Icons.videogame_asset_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.credit_card_rounded,
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.school_rounded,
    Icons.newspaper_rounded,
    Icons.shopping_bag_rounded,
    Icons.local_taxi_rounded,
    Icons.vpn_lock_rounded,
    Icons.password_rounded,
    Icons.wifi_rounded,
    Icons.home_rounded,
    Icons.phone_android_rounded,
    Icons.security_rounded,
    Icons.stars_rounded,
  ];

  static const List<Color> _brandColors = [
    Color(0xFF5390F5),
    Color(0xFF00C05A),
    Color(0xFFF07167),
    Color(0xFF48B5A0),
    Color(0xFF7E57C2),
    Color(0xFFF4A261),
    Color(0xFFE50914),
    Color(0xFF1DB954),
    Color(0xFF10A37F),
    Color(0xFF00A8E1),
    Color(0xFFF24E1E),
    Color(0xFF9146FF),
    Color(0xFF0A66C2),
    Color(0xFF1C1C1E),
    Color(0xFFFC4C02),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _urlController = TextEditingController(text: widget.initialLogoUrl ?? '');
    _previewLogoUrl = widget.initialLogoUrl;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.72 + bottomInset,
      decoration: const BoxDecoration(
        color: OneUITheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Modal Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Brand Logo & Icon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: OneUITheme.surfacePillActive,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: OneUITheme.textSecondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Brand Presets'),
                Tab(text: 'System Icons'),
                Tab(text: 'Custom URL'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildSystemIconsTab(),
                _buildCustomUrlTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: OneUIBrandCatalog.presets.length,
      itemBuilder: (context, index) {
        final preset = OneUIBrandCatalog.presets[index];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(
              context,
              IconPickerResult(
                iconData: preset.icon,
                brandColor: preset.color,
                brandPresetId: preset.id,
                logoUrl: preset.logoUrl,
              ),
            );
          },
          child: Column(
            children: [
              OneUIBrandIcon(
                brandPresetId: preset.id,
                name: preset.name,
                brandColor: preset.color,
                size: 52,
              ),
              const SizedBox(height: 6),
              Text(
                preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemIconsTab() {
    return Column(
      children: [
        // Color selector
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _brandColors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final color = _brandColors[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(
                    context,
                    IconPickerResult(
                      iconData: widget.initialIcon,
                      brandColor: color,
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 16),
        // Icons grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
            ),
            itemCount: _systemIcons.length,
            itemBuilder: (context, index) {
              final icon = _systemIcons[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(
                    context,
                    IconPickerResult(
                      iconData: icon,
                      brandColor: widget.initialColor,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: OneUITheme.surfacePill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomUrlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: OneUIBrandIcon(
              name: 'Custom',
              logoUrl: _previewLogoUrl,
              brandColor: widget.initialColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Custom Logo Image URL',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: OneUITheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: OneUITheme.surfacePill,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'https://example.com/logo.png',
                hintStyle: TextStyle(color: OneUITheme.textSecondary, fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() {
                  _previewLogoUrl = val.trim();
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final url = _urlController.text.trim();
                Navigator.pop(
                  context,
                  IconPickerResult(
                    iconData: widget.initialIcon,
                    brandColor: widget.initialColor,
                    logoUrl: url.isNotEmpty ? url : null,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OneUITheme.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Apply Logo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
