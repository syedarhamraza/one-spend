import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';

/// Dedicated Samsung One UI Category Picker Subpage.
/// Matches the design language of ReminderPickerScreen with hero status banner,
/// One UI grouped card with descriptive subtitles, checkmarks, and floating stadium save pill.
class CategoryPickerScreen extends StatefulWidget {
  final SubscriptionCategory initialCategory;

  const CategoryPickerScreen({
    super.key,
    required this.initialCategory,
  });

  static Future<SubscriptionCategory?> open(
    BuildContext context, {
    required SubscriptionCategory initialCategory,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.push<SubscriptionCategory>(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPickerScreen(initialCategory: initialCategory),
      ),
    );
  }

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  late SubscriptionCategory _selectedCategory;

  static const Map<SubscriptionCategory, _CategoryMeta> _meta = {
    SubscriptionCategory.entertainment: _CategoryMeta(
      subtitle: 'Movies, TV series, streaming & live video',
      color: Color(0xFFE50914),
    ),
    SubscriptionCategory.music: _CategoryMeta(
      subtitle: 'Music streaming, podcasts & audiobooks',
      color: Color(0xFF1DB954),
    ),
    SubscriptionCategory.productivity: _CategoryMeta(
      subtitle: 'Productivity suites, AI assistants & workspaces',
      color: Color(0xFF6C5CE7),
    ),
    SubscriptionCategory.cloud: _CategoryMeta(
      subtitle: 'Cloud storage, file hosting & drive backup',
      color: Color(0xFF0984E3),
    ),
    SubscriptionCategory.gaming: _CategoryMeta(
      subtitle: 'Game passes, consoles & cloud gaming',
      color: Color(0xFFE84393),
    ),
    SubscriptionCategory.design: _CategoryMeta(
      subtitle: 'Creative suites, vector & graphic design tools',
      color: Color(0xFFFF7675),
    ),
    SubscriptionCategory.developer: _CategoryMeta(
      subtitle: 'Cloud hosting, APIs, code tools & repositories',
      color: Color(0xFF00CEC9),
    ),
    SubscriptionCategory.utilities: _CategoryMeta(
      subtitle: 'VPNs, password managers & privacy utilities',
      color: Color(0xFF74B9FF),
    ),
    SubscriptionCategory.finance: _CategoryMeta(
      subtitle: 'Banking, investing & personal finance trackers',
      color: Color(0xFF00B894),
    ),
    SubscriptionCategory.health: _CategoryMeta(
      subtitle: 'Fitness tracking, workout coaching & wellness',
      color: Color(0xFFFD79A8),
    ),
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, _selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta = _meta[_selectedCategory] ??
        const _CategoryMeta(subtitle: 'Subscription service', color: OneUITheme.accentBlue);

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
                  title: 'Category',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Hero Status Banner
                      AnimatedBuilder(
                        animation: OneUIEffectsController.instance,
                        builder: (context, child) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: OneUITheme.cardColor,
                              borderRadius: OneUITheme.cardBorderRadius,
                              border: OneUITheme.cardBorder,
                              boxShadow: OneUITheme.cardShadow,
                            ),
                            child: child,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: currentMeta.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                _selectedCategory.icon,
                                color: currentMeta.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCategory.label,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currentMeta.subtitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: OneUITheme.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section Label
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'ALL CATEGORIES',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: OneUITheme.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Group Card with All Categories
                      OneUIGroupCard(
                        margin: EdgeInsets.zero,
                        items: [
                          for (final cat in SubscriptionCategory.values)
                            _buildCategoryItem(cat),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Floating Stadium Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: Center(
                child: OneUIFloatingCancelSavePill(
                  cancelLabel: 'Cancel',
                  saveLabel: 'Save',
                  onCancel: () => Navigator.pop(context),
                  onSave: _save,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OneUIGroupItem _buildCategoryItem(SubscriptionCategory cat) {
    final isSelected = cat == _selectedCategory;
    final meta = _meta[cat] ??
        const _CategoryMeta(subtitle: 'Subscription service', color: OneUITheme.accentBlue);

    return OneUIGroupItem(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: isSelected ? 0.22 : 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Icon(
          cat.icon,
          size: 19,
          color: isSelected ? meta.color : OneUITheme.textPrimary.withValues(alpha: 0.85),
        ),
      ),
      title: cat.label,
      subtitle: meta.subtitle,
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: OneUITheme.accentBlue,
              size: 22,
            )
          : const Icon(
              Icons.radio_button_unchecked_rounded,
              color: OneUITheme.textTertiary,
              size: 22,
            ),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = cat;
        });
      },
    );
  }
}

class _CategoryMeta {
  final String subtitle;
  final Color color;
  const _CategoryMeta({required this.subtitle, required this.color});
}
