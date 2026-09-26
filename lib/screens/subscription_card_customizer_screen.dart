import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
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
                              isCardExpiring: _previewExpiring,
                              hasNoCard: false,
                            ),
                          ),

                          // Section 1: Display options (One UI Value Pickers)
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
                                  onTap: () => _pickPriceMode(context, ctrl),
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
                                  onTap: () => _pickRenewalBadgeMode(context, ctrl),
                                ),
                              ],
                            ),
                          ),

                          // Section 2: Card details (Switches)
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
                                    OneUIGroupItem(
                                      title: 'Category',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showCategoryChip,
                                        onChanged: (val) => ctrl.showCategoryChip = val,
                                      ),
                                      onTap: () => ctrl.showCategoryChip = !ctrl.showCategoryChip,
                                    ),
                                    OneUIGroupItem(
                                      title: 'Corner payment badge',
                                      subtitle: 'Badge card logo on app icon to prevent text clipping',
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
                                      title: 'Daily equivalent cost',
                                      trailing: _buildOneUISwitch(
                                        value: ctrl.showDailyEquivalent,
                                        onChanged: (val) => ctrl.showDailyEquivalent = val,
                                      ),
                                      onTap: () => ctrl.showDailyEquivalent = !ctrl.showDailyEquivalent,
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 6),
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

                          // Section 3: Status alerts
                          OneUISection(
                            title: 'Status alerts',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneUIGroupCard(
                                  items: [
                                    OneUIGroupItem(
                                      title: 'Simulate expiring card',
                                      subtitle: 'Preview "Card expiring" status badge in live card above',
                                      trailing: _buildOneUISwitch(
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
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 6),
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

                          // Section 4: Actions (Reset)
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
                                    setState(() => _previewExpiring = false);
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

  // --- One UI Adaptive Switch Builder ---

  Widget _buildOneUISwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeTrackColor = OneUITheme.accentBlue,
  }) {
    return Switch.adaptive(
      value: value,
      activeTrackColor: activeTrackColor,
      activeThumbColor: Colors.white,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFF38383A),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      onChanged: (val) {
        HapticFeedback.lightImpact();
        onChanged(val);
      },
    );
  }

  // --- One UI Floating Radio Pickers (matching media_1790397521913.png) ---

  void _pickPriceMode(BuildContext context, OneUIEffectsController ctrl) {
    _showOneUIRadioModal<SubscriptionPriceMode>(
      context: context,
      title: 'Price display',
      currentValue: ctrl.priceMode,
      options: const [
        (value: SubscriptionPriceMode.billedAmount, label: 'Actual billed amount'),
        (value: SubscriptionPriceMode.monthlyEquivalent, label: 'Monthly normalized'),
        (value: SubscriptionPriceMode.rawAmount, label: 'Amount only'),
      ],
      onSelected: (val) => ctrl.priceMode = val,
    );
  }

  void _pickRenewalBadgeMode(BuildContext context, OneUIEffectsController ctrl) {
    _showOneUIRadioModal<SubscriptionRenewalBadgeMode>(
      context: context,
      title: 'Renewal badge format',
      currentValue: ctrl.renewalBadgeMode,
      options: const [
        (value: SubscriptionRenewalBadgeMode.countdown, label: 'Days remaining countdown'),
        (value: SubscriptionRenewalBadgeMode.exactDate, label: 'Exact renewal date'),
        (value: SubscriptionRenewalBadgeMode.combined, label: 'Countdown and exact date'),
      ],
      onSelected: (val) => ctrl.renewalBadgeMode = val,
    );
  }

  void _showOneUIRadioModal<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<({T value, String label})> options,
    required ValueChanged<T> onSelected,
  }) {
    HapticFeedback.lightImpact();
    OneUIFloatingModal.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OneUITheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ...options.map((opt) {
            final isSelected = opt.value == currentValue;
            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(opt.value);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                child: Row(
                  children: [
                    Container(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: OneUITheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: OneUITheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Display Label Helpers ---

  String _priceModeLabel(SubscriptionPriceMode mode) {
    return switch (mode) {
      SubscriptionPriceMode.billedAmount => 'Actual billed amount',
      SubscriptionPriceMode.monthlyEquivalent => 'Monthly normalized',
      SubscriptionPriceMode.rawAmount => 'Amount only',
    };
  }

  String _renewalBadgeLabel(SubscriptionRenewalBadgeMode mode) {
    return switch (mode) {
      SubscriptionRenewalBadgeMode.countdown => 'Days remaining countdown',
      SubscriptionRenewalBadgeMode.exactDate => 'Exact renewal date',
      SubscriptionRenewalBadgeMode.combined => 'Countdown and exact date',
    };
  }
}
