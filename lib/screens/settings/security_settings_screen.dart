import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
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
                title: PlannedFeature.privacyPolicy.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.privacyPolicy),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'One Spend stores everything on this device. It has no account, no ads and no analytics.',
            style: TextStyle(fontSize: 13, height: 1.35, color: OneUITheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
