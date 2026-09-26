import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_subscription_card.dart';
import '../widgets/one_ui_switch.dart';
import '../widgets/one_ui_toast.dart';

/// Samsung One UI Subscription Card Display & Data Indicators Screen
class SubscriptionCardCustomizerScreen extends StatelessWidget {
  const SubscriptionCardCustomizerScreen({super.key});

  static final Subscription _previewSub = Subscription(
    id: 'pop_spotify',
    name: 'Spotify Premium',
    description: 'Music & Podcasts streaming',
    price: 10.99,
    currency: '\$',
    billingCycle: BillingCycle.monthly,
    category: SubscriptionCategory.entertainment,
    nextBillingDate: DateTime.now().add(const Duration(days: 5)),
    brandColorValue: 0xFF1DB954,
    brandPresetId: 'spotify',
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Standalone Live Preview Card
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: OneUISubscriptionCard(
                              subscription: _previewSub,
                              paymentMethodNickname: 'Chase',
                              cardBrand: CardBrand.visa,
                              cardBrandIcon: Icons.credit_card_rounded,
                              isCardExpiring: false,
                              hasNoCard: false,
                            ),
                          ),

                          // Section 1: Display options (Navigates to dedicated subpage with live preview)
                          OneUISection(
                            title: 'Display options',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  title: 'Price display',
                                  subtitle: _priceModeLabel(ctrl.priceMode),
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
                                        builder: (_) => SubscriptionCardOptionScreen<SubscriptionPriceMode>(
                                          title: 'Price display',
                                          currentValue: ctrl.priceMode,
                                          options: const [
                                            (value: SubscriptionPriceMode.billedAmount, label: 'Actual billed amount'),
                                            (value: SubscriptionPriceMode.monthlyEquivalent, label: 'Monthly normalized'),
                                            (value: SubscriptionPriceMode.rawAmount, label: 'Amount only'),
                                          ],
                                          onSelected: (val) => ctrl.priceMode = val,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                OneUIGroupItem(
                                  title: 'Renewal badge format',
                                  subtitle: _renewalBadgeLabel(ctrl.renewalBadgeMode),
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
                                        builder: (_) => SubscriptionCardOptionScreen<SubscriptionRenewalBadgeMode>(
                                          title: 'Renewal badge format',
                                          currentValue: ctrl.renewalBadgeMode,
                                          options: const [
                                            (value: SubscriptionRenewalBadgeMode.countdown, label: 'Days remaining countdown'),
                                            (value: SubscriptionRenewalBadgeMode.exactDate, label: 'Exact renewal date'),
                                            (value: SubscriptionRenewalBadgeMode.combined, label: 'Countdown and exact date'),
                                          ],
                                          onSelected: (val) => ctrl.renewalBadgeMode = val,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Section 2: Card details (Clean switches with no descriptions)
                          OneUISection(
                            title: 'Card details',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      title: 'Payment method',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showPaymentMethodChip,
                                        onChanged: (val) => ctrl.showPaymentMethodChip = val,
                                      ),
                                      onTap: () => ctrl.showPaymentMethodChip = !ctrl.showPaymentMethodChip,
                                    ),
                                    if (ctrl.showPaymentMethodChip)
                                      OneUIGroupItem(
                                        title: 'Corner payment badge',
                                        subtitle: ctrl.paymentBadgeStyle == PaymentBadgeStyle.cornerBadge
                                            ? 'Pinned on app icon'
                                            : 'In subtitle text',
                                        trailing: _buildOneUISwitch(
                                          value: ctrl.paymentBadgeStyle == PaymentBadgeStyle.cornerBadge,
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
                                      title: 'Category',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showCategoryChip,
                                        onChanged: (val) => ctrl.showCategoryChip = val,
                                      ),
                                      onTap: () => ctrl.showCategoryChip = !ctrl.showCategoryChip,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Billing cycle',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showBillingCycle,
                                        onChanged: (val) => ctrl.showBillingCycle = val,
                                      ),
                                      onTap: () => ctrl.showBillingCycle = !ctrl.showBillingCycle,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Daily equivalent cost',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showDailyEquivalent,
                                        onChanged: (val) => ctrl.showDailyEquivalent = val,
                                      ),
                                      onTap: () => ctrl.showDailyEquivalent = !ctrl.showDailyEquivalent,
                                    ),
                                  ],
                                ),
                                if (ctrl.showPaymentMethodChip)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 6),
                                    child: Text(
                                      'When Corner payment badge is on, card logos are pinned on the app icon to prevent text clipping on smaller screens.',
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
                                    ctrl.resetCardStyle();
                                    OneUIToast.show(context, 'Reset to defaults');
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
                child: OneUIBottomVignette(),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Compact One UI Switch Builder ---

  static Widget _buildOneUISwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeTrackColor = OneUITheme.accentBlue,
  }) {
    return OneUISwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeTrackColor,
    );
  }

  // --- Display Label Helpers ---

  static String _priceModeLabel(SubscriptionPriceMode mode) {
    return switch (mode) {
      SubscriptionPriceMode.billedAmount => 'Actual billed amount',
      SubscriptionPriceMode.monthlyEquivalent => 'Monthly normalized',
      SubscriptionPriceMode.rawAmount => 'Amount only',
    };
  }

  static String _renewalBadgeLabel(SubscriptionRenewalBadgeMode mode) {
    return switch (mode) {
      SubscriptionRenewalBadgeMode.countdown => 'Days remaining countdown',
      SubscriptionRenewalBadgeMode.exactDate => 'Exact renewal date',
      SubscriptionRenewalBadgeMode.combined => 'Countdown and exact date',
    };
  }
}

/// Dedicated subpage for selecting a card setting option (e.g. Price display or Renewal badge format)
/// with a live preview card at the top matching One UI reference screenshots.
class SubscriptionCardOptionScreen<T> extends StatefulWidget {
  final String title;
  final T currentValue;
  final List<({T value, String label})> options;
  final ValueChanged<T> onSelected;

  const SubscriptionCardOptionScreen({
    super.key,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  @override
  State<SubscriptionCardOptionScreen<T>> createState() => _SubscriptionCardOptionScreenState<T>();
}

class _SubscriptionCardOptionScreenState<T> extends State<SubscriptionCardOptionScreen<T>> {
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: OneUIEffectsController.instance,
      builder: (context, _) {
        final previewSub = Subscription(
          id: 'pop_spotify',
          name: 'Spotify Premium',
          description: 'Music & Podcasts streaming',
          price: 10.99,
          currency: '\$',
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.entertainment,
          nextBillingDate: DateTime.now().add(const Duration(days: 5)),
          brandColorValue: 0xFF1DB954,
          brandPresetId: 'spotify',
        );

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
                      title: widget.title,
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
                            child: OneUISubscriptionCard(
                              subscription: previewSub,
                              paymentMethodNickname: 'Chase',
                              cardBrand: CardBrand.visa,
                              cardBrandIcon: Icons.credit_card_rounded,
                              isCardExpiring: false,
                              hasNoCard: false,
                            ),
                          ),

                          // Radio options card (Samsung One UI Left-Aligned Radios)
                          OneUIGroupCard(
                            items: widget.options.map((opt) {
                              final isSelected = opt.value == _selectedValue;
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
                                title: opt.label,
                                trailing: const SizedBox.shrink(),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedValue = opt.value;
                                  });
                                  widget.onSelected(opt.value);
                                },
                              );
                            }).toList(),
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
                child: OneUIBottomVignette(),
              ),
            ],
          ),
        );
      },
    );
  }
}
