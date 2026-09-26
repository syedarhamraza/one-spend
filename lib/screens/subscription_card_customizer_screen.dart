import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_toast.dart';

/// Samsung One UI Subscription Card Display & Data Indicators Screen
class SubscriptionCardCustomizerScreen extends StatelessWidget {
  const SubscriptionCardCustomizerScreen({super.key});

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

                          // Section 2: Card details
                          OneUISection(
                            title: 'Card details',
                            child: OneUIGroupCard(
                              items: [
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.credit_card_rounded, OneUITheme.accentGreen),
                                  title: 'Payment method',
                                  trailing: Switch.adaptive(
                                    value: ctrl.showPaymentMethodChip,
                                    activeTrackColor: OneUITheme.accentBlue,
                                    onChanged: (val) => ctrl.showPaymentMethodChip = val,
                                  ),
                                  onTap: () => ctrl.showPaymentMethodChip = !ctrl.showPaymentMethodChip,
                                ),
                                OneUIGroupItem(
                                  leading: _buildIconBadge(Icons.category_rounded, OneUITheme.accentPurple),
                                  title: 'Category',
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
                                title: 'Reset to defaults',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ctrl.resetCardStyle();
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
