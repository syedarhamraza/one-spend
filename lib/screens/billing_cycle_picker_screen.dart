import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import '../widgets/one_ui_cancel_save_pill.dart';
import '../widgets/one_ui_card.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_radio.dart';
import '../core/haptics/haptics.dart';
import '../theme/one_ui_scroll.dart';

/// Dedicated Samsung One UI Billing Cycle Picker Subpage.
/// Matches the design language of ReminderPickerScreen with One UI grouped card,
/// clean subtitles, radio checkmarks, and floating stadium save pill,
/// streamlined without a hero preview banner.
class BillingCyclePickerScreen extends StatefulWidget {
  final BillingCycle initialCycle;

  const BillingCyclePickerScreen({
    super.key,
    required this.initialCycle,
  });

  static Future<BillingCycle?> open(
    BuildContext context, {
    required BillingCycle initialCycle,
  }) {
    Haptics.tap();
    return context.push<BillingCycle>(AppRoutes.billingCyclePicker, extra: initialCycle);
  }

  @override
  State<BillingCyclePickerScreen> createState() => _BillingCyclePickerScreenState();
}

class _BillingCyclePickerScreenState extends State<BillingCyclePickerScreen> {
  late BillingCycle _selectedCycle;

  static const Map<BillingCycle, String> _subtitles = {
    BillingCycle.monthly: 'Billed once every month (12x/yr)',
    BillingCycle.yearly: 'Billed once every year (1x/yr)',
    BillingCycle.weekly: 'Billed every week (52x/yr)',
    BillingCycle.quarterly: 'Billed every 3 months (4x/yr)',
  };

  @override
  void initState() {
    super.initState();
    _selectedCycle = widget.initialCycle;
  }

  void _save() {
    Haptics.confirm();
    Navigator.pop(context, _selectedCycle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneUITheme.surfacePitch,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const OneUIScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Billing cycle',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneUISection(
                        title: 'Billing frequency',
                        child: OneUIGroupCard(
                          margin: EdgeInsets.zero,
                          items: BillingCycle.values.map((cycle) {
                            final isSelected = cycle == _selectedCycle;
                            final subtitle = _subtitles[cycle] ??
                                'Charged ${cycle.occurrencesPerYear}x / year';

                            return OneUIGroupItem(
                              title: cycle.label,
                              subtitle: subtitle,
                              subtitleColor: OneUITheme.textSecondary,
                              trailing: OneUIRadio(isSelected: isSelected),
                              onTap: () {
                                Haptics.select();
                                setState(() {
                                  _selectedCycle = cycle;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progressive OLED Bottom Vignette Scrim
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OneUIBottomVignette(),
          ),

          // Bottom Floating Stadium Save Pill
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
          ),
        ],
      ),
    );
  }
}
