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

/// Samsung One UI Subscription Card Display & Data Indicators Screen
/// Provides an interactive live preview at the top and real-time controls
/// for price display formats, daily equivalent costs, cycle progress bars,
/// and metadata badge chips (payment card, category).
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
                      title: 'Card details & indicators',
                      subtitle: 'Price display & metadata indicators',
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

                          // Section 1: Price & Cost Presentation
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

                          // Section 2: Indicators & Badges
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

                          // Reset Button
                          OneUIGroupCard(
                            items: [
                              OneUIGroupItem(
                                leading: _buildIconBadge(Icons.refresh_rounded, OneUITheme.accentOrange),
                                title: 'Reset card data display to defaults',
                                subtitle: 'Restores default price mode and indicator badges',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ctrl.priceMode = SubscriptionPriceMode.billedAmount;
                                  ctrl.renewalBadgeMode = SubscriptionRenewalBadgeMode.countdown;
                                  ctrl.showCycleProgress = true;
                                  ctrl.showPaymentMethodChip = true;
                                  ctrl.showCategoryChip = true;
                                  ctrl.showDailyEquivalent = false;
                                  OneUIToast.show(context, 'Reset card data display to defaults');
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
      trailing: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? OneUITheme.accentBlue : OneUITheme.textSecondary,
            width: isSelected ? 6.5 : 1.8,
          ),
        ),
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(value);
      },
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
