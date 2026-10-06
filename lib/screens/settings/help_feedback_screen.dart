import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/router/app_router.dart';
import '../../core/telemetry/device_summary.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
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
    const openIcon = Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary);
    return OneUISubpage(
      title: 'Help & feedback',
      builder: (context) => [
        OneUIGroupCard(
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
          ],
        ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              leading: const OneUIIconBadge(Icons.forum_rounded, OneUITheme.textTertiary),
              title: 'Feedback on GitHub',
              subtitle: 'See known issues and suggest features',
              subtitleColor: OneUITheme.textSecondary,
              trailing: openIcon,
              onTap: () {
                HapticFeedback.lightImpact();
                openExternalLink(context, AppInfo.feedbackRepoUrl);
              },
            ),
            OneUIGroupItem(
              leading: const OneUIIconBadge(Icons.star_rounded, OneUITheme.accentAmber),
              title: 'Rate One Spend',
              subtitle: 'On Google Play',
              subtitleColor: OneUITheme.textSecondary,
              trailing: openIcon,
              onTap: () {
                HapticFeedback.lightImpact();
                openExternalLinkOr(context, AppInfo.playStoreMarketUrl, AppInfo.playStoreUrl);
              },
            ),
          ],
        ),
      ],
    );
  }
}
