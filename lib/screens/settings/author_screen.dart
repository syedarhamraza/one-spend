import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/router/app_router.dart';
import '../../theme/one_ui_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/one_ui_group_card.dart';
import '../../widgets/one_ui_subpage.dart';

/// Settings › About One Spend › Developer: the developer's name, GitHub and email.
class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  static Future<void> open(BuildContext context) {
    HapticFeedback.lightImpact();
    return context.push(AppRoutes.settingsAuthor);
  }

  @override
  Widget build(BuildContext context) {
    const openIcon = Icon(Icons.open_in_new_rounded, size: 18, color: OneUITheme.textSecondary);
    return OneUISubpage(
      title: 'Developer',
      builder: (context) => [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Text(
            AuthorInfo.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: OneUITheme.textPrimary,
            ),
          ),
        ),
        OneUIGroupCard(
          margin: EdgeInsets.zero,
          items: [
            OneUIGroupItem(
              title: 'GitHub',
              subtitle: '@${AuthorInfo.githubUsername}',
              subtitleColor: OneUITheme.textSecondary,
              trailing: openIcon,
              onTap: () => openExternalLink(context, AuthorInfo.githubUrl),
            ),
            OneUIGroupItem(
              title: 'Email',
              subtitle: AuthorInfo.email,
              subtitleColor: OneUITheme.textSecondary,
              trailing: openIcon,
              onTap: () => openExternalLink(context, mailtoUrl(AuthorInfo.email, subject: 'Hello from One Spend')),
            ),
          ],
        ),
      ],
    );
  }
}
