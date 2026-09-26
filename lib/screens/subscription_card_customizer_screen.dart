import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subscription_card.dart';
import '../widgets/one_ui_toast.dart';

/// Samsung One UI Subscription Card Display & Data Indicators Screen
class SubscriptionCardCustomizerScreen extends StatefulWidget {
  const SubscriptionCardCustomizerScreen({super.key});

  @override
  State<SubscriptionCardCustomizerScreen> createState() => _SubscriptionCardCustomizerScreenState();
}

class _SubscriptionCardCustomizerScreenState extends State<SubscriptionCardCustomizerScreen> {
  bool _previewExpiring = false;

  late final Subscription _previewSub = Subscription(
    id: 'preview_spotify',
    name: 'Spotify Premium',
    description: 'Music & Podcasts streaming',
    price: 10.99,
    currency: '\$',
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    nextBillingDate: DateTime.now().add(const Duration(days: 5)),
    brandColorValue: 0xFF1DB954,
  );

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
                      title: 'Card details & indicators',
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Standalone Live Preview Card
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: OneUISubscriptionCard(
                              subscription: _previewSub,
                              paymentMethodNickname: 'Chase Sapphire',
                              cardBrand: CardBrand.visa,
                              cardBrandIcon: Icons.credit_card_rounded,
                              isCardExpiring: _previewExpiring,
                              hasNoCard: false,
                            ),
                          ),

                          // Section 1: Price display
                          OneUISection(
                            title: 'Price display',
                            child: OneUIGroupCard(
                              items: [
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Actual billed amount',
                                  value: SubscriptionPriceMode.billedAmount,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Monthly normalized',
                                  value: SubscriptionPriceMode.monthlyEquivalent,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                                _buildRadioOption<SubscriptionPriceMode>(
                                  title: 'Amount only',
                                  value: SubscriptionPriceMode.rawAmount,
                                  groupValue: ctrl.priceMode,
                                  onChanged: (val) => ctrl.priceMode = val,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 2: Renewal badge format
                          OneUISection(
                            title: 'Renewal badge format',
                            child: OneUIGroupCard(
                              items: [
                                _buildRadioOption<SubscriptionRenewalBadgeMode>(
                                  title: 'Days remaining countdown',
                                  value: SubscriptionRenewalBadgeMode.countdown,
                                  groupValue: ctrl.renewalBadgeMode,
                                  onChanged: (val) => ctrl.renewalBadgeMode = val,
                                ),
                                _buildRadioOption<SubscriptionRenewalBadgeMode>(
                                  title: 'Exact renewal date',
                                  value: SubscriptionRenewalBadgeMode.exactDate,
                                  groupValue: ctrl.renewalBadgeMode,
                                  onChanged: (val) => ctrl.renewalBadgeMode = val,
                                ),
                                _buildRadioOption<SubscriptionRenewalBadgeMode>(
                                  title: 'Countdown and exact date',
                                  value: SubscriptionRenewalBadgeMode.combined,
                                  groupValue: ctrl.renewalBadgeMode,
                                  onChanged: (val) => ctrl.renewalBadgeMode = val,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 3: Card details & indicators
                          OneUISection(
                            title: 'Card details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      title: 'Payment method',
                                      trailing: Switch.adaptive(
                                        value: ctrl.showPaymentMethodChip,
                                        activeTrackColor: OneUITheme.accentBlue,
                                        onChanged: (val) => ctrl.showPaymentMethodChip = val,
                                      ),
                                      onTap: () => ctrl.showPaymentMethodChip = !ctrl.showPaymentMethodChip,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Category',
                                      trailing: Switch.adaptive(
                                        value: ctrl.showCategoryChip,
                                        activeTrackColor: OneUITheme.accentBlue,
                                        onChanged: (val) => ctrl.showCategoryChip = val,
                                      ),
                                      onTap: () => ctrl.showCategoryChip = !ctrl.showCategoryChip,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Corner payment badge',
                                      trailing: Switch.adaptive(
                                        value: ctrl.paymentBadgeStyle == PaymentBadgeStyle.cornerBadge,
                                        activeTrackColor: OneUITheme.accentBlue,
                                        onChanged: (val) {
                                          ctrl.paymentBadgeStyle = val
                                              ? PaymentBadgeStyle.cornerBadge
                                              : PaymentBadgeStyle.inlineSubtitle;
                                        },
                                      ),
                                      onTap: () {
                                        ctrl.paymentBadgeStyle =
                                            ctrl.paymentBadgeStyle == PaymentBadgeStyle.cornerBadge
                                                ? PaymentBadgeStyle.inlineSubtitle
                                                : PaymentBadgeStyle.cornerBadge;
                                      },
                                    ),
                                    OneUIGroupItem(
                                      title: 'Daily equivalent cost',
                                      trailing: Switch.adaptive(
                                        value: ctrl.showDailyEquivalent,
                                        activeTrackColor: OneUITheme.accentBlue,
                                        onChanged: (val) => ctrl.showDailyEquivalent = val,
                                      ),
                                      onTap: () => ctrl.showDailyEquivalent = !ctrl.showDailyEquivalent,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'When Corner payment badge is on, card logos are pinned on the app icon to prevent text clipping on smaller screens.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 4: Status badges (Card expiring & No card)
                          OneUISection(
                            title: 'Status badges',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      title: 'Simulate expiring card',
                                      trailing: Switch.adaptive(
                                        value: _previewExpiring,
                                        activeTrackColor: OneUITheme.accentAmber,
                                        onChanged: (val) {
                                          setState(() => _previewExpiring = val);
                                        },
                                      ),
                                      onTap: () {
                                        setState(() => _previewExpiring = !_previewExpiring);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Status badges like "Card expiring" and "No card" are always displayed to ensure critical payment alerts are never missed.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: OneUITheme.textSecondary.withValues(alpha: 0.8),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section 5: Reset
                          OneUIGroupCard(
                            items: [
                              OneUIGroupItem(
                                title: 'Reset to defaults',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ctrl.resetCardStyle();
                                  setState(() => _previewExpiring = false);
                                  OneUIToast.show(context, 'Reset to defaults');
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: const OneUIBottomVignette(),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Item Builders ---

  OneUIGroupItem _buildRadioOption<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    final isSelected = value == groupValue;

    return OneUIGroupItem(
      title: title,
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
}
