import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_glass_surface.dart';
import '../utils/one_ui_brand_catalog.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI Popular Services & Presets Subpage.
/// Replaces the horizontal scroll in AddSubscriptionScreen with a clean,
/// categorized, and searchable One UI list with floating search bar.
class PopularPresetsScreen extends StatefulWidget {
  const PopularPresetsScreen({super.key});

  static Future<BrandPreset?> open(BuildContext context) {
    Haptics.tap();
    return context.push<BrandPreset>(AppRoutes.popularPresets);
  }

  @override
  State<PopularPresetsScreen> createState() => _PopularPresetsScreenState();
}

class _PopularPresetsScreenState extends State<PopularPresetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    Haptics.tap();
    setState(() {
      _showSearch = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _showSearch) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    Haptics.tap();
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search services, e.g. Netflix',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E95B8),
                        fontSize: 15,
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
                      Haptics.tap();
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
        : allPresets.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.category.label.toLowerCase().contains(q);
          }).toList();

    // Group filtered presets by category
    final Map<SubscriptionCategory, List<BrandPreset>> grouped = {};
    for (final preset in filtered) {
      grouped.putIfAbsent(preset.category, () => []).add(preset);
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
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
                // Header with back button & search action
                SliverPersistentHeader(
                  pinned: true,
                  delegate: OneUICollapsibleHeaderDelegate(
                    title: _showSearch ? 'Search presets' : 'Popular services',
                    hasBigHeader: false,
                    showBackButton: true,
                    onBack: () {
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
                              tooltip: 'Search presets',
                              onTap: _enterSearchMode,
                            ),
                          ],
                  ),
                ),

          // Presets grouped by category
          if (grouped.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: OneUITheme.textSecondary),
                      SizedBox(height: 12),
                      Text(
                        'No matching services found',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: OneUITheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, _showSearch ? (searchPillBottom + 70) : 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = grouped.keys.elementAt(index);
                    final presetsInCategory = grouped[category]!;

                    return OneUISection(
                      title: category.label,
                      child: OneUIGroupCard(
                        items: presetsInCategory.map((preset) {
                          return OneUIGroupItem(
                            leading: OneUIBrandIcon(
                              brandPresetId: preset.id,
                              name: preset.name,
                              brandColor: preset.color,
                              size: 40,
                              borderRadius: 13,
                            ),
                            title: preset.name,
                            subtitle: '${preset.category.label} • Auto-fills info',
                            subtitleColor: OneUITheme.textSecondary,
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: OneUITheme.textSecondary,
                            ),
                            onTap: () {
                              Haptics.tap();
                              Navigator.pop(context, preset);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
          ],
        ),

        // Progressive OLED Bottom Vignette Scrim (decreased when browsing, normal when search pill opens)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: OneUIBottomVignette(
            hasFloatingElements: _showSearch,
          ),
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

