import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../theme/one_ui_theme.dart';
import '../../../utils/external_links.dart';
import '../../../widgets/one_ui_card.dart';
import '../../../widgets/one_ui_cancel_save_pill.dart';
import '../../../widgets/one_ui_group_card.dart';
import '../../../widgets/one_ui_subpage.dart';
import '../../../widgets/one_ui_toast.dart';
import 'pro_controller.dart';

/// Settings › OneSpend Pro: what Pro includes, buy, restore and redeem a promo code.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  /// Play Store page for redeeming a promo code.
  static const redeemUrl = 'https://play.google.com/redeem';

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsPro);
  }

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final _pro = ProController.instance;
  StreamSubscription<String>? _messages;

  @override
  void initState() {
    super.initState();
    _messages = _pro.messages.listen((message) {
      if (mounted) OneUIToast.show(context, message);
    });
    unawaited(_pro.refresh());
  }

  @override
  void dispose() {
    _messages?.cancel();
    super.dispose();
  }

  Widget _hero() {
    final isPro = _pro.isPro;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(color: OneUITheme.cardColor, borderRadius: OneUITheme.cardBorderRadius),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: OneUITheme.accentAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 36, color: OneUITheme.accentAmber),
          ),
          const SizedBox(height: 18),
          Text(
            isPro ? 'You have Pro' : 'OneSpend Pro',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: OneUITheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPro
                ? 'Thanks for supporting OneSpend. Every Pro feature is unlocked on this Google account.'
                : 'Make OneSpend yours. One payment, yours for good, with no account and no ads.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4, color: OneUITheme.textSecondary),
          ),
        ],
      ),
    );
  }

  OneUIGroupItem _benefit(IconData icon, Color color, String title, String subtitle) {
    return OneUIGroupItem(
      leading: OneUIIconBadge(icon, color),
      title: title,
      subtitle: subtitle,
      subtitleColor: OneUITheme.textSecondary,
      trailing: const SizedBox.shrink(),
    );
  }

  Widget? _pill() {
    if (_pro.isPro) return null;
    final price = _pro.priceLabel;
    return OneUIFloatingCancelSavePill(
      onCancel: () => Navigator.pop(context),
      onSave: () {
        HapticFeedback.mediumImpact();
        _pro.buy();
      },
      canSave: !_pro.busy,
      saveLabel: price == null ? 'Get Pro' : 'Get Pro · $price',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pro,
      builder: (context, _) => OneUISubpage(
        title: 'OneSpend Pro',
        bottomPill: _pill(),
        builder: (context) => [
          _hero(),
          OneUISection(
            title: 'Included',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                _benefit(Icons.style_rounded, OneUITheme.accentPurple, 'Card studio',
                    'Layouts, backgrounds, brand accents and badges for your subscription cards'),
                _benefit(Icons.tune_rounded, OneUITheme.accentBlue, 'Detail studio',
                    'Icons and highlights on the subscription page'),
                _benefit(Icons.picture_as_pdf_rounded, OneUITheme.accentRed, 'PDF reports',
                    'Share your spending, a selection or one subscription as a PDF'),
                _benefit(Icons.flag_rounded, OneUITheme.accentAmber, 'Year-end projection',
                    'What this year adds up to, against your budget'),
                _benefit(Icons.savings_rounded, OneUITheme.accentGreen, 'Annual vs. monthly',
                    'See how much paying yearly would save'),
                _benefit(Icons.label_rounded, OneUITheme.accentOrange, 'Custom categories',
                    'Your own categories with their own icon and colour'),
              ],
            ),
          ),
          OneUISection(
            title: 'Coming to Pro',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                _benefit(Icons.add_to_drive_rounded, OneUITheme.accentTeal, 'Google Drive backup',
                    'Automatic backups to your own Drive'),
                _benefit(Icons.widgets_rounded, OneUITheme.accentAmber, 'Home screen widgets',
                    'Upcoming renewals and budget at a glance'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Restore purchase',
                subtitle: 'Already bought Pro on this Google account',
                subtitleColor: OneUITheme.textSecondary,
                trailing: _pro.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: OneUITheme.accentBlue),
                      )
                    : const SizedBox.shrink(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pro.restore();
                },
              ),
              OneUIGroupItem(
                title: 'Redeem a code',
                subtitle: 'Opens Google Play. Pro unlocks when you come back',
                subtitleColor: OneUITheme.textSecondary,
                trailing: const Icon(Icons.open_in_new_rounded, size: 20, color: OneUITheme.textSecondary),
                onTap: () {
                  HapticFeedback.lightImpact();
                  openExternalLink(context, ProScreen.redeemUrl);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
