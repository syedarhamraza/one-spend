import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_payment_brand_icon.dart';
import '../widgets/one_ui_switch.dart';
import '../widgets/one_ui_toast.dart';

/// Samsung One UI Subscription Detail Screen Appearance & Styling Customizer Screen
class SubscriptionDetailCustomizerScreen extends StatelessWidget {
  const SubscriptionDetailCustomizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final ctrl = OneUIEffectsController.instance;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // One UI Signature Collapsible Header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: OneUICollapsibleHeaderDelegate(
                      title: 'Detail screen styling',
                      hasBigHeader: false,
                      showBackButton: true,
                      onBack: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // Body Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Standalone Live Interactive Preview of Detail Settings Group
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _DetailScreenLivePreview(
                              showIcons: ctrl.detailShowItemIcons,
                              iconShape: ctrl.detailIconShape,
                              highlightSelectable: ctrl.detailHighlightSelectable,
                            ),
                          ),

                          // Section 1: Display options (Icon Shape)
                          OneUISection(
                            title: 'Display options',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  title: 'Icon shape',
                                  subtitle: ctrl.detailIconShape == DetailIconShape.circle
                                      ? 'Circle'
                                      : 'Rounded (Squircle)',
                                  subtitleColor: OneUITheme.accentBlue,
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: OneUITheme.textSecondary,
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const _DetailIconShapeOptionScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Section 2: Setting items details (Switches)
                          OneUISection(
                            title: 'Setting items',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      title: 'Show setting icons',
                                      subtitle: 'Display leading icons for rows under hero card',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.detailShowItemIcons,
                                        onChanged: (val) => ctrl.detailShowItemIcons = val,
                                      ),
                                      onTap: () => ctrl.detailShowItemIcons = !ctrl.detailShowItemIcons,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Blue selectable descriptions',
                                      subtitle: 'Highlight items with selectable choices in blue',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.detailHighlightSelectable,
                                        onChanged: (val) => ctrl.detailHighlightSelectable = val,
                                      ),
                                      onTap: () => ctrl.detailHighlightSelectable = !ctrl.detailHighlightSelectable,
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 6),
                                  child: Text(
                                    'When Blue selectable descriptions is enabled, values for Service name, Price, Billing cycle, Renewal date, Category, Payment method, and Plan notes display in accent blue matching One UI settings.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: OneUITheme.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Section 3: Actions (Reset)
                          OneUISection(
                            title: 'Actions',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  title: 'Reset to defaults',
                                  trailing: const SizedBox.shrink(),
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    ctrl.resetDetailStyle();
                                    OneUIToast.show(context, 'Reset detail styling to defaults');
                                  },
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
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: OneUIBottomVignette(
                  hasFloatingElements: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOneUISwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Transform.scale(
      scale: 0.88,
      alignment: Alignment.centerRight,
      child: OneUISwitch(
        value: value,
        activeTrackColor: OneUITheme.accentBlue,
        onChanged: onChanged,
      ),
    );
  }
}

/// Standalone Live Preview Card simulating the settings list of SubscriptionDetailScreen
class _DetailScreenLivePreview extends StatelessWidget {
  final bool showIcons;
  final DetailIconShape iconShape;
  final bool highlightSelectable;

  const _DetailScreenLivePreview({
    required this.showIcons,
    required this.iconShape,
    required this.highlightSelectable,
  });

