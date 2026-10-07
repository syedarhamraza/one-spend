import 'package:flutter/material.dart';
import '../models/subscription.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_date_formats.dart';
import '../widgets/one_ui_collapsible_header.dart';
import '../widgets/one_ui_floating_modal.dart';
import '../widgets/one_ui_group_card.dart';
import '../widgets/one_ui_toast.dart';
import '../widgets/one_ui_brand_icon.dart';
import '../widgets/one_ui_bottom_vignette.dart';
import 'date_picker_screen.dart';
import '../core/haptics/haptics.dart';

/// Samsung One UI Payment History Screen.
/// Displays reverse-chronological ledger of past subscription charges,
/// lifetime spend metrics, and allows logging or deleting payment records.
class PaymentHistoryScreen extends StatefulWidget {
  final String subscriptionId;

  const PaymentHistoryScreen({
    super.key,
    required this.subscriptionId,
  });

  static Future<void> open(BuildContext context, String subscriptionId) {
    Haptics.tap();
    return context.push(AppRoutes.paymentHistory(subscriptionId));
  }

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _dateFormat = OneUIDateFormats.fullMonthDayYear;

  void _showAddPaymentDialog(Subscription sub) async {
    final now = DateTime.now();
    final picked = await DatePickerScreen.open(
      context,
      initialDate: now,
      firstDate: DateTime(2018),
      lastDate: now,
      title: 'Payment date',
      subtitle: 'Logs a past ${sub.name} charge of ${formatMoney(sub.price, sub.currency)}',
    );

    if (picked != null && mounted) {
      final added = SubscriptionStore.instance.addPaymentRecord(sub.id, picked);
      if (added) {
        OneUIToast.show(context, 'Payment logged for ${_dateFormat.format(picked)}');
      } else {
        OneUIToast.show(context, 'A payment record for this date already exists');
      }
    }
  }

  void _confirmDeleteRecord(Subscription sub, int index, DateTime date) {
    Haptics.tap();
    OneUIFloatingModal.showConfirmationDialog(
      context: context,
      title: 'Delete record',
      message: 'Remove payment record for ${_dateFormat.format(date)}? This will adjust your lifetime spend calculation.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      confirmTextColor: OneUITheme.accentRed,
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        SubscriptionStore.instance.deletePaymentRecord(sub.id, index);
        OneUIToast.show(context, 'Record removed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = SubscriptionStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final sub = store.getSubscription(widget.subscriptionId);
        if (sub == null) {
          return const Scaffold(
            backgroundColor: OneUITheme.surfacePitch,
            body: Center(
              child: Text(
                'Subscription not found',
                style: TextStyle(color: OneUITheme.textSecondary),
              ),
            ),
          );
        }

        final linkedCard = store.getPaymentMethod(sub.paymentMethodId);
        final recordedPayments = sub.paymentHistory.length;
        final totalPaid = recordedPayments * sub.price;

        return Scaffold(
          backgroundColor: OneUITheme.surfacePitch,
          body: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
              // One UI Collapsible Header with Add Action
              SliverPersistentHeader(
                pinned: true,
                delegate: OneUICollapsibleHeaderDelegate(
                  title: 'Payment History',
                  hasBigHeader: false,
                  showBackButton: true,
                  onBack: () {
                    Haptics.tap();
                    Navigator.pop(context);
                  },
                  actions: [
                    OneUIHeaderAction(
                      icon: Icons.add,
                      size: 26,
                      tooltip: 'Add past payment',
                      onTap: () => _showAddPaymentDialog(sub),
                    ),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Metric Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: OneUITheme.cardColor,
                          borderRadius: OneUITheme.cardBorderRadius,
                          border: OneUITheme.cardBorder,
                          boxShadow: OneUITheme.cardShadow,
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                OneUIBrandIcon(
                                  subscription: sub,
                                  size: 48,
                                  borderRadius: 16,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                          color: OneUITheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${formatMoney(sub.price, sub.currency)} • ${sub.billingCycle.label}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: OneUITheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 0.8,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lifetime spend',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: OneUITheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatMoney(totalPaid, sub.currency, style: MoneyStyle.summary),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                        color: OneUITheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: OneUITheme.accentBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$recordedPayments ${recordedPayments == 1 ? 'cycle' : 'cycles'} paid',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: OneUITheme.accentBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Section Title
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 8),
                        child: Text(
                          'Payment ledger',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: OneUITheme.textSecondary,
                          ),
                        ),
                      ),

                      // Payment Ledger List or Empty State
                      if (sub.paymentHistory.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                          decoration: BoxDecoration(
                            color: OneUITheme.cardColor,
                            borderRadius: OneUITheme.cardBorderRadius,
                            border: OneUITheme.cardBorder,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: OneUITheme.accentBlue.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 34,
                                  color: OneUITheme.accentBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No payments recorded yet',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: OneUITheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Payments are automatically recorded when renewal dates occur, or when marked as paid.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: OneUITheme.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showAddPaymentDialog(sub),
                                  borderRadius: BorderRadius.circular(100),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: OneUITheme.accentBlue.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded, size: 18, color: OneUITheme.accentBlue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add past payment',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: OneUITheme.accentBlue,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        OneUIGroupCard(
                          items: [
                            for (int i = 0; i < sub.paymentHistory.length; i++)
                              OneUIGroupItem(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: OneUITheme.accentGreen.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: OneUITheme.accentGreen,
                                  ),
                                ),
                                title: _dateFormat.format(sub.paymentHistory[i]),
                                subtitle: '${formatMoney(sub.price, sub.currency)} • ${linkedCard?.nickname ?? 'Paid'}',
                                subtitleColor: OneUITheme.textSecondary,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: OneUITheme.accentGreen.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Paid',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: OneUITheme.accentGreen,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 19,
                                        color: OneUITheme.textSecondary,
                                      ),
                                      tooltip: 'Delete record',
                                      onPressed: () => _confirmDeleteRecord(sub, i, sub.paymentHistory[i]),
                                    ),
                                  ],
                                ),
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
}
