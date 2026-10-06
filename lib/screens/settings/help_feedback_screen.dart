import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/router/app_router.dart';
import '../../core/telemetry/device_summary.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_card.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';

/// Settings › Help & feedback: email the developer, the public GitHub tracker, and rating.
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
    // Every row has the same shape: badge, title, one grey line, and the "opens elsewhere" icon.
    OneUIGroupItem row(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) =>
        OneUIGroupItem(
          leading: OneUIIconBadge(icon, color),
          title: title,
          subtitle: subtitle,
          subtitleColor: OneUITheme.textSecondary,
          trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
        );

    return OneUISubpage(
      title: 'Help & feedback',
      builder: (context) => [
        OneUISection(
          title: 'Contact the developer',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              row(
                Icons.mail_rounded,
                OneUITheme.accentBlue,
                'Send feedback',
                'Ideas or questions, by email',
                () => _email(context, 'One Spend feedback'),
              ),
              row(
                Icons.bug_report_rounded,
                OneUITheme.accentRed,
                'Report a problem',
                'Your phone and app version are added for you',
                () => _email(
                  context,
                  'One Spend problem report',
                  prompt: 'What happened, and what were you doing just before?',
                ),
              ),
            ],
          ),
        ),
        OneUISection(
          title: 'Community',
          child: OneUIGroupCard(
            margin: EdgeInsets.zero,
            items: [
              row(
                Icons.forum_rounded,
                OneUITheme.accentPurple,
                'Feedback on GitHub',
                'See known issues and suggest features',
                () => openExternalLink(context, AppInfo.feedbackRepoUrl),
              ),
              row(
                Icons.star_rounded,
                OneUITheme.accentAmber,
                'Rate One Spend',
                'Leave a review on Google Play',
                () => openExternalLinkOr(context, AppInfo.playStoreMarketUrl, AppInfo.playStoreUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