  Widget? _buildPreviewIcon(IconData icon, Color color) {
    if (!showIcons) return null;
    final isCircle = iconShape == DetailIconShape.circle;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget? _buildPreviewPaymentIcon() {
    if (!showIcons) return null;
    if (iconShape == DetailIconShape.circle) {
      return const OneUIPaymentBrandIcon.square(
        brand: CardBrand.visa,
        size: 36,
        borderRadius: 18,
      );
    }
    return const OneUIPaymentBrandIcon(
      brand: CardBrand.visa,
      width: 36,
      height: 26,
    );
  }

  Color _selectableColor({Color fallback = OneUITheme.textSecondary}) {
    return highlightSelectable ? OneUITheme.accentBlue : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            'LIVE PREVIEW',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: OneUITheme.textTertiary,
            ),
          ),
        ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.badge_outlined, OneUITheme.accentBlue),
              title: 'Service name',
              subtitle: 'Netflix Premium',
              subtitleColor: _selectableColor(fallback: OneUITheme.textPrimary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.attach_money_rounded, OneUITheme.accentGreen),
              title: 'Price / Cost',
              subtitle: '\$15.99 / Monthly',
              subtitleColor: _selectableColor(fallback: OneUITheme.accentGreen),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.repeat_rounded, OneUITheme.accentPurple),
              title: 'Billing cycle',
              subtitle: 'Monthly (12x / year)',
              subtitleColor: _selectableColor(fallback: OneUITheme.textSecondary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.calendar_month_rounded, OneUITheme.accentTeal),
              title: 'Next renewal date',
              subtitle: 'Sep 30, 2026',
              subtitleColor: _selectableColor(fallback: OneUITheme.textSecondary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.movie_outlined, OneUITheme.accentPurple),
              title: 'Category',
              subtitle: 'Entertainment',
              subtitleColor: _selectableColor(fallback: OneUITheme.textPrimary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewPaymentIcon(),
              title: 'Payment method',
              subtitle: 'Visa •••• 4242',
              subtitleColor: _selectableColor(fallback: OneUITheme.textPrimary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
            OneUIGroupItem(
              leading: _buildPreviewIcon(Icons.notes_rounded, Colors.white70),
              title: 'Plan notes',
              subtitle: '4K Ultra HD • Family Plan',
              subtitleColor: _selectableColor(fallback: OneUITheme.textSecondary),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: OneUITheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dedicated subpage to select Icon Shape with interactive live preview
class _DetailIconShapeOptionScreen extends StatefulWidget {
  const _DetailIconShapeOptionScreen();

  @override
  State<_DetailIconShapeOptionScreen> createState() => _DetailIconShapeOptionScreenState();
}

class _DetailIconShapeOptionScreenState extends State<_DetailIconShapeOptionScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final ctrl = OneUIEffectsController.instance;

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
                      title: 'Icon shape',
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
                          // Live Preview Card
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DetailScreenLivePreview(
                              showIcons: ctrl.detailShowItemIcons,
                              iconShape: ctrl.detailIconShape,
                              highlightSelectable: ctrl.detailHighlightSelectable,
                            ),
                          ),

                          // Radio options card (Samsung One UI Left-Aligned Radios)
                          OneUIGroupCard(
                            items: [
                              _buildRadioItem(
                                label: 'Rounded (Squircle)',
                                value: DetailIconShape.squircle,
                                selectedValue: ctrl.detailIconShape,
                                onSelect: () => ctrl.detailIconShape = DetailIconShape.squircle,
                              ),
                              _buildRadioItem(
                                label: 'Circle',
                                value: DetailIconShape.circle,
                                selectedValue: ctrl.detailIconShape,
                                onSelect: () => ctrl.detailIconShape = DetailIconShape.circle,
                              ),
                            ],
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
                child: OneUIBottomVignette(
                  hasFloatingElements: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  OneUIGroupItem _buildRadioItem({
    required String label,
    required DetailIconShape value,
    required DetailIconShape selectedValue,
    required VoidCallback onSelect,
  }) {
    final isSelected = value == selectedValue;
    return OneUIGroupItem(
      leading: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? OneUITheme.accentBlue : const Color(0xFF5E5E62),
            width: isSelected ? 2.0 : 1.6,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: OneUITheme.accentBlue,
                ),
              )
            : null,
      ),
      title: label,
      trailing: const SizedBox.shrink(),
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
    );
  }
}
