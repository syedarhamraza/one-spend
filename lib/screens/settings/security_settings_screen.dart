import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/config/feature_flags.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';

/// Settings › Security & privacy.
class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsSecurity);
  }

  @override
  Widget build(BuildContext context) {
    return OneUISubpage(
      title: 'Security & privacy',
      builder: (context) => [
        if (FeatureFlags.showPlannedFeatures)
          OneUISection(
            title: 'Security',
            child: OneUIGroupCard(
              margin: EdgeInsets.zero,
              items: [
                OneUIGroupItem(
                  title: PlannedFeature.appLock.title,
                  trailing: const OneUISoonChip(),
                  onTap: () => ComingSoonScreen.open(context, PlannedFeature.appLock),
                ),
              ],
            ),
          ),
        OneUISection(
          title: 'Privacy',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              OneUIGroupItem(
                title: 'Privacy policy',
                onTap: () {
                  HapticFeedback.lightImpact();
                  openInAppBrowser(context, AppInfo.privacyPolicyUrl);
                },
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Your subscriptions and cards stay on this device, with no account and no ads. To fix bugs and '
            'improve the app, One Spend sends crash reports and anonymous usage statistics (which screens and '
            'features are used) to Google Firebase. It never sends your subscription names, prices, notes or '
            'card details.',
            style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
