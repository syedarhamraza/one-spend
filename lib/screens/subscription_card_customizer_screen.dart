import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subscription_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_toast.dart';

/// Samsung One UI Subscription Card Customizer Studio
/// Provides an interactive live preview at the top and real-time controls
/// for card layouts, background colors, custom hex colors, brand accents,
/// price modes, progress indicators, and upcoming renewal presentation.
class SubscriptionCardCustomizerScreen extends StatefulWidget {
  const SubscriptionCardCustomizerScreen({super.key});

  @override
  State<SubscriptionCardCustomizerScreen> createState() =>
      _SubscriptionCardCustomizerScreenState();
}

class _SubscriptionCardCustomizerScreenState
    extends State<SubscriptionCardCustomizerScreen> {
  int _sampleIndex = 0;

  // Curated sample subscriptions to test different brands, colors, and cycles
  final List<Subscription> _sampleSubscriptions = [
    Subscription(
      id: 'preview_netflix',
      name: 'Netflix',
      description: 'Movies & TV streaming',
      price: 22.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime.now().add(const Duration(days: 4)),
      brandColor: const Color(0xFFE50914),
      brandPresetId: 'netflix',
    ),
    Subscription(
      id: 'preview_spotify',
      name: 'Spotify Premium',
      description: 'Family music streaming plan',
      price: 131.88,
      billingCycle: BillingCycle.yearly,
      category: SubscriptionCategory.music,
      nextBillingDate: DateTime.now().add(const Duration(days: 9)),
      brandColor: const Color(0xFF1DB954),
      brandPresetId: 'spotify',
    ),
    Subscription(
      id: 'preview_youtube',
      name: 'YouTube Premium',
      description: 'Ad-free video & music',
      price: 13.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      nextBillingDate: DateTime.now().add(const Duration(days: 1)),
      brandColor: const Color(0xFFFF0000),
      brandPresetId: 'youtube',
    ),
    Subscription(
      id: 'preview_icloud',
      name: 'Apple iCloud+ 2TB',
      description: 'Cloud storage and private relay',
      price: 9.99,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.cloud,
      nextBillingDate: DateTime.now().add(const Duration(days: 22)),
      brandColor: const Color(0xFF007AFF),
      brandPresetId: 'icloud',
    ),
  ];

  static const List<Color> _customColorPalette = [
    Color(0xFF161B26), // Slate Navy
    Color(0xFF1E172E), // Deep Amethyst
    Color(0xFF1B2421), // Forest Pine Dark
    Color(0xFF281C1D), // Deep Wine Dark
    Color(0xFF202026), // Midnight Steel
    Color(0xFF2A241C), // Warm Amber Dark
    Color(0xFF11222C), // Deep Teal Dark
    Color(0xFF241628), // Mulberry Velvet
    Color(0xFF13181F), // Dark Sapphire
    Color(0xFF201A18), // Dark Espresso
  ];

  void _openCustomColorPicker() {
    HapticFeedback.lightImpact();
    final ctrl = OneUIEffectsController.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: OneUITheme.surfacePitch,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select custom background color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: OneUITheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose a surface tone for your subscription cards',
                  style: TextStyle(
                    fontSize: 13,
                    color: OneUITheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _customColorPalette.map((color) {
                    final isSelected = ctrl.cardBackground == SubscriptionCardBackground.custom &&
                        ctrl.customCardBackgroundColor.toARGB32() == color.toARGB32();

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ctrl.customCardBackgroundColor = color;
                        ctrl.cardBackground = SubscriptionCardBackground.custom;
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? OneUITheme.accentBlue : Colors.white.withValues(alpha: 0.2),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final ctrl = OneUIEffectsController.instance;
        final currentSample = _sampleSubscriptions[_sampleIndex];

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
                      title: 'Card style',
                      subtitle: 'Customize cards & appearance',
                      hasBigHeader: true,
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section: Pinned Live Preview
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'Live preview',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: OneUITheme.textSecondary,
                              ),
                            ),
                          ),

                          // Live Preview Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121316),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUISubscriptionCard(
                                  subscription: currentSample,
                                  paymentMethodNickname: 'Chase Sapphire',
                                  isCardExpiring: false,
                                  hasNoCard: false,
                                ),
                                const SizedBox(height: 12),
                                // Sample Preset Switcher
                                const Text(
                                  'Preview with sample:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: OneUITheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: List.generate(_sampleSubscriptions.length, (index) {
                                      final sample = _sampleSubscriptions[index];
                                      final isSelected = index == _sampleIndex;

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(sample.name),
                                          selected: isSelected,
                                          selectedColor: sample.brandColor.withValues(alpha: 0.25),
                                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                                          labelStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected ? sample.brandColor : OneUITheme.textSecondary,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? sample.brandColor.withValues(alpha: 0.6)
                                                : Colors.transparent,
                                          ),
                                          onSelected: (_) {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _sampleIndex = index;
                                            });
                                          },
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section 1: Card Background Color & Surface Style
                          OneUISection(
                            title: 'Background color & surface style',
                            child: OneUIGroupCard(
                              items: [
                                _buildBackgroundOption(
                                  title: 'One UI Dark',
                                  subtitle: 'Classic Samsung charcoal surface',
                                  type: SubscriptionCardBackground.oneUiDark,
                                  previewColor: const Color(0xFF1C1C1E),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.oneUiDark,
                                ),
                                _buildBackgroundOption(
                                  title: 'Pure Black (OLED)',
                                  subtitle: 'Maximum battery savings & high contrast',
                                  type: SubscriptionCardBackground.pureBlack,
                                  previewColor: const Color(0xFF090A0D),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.pureBlack,
                                ),
                                _buildBackgroundOption(
                                  title: 'Brand-tinted glow',
                                  subtitle: 'Dynamic ambient wash matching service brand',
                                  type: SubscriptionCardBackground.brandTinted,
                                  previewColor: currentSample.brandColor.withValues(alpha: 0.35),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.brandTinted,
                                ),
                                _buildBackgroundOption(
                                  title: 'Midnight Navy',
                                  subtitle: 'Modern slate-navy fintech tone',
                                  type: SubscriptionCardBackground.midnightNavy,
                                  previewColor: const Color(0xFF151B27),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.midnightNavy,
                                ),
                                _buildBackgroundOption(
                                  title: 'Deep Amethyst',
                                  subtitle: 'Warm, elegant deep violet slate',
                                  type: SubscriptionCardBackground.deepAmethyst,
                                  previewColor: const Color(0xFF1E172E),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.deepAmethyst,
                                ),
                                _buildBackgroundOption(
                                  title: 'Frosted Glass',
                                  subtitle: 'Translucent glass with soft backdrop blur',
                                  type: SubscriptionCardBackground.frostedGlass,
                                  previewColor: const Color(0xFF22242B),
                                  activeType: ctrl.cardBackground,
                                  onSelect: () => ctrl.cardBackground = SubscriptionCardBackground.frostedGlass,
                                ),
                                _buildBackgroundOption(
                                  title: 'Custom color',
                                  subtitle: 'Pick your own surface tone from a palette',
                                  type: SubscriptionCardBackground.custom,
                                  previewColor: ctrl.customCardBackgroundColor,
                                  activeType: ctrl.cardBackground,
                                  trailingAction: const Icon(Icons.palette_outlined, size: 20, color: OneUITheme.accentBlue),
                                  onSelect: () {
                                    ctrl.cardBackground = SubscriptionCardBackground.custom;
                                    _openCustomColorPicker();
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 2: Card Layout Architecture
                          OneUISection(
                            title: 'Card layout architecture',
                            child: OneUIGroupCard(
                              items: [
                                _buildLayoutOption(
                                  title: 'One UI Fluent (Grouped Cards)',
                                  subtitle: 'Native One UI grouped container with soft dividers',
                                  icon: Icons.view_agenda_outlined,
                                  layout: SubscriptionCardLayout.oneUiFluent,
                                  activeLayout: ctrl.cardLayout,
                                  onSelect: () => ctrl.cardLayout = SubscriptionCardLayout.oneUiFluent,
                                ),
                                _buildLayoutOption(
                                  title: 'Bento Elevated (Standalone Cards)',
                                  subtitle: 'Distinct standalone cards with ambient depth',
                                  icon: Icons.dashboard_customize_outlined,
                                  layout: SubscriptionCardLayout.bentoElevated,
                                  activeLayout: ctrl.cardLayout,
                                  onSelect: () => ctrl.cardLayout = SubscriptionCardLayout.bentoElevated,
                                ),
                                _buildLayoutOption(
                                  title: 'Compact Minimalist',
                                  subtitle: 'High-density streamlined rows for rapid scanning',
                                  icon: Icons.table_rows_outlined,
                                  layout: SubscriptionCardLayout.compact,
                                  activeLayout: ctrl.cardLayout,
                                  onSelect: () => ctrl.cardLayout = SubscriptionCardLayout.compact,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 3: Brand Color Accent Style
                          OneUISection(
                            title: 'Brand color accent style',
                            child: OneUIGroupCard(
                              items: [
                                _buildRadioOption<SubscriptionBrandAccent>(
                                  title: 'Left vertical accent strip',
                                  subtitle: '3.5px brand-colored indicator on the card edge',
                                  value: SubscriptionBrandAccent.leftStrip,
                                  groupValue: ctrl.brandAccent,
                                  onChanged: (val) => ctrl.brandAccent = val,
                                ),
                                _buildRadioOption<SubscriptionBrandAccent>(
                                  title: 'Subtle ambient glow',
                                  subtitle: 'Soft gradient wash across the background',
                                  value: SubscriptionBrandAccent.ambientGlow,
                                  groupValue: ctrl.brandAccent,
                                  onChanged: (val) => ctrl.brandAccent = val,
                                ),
                                _buildRadioOption<SubscriptionBrandAccent>(
                                  title: 'Border highlight',
                                  subtitle: 'Delicate 1px brand-tinted perimeter outline',
                                  value: SubscriptionBrandAccent.borderHighlight,
                                  groupValue: ctrl.brandAccent,
                                  onChanged: (val) => ctrl.brandAccent = val,
                                ),
                                _buildRadioOption<SubscriptionBrandAccent>(
                                  title: 'Neutral / monochrome',
                                  subtitle: 'Classic card surface without brand tinting',
                                  value: SubscriptionBrandAccent.neutral,
                                  groupValue: ctrl.brandAccent,
                                  onChanged: (val) => ctrl.brandAccent = val,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 4: Price & Cost Presentation
                          OneUISection(
                            title: 'Price & cost presentation',
                            child: OneUIGroupCard(
                              items: [
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Billed amount prominent',
                                  subtitle: '\$131.88/yr prominent, (\$10.99/mo) secondary',
                                  value: SubscriptionPriceMode.billedAmount,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Monthly normalized prominent',
                                  subtitle: '\$10.99/mo prominent, Billed \$131.88/yr secondary',
                                  value: SubscriptionPriceMode.monthlyEquivalent,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Raw amount only',
                                  subtitle: 'Displays only the raw recurring price',
                                  value: SubscriptionPriceMode.rawAmount,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.calendar_view_day_rounded, OneUITheme.accentTeal),
                                  title: 'Show daily equivalent cost',
                                  subtitle: 'e.g. ~\$0.76 / day underneath monthly spend',
                                  trailing: Switch.adaptive(
                                    value: ctrl.showDailyEquivalent,
                                    activeTrackColor: OneUITheme.accentBlue,
                                    onChanged: (val) => ctrl.showDailyEquivalent = val,
                                  ),
                                  onTap: () => ctrl.showDailyEquivalent = !ctrl.showDailyEquivalent,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 5: Indicators & Badges
                          OneUISection(
                            title: 'Indicators & badges',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.timelapse_rounded, OneUITheme.accentBlue),
                                  title: 'Billing cycle progress bar',
                                  subtitle: 'Shows visual progress of current billing period',
                                  trailing: Switch.adaptive(
                                    value: ctrl.showCycleProgress,
                                    activeTrackColor: OneUITheme.accentBlue,
                                    onChanged: (val) => ctrl.showCycleProgress = val,
                                  ),
                                  onTap: () => ctrl.showCycleProgress = !ctrl.showCycleProgress,
                                ),
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.credit_card_rounded, OneUITheme.accentGreen),
                                  title: 'Payment method chip',
                                  subtitle: 'Displays linked card nickname (e.g. Chase Sapphire)',
                                  trailing: Switch.adaptive(
                                    value: ctrl.showPaymentMethodChip,
                                    activeTrackColor: OneUITheme.accentBlue,
                                    onChanged: (val) => ctrl.showPaymentMethodChip = val,
                                  ),
                                  onTap: () => ctrl.showPaymentMethodChip = !ctrl.showPaymentMethodChip,
                                ),
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.category_rounded, OneUITheme.accentPurple),
                                  title: 'Category chip',
                                  subtitle: 'Displays category badge (e.g. Entertainment)',
                                  trailing: Switch.adaptive(
                                    value: ctrl.showCategoryChip,
                                    activeTrackColor: OneUITheme.accentBlue,
                                    onChanged: (val) => ctrl.showCategoryChip = val,
                                  ),
                                  onTap: () => ctrl.showCategoryChip = !ctrl.showCategoryChip,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 6: Upcoming Renewals Presentation
                          OneUISection(
                            title: 'Upcoming renewals layout',
                            child: OneUIGroupCard(
                              items: [
                                _buildRadioOption<UpcomingSectionStyle>(
                                  title: 'Horizontal swipeable carousel',
                                  subtitle: 'Swipeable cards with quick 1-tap "Paid" action',
                                  value: UpcomingSectionStyle.carousel,
                                  groupValue: ctrl.upcomingStyle,
                                  onChanged: (val) => ctrl.upcomingStyle = val,
                                ),
                                _buildRadioOption<UpcomingSectionStyle>(
                                  title: 'Standard One UI grouped list',
                                  subtitle: 'Classic 2-row grouped list card',
                                  value: UpcomingSectionStyle.groupedList,
                                  groupValue: ctrl.upcomingStyle,
                                  onChanged: (val) => ctrl.upcomingStyle = val,
                                ),
                                _buildRadioOption<UpcomingSectionStyle>(
                                  title: 'Urgent renewal spotlight',
                                  subtitle: 'Single hero card focusing on the next bill',
                                  value: UpcomingSectionStyle.spotlight,
                                  groupValue: ctrl.upcomingStyle,
                                  onChanged: (val) => ctrl.upcomingStyle = val,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Reset Button
                          OneUIGroupCard(
                            items: [
                              OneUIGroupItem(
                                leading: _buildIconBadge(Icons.refresh_rounded, OneUITheme.accentOrange),
                                title: 'Reset card styling to defaults',
                                subtitle: 'Restores default One UI Fluent layout and colors',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ctrl.cardBackground = SubscriptionCardBackground.oneUiDark;
                                  ctrl.cardLayout = SubscriptionCardLayout.oneUiFluent;
                                  ctrl.brandAccent = SubscriptionBrandAccent.leftStrip;
                                  ctrl.priceMode = SubscriptionPriceMode.billedAmount;
                                  ctrl.renewalBadgeMode = SubscriptionRenewalBadgeMode.countdown;
                                  ctrl.upcomingStyle = UpcomingSectionStyle.groupedList;
                                  ctrl.showCycleProgress = true;
                                  ctrl.showPaymentMethodChip = true;
                                  ctrl.showCategoryChip = true;
                                  ctrl.showDailyEquivalent = false;
                                  OneUIToast.show(context, 'Reset card appearance to defaults');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const OneUIBottomVignette(),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Item Builders ---

  OneUIGroupItem _buildBackgroundOption({
    required String title,
    required String subtitle,
    required SubscriptionCardBackground type,
    required Color previewColor,
    required SubscriptionCardBackground activeType,
    required VoidCallback onSelect,
    Widget? trailingAction,
  }) {
    final isSelected = activeType == type;

    return OneUIGroupItem(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: previewColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? OneUITheme.accentBlue : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
      title: title,
      subtitle: subtitle,
      trailing: trailingAction ??
          (isSelected
              ? const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
              : const Icon(Icons.circle_outlined, color: OneUITheme.textSecondary, size: 22)),
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
    );
  }

  OneUIGroupItem _buildLayoutOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required SubscriptionCardLayout layout,
    required SubscriptionCardLayout activeLayout,
    required VoidCallback onSelect,
  }) {
    final isSelected = activeLayout == layout;

    return OneUIGroupItem(
      leading: _buildIconBadge(icon, isSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary),
      title: title,
      subtitle: subtitle,
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: OneUITheme.accentBlue, size: 22)
          : const Icon(Icons.circle_outlined, color: OneUITheme.textSecondary, size: 22),
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect();
      },
    );
  }

  OneUIGroupItem _buildRadioOption<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    final isSelected = value == groupValue;

    return OneUIGroupItem(
      title: title,
      subtitle: subtitle,
      trailing: isSelected
          ? const Icon(Icons.radio_button_checked_rounded, color: OneUITheme.accentBlue, size: 22)
          : const Icon(Icons.radio_button_off_rounded, color: OneUITheme.textSecondary, size: 22),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(value);
      },
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}
