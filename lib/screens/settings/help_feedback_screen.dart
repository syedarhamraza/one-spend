import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/config/feature_flags.dart';
import '../../core/router/app_router.dart';
import '../../core/telemetry/device_summary.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';
import 'coming_soon_screen.dart';
import 'planned_feature.dart';

/// Settings › Help & feedback.
class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsHelp);
  }

  /// Opens an email to the developer with the build and phone already filled in.
  Future<void> _email(BuildContext context, String subject, {String prompt = ''}) async {
    final details = await deviceSummary();
    if (!context.mounted) return;
    final body = '$prompt\n\n\n---\n$details';
    await openExternalLink(context, mailtoUrl(AuthorInfo.email, subject: subject, body: body.trimLeft()));
  }

  @override
  Widget build(BuildContext context) {
    const openIcon = Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary);
    return OneUISubpage(
      title: 'Help & feedback',
      builder: (context) => [
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              leading: const OneUIIconBadge(Icons.mail_rounded, OneUITheme.accentBlue),
              title: 'Send feedback',
              trailing: openIcon,
              onTap: () => _email(context, 'One Spend feedback'),
            ),
            OneUIGroupItem(
              leading: const OneUIIconBadge(Icons.bug_report_rounded, OneUITheme.accentRed),
              title: 'Report a problem',
              trailing: openIcon,
              onTap: () => _email(
                context,
                'One Spend problem report',
                prompt: 'What happened, and what were you doing just before?',
              ),
            ),
            if (FeatureFlags.showPlannedFeatures)
              OneUIGroupItem(
                leading: const OneUIIconBadge(Icons.star_rounded, OneUITheme.accentAmber),
                title: PlannedFeature.rateApp.title,
                trailing: const OneUISoonChip(),
                onTap: () => ComingSoonScreen.open(context, PlannedFeature.rateApp),
              ),
          ],
        ),
      ],
    );
  }
}
